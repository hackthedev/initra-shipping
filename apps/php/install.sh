#!/bin/bash

# this is where you do your install logic

apt install php8.3 php8.3-cli php8.3-common php8.3-curl php8.3-gd php8.3-intl php8.3-mbstring php8.3-mysql php8.3-opcache php8.3-readline php8.3-xml php8.3-xsl php8.3-zip php8.3-bz2 libapache2-mod-php8.3 -y
a2enmod php8.3
systemctl restart apache2


echo "initra://install/done"
echo "initra://ssh/close"