replace() {
  local file="$1"
  local search="$2"
  local replace="$3"

  sed -i "s|$search|$replace|g" "$file"
}
