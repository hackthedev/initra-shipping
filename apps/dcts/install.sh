#!/bin/bash

source <(wget -qO- https://raw.githubusercontent.com/hackthedev/initra-shipping/refs/heads/main/snippets/argument_parser.sh)
source <(wget -qO- https://raw.githubusercontent.com/hackthedev/initra-shipping/refs/heads/main/snippets/hasOutput.sh)
source <(wget -qO- https://raw.githubusercontent.com/hackthedev/initra-shipping/refs/heads/main/snippets/replaceStringInFile.sh)
source <(wget -qO- https://raw.githubusercontent.com/hackthedev/initra-shipping/refs/heads/main/snippets/safeName.sh)

# where all instance will run on
root_path="/home/dcts/instances"
mkdir -p "$root_path"

if hasFlag create-instance "$@"; then
  curl -sSL https://raw.githubusercontent.com/hackthedev/initra-shipping/refs/heads/main/apps/dcts/create-instance.sh | bash -s -- "$@"
fi



echo "initra://install/done"
echo "initra://ssh/close"

echo " "
echo "Installation finished. Please check and see if the instance is reachable."
echo "Thanks for considering DCTS <3"

# curl -sSL https://raw.githubusercontent.com/hackthedev/initra-shipping/refs/heads/main/apps/dcts/install.sh | bash -s -- --create-instance "Test Server 1" --port 2000 --create-cert --domain dev0002.network-z.com --email admin@xyz.com