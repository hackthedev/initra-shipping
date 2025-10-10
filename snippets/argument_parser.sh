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