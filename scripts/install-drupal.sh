#!/bin/bash
set -e

ctx logger info "Installing apache2 mysql-client and some tools."

sudo apt-get update -qq
sudo apt-get install -y -qq unzip wget apache2 php5 libapache2-mod-php5 php5-mcrypt php5-gd mysql-client php5-mysqlnd-ms
pushd $HOME
wget --quiet -O drupal-8.4.4.zip https://ftp.drupal.org/files/projects/drupal-8.4.4.zip
unzip drupal-8.4.4.zip

ctx logger info "Installing Drupal packages."

pushd $HOME/drupal-8.4.4
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('SHA384', 'composer-setup.php') === '544e09ee996cdf60ece3804abc52599c22b1f40f4323403c44d44fdfdd586475ca9813a858088ffbc1f233e9b180f061') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php
php -r "unlink('composer-setup.php');"
./composer.phar install
sudo cp -R . /var/www/html
popd
sudo rm /var/www/html/index.html

ctx logger info "Creating the Drupal Database."

# set +e

# mysql -u $dbUser -e "CREATE DATABASE ${MYSQL_DB} CHARACTER SET utf8 COLLATE utf8_general_ci"

# set -e

ctx logger info "Adding Drupal apache2 vhost and drupal application."

ctx download-resource scripts/vhost '@{"target_path": "/tmp/vhost"}'
sudo mv /tmp/vhost /etc/apache2/sites-available/000-default.conf

ctx download-resource scripts/htaccess '@{"target_path": "/tmp/htaccess"}'
sudo mv /tmp/htaccess /var/www/html/.htaccess

ctx download-resource scripts/php.ini '@{"target_path": "/tmp/php.ini"}'
sudo mv /tmp/php.ini /var/www/html/php.ini

sudo mkdir -p /var/www/html/sites/default/files
sudo cp /var/www/html/sites/default/default.settings.php /var/www/html/sites/default/settings.php
sudo chown -R www-data:root /var/www/html/
sudo a2enmod rewrite
sudo /etc/init.d/apache2 restart
