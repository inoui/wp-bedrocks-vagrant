#!/bin/sh

## This file gets executed the first time you do a `vagrant up`, if you want it to
## run again you'll need run `vagrant provision`

## Bash isn't ideal for provisioning but Ansible/Chef/Puppet 
## are not within the scope of this article

## Install all the things
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install --assume-yes php5 php5-mysql php5-cli php5-curl php-apc \
	apache2 libapache2-mod-php5 mysql-client mysql-server supervisor \
	vim ntp bzip2 php-pear git

## make www-data use /bin/bash for shell
chsh -s /bin/bash www-data


## install composer
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer


## Create a directory structure
## (These would probably already exist within your project)
mkdir /var/www/hipafrica.dev/etc
git clone https://github.com/roots/bedrock.git /var/www/hipafrica.dev/code
cd /var/www/hipafrica.dev/code

composer install
##mkdir /var/www/hipafrica.dev/code

git clone https://github.com/roots/sage.git /var/www/hipafrica.dev/code/web/app/themes/hipafrica

## Create an Apache vhost
## (This would probably already exist within your project)
echo "<VirtualHost *:80>
ServerName hipafrica.dev
DocumentRoot /var/www/hipafrica.dev/code/web
<Directory /var/www/hipafrica.dev/code/web>
	AllowOverride All
    Allow from All
</Directory>  
</VirtualHost>" > /var/www/hipafrica.dev/etc/hipafrica.dev.conf

## Tell Apache about our vhost
ln -s /var/www/hipafrica.dev/etc/hipafrica.dev.conf /etc/apache2/sites-enabled/hipafrica.dev.conf

## Tweak permissions for www-data user
chgrp www-data /var/log/apache2
chmod g+w /var/log/apache2
chown www-data.www-data /var/www/hipafrica.dev/etc
chown www-data.www-data /var/www/hipafrica.dev/code

## Enable Apache's mod-rewrite, if it's not already
a2enmod rewrite

## Disable the default sites 
a2dissite 000-default

## Configure PHP for dev
echo "upload_max_filesize = 15M
log_errors = On
display_errors = On
display_startup_errors = On
error_log = /var/log/apache2/php.log
memory_limit = 1024M
date.timezone = Europe/London" > /etc/php5/mods-available/siftware.ini

php5enmod siftware

## Restart Apache
service apache2 reload

## Create a database and grant a user some permissions
echo "create database hipafrica_dev;" | mysql -u root
echo "grant all on hipafrica_dev.* to hipafrica_dev@localhost identified by 'lamepassword';" | mysql -u root


echo "DB_NAME=hipafrica_dev
DB_USER=hipafrica_dev
DB_PASSWORD=lamepassword
DB_HOST=localhost

WP_ENV=development
WP_HOME=http://hipafrica.dev
WP_SITEURL=http://hipafrica.dev/wp
" > /var/www/hipafrica.dev/code/.env

# ## Install wp-cli
# curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar

# mv /home/vagrant/wp-cli.phar /var/www/hipafrica.dev/wp-cli
# chmod +x /var/www/hipafrica.dev/wp-cli

# ## Install Wordpress core using wp-cli
# /var/www/hipafrica.dev/wp-cli core download \
# 	--path=/var/www/hipafrica.dev/code \
# 	--force --allow-root
 
# rm /var/www/hipafrica.dev/code/wp-config-sample.php

# ## Very basic wp-config.php using our recently created MySQL credentials
# ## Could use wp-cli for this too, but this'll do
# echo "<?php 
# \$table_prefix = 'foo_';
# define('DB_NAME',     'hipafrica.dev');
# define('DB_USER',     'hipafrica.dev');
# define('DB_PASSWORD', 'lamepassword');
# define('DB_HOST',     'localhost');
# define('DB_CHARSET',  'utf8');
# define('WPLANG', '' );
# if (!defined('ABSPATH')) 
# 	define('ABSPATH', dirname(__FILE__) . '/');
# require_once(ABSPATH . 'wp-settings.php');
# ?>" > /var/www/hipafrica.dev/code/wp-config.php
  
# ## Provision Wordpress using wp-cli
# /var/www/hipafrica.dev/wp-cli core install \
# 	--url='http://hipafrica.dev' \
# 	--path=/var/www/hipafrica.dev/code \
# 	--title='Vagrant FTW' \
# 	--admin_user=admin \
# 	--admin_password=password \
# 	--admin_email=wp@inoui.io \
# 	--allow-root

# ## siteurl & home are getting /code appended in wp_options, no idea why
# /var/www/hipafrica.dev/wp-cli option update siteurl 'http://hipafrica.dev' \
# 	--path=/var/www/hipafrica.dev/code \
# 	--allow-root

# /var/www/hipafrica.dev/wp-cli option update home 'http://hipafrica.dev' \
# 	--path=/var/www/hipafrica.dev/code \
# 	--allow-root

# /var/www/hipafrica.dev/wp-cli option update blogdescription 'Brought to you by inoui.io' \
# 	--path=/var/www/hipafrica.dev/code \
# 	--allow-root

# /var/www/hipafrica.dev/wp-cli post create \
# 	--path=/var/www/hipafrica.dev/code \
# 	--post_title='What is Vagrant and why should I care?' \
# 	--post_content='<p>OK, I totally get it now<p>' \
# 	--post_status=publish \
# 	--allow-root


 
