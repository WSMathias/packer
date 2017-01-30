#!/bin/bash

set -o errexit

source $(dirname $0)/export_env_vars.sh


# check prerequisites
command -v aws >/dev/null 2>&1 || { echo "aws cli is required" && exit 1; }
[ -z "$AWS_ACCESS_KEY_ID" ] && echo "AWS_ACCESS_KEY_ID is required for aws cli" && exit 1
[ -z "$AWS_SECRET_ACCESS_KEY" ] && echo "AWS_SECRET_ACCESS_KEY is required for aws cli" && exit 1

$YUM install gcc-c++-4.8.5 policycoreutils-python
$YUM install sendmail
service sendmail start

aws s3 cp s3://$COUNTLY_S3_LINK countly.zip

unzip countly.zip -d /opt/countly

cd /opt/countly

npm install -g node-gyp --unsafe-perm
npm install -g grunt-cli --unsafe-perm
npm install --unsafe-perm

# install plugins
node ./bin/scripts/install_plugins

# install sdk-web
./bin/scripts/update.sh sdk-web

# compile scripts for production
grunt dist-all

#configure and start nginx
useradd www-data
cp /etc/nginx/conf.d/default.conf ./bin/config/nginx.default.backup
cp ./bin/config/nginx.server.conf /etc/nginx/conf.d/default.conf
cp ./bin/config/nginx.conf        /etc/nginx/nginx.conf
service nginx restart

# move countly's supervisord config
cp ./bin/config/supervisord.conf /etc/supervisord.conf

# configure countly.
cp ./frontend/express/public/javascripts/countly/countly.config.sample.js ./frontend/express/public/javascripts/countly/countly.config.js
cp ./api/config.sample.js ./api/config.js
cp ./frontend/express/config.sample.js ./frontend/express/config.js
cp ./plugins/plugins.default.json ./plugins/plugins.json
