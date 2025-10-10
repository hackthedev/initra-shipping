#!/bin/bash

# this is where you do your install logic

apt install -y apt-transport-https lsb-release ca-certificates curl gnupg
curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /usr/share/keyrings/sury-php.gpg
echo "deb [signed-by=/usr/share/keyrings/sury-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/sury-php.list
apt update


apt install -y php8.2 php8.2-cli php8.2-common php8.2-curl php8.2-gd php8.2-intl php8.2-mbstring php8.2-mysql php8.2-opcache php8.2-readline php8.2-xml php8.2-zip libapache2-mod-php8.2
a2enmod php8.2
systemctl restart apache2

echo "initra://install/done"
echo "initra://ssh/close"