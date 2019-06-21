#!/usr/bin/env bash

export SOURCEGRAPH_VERSION=3.4.3
export USER_HOME=/home/ec2-user
export SOURCEGRAPH_CONFIG=/etc/sourcegraph
export SOURCEGRAPH_DATA=/var/opt/sourcegraph
export PATH=$PATH:/usr/local/bin
export DEBIAN_FRONTEND=noninteractive
export CAROOT=${SOURCEGRAPH_CONFIG}
export MKCERT_VERSION=1.3.0 # https://github.com/FiloSottile/mkcert/releases
export PUBLIC_HOSTNAME=$(curl http://169.254.169.254/latest/meta-data/public-hostname)
export IP_ADDRESS=$(echo $(hostname -I) | awk '{print $1;}')
export LANG_SERVER_PASS=$(echo -n $(echo -n date | sha256sum | awk '{print $1}'))

# Add Sourcegraph specific motd
cat > /etc/update-motd.d/99-one-click <<EOL
!/bin/sh

PUBLIC_HOSTNAME=$(curl http://169.254.169.254/latest/meta-data/public-hostname)

cat <<EOF

********************************************************************************

Welcome to your Sourcegraph instance.

For help and more information, visit https://docs.sourcegraph.com/

## Accessing Sourcegraph

Sourcegraph is running as the sourcegraph/server Docker container with two different access points:
 - Sourcegraph web app: https://${PUBLIC_HOSTNAME}
 - Sourcegraph management console: https://${PUBLIC_HOSTNAME}:2633

## Controlling Sourcegraph

The language servers edition of Sourcegraph uses Docker Compose so control Sourcegraph direcrtly
through the `docker-compose` binary.

## Server resources

 - Sourcegraph configuration files are in /etc/sourcegraph
 - Sourcegraph data files are in /var/opt/sourcegraph

## PostgreSQL access

Access the PostgreSQL db inside the Docker container by running: docker container exec -it sourcegraph psql -U postgres sourcegraph

## Language server configuration

Add these properties to the root object in Global settings to configure supported language extensions for precise code intel.

  "go.serverUrl": "wss://sourcegraph:${LANG_SERVER_PASS}@${PUBLIC_HOSTNAME}/lang-go",
  "go.sourcegraphUrl": "http://sourcegraph:8080",
  // 
  "typescript.serverUrl": "wss://sourcegraph:${LANG_SERVER_PASS}@${PUBLIC_HOSTNAME}/lang-typescript",
  "typescript.sourcegraphUrl": "http://sourcegraph:8080",
  "typescript.progress": true,
  //
  "python.serverUrl": "wss://sourcegraph:${LANG_SERVER_PASS}@${PUBLIC_HOSTNAME}/lang-python",
  "python.sourcegraphUrl": "http://sourcegraph:8080",

A backup of this file is at ${SOURCEGRAPH_CONFIG}/languager-server-settings.text

---

To delete this message of the day: rm -rf $(readlink -f ${0})

********************************************************************************
EOF
EOL
chmod +x /etc/update-motd.d/99-one-click
update-motd

# Update system
yum clean all
yum update -y
yum upgrade -y

# Add docker to packages list
amazon-linux-extras install docker

yum install -y \
    httpd-tools \
    docker \
    git \
    make \
    nano

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Start docker service now and on boot
systemctl enable --now --no-block docker

# Create the required Sourcegraph directories
mkdir -p ${SOURCEGRAPH_CONFIG}/management
mkdir -p ${SOURCEGRAPH_DATA}

# Install mkcert and generate root CA, certificate and key 
wget https://github.com/FiloSottile/mkcert/releases/download/v1.3.0/mkcert-v1.3.0-linux-amd64 -O /usr/local/bin/mkcert
chmod a+x /usr/local/bin/mkcert

mkcert -install
mkcert -cert-file ${SOURCEGRAPH_CONFIG}/sourcegraph.crt -key-file ${SOURCEGRAPH_CONFIG}/sourcegraph.key ${PUBLIC_HOSTNAME}

# Generate the languager server settings
htpasswd -b -c -B ${SOURCEGRAPH_CONFIG}/.lang_sever_htpasswd  sourcegraph ${LANG_SERVER_PASS}

cat > ${SOURCEGRAPH_CONFIG}/languager-server-settings.text <<EOL
Add these properties to the root object in Global settings to configure supported language extensions for precise code intel.

"go.serverUrl": "wss://sourcegraph:${LANG_SERVER_PASS}@${PUBLIC_HOSTNAME}/lang-go",
"go.sourcegraphUrl": "http://sourcegraph:8080",
// 
"typescript.serverUrl": "wss://sourcegraph:${LANG_SERVER_PASS}@${PUBLIC_HOSTNAME}/lang-typescript",
"typescript.sourcegraphUrl": "http://sourcegraph:8080",
"typescript.progress": true,
//
"python.serverUrl": "wss://sourcegraph:${LANG_SERVER_PASS}@${PUBLIC_HOSTNAME}/lang-python",
"python.sourcegraphUrl": "http://sourcegraph:8080"
}
EOL

#
# Configure NGINX for TLS support
#
cat > ${SOURCEGRAPH_CONFIG}/nginx.conf <<EOL
# This config was generated by Sourcegraph.
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
        ssl_certificate         sourcegraph.crt;
        ssl_certificate_key     sourcegraph.key;

        location / {
            proxy_pass http://backend;
            proxy_set_header Host \$http_host;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }

        location /lang-go {
            proxy_pass http://go-lang-server:4389;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "Upgrade";

            auth_basic "Basic authentication required to access language server";
            auth_basic_user_file /etc/sourcegraph/.lang_sever_htpasswd;
        }

        location /lang-typescript {
            proxy_pass http://ts-lang-server:8080;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "Upgrade";

            auth_basic "Basic authentication required to access language server";
            auth_basic_user_file /etc/sourcegraph/.lang_sever_htpasswd;
        }

        location /lang-python {
            proxy_pass http://py-lang-server:4288;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "Upgrade";

            auth_basic "Basic authentication required to access language server";
            auth_basic_user_file /etc/sourcegraph/.lang_sever_htpasswd;
        }

        location '/.well-known/acme-challenge' {
            default_type "text/plain";
            root /var/www/html;
        }
    }
}
EOL

