#!/bin/bash

source <(wget -qO- https://raw.githubusercontent.com/hackthedev/initra-shipping/refs/heads/main/snippets/argument_parser.sh)
source <(wget -qO- https://raw.githubusercontent.com/hackthedev/initra-shipping/refs/heads/main/snippets/hasOutput.sh)
source <(wget -qO- https://raw.githubusercontent.com/hackthedev/initra-shipping/refs/heads/main/snippets/replaceStringInFile.sh)
source <(wget -qO- https://raw.githubusercontent.com/hackthedev/initra-shipping/refs/heads/main/snippets/safeName.sh)

# where all instance will run on
root_path="/home/dcts/instances"
mkdir -p "$root_path"

# arguments etc
instance_name="$(safeName "$(getArg create-instance "$@")")"
instance_path="$root_path/$instance_name"
port="$(getArg port "$@")"
domain="$(getArg domain "$@")"
email="$(getArg email "$@")"

mariadb_pass="$(openssl rand -hex 16)"
db_name="dcts_$instance_name"
db_user="dcts_$instance_name"
db_pass="$(openssl rand -hex 16)"

# flag for checks
validArgs=1

# check parameters
if [[ -z "$instance_name" ]]; then
  echo "No instance name supplied"
  validArgs=0
fi

if [[ -z "$port" ]]; then
  echo "No instance name supplied"
  validArgs=0
fi

# if a cert file should be created
if hasFlag create-cert "$@"; then
  if [[ -z "$domain" ]]; then
    echo "No instance name supplied"
    validArgs=0
  fi

  if [[ -z "$email" ]]; then
    echo "No instance name supplied"
    validArgs=0
  fi
fi

# if any check set it to 0, we need need to exit
if [[ "$validArgs" == 0 ]]; then
  echo "initra://install/error"
  echo "initra://ssh/close"
  exit 1
fi

# install git if missing
if ! hasOutput which curl; then
  apt install curl -y
fi

# install screen if missing
if ! hasOutput which git; then
  apt install screen -y
fi

# install git if missing
if ! hasOutput which git; then
  curl -sSL https://raw.githubusercontent.com/hackthedev/initra-shipping/refs/heads/main/apps/git/install.sh | bash
fi

# install nodejs if missing
if ! hasOutput which node; then
  curl -sSL https://raw.githubusercontent.com/hackthedev/initra-shipping/refs/heads/main/apps/nodejs/install.sh | bash
fi

# install supervisorctl
if ! hasOutput which supervisorctl; then
  curl -sSL https://raw.githubusercontent.com/hackthedev/initra-shipping/refs/heads/main/apps/supervisor/install.sh | bash
fi

# install mariadb
if ! hasOutput which mariadb; then
  curl -sSL https://raw.githubusercontent.com/hackthedev/initra-shipping/refs/heads/main/apps/mariadb/install.sh | bash -s -- --rootPassword "$mariadb_pass"
fi

# setup the database and a user for it so everything works out of the box.
# at this point im so happy i made the mariadb installer script and shit,
# otherwise this would be so painful.
#
# create database
mariadb -u root -p"$mariadb_pass" -e "CREATE DATABASE IF NOT EXISTS $db_name;"
# create user
mariadb -u root -p"$mariadb_pass" -e "CREATE USER IF NOT EXISTS '$db_user'@'localhost' IDENTIFIED BY '$db_pass';"
# grant permissions
mariadb -u root -p"$mariadb_pass" -e "GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost';"
# apply changes
mariadb -u root -p"$mariadb_pass" -e "FLUSH PRIVILEGES;"

# install livekit. will be skipped if installed
curl -sSL https://raw.githubusercontent.com/hackthedev/initra-shipping/refs/heads/main/apps/livekit/install.sh | bash

# install dcts main or beta
if hasFlag beta "$@"; then
  git clone --depth 1 https://github.com/hackthedev/dcts-shipping -b beta "$instance_path"
else
  git clone --depth 1 https://github.com/hackthedev/dcts-shipping "$instance_path"
fi

# optionally if set, get a cert file
if hasFlag create-cert "$@"; then
  curl -sSL https://raw.githubusercontent.com/hackthedev/initra-shipping/refs/heads/main/snippets/certgen.sh | bash -s -- --domain "$domain" --email "$email" --path /home/livekit/

  # create the configs dir if it doesnt exist already
  mkdir -p "$instance_path/configs/"
  echo " " > "$instance_path/configs/ssl.txt"
fi

# check if supervisor config exists
if [[ ! -f "$instance_path/sv/supervisor.conf.example" ]]; then
  echo "Couldnt find supervisor config example file"
  echo "initra://install/error"
  echo "initra://ssh/close"
  exit 1
fi

# error didnt happen, so the config example file exists.
# that means we need to copy it to the supervisor conf.d folder.
cp "$instance_path/sv/supervisor.conf.example" "/etc/supervisor/conf.d/dcts_$instance_name.conf"

# now that we copied it, we need to change some settings inside the config file
replace "/etc/supervisor/conf.d/dcts_$instance_name.conf" "program:dcts" "program:dcts_$instance_name"
replace "/etc/supervisor/conf.d/dcts_$instance_name.conf" "directory=/home/dcts/sv" "directory=$instance_path"
replace "/etc/supervisor/conf.d/dcts_$instance_name.conf" "command=sh check.sh" "command=sh sv/check.sh"
replace "/etc/supervisor/conf.d/dcts_$instance_name.conf" "stderr_logfile=/home/dcts/sv/err.log" "stderr_logfile=$instance_path/sv/err.log"
replace "/etc/supervisor/conf.d/dcts_$instance_name.conf" "stdout_logfile=/home/dcts/sv/out.log" "stdout_logfile=$instance_path/sv/out.log"

# change dcts sv files
replace "$instance_path/sv/start.sh" "/home/dcts" "$instance_path"
replace "$instance_path/sv/check.sh" "/home/dcts/sv/start.sh" "$instance_path/sv/start.sh"

# dcts config file
cp "$instance_path/config.json.example" "$instance_path/config.json"
replace "$instance_path/config.json" "/etc/letsencrypt/live/EXAMPLE.COM/privkey.pem" "/etc/letsencrypt/live/$domain/privkey.pem"
replace "$instance_path/config.json" "/etc/letsencrypt/live/EXAMPLE.COM/cert.pem" "/etc/letsencrypt/live/$domain/cert.pem"
replace "$instance_path/config.json" "/etc/letsencrypt/live/EXAMPLE.COM/chain.pem" "/etc/letsencrypt/live/$domain/chain.pem"

# adapt livekit config file
replace "/home/livekit/livekit.yaml" "domain.com" "$domain"
service livekit restart

# install node packages
cd "$instance_path" && npm i

# export these vars into a file that dcts can read on start up and apply
# the changes to the config.json file as i dont wanna deal with
# json in this bash script. even tho its all kinda fun its painful at the
# same time.
echo "$db_user" > "$instance_path/configs/sql.txt"
echo "$db_pass" >> "$instance_path/configs/sql.txt"
echo "$db_name" >> "$instance_path/configs/sql.txt"


# then we update the supervisor
supervisorctl reread
supervisorctl update
supervisorctl start dcts_$instance_name

echo "initra://install/done"
echo "initra://ssh/close"

# curl -sSL https://raw.githubusercontent.com/hackthedev/initra-shipping/refs/heads/main/apps/dcts/install.sh | bash -s -- --create-instance "Test Server 1" --port 2000 --create-cert --domain es2.network-z.com --email admin@xyz.com
# bash dcts.sh --create-instance "Test Server 1" --port 2000 --create-cert --domain es1.network-z.com --email admin@xyz.com