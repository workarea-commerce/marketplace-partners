#!/bin/bash
#
# Configure all login shells to use the settings in `/etc/workarea.env`.
# Set up the Workarea application's configuration if this is the first
# time someone has logged in.
#

set -a
. ../workarea.env
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
  echo -n "Enter your AWS S3 Secret Key (optional): "
  read -r secret_key
  echo -n "Enter your AWS S3 Bucket Name (optional): "
  read -r bucket_name

  ip="$(curl -s https://ipinfo.io/ip)"
  echo -n "Enter your Hostname (default $ip): "
  read -r host
  echo
  if [[ -z $host ]]; then
    host=$ip
  fi

  echo -n "Enter your CDN hostname (leave blank to use your hostname):"
  read -r host
  echo
  if [[ -z $cdn ]]; then
    cdn="https://$host"
  fi

  echo "Applying configuration..."
  {
    echo "WORKAREA_S3_ACCESS_KEY_ID=$access_key"
    echo "WORKAREA_S3_SECRET_ACCESS_KEY=$secret_key"
    echo "WORKAREA_S3_BUCKET_NAME=$bucket_name"
    echo "WORKAREA_HOST=$host"
    echo "WORKAREA_ASSET_HOST=$cdn"
  } >> ../workarea.env
  set -a
  . ../workarea.env
  set +a
  sed -i "s/www.shop.com/$host/" /srv/shop/config/initializers/workarea.rb

  if [[ -z $access_key ]]; then
    echo 'Workarea.config.asset_store = :file' >> /srv/shop/config/initializers/workarea.rb
  fi

  echo "Restarting processes..."
  systemctl restart rails sidekiq
  echo "Seeding the database..."
  pushd /srv/shop
  bin/rails db:seed
  echo "Generating admin password..."
  password=$(bin/rails workarea:admin:password)
  popd
  if [[ "$host" != "$ip" ]]; then
    echo "Setting up SSL for $host with certbot..."
    certbot --nginx
  fi
  echo "View your application at https://$host"
  echo "Log into /admin with email 'user@workarea.com' and password '$password'"
}

if [[ -z "$WORKAREA_HOST" ]]; then
  setup
fi