# Use the same certificate for the management console
cp ${SOURCEGRAPH_CONFIG}/sourcegraph.crt ${SOURCEGRAPH_CONFIG}/management/cert.pem
cp ${SOURCEGRAPH_CONFIG}/sourcegraph.key ${SOURCEGRAPH_CONFIG}/management/key.pem

# Zip the CA Root key and certificate for easy downloading
sudo zip -j ${USER_HOME}/sourcegraph-root-ca.zip ${SOURCEGRAPH_CONFIG}/root*
sudo chown ec2-user ${USER_HOME}/sourcegraph-root-ca.zip

cat > ${USER_HOME}/docker-compose.yml <<EOL
version: '3.7'
services:
  sourcegraph:
    container_name: sourcegraph
    image: sourcegraph/server:${SOURCEGRAPH_VERSION}
    environment:
      - SRC_LOG_LEVEL=dbug
    ports:
      - '80:7080'
      - '443:7443'
      - '2633:2633'
    ulimits:
      nofile:
        soft: 262144
        hard: 262144
    volumes:
      - /etc/sourcegraph:/etc/sourcegraph
      - /var/opt/sourcegraph:/var/opt/sourcegraph
    networks:
      - sourcegraph
    depends_on:
      - go-lang-server
    restart: always

  go-lang-server:
    image: sourcegraph/lang-go:latest
    ports:
      - '127.0.0.1:4389:4389'
    command: ['go-langserver', '-mode=websocket', '-addr=:4389', '-usebuildserver', '-usebinarypkgcache=false']
    networks:
      - sourcegraph
    restart: always

  ts-lang-server:
    image: sourcegraph/lang-typescript:latest
    networks:
      - sourcegraph
    restart: always

  py-lang-server:
    image: sourcegraph/lang-python:latest
    networks:
      - sourcegraph

networks:
  sourcegraph:
EOL

cat > ${USER_HOME}/update-lang-servers <<EOL
#!/usr/bin/env bash

echo "[info]: Pull latest language server images"

docker image pull sourcegraph/lang-go:latest
docker image pull sourcegraph/lang-typescript:latest
docker image pull sourcegraph/lang-python:latest
EOL
chmod +x ${USER_HOME}/update-lang-servers

# TODO: Add a cronjob that runs the image pull script nightly
# echo $(crontab -l ; echo '0 0 * * * /home/ec2-user/update-lang-servers') | crontab -

cd ${USER_HOME} && docker-compose up --detach

# In case this script is used to generate a AWS marketplace image, truncate the `global_state` 
# db table so a unique site_id will be generated upon launch.
docker container exec -it sourcegraph psql -U postgres sourcegraph --command "DELETE FROM global_state WHERE 1=1;"