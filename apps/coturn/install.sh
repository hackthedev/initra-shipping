#!/bin/bash

source <(wget -qO- https://raw.githubusercontent.com/hackthedev/initra-shipping/refs/heads/main/snippets/hasOutput.sh)

# if its already installed exit
if hasOutput which coturn; then
  echo "initra://install/done"
  echo "initra://ssh/close"
  exit 0
fi



# default config stuff
echo "TURNSERVER_ENABLED=1">/etc/default/coturn

echo "listening-ip=0.0.0.0">>/etc/turnserver.conf
echo "user-quota=10">>/etc/turnserver.conf
echo "total-quota=200">>/etc/turnserver.conf

# restart
sudo service coturn restart

# and we're done
echo "initra://install/done"
echo "initra://ssh/close"