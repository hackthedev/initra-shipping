hasOutput() {
    local result
    result="$($@ 2>/dev/null)"
    if [[ -n "$result" ]]; then
        return 0  # true
    else
        return 1  # false
    fi
}
