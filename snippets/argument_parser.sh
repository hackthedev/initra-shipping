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

hasFlag() {
  local key="$1"
  shift
  for arg in "$@"; do
    if [[ "$arg" == "--$key" || "$arg" == "-$key" ]]; then
      return 0
    fi
  done
  return 1
}
