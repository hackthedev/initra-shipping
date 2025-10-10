#!/bin/bash

# helper to get args by name
getArg() {
  local key="$1"
  shift
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -$key|--$key)
        echo "$2"
        return 0
        ;;
    esac
    shift
  done
  return 1
}

# set the name as variable
NAME="$(getArg "name" "$@")"

# check if null
#if [[ -z "$NAME" ]]; then
#  echo "Missing Parameter -name"
#  exit 1
#fi

# something with it. this is just an example app!
# because of that we dont need any arguments here
# but the code is left in for examples.
# echo "Hello $NAME"

# this is where you do your install logic
sudo apt update -y
sudo apt upgrade -y

# these lines are a must-have. without it, initra doesnt know
# if the installation is done and if it should close the connection.
echo "initra://install/done"
echo "initra://ssh/close"