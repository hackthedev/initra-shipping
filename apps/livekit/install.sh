#!/bin/bash

source <(wget -qO- https://raw.githubusercontent.com/hackthedev/initra-shipping/refs/heads/main/snippets/hasOutput.sh)

# if its already installed exit
if hasOutput which livekit; then
  echo "initra://install/done"
  echo "initra://ssh/close"
  exit 0
fi

# install livekit
curl -sSL https://get.livekit.io | bash

# setup some stuff
mkdir /home/livekit
wget https://raw.githubusercontent.com/hackthedev/initra-shipping/refs/heads/main/apps/livekit/livekit.yaml -O /home/livekit/livekit.yaml
sudo wget https://raw.githubusercontent.com/hackthedev/initra-shipping/refs/heads/main/apps/livekit/livekit.service -O /etc/systemd/system/livekit.service
sudo systemctl enable --now livekit.service

echo "initra://install/done"
echo "initra://ssh/close"