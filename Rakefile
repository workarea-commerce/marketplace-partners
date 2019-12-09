require 'bundler/setup'
require 'net/ssh'
require 'http'
require 'droplet_kit'
require 'fileutils'

NAME='workarea'
REGION='nyc3'
SIZE='8gb'
USER='root'
SSH_OPTIONS = {
  host_key: 'ssh-rsa',
  encryption: 'blowfish-cbc',
  keys: %w(~/.ssh/id_rsa.pub),
  compression: 'zlib'
}
SSH_PUBLIC = ENV['SSH_PUBLIC_KEY']
SSH_PRIVATE = ENV['SSH_PRIVATE_KEY']
DIGITALOCEAN_TOKEN = ENV['DIGITALOCEAN_TOKEN']
DO = DropletKit::Client.new(access_token: DIGITALOCEAN_TOKEN)
CONFIG_PATH = '/srv/shop/config/initializers/workarea.rb'

def image_ids
  DO.images
    .all
    .select { |image| image.name.start_with? 'workarea' }
    .map(&:id)
end

desc 'Build the DigitalOcean Marketplace Image with Packer'
task :build do
  sh 'packer build marketplace-image.json'
end

desc 'Install the latest image onto a DigitalOcean Droplet'
task :install do
  latest = image_ids.last
  ssh_keys = DO.ssh_keys.all.collect(&:fingerprint)
  droplet = DropletKit::Droplet.new(
    name: NAME,
    image: latest,
    size: SIZE,
    region: REGION,
    ssh_keys: ssh_keys
  )

  DO.droplets.create(droplet)
end

desc 'Run validations on the image template'
task :check do
  sh 'packer validate marketplace-image.json'
end

desc 'Test the droplet installation'
task :test do
  puts 'Pre-configuring Droplet...'
  droplet = DO.droplets.all.find { |droplet| droplet.name == NAME }
  ip = droplet.networks.first.first.ip_address

  FileUtils.mkdir_p '~/.ssh'
  File.write '~/.ssh/id_rsa.pub', SSH_PUBLIC unless SSH_PUBLIC.nil?
  File.write '~/.ssh/id_rsa', SSH_PRIVATE unless SSH_PRIVATE.nil?

  ssh = Net::SSH.start(ip, USER)

  ssh.exec! %(echo "WORKAREA_HOST=#{ip}" > /etc/workarea.env)
  ssh.exec! %(sed -i "s/www.shop.com/#{ip}/" #{CONFIG_PATH})
  ssh.exec! 'systemctl restart rails sidekiq'

  puts 'Checking whether Droplet is active...'
  sleep 15
  ctx = OpenSSL::SSL::SSLContext.new
  ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE
  response = HTTP.get "https://#{ip}", ssl_context: ctx
  raise response.to_s unless response.status.ok?
  puts 'Droplet is active! Test passed'
end

desc 'Remove all image snapshots and droplets'
task clean: %w[clean:images clean:droplets]

namespace :clean do
  desc 'Remove all workarea images'
  task :images do
    DO.images.all.each do |image|
      image.delete if !image.public && image.name.start_with?('workarea-')
    rescue
    end
  end

  desc 'Remove all workarea droplets'
  task :droplets do
    DO.droplets.all.each do |droplet|
      droplet.delete if droplet.name == NAME
    rescue
    end
  end
end

task default: %i[build]
