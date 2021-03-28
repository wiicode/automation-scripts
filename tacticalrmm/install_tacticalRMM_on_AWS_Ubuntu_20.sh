#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

#setup working directory
mkdir -p "/opt/tacticalrmm"
chmod 777 "/opt/tacticalrmm"

#prepare URLs
read -p "Enter the APP_HOST DNS address (app.example.com): " APP_HOST
read -p "Enter the API_HOST DNS address (api.example.com): " API_HOST
read -p "Enter the MESH_HOST DNS address (mesh.example.com): " MESH_HOST

#Prepare Config Files
wget -N https://raw.githubusercontent.com/wh1te909/tacticalrmm/master/docker/docker-compose.yml -P "/opt/tacticalrmm/"
wget -N https://raw.githubusercontent.com/wh1te909/tacticalrmm/master/docker/.env.example -P "/opt/tacticalrmm/"
mv /opt/tacticalrmm/.env /opt/tacticalrmm/.env_$(date +%Y-%m-%d-%H-%M-%S)
mv /opt/tacticalrmm/.env.example /opt/tacticalrmm/.env

# Assign the filename
filename="/opt/tacticalrmm/.env"
search1="app.example.com"
search2="api.example.com"
search3="mesh.example.com"

sed -i "s/$search1/$APP_HOST/" $filename
sed -i "s/$search2/$API_HOST/" $filename
sed -i "s/$search3/$MESH_HOST/" $filename
#LetsEncrypt
apt-get update -y
apt install certbot python3-certbot-apache -y
certbot certonly --manual -d $APP_HOST --agree-tos --no-bootstrap --manual-public-ip-logging-ok --preferred-challenges dns

#FUTURE WARNING: you must keep these entries clean in .ENV.
echo "CERT_PUB_KEY=$(sudo base64 -w 0 /etc/letsencrypt/live/$APP_HOST/fullchain.pem)" >> /opt/tacticalrmm/.env
echo "CERT_PRIV_KEY=$(sudo base64 -w 0 /etc/letsencrypt/live/$APP_HOST/privkey.pem)" >> /opt/tacticalrmm/.env

#docker time
apt-get update -y
apt-get remove docker docker-engine docker.io containerd runc -y

apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release -y

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install docker-ce docker-ce-cli containerd.io -y
snap install docker
apt install docker-compose -y
