#!/bin/bash

# this is where you do your install logic

sudo apt install ca-certificates apt-transport-https lsb-release gnupg curl nano unzip -y
sudo curl -fsSL https://packages.sury.org/php/apt.gpg -o /usr/share/keyrings/php-archive-keyring.gpg
sudo echo "deb [signed-by=/usr/share/keyrings/php-archive-keyring.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list

sudo apt update

apt install php8.2 php8.2-cli php8.2-common php8.2-curl php8.2-gd php8.2-intl php8.2-mbstring php8.2-mysql php8.2-opcache php8.2-readline php8.2-xml php8.2-xsl php8.2-zip php8.2-bz2 libapache2-mod-php8.2 -y
sudo a2enmod php8.2
sudo service apache2 restart

echo "initra://install/done"
echo "initra://ssh/close"