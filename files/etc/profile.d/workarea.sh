#!/bin/bash
#
# Configure all login shells to use the settings in `/etc/workarea.env`.
# Set up the Workarea application's configuration if this is the first
# time someone has logged in.
#

set -a
. /etc/workarea.env
set +a

setup() {
  local ip
  local host
  local access_key
  local secret_key
  local bucket_name
  local password
  local cdn

  echo
  echo "Welcome to your new Workarea application!"
  echo
  echo "There are just a few options you need to set..."
  echo

  echo -n "Enter your AWS S3 Access Key (optional): "
  read -r access_key
  if [[ -e $access_key ]]; then
    echo "WORKAREA_S3_ACCESS_KEY_ID=$access_key" >> /etc/workarea.env
  fi
  echo -n "Enter your AWS S3 Secret Key (optional): "
  read -r secret_key
  if [[ -e $secret_key ]]; then
    echo "WORKAREA_S3_SECRET_ACCESS_KEY=$secret_key" >> /etc/workarea.env
  fi
  echo -n "Enter your AWS S3 Bucket Name (optional): "
  read -r bucket_name
  if [[ -e $bucket_name ]]; then
    echo "WORKAREA_S3_BUCKET_NAME=$bucket_name" >> /etc/workarea.env
  fi
  if [[ -z $access_key && -z $secret_key ]]; then
    echo 'Workarea.config.asset_store = :file' > /srv/shop/config/initializers/local_asset_store.rb
  fi

  ip="$(curl -s https://ipinfo.io/ip)"
  echo -n "Enter your Hostname (default $ip): "
  read -r host
  echo
  if [[ -z $host ]]; then
    host=$ip
  fi
  echo "WORKAREA_HOST=$host" >> /etc/workarea.env

  echo -n "Enter your CDN hostname  (leave blank to use your hostname,
do not put in your protocol like https://, this is handled for you):"
  read -r cdn
  echo
  if [[ -z $cdn ]]; then
    cdn="https://$host"
  fi
  echo "WORKAREA_ASSET_HOST=$cdn" >> /etc/workarea.env

  echo "Applying configuration..."
  set -a
  . /etc/workarea.env
  set +a
  sed -i "s/www.shop.com/$host/" /srv/shop/config/initializers/workarea.rb

  if [[ "$host" != "$ip" ]]; then
    echo "Setting up SSL for $host with certbot..."
    certbot --nginx
  else
    echo "Generating self-signed SSL cert..."
    pushd /etc/ssl/private
    openssl genrsa -out workarea.key 2048 > /dev/null 2>&1
    openssl rsa -in workarea.key -out workarea.key > /dev/null 2>&1
    openssl req -sha256 -new -key workarea.key -out workarea.csr -subj "/CN=$ip" > /dev/null 2>&1
    openssl x509 -req -sha256 -days 365 -in workarea.csr -signkey workarea.key -out workarea.crt > /dev/null 2>&1
    popd
  fi

  echo "Restarting processes..."
  systemctl restart rails sidekiq nginx
  printf "Waiting for Elasticsearch..."
  until curl -s http://localhost:9200 > /dev/null; do
    printf "."
  done
  echo
  echo "Seeding the database..."
  pushd /srv/shop
  bin/rails db:seed
  echo "Generating admin password..."
  bin/rails workarea:admin:password
  popd
  echo "View your application at https://$host"
}

if [[ -z "$WORKAREA_HOST" ]]; then
  setup
fi
