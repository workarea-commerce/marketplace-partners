# Workarea One-Click Droplet Image

**NOTE:** This repo is not meant to be used directly. If you're looking for our one-click droplet image, it will be available on DigitalOcean when they approve it! :)

This is the source for Workarea's One-Click DigitalOcean Droplet, an
image that you can run in your [DigitalOcean][] account that sets up a basic
Workarea application. It uses [Packer][], a tool for creating images
from a single source configuration, to automatically build and snapshot
the image for use in DigitalOcean's marketplace.

## What's Workarea?

[Workarea](https://www.workarea.com) is an enterprise-grade commerce
platform written in [Ruby on Rails](https://rubyonrails.org). It uses
[MongoDB](https://www.mongodb.com),
[Elasticsearch](https://www.elastic.co/products/elasticsearch), and
[Redis](https://redis.io). Workarea also uses a whole lot of gems you
can see in [our
gemspec](https://github.com/workarea-commerce/workarea/blob/master/core/workarea-core.gemspec).

This droplet contains everything you need to run a basic Workarea
application, including all of the aforementioned services. It's useful
for evaluating a Commerce Cloud installation of Workarea, or simply
using it on its own for a smaller-size store.

## Building

Packer uses the [DigitalOcean builder][] to build the image as a
droplet on DigitalOcean, and save it to your account thereafter. In
order to build the image, you need to have `$DIGITALOCEAN_TOKEN` set to
an API token (with write access) that you create in your account settings.

To build the image, run `rake`.

To build a droplet using the image you just made, run `rake install`.

To ensure the droplet is working after installation, run `rake test`.

And, to delete everything you just made, run `rake clean`.

### Configuration

In the `marketplace-image.json` file, you can configure the APT packages
and flags passed to `rails new` in the `variables` section.

You can also modify these variables at runtime by using [the `-var` flag][var].

This template uses Packer's [file provisioner][] to upload complete
directories to the Droplet. The contents of `files/var/` will be
uploaded to `/var/`. Likewise, the contents of `files/etc/` will be
uploaded to `/etc/`. One important thing to note about the file
provisioner, from Packer's docs:

> The destination directory must already exist. If you need to create
> it, use a shell provisioner just prior to the file provisioner in order
> to create the directory. If the destination directory does not exist,
> the file provisioner may succeed, but it will have undefined results.

This template also uses Packer's [shell provisioner][] to run scripts
from the `/scripts` directory and install APT packages using an inline
task.

## Usage

When users first log in to the image, they will be presented with a
command-line interface that sets some required Workarea configuration in
the shell, and applies it to the `rails` and `sidekiq` services as well
as your current shell session. The script will then proceed to seed the
database with default data so you can log in immediately. If a custom
hostname is provided, the script will also set up SSL certificates and
the renewal process with [Certbot][] so you can get to work immediately.
The last line of the script run instructs you how to log into `/admin`
for the first time. Be sure to change your password after this.

### Getting Started

After creating the Workarea Droplet, SSH into your newly-created droplet
and follow the on-screen instructions to set your domain name, AWS S3
settings, and CDN domain. Most of these are optional, but are provided
here to get you started on the right foot. After database seeding
completes, you can browse your new store at the configured host or your
droplet's IP. Log in with email **user@workarea.com** and the generated
password that you see after seeds complete.

If you provide a hostname in the setup process, `certbot --nginx` will
run automatically and set up your site with a real SSL certificate
provided by LetsEncrypt. Otherwise (such as for demo or evaluation
purposes), a self-signed certificate will be generated. Since the
application runs in production mode, some kind of SSL cert is necessary
in order for the application to function properly.

## Development

The `marketplace-image.json` file is validated and built upon every
new push to the repository. Using a GitHub Workflow integrated with a
private DigitalOcean account, the CI scripts are responsible for
building, setting up, and tearing down an image for each change made to
this repository.

To test your changes actually work locally, you'll need a [DigitalOcean][]
account. Set your `$DIGITALOCEAN_TOKEN` in the environment before
running `packer`, and use the Rake tasks described above to create
images and droplets. View `rake --tasks` for a full list of tasks.

## Releasing

The droplet image must be released manually by an authorized user on the
[vendor portal][]. From here, you'll be able to select the snapshot to
use for the 1-click droplet image (which will be deleted from your
account). This should be an image built automatically using the GitHub
Workflow that is triggered when new PRs are merged, however you can also
build it manually from your local machine by running `rake`.

[DigitalOcean]: https://www.digitalocean.com
[Packer]: https://www.packer.io/intro/index.html
[DigitalOcean builder]: https://www.packer.io/docs/builders/digitalocean.html
[var]: https://www.packer.io/docs/templates/user-variables.html#setting-variables
[file provisioner]: https://www.packer.io/docs/provisioners/file.html
[shell provisioner]: https://www.packer.io/docs/provisioners/shell.html
[vendor portal]: https://marketplace.digitalocean.com/vendorportal
