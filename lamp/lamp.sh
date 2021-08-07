#!/bin/sh

# Create rg
az group create -n lamp -l eastus

# Create VM
az vm create -g lamp -n hjVM --image UbuntuLTS --admin-username azureuser --generate-ssh-keys

# Query IP Address
az network public-ip list -g lamp --query "[0].ipAddress"

# Install Apache, MySQL, PHP
sudo apt update && sudo apt install lamp-server^

# Install Wordpress
sudo apt install wordpress

# Configure Wordpress
sudo vi wordpress.sql
# CREATE DATABASE wordpress;
# GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,ALTER
# ON wordpress.*
# TO wordpress@localhost
# IDENTIFIED BY 'yourPassword';

cat wordpress.sql | sudo mysql --defaults-extra-file=/etc/mysql/debian.cnf
sudo rm wordpress.sql
sudo vi /etc/wordpress/config-localhost.php
# <?php
# define('DB_NAME', 'wordpress');
# define('DB_USER', 'wordpress');
# define('DB_PASSWORD', 'yourPassword');
# define('DB_HOST', 'localhost');
# define('WP_CONTENT_DIR', '/usr/share/wordpress/wp-content');
# ?>

sudo ln -s /usr/share/wordpress /var/www/html/wordpress
sudo mv /etc/wordpress/config-localhost.php /etc/wordpress/config-default.php