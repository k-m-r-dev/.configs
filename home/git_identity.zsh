# -------------------------------------------------------------------------
# git-identity — set local/global Git identity; export GH_TOKEN for this shell
# -------------------------------------------------------------------------

git-identity() {
  local script="$HOME/.config/nix/scripts/git-identity.sh"
  local token_user="" git_user="" email_seen=0 user_seen=0
  local -a args
  args=("$@")

  local i=1
  while (( i <= $# )); do
    case "${argv[i]}" in
      -u|--user)
        if (( i + 1 <= $# )); then
          git_user="${argv[i+1]}"
          user_seen=1
        fi
        (( i += 2 ))
        ;;
      -e|--email)
        email_seen=1
        (( i += 2 ))
        ;;
      --token)
        if (( i + 1 <= $# )); then
          token_user="${argv[i+1]}"
        fi
        (( i += 2 ))
        ;;
      *)
        (( i += 1 ))
        ;;
    esac
  done

  bash "$script" "$@" || return $?

  local gh_user=""
  if [[ -n "$token_user" ]]; then
    gh_user="$token_user"
  elif (( user_seen && email_seen )) && [[ -n "$git_user" ]]; then
    gh_user="$git_user"
  else
    return 0
  fi

  if ! command -v gh >/dev/null 2>&1; then
    echo "error: gh (GitHub CLI) is required to set GH_TOKEN" >&2
    return 1
  fi

  local token
  if ! token="$(gh auth token --user "$gh_user" 2>/dev/null)" || [[ -z "$token" ]]; then
    echo "error: could not get token for GitHub user: $gh_user" >&2
    return 1
  fi

  export GH_TOKEN="$token"
  echo "GH_TOKEN set for this session (user=$gh_user)"
}
