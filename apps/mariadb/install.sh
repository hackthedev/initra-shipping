#!/bin/bash

# get argument parser
source <(wget -qO- https://raw.githubusercontent.com/hackthedev/initra-shipping/refs/heads/main/snippets/argument_parser.sh)

apt install mariadb-server mariadb-client -y

# set the name as variable
rootPw="$(getArg "rootPassword" "$@")"

# check if null
if [[ -z "$rootPw" ]]; then
  # no root password set for some reason
  echo "No password supplied"
else
  # root password was set so we try to change the pw
  mariadb -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$rootPw';"
fi

echo "initra://install/done"
echo "initra://ssh/close"