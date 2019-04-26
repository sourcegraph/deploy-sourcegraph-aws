#!/usr/bin/env bash

export SOURCEGRAPH_VERSION=3.3.2

export USER_HOME=/home/ec2-user
export SOURCEGRAPH_CONFIG=/etc/sourcegraph
export SOURCEGRAPH_DATA=/var/opt/sourcegraph
export PATH=$PATH:/usr/local/bin
export CAROOT=${SOURCEGRAPH_CONFIG}

# Update system
yum clean all
yum update -y
yum upgrade -y

# Add docker to packages list
amazon-linux-extras install docker

yum install -y \
    docker \
    git \
    make \
    nano \
    python3 \

# Install Docker Compose
pip3 install pip setuptools --upgrade
pip3 install docker-compose

# Start docker service now and on boot
systemctl enable --now --no-block docker

# Create the required Sourcegraph directories
mkdir -p ${SOURCEGRAPH_CONFIG}/management
mkdir -p ${SOURCEGRAPH_DATA}

# Install mkcert and generate root CA, certificate and key 
wget https://github.com/FiloSottile/mkcert/releases/download/v1.3.0/mkcert-v1.3.0-linux-amd64 -O /usr/local/bin/mkcert
chmod a+x /usr/local/bin/mkcert

mkcert -install
mkcert -cert-file ${SOURCEGRAPH_CONFIG}/sourcegraph.crt -key-file ${SOURCEGRAPH_CONFIG}/sourcegraph.key $(curl http://169.254.169.254/latest/meta-data/public-hostname)

#
# Configure the nginx.conf file for SSL.
#
# This so the nginx.conf file contents does not have to be hard-coded in this file, 
# which means a new instance will always use the original nginx.conf file from that
# image version.
#
wget https://raw.githubusercontent.com/sourcegraph/sourcegraph/v${SOURCEGRAPH_VERSION}/cmd/server/shared/assets/nginx.conf -O ${SOURCEGRAPH_CONFIG}/nginx.conf
export NGINX_FILE_PATH="${SOURCEGRAPH_CONFIG}/nginx.conf"
cp ${NGINX_FILE_PATH} ${NGINX_FILE_PATH}.bak
python -u -c "import os; print(open(os.environ['NGINX_FILE_PATH'] + '.bak').read().replace('listen 7080;', '''listen 7080 ssl;

        # Presumes .crt and.key files are in the same directory as this nginx.conf (${SOURCEGRAPH_CONFIG} in the container)
        ssl_certificate         sourcegraph.crt;
        ssl_certificate_key     sourcegraph.key;

'''
))" > ${NGINX_FILE_PATH}

# Use the same certificate for the management console
cp ${SOURCEGRAPH_CONFIG}/sourcegraph.crt ${SOURCEGRAPH_CONFIG}/management/cert.pem
cp ${SOURCEGRAPH_CONFIG}/sourcegraph.key ${SOURCEGRAPH_CONFIG}/management/key.pem

# Zip the CA Root key and certificate for easy downloading
sudo zip -j ${USER_HOME}/sourcegraph-root-ca.zip ${SOURCEGRAPH_CONFIG}/root*
sudo chown ec2-user ${USER_HOME}/sourcegraph-root-ca.zip

# Start Sourcegraph script
cat > ${USER_HOME}/sourcegraph-start <<EOL
#!/usr/bin/env bash

# Change version number, then run this script to upgrade
SOURCEGRAPH_VERSION=${SOURCEGRAPH_VERSION}

# Disable exit on non 0 as these may fail, which is ok 
# because failure will only occur if the network exists
# or if the sourcegraph container doesn't exist.
set +e
docker network create sourcegraph > /dev/null 2>&1
docker container rm -f sourcegraph > /dev/null 2>&1

# Enable exit on non 0
set -e

echo "[info]:  Running Sourcegraph ${SOURCEGRAPH_VERSION}"

# Recommend removing listening on port 7080 once SSL is configured
docker container run \\
    --name sourcegraph \\
    -d \\
    --restart on-failure \\
    \\
    --network sourcegraph \\
    --hostname sourcegraph \\
    --network-alias sourcegraph \\
    \\
    -p 80:7080 \\
    -p 443:7080 \\
    -p 2633:2633 \\
    \\
    -v ${SOURCEGRAPH_CONFIG}:${SOURCEGRAPH_CONFIG} \\
    -v ${SOURCEGRAPH_DATA}:${SOURCEGRAPH_DATA} \\
    \\
    sourcegraph/server:${SOURCEGRAPH_VERSION}
EOL

# Stop Sourcegraph script
cat > ${USER_HOME}/sourcegraph-stop <<EOL
#!/usr/bin/env bash

echo "[info]:  Stopping Sourcegraph" 
docker container stop sourcegraph > /dev/null 2>&1 docker container rm sourcegraph 
EOL

chmod +x ${USER_HOME}/sourcegraph-st*
${USER_HOME}/sourcegraph-start
