#!/bin/bash

# small helper to get arguments by name
getArg() {
  local key="$1"
  shift
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -$key|--$key)
        return 0
        ;;
    esac
    shift
  done
  return 1
}

# setup variable
NAME=$(getArg "name" "$@")

# check if variable is null
if [[ -z "NAME" ]]; then
  echo "Missing Parameter -name"
  exit 1
fi


# continue script :)
echo "Hello $NAME"
sudo apt update -y

echo "initra://install/done"
echo "initra://ssh/close"