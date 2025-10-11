#!/bin/bash

source <(wget -qO- https://raw.githubusercontent.com/hackthedev/initra-shipping/refs/heads/main/snippets/hasOutput.sh)
source <(wget -qO- https://raw.githubusercontent.com/hackthedev/initra-shipping/refs/heads/main/snippets/argument_parser.sh)

# check if phpMyAdmin is already installed
if [[ -d "/usr/share/phpmyadmin" ]]; then
  echo "initra://install/done"
  echo "initra://ssh/close"
  exit 0
fi


# this is where you do your install logic
wget https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.zip -O /usr/share/phpmyadmin.zip

cd /usr/share
unzip phpmyadmin.zip
rm phpmyadmin.zip
mv phpMyAdmin-*-all-languages phpmyadmin


chmod -R 0755 /usr/share/phpmyadmin

# get config script
wget https://raw.githubusercontent.com/hackthedev/initra-shipping/refs/heads/submissions/apps/phpmyadmin/phpmyadmin.conf -O /etc/apache2/conf-available/phpmyadmin.conf

a2enconf phpmyadmin
systemctl reload apache2

mkdir /usr/share/phpmyadmin/tmp/
chown -R www-data:www-data /usr/share/phpmyadmin/tmp/



# enable root login for users if user chose to and it exists
if hasOutput which mariadb; then

  # set the name as variable
  enableRootLogin="$(getArg "enableRootLogin" "$@")"
  rootPassword="$(getArg "rootPassword" "$@")"

  # check if null
  if [[ "$enableRootLogin" == "true" ]] && [[ -n "$rootPassword" ]]; then
    mariadb -u root -p"$rootPassword" -e "UPDATE mysql.user SET plugin = 'mysql_native_password' WHERE user = 'root' AND plugin = 'unix_socket';"
  fi
fi


echo "initra://install/done"
echo "initra://ssh/close"