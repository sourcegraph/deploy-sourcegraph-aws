#!/usr/bin/env bash

export SOURCEGRAPH_VERSION=3.13.0
export USER_HOME=/home/ec2-user
export SOURCEGRAPH_CONFIG=/etc/sourcegraph
export SOURCEGRAPH_DATA=/var/opt/sourcegraph
export PATH=$PATH:/usr/local/bin
export DEBIAN_FRONTEND=noninteractive
export CAROOT=${SOURCEGRAPH_CONFIG}
export MKCERT_VERSION=1.4.1 # https://github.com/FiloSottile/mkcert/releases
export PUBLIC_HOSTNAME=$(curl http://169.254.169.254/latest/meta-data/public-hostname)
export IP_ADDRESS=$(echo $(hostname -I) | awk '{print $1;}')

# Update system
yum clean all
yum update -y
yum upgrade -y

# Add docker to packages list
amazon-linux-extras install docker

yum install -y \
    docker \
    git \
    telnet \
    httpd-tools \
    nano \

# Start docker service now and on boot
systemctl enable --now --no-block docker

# Create the required Sourcegraph directories
mkdir -p ${SOURCEGRAPH_CONFIG}/management
mkdir -p ${SOURCEGRAPH_CONFIG}/cert
mkdir -p ${SOURCEGRAPH_DATA}

# Install mkcert and generate root CA, certificate and key 
wget https://github.com/FiloSottile/mkcert/releases/download/v${MKCERT_VERSION}/mkcert-v${MKCERT_VERSION}-linux-amd64 -O /usr/local/bin/mkcert
chmod a+x /usr/local/bin/mkcert
ln -s /usr/local/bin/mkcert /usr/sbin/mkcert

# Generate self-signed certificate and key
mkcert -install
mkcert -cert-file ${SOURCEGRAPH_CONFIG}/cert/sourcegraph.crt -key-file ${SOURCEGRAPH_CONFIG}/cert/sourcegraph.key ${PUBLIC_HOSTNAME}

# Configure NGINX file for TLS
cat > ${SOURCEGRAPH_CONFIG}/nginx.conf <<EOL
# From https://github.com/sourcegraph/sourcegraph/blob/master/cmd/server/shared/assets/nginx.conf
# You can adjust the configuration to add additional TLS or HTTP features.
# Read more at https://docs.sourcegraph.com/admin/nginx

error_log stderr;
pid /var/run/nginx.pid;

# Do not remove. The contents of sourcegraph_main.conf can change between
# versions and may include improvements to the configuration.
include nginx/sourcegraph_main.conf;

events {
}

http {
    server_tokens off;

    # SAML redirect response headers are sometimes large
    proxy_buffer_size           128k;
    proxy_buffers               8 256k;
    proxy_busy_buffers_size     256k;  

    # Do not remove. The contents of sourcegraph_http.conf can change between
    # versions and may include improvements to the configuration.
    include nginx/sourcegraph_http.conf;

    access_log off;
    upstream backend {
        # Do not remove. The contents of sourcegraph_backend.conf can change
        # between versions and may include improvements to the configuration.
        include nginx/sourcegraph_backend.conf;
    }

    # Redirect all HTTP traffic to HTTPS
    server {
        listen 7080 default_server;
        return 301 https://\$host\$request_uri;
    }

    server {
        # Do not remove. The contents of sourcegraph_server.conf can change
        # between versions and may include improvements to the configuration.
        include nginx/sourcegraph_server.conf;

        listen 7443 ssl http2 default_server;        
        ssl_certificate         cert/sourcegraph.crt;
        ssl_certificate_key     cert/sourcegraph.key;

        location / {
            proxy_pass http://backend;
            proxy_set_header Host \$http_host;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }

        # SAML redirect response headers are sometimes large
        proxy_buffer_size           128k;
        proxy_buffers               8 256k;
        proxy_busy_buffers_size     256k;        

        location '/.well-known/acme-challenge' {
            default_type "text/plain";
            root /var/www/html;
        }
    }
}
EOL

# Zip the CA Root key and certificate for easy downloading
sudo zip -j ${USER_HOME}/sourcegraph-root-ca.zip ${SOURCEGRAPH_CONFIG}/cert/*
sudo chown ec2-user ${USER_HOME}/sourcegraph-root-ca.zip

cat > ${USER_HOME}/sourcegraph-start <<EOL
#!/usr/bin/env bash

SOURCEGRAPH_VERSION=${SOURCEGRAPH_VERSION}

# Disable exit on non 0 as these may fail, which is ok 
# because failure will only occur if the network exists
# or if the sourcegraph container doesn't exist.
set +e
docker network create sourcegraph > /dev/null 2>&1
docker container rm -f sourcegraph > /dev/null 2>&1

# Enable exit on non 0
set -e

echo "[info]: Starting Sourcegraph \${SOURCEGRAPH_VERSION}"

docker container run \\
    --name sourcegraph \\
    -d \\
    --restart always \\
    \\
    --network sourcegraph \\
    --hostname sourcegraph \\
    --network-alias sourcegraph \\
    \\
    -p 80:7080 \\
    -p 443:7443 \\
    -p 127.0.0.1:8080:8080 \\
    -p 127.0.0.1:3370:3370 \\
    \\
    -v ${SOURCEGRAPH_CONFIG}:${SOURCEGRAPH_CONFIG} \\
    -v ${SOURCEGRAPH_DATA}:${SOURCEGRAPH_DATA} \\
    \\
    sourcegraph/server:\${SOURCEGRAPH_VERSION}
EOL

cat > ${USER_HOME}/sourcegraph-stop <<EOL
#!/usr/bin/env bash

echo "[info]:  Stopping Sourcegraph"
docker container stop sourcegraph > /dev/null 2>&1 docker container rm sourcegraph 
EOL

cat > ${USER_HOME}/sourcegraph-upgrade <<EOL
#!/usr/bin/env bash

./sourcegraph-stop

read -p "Sourcegraph version to upgrade to: " VERSION
sed -i -E "s/SOURCEGRAPH_VERSION=[0-9\.]+/SOURCEGRAPH_VERSION=\$VERSION/g" ./sourcegraph-start

./sourcegraph-start
EOL

cat > ${USER_HOME}/sourcegraph-restart <<EOL
#!/usr/bin/env bash

./sourcegraph-stop
./sourcegraph-start
EOL

chmod +x ${USER_HOME}/sourcegraph-*
${USER_HOME}/sourcegraph-start

# In case this script is used to generate a AWS marketplace image, truncate the `global_state` 
# db table so a unique site_id will be generated upon launch.
docker container exec -it sourcegraph psql -U postgres sourcegraph --command "DELETE FROM global_state WHERE 1=1;"


# Add Sourcegraph specific motd
cat > /etc/update-motd.d/99-one-click <<EOL
#!/bin/sh
#
PUBLIC_HOSTNAME=$(curl http://169.254.169.254/latest/meta-data/public-hostname)
cat <<EOF

********************************************************************************

Welcome to your Sourcegraph instance.

For help and more information, visit https://docs.sourcegraph.com/

## Accessing Sourcegraph

Sourcegraph is running as the sourcegraph/server Docker container with two different access points:
 - Web app: https://${PUBLIC_HOSTNAME}
 - Grafana dashboards: https://127.0.0.1:3370 (requires SSH tunnel as access is only exposed to localhost)

## Controlling Sourcegraph

There are four scripts in the /root directory for controlling Sourcegraph:
 - sourcegraph-start
 - sourcegraph-stop
 - sourcegraph-restart
 - sourcegraph-upgrade

## Server resources

 - Sourcegraph configuration files are in /etc/sourcegraph
 - Sourcegraph data files are in /var/opt/sourcegraph

## PostgreSQL access

Access the PostgreSQL db inside the Docker container by running: docker container exec -it sourcegraph psql -U postgres sourcegraph

---

For support, log an issue at https://github.com/sourcegraph/deploy-sourcegraph-aws/issues/new or email support@sourcegraph.com.

To delete this message of the day: rm -rf $(readlink -f ${0})

********************************************************************************
EOF
EOL
chmod +x /etc/update-motd.d/99-one-click
update-motd
