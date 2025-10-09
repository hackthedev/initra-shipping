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


NAME="$(getArg "name" "$@")"

# check if null
if [[ -z "$NAME" ]]; then
  echo "Missing Parameter -name"
  exit 1
fi

# display it
echo "Hello $NAME"

# end signals. very important!!
echo "initra://install/done"
echo "initra://ssh/close"
