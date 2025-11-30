#!/bin/bash

source <(wget -qO- https://raw.githubusercontent.com/hackthedev/initra-shipping/refs/heads/main/snippets/argument_parser.sh)
source <(wget -qO- https://raw.githubusercontent.com/hackthedev/initra-shipping/refs/heads/main/snippets/hasOutput.sh)
source <(wget -qO- https://raw.githubusercontent.com/hackthedev/initra-shipping/refs/heads/main/snippets/replaceStringInFile.sh)
source <(wget -qO- https://raw.githubusercontent.com/hackthedev/initra-shipping/refs/heads/main/snippets/safeName.sh)

# arguments etc
instance_name="$(safeName "$(getArg create-instance "$@")")"
root_path="/home/dcts/instances"
instance_path="$root_path/$instance_name"
port="$(getArg port "$@")"
domain="$(getArg domain "$@")"
livekit_domain="lk.$domain"

mariadb_pass="$(openssl rand -hex 16)"
db_name="dcts_$instance_name"
db_user="dcts_$instance_name"
db_pass="$(openssl rand -hex 16)"

if [[ -d "$instance_path" ]]; then
  echo "Instance already exists"
  echo "initra://install/error"
  echo "initra://ssh/close"
  exit 1
fi

# flag for checks
validArgs=1

# check parameters
if [[ -z "$instance_name" ]]; then
  echo "No instance name supplied"
  validArgs=0
fi

if [[ -z "$port" ]]; then
  echo "No port name supplied"
  validArgs=0
fi

# if any check set it to 0, we need need to exit
if [[ "$validArgs" == 0 ]]; then
  echo "initra://install/error"
  echo "initra://ssh/close"
  exit 1
fi

# install curl if missing
if ! hasOutput which curl; then
  apt install curl -y
fi

# install screen if missing
if ! hasOutput which screen; then
  apt install screen -y
fi

# install caddy if missing
if ! hasOutput which caddy; then
  apt install caddy -y
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
#
# create database etc
mariadb -u root -p"$mariadb_pass" -e "CREATE DATABASE IF NOT EXISTS $db_name;"
mariadb -u root -p"$mariadb_pass" -e "CREATE USER IF NOT EXISTS '$db_user'@'localhost' IDENTIFIED BY '$db_pass';"
mariadb -u root -p"$mariadb_pass" -e "GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost';"
mariadb -u root -p"$mariadb_pass" -e "FLUSH PRIVILEGES;"

# install livekit. will be skipped if installed
curl -sSL https://raw.githubusercontent.com/hackthedev/initra-shipping/refs/heads/main/apps/livekit/install.sh | bash

# install dcts main or beta
if hasFlag beta "$@"; then
  git clone --depth 1 https://github.com/hackthedev/dcts-shipping -b beta "$instance_path"
else
  git clone --depth 1 https://github.com/hackthedev/dcts-shipping "$instance_path"
fi

mkdir -p "$instance_path/configs/"
echo " " > "$instance_path/configs/ssl.txt"

# trigger caddy to pull certificates
systemctl reload caddy
sleep 5

# separate cert directories for dcts + livekit
certdir_dcts="/var/lib/caddy/.local/share/caddy/certificates/acme-v02.api.letsencrypt.org-directory/$domain"
certdir_livekit="/var/lib/caddy/.local/share/caddy/certificates/acme-v02.api.letsencrypt.org-directory/$livekit_domain"


# make livekit reverse proxy if it doesnt exist already.
# if it does fucking exist then we overwrite the motherfucking livekit_domain variable for later use.
# this shit is so painful i wanna smash my computer >:(
# its not even that complex just hella annoying
existing_lk_block="$(grep -oP '(?<=# LIVEKIT-).*' /etc/caddy/Caddyfile 2>/dev/null | head -n 1)"

if grep -q "# LIVEKIT-" /etc/caddy/Caddyfile 2>/dev/null; then
  livekit_domain="$existing_lk_block"
else
  cat > /etc/caddy/Caddyfile <<EOF
# LIVEKIT-$livekit_domain
$livekit_domain {
    reverse_proxy localhost:7880 {
        transport http {
            versions h1_1
        }
    }

    header {
        Access-Control-Allow-Origin *
        Access-Control-Allow-Methods "GET, POST, OPTIONS"
        Access-Control-Allow-Headers *
        Access-Control-Allow-Credentials true
    }
}
EOF
fi


# dcts reverse proxy
if ! grep -q "# DCTS-$domain" "/etc/caddy/Caddyfile"; then
cat >> /etc/caddy/Caddyfile <<EOF
# DCTS-$domain
$domain {
    reverse_proxy localhost:$port
}
EOF
fi

systemctl reload caddy

sleep 2

replace "/home/livekit/livekit.yaml" "/home/livekit/cert.pem" "$certdir_dcts/$domain.crt"
replace "/home/livekit/livekit.yaml" "/home/livekit/privkey.pem" "$certdir_dcts/$domain.key"
replace "/home/livekit/livekit.yaml" "domain.com" "$livekit_domain"
service livekit restart


# check if supervisor config exists
if [[ ! -f "$instance_path/sv/supervisor.conf.example" ]]; then
  echo "Couldnt find supervisor config example file"
  echo "initra://install/error"
  echo "initra://ssh/close"
  exit 1
fi

# copy supervisor template
cp "$instance_path/sv/supervisor.conf.example" "/etc/supervisor/conf.d/dcts_$instance_name.conf"

# edit supervisor config
replace "/etc/supervisor/conf.d/dcts_$instance_name.conf" "program:dcts" "program:dcts_$instance_name"
replace "/etc/supervisor/conf.d/dcts_$instance_name.conf" "directory=/home/dcts/sv" "directory=$instance_path"
replace "/etc/supervisor/conf.d/dcts_$instance_name.conf" "command=bash check.sh" "command=bash sv/check.sh $instance_name"
replace "/etc/supervisor/conf.d/dcts_$instance_name.conf" "stderr_logfile=/home/dcts/sv/err.log" "stderr_logfile=$instance_path/sv/err.log"
replace "/etc/supervisor/conf.d/dcts_$instance_name.conf" "stdout_logfile=/home/dcts/sv/out.log" "stdout_logfile=$instance_path/sv/out.log"

# change dcts sv files
replace "$instance_path/sv/start.sh" "/home/dcts" "$instance_path"
replace "$instance_path/sv/check.sh" "/home/dcts/sv/start.sh" "$instance_path/sv/start.sh"

# dcts config file
cp "$instance_path/config.example.json" "$instance_path/configs/config.json"

# DCTS MUST USE DCTS DOMAIN CERTS
replace "$instance_path/configs/config.json" "/etc/letsencrypt/live/EXAMPLE.COM/privkey.pem" "$certdir_dcts/$domain.key"
replace "$instance_path/configs/config.json" "/etc/letsencrypt/live/EXAMPLE.COM/cert.pem" "$certdir_dcts/$domain.crt"
replace "$instance_path/configs/config.json" "/etc/letsencrypt/live/EXAMPLE.COM/chain.pem" "$certdir_dcts/$domain.crt"

replace "$instance_path/configs/config.json" "default_livekit_url" "$livekit_domain"
replace "$instance_path/configs/config.json" "Default Server" "$instance_name"
replace "$instance_path/configs/config.json" "2052" "$port"

# install node packages
cd "$instance_path" && npm i

# write sql access file
echo "$db_user" > "$instance_path/configs/sql.txt"
echo "$db_pass" >> "$instance_path/configs/sql.txt"
echo "$db_name" >> "$instance_path/configs/sql.txt"

# then we update the supervisor
supervisorctl reread
supervisorctl update

echo "Restarting Instance in 5 seconds..."
sleep 5
supervisorctl restart dcts_$instance_name
