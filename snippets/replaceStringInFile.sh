replace() {
  local file="$1"
  local search="$2"
  local replace="$3"

  local search_escaped
  local replace_escaped

  search_escaped=$(printf '%s\n' "$search" | sed 's/[.[\*^$\/]/\\&/g')
  replace_escaped=$(printf '%s\n' "$replace" | sed 's/[\/&]/\\&/g')

  sed -i "s/$search_escaped/$replace_escaped/g" "$file"
}
