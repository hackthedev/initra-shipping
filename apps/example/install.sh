#!/bin/bash

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

NAME=$(getArg "name" "$@")

if [[ -z "$FILE" ]]; then
  echo "Missing Parameter -name"
  exit 1
fi

echo "Hello $NAME"

echo "initra://ssh/close"