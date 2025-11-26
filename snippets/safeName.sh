safeName() {
  local input="$1"
  input="$(echo "$input" | tr '[:upper:]' '[:lower:]')"
  input="$(echo "$input" | tr -cd 'a-z0-9._-')"
  echo "$input"
}
