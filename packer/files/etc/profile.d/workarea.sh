#
# Workarea Environment Configuration
#

# Change the following settings to match your external services
# configuration if you are running your MongoDB, Elasticsearch, and/or
# Redis servers on a different machine.
#export WORKAREA_MONGOID_HOST="localhost:27015"
#export WORKAREA_ELASTICSEARCH_URL="localhost:9200"
#export WORKAREA_REDIS_HOST="localhost"
#export WORKAREA_REDIS_PORT="6379"
#export WORKAREA_REDIS_CACHE_HOST="localhost"
#export WORKAREA_REDIS_CACHE_PORT="6379"

# By default, apps on remote servers run in production mode. This
# enables caching, host protection, and loads of other features that
# help production apps run efficiently.
export RAILS_ENV="production"

# Configure your AWS S3 credentials to support uploading images. These
# settings are **REQUIRED** or the application won't install properly.
export WORKAREA_S3_ACCESS_KEY="CHANGE ME"
export WORKAREA_S3_SECRET_KEY="CHANGE ME"
export WORKAREA_S3_BUCKET_NAME="CHANGE ME"

# For more settings you can apply here, check out:
# https://developer.workarea.com/articles/configuration-for-hosting.html
