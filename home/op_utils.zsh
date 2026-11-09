# Fetch a 1Password item by name or ID.
# Usage: op_get_item ITEM [--vault VAULT] [--account ACCOUNT] [--format FORMAT]
op_get_item() {
  if (( $# == 0 )); then
    print -u2 "Usage: op_get_item ITEM [--vault VAULT] [--account ACCOUNT] [--format FORMAT]"
    return 2
  fi

  local item="$1"
  shift
  local format="json"
  local vault=""
  local account=""

  while (( $# > 0 )); do
    case "$1" in
      --vault)
        if (( $# < 2 )); then
          print -u2 "Missing value for --vault"
          return 2
        fi
        vault="$2"
        shift 2
        ;;
      --account)
        if (( $# < 2 )); then
          print -u2 "Missing value for --account"
          return 2
        fi
        account="$2"
        shift 2
        ;;
      --format)
        if (( $# < 2 )); then
          print -u2 "Missing value for --format"
          return 2
        fi
        format="$2"
        shift 2
        ;;
      *)
        print -u2 "Unknown option: $1"
        return 2
        ;;
    esac
  done

  if ! command -v op >/dev/null 2>&1; then
    print -u2 "Missing dependency: 1Password CLI (op)"
    return 127
  fi

  local -a op_args=(item get "$item" --format "$format")
  [[ -n "$vault" ]] && op_args+=(--vault "$vault")
  [[ -n "$account" ]] && op_args+=(--account "$account")

  command op "${op_args[@]}"
}
