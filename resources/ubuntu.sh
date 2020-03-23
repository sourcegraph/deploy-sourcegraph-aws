#!/usr/bin/env bash

export SOURCEGRAPH_VERSION=3.14.0
export USER_HOME=/home/ubuntu
export SOURCEGRAPH_CONFIG=/etc/sourcegraph
export SOURCEGRAPH_DATA=/var/opt/sourcegraph
export PATH=$PATH:/usr/local/bin
export DEBIAN_FRONTEND=noninteractive
export CAROOT=${SOURCEGRAPH_CONFIG}
export IP_ADDRESS=$(echo $(hostname -I) | awk '{print $1;}')

# Update system
apt update
apt upgrade -y

# Install Docker
apt install -y  update-motd apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"

apt update
apt-cache policy docker-ce
apt install -y docker-ce

# Configure Docker to be usable by ubuntu user and start server on boot
systemctl enable --now --no-block docker
usermod -a -G docker ubuntu

# Create the required Sourcegraph directories
mkdir -p ${SOURCEGRAPH_CONFIG}
mkdir -p ${SOURCEGRAPH_DATA}

# Install mkcert and generate root CA, certificate and key 
wget https://github.com/FiloSottile/mkcert/releases/download/v1.4.1/mkcert-v1.4.1-linux-amd64 -O /usr/local/bin/mkcert
chmod a+x /usr/local/bin/mkcert
ln -s /usr/local/bin/mkcert /usr/sbin/mkcert

# Generate self-signed certificate and key
mkcert -install
mkcert -cert-file ${SOURCEGRAPH_CONFIG}/sourcegraph.crt -key-file ${SOURCEGRAPH_CONFIG}/sourcegraph.key sourcegraph.local

# Configure NGINX file for TLS
cat > ${SOURCEGRAPH_CONFIG}/nginx.conf <<EOL
# From https://github.com/sourcegraph/sourcegraph/blob/master/cmd/server/shared/assets/nginx.conf
# You can adjust the configuration to add additional TLS or HTTP features.
# Read more at https://docs.sourcegraph.com/admin/nginx

error_log stderr;
pid /var/run/nginx.pid;

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
        listen 7443 ssl http2 default_server;        
        ssl_certificate         sourcegraph.crt;
        ssl_certificate_key     sourcegraph.key;

        location / {
            proxy_pass http://backend;
            proxy_set_header Host \$http_host;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
}
EOL

cat > /usr/local/bin/sourcegraph-start <<EOL
#!/usr/bin/env bash

SOURCEGRAPH_VERSION=${SOURCEGRAPH_VERSION}

echo "[info]: Starting Sourcegraph \${SOURCEGRAPH_VERSION}"

docker container run \\
    --name sourcegraph \\
    -d \\
    --restart always \\
    \
    -p 80:7080 \\
    -p 443:7443 \\
    -p 127.0.0.1:8080:8080 \\
    -p 127.0.0.1:3370:3370 \\
    \\
    -v ${SOURCEGRAPH_CONFIG}:${SOURCEGRAPH_CONFIG} \\
    -v ${SOURCEGRAPH_DATA}:${SOURCEGRAPH_DATA} \\
    \\
    sourcegraph/server:\${SOURCEGRAPH_VERSION} > /dev/null 2>&1
EOL

cat > /usr/local/bin/sourcegraph-stop <<EOL
#!/usr/bin/env bash

echo "[info]: Stopping Sourcegraph"
docker container stop sourcegraph > /dev/null 2>&1
docker container rm sourcegraph > /dev/null 2>&1
EOL

cat > /usr/local/bin/sourcegraph-upgrade <<EOL
#!/usr/bin/env bash

read -p "Sourcegraph version to upgrade to: " VERSION
sed -i -E "s/SOURCEGRAPH_VERSION=[0-9\.]+/SOURCEGRAPH_VERSION=\$VERSION/g"

sourcegraph-restart
EOL

cat > /usr/local/bin/sourcegraph-restart <<EOL
#!/usr/bin/env bash

sourcegraph-stop
sourcegraph-start
EOL

chmod +x /usr/local/bin/sourcegraph-*
sourcegraph-start

# In case this script is used to generate a AWS marketplace image, truncate the `global_state` 
# db table so a unique site_id will be generated upon launch.
docker container exec -it sourcegraph psql -U postgres sourcegraph --command "DELETE FROM global_state WHERE 1=1;"

# Add Sourcegraph specific motd
cat > /etc/update-motd.d/99-one-click <<EOL
#!/bin/sh
#
cat <<EOF

********************************************************************************

Welcome to your Sourcegraph instance.

For help and more information, visit https://docs.sourcegraph.com/

## Accessing Sourcegraph

Sourcegraph is running as the sourcegraph/server Docker container with two different access points:
 - Web app: https://<PUBLIC IP>
 - Grafana dashboards: https://127.0.0.1:3370 (requires SSH tunnel as access is only exposed to localhost)

## Controlling Sourcegraph

There are four scripts in the /usr/local/bin directory for controlling Sourcegraph:
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
