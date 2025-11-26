#!/bin/bash

# some small helpers
source <(wget -qO- https://raw.githubusercontent.com/hackthedev/initra-shipping/refs/heads/main/snippets/argument_parser.sh)
source <(wget -qO- https://raw.githubusercontent.com/hackthedev/initra-shipping/refs/heads/main/snippets/hasOutput.sh)

domain="$(getArg "domain" "$@")"
email="$(getArg "email" "$@")"
target="$(getArg "path" "$@")"

# check parameters
if [[ -z "$domain" || -z "$email" || -z "$target" ]]; then
  echo "Missing domain, email or path"

  # only needed for initra.
  echo "initra://install/error"
  echo "initra://ssh/close"
  exit 1
fi

# if certbot command wasnt found lets assume its not installed
# and install it.
if ! hasOutput which certbot; then
  apt update
  apt install certbot -y
fi

# try to create the cert
certbot certonly --standalone --agree-tos --non-interactive -m "$email" -d "$domain"

# copy the cert files if they exist, else error
if [[ ! -f "/etc/letsencrypt/live/$domain/fullchain.pem" || ! -f "/etc/letsencrypt/live/$domain/privkey.pem" ]]; then
  echo " "
  echo "****** ERROR INSTALLING OR GETTING CERT FILES ******"
  echo "          CERT FILES NOT FOUND - CANT COPY"
  echo " "
  echo "initra://install/error"
  echo "initra://ssh/close"
  exit 1
fi

# the files did exist, so we continue execution by copying the files.
cp "/etc/letsencrypt/live/$domain/fullchain.pem" "$target/cert.pem"
cp "/etc/letsencrypt/live/$domain/privkey.pem" "$target/key.pem"

# tell initra app we are done.
echo "initra://install/done"
echo "initra://ssh/close"