#!/usr/bin/env bash
# Show or set Git author / GPG identity for a repository (cwd by default).
# Session GH_TOKEN is exported by the zsh git-identity wrapper, not this script.
#
# Usage:
#   git-identity [DIR] [--global] [--more]
#   git-identity [DIR] -u|--user NAME -e|--email EMAIL [--gpg-key KEY] [--gpg-signing true|false] [--global]
#   git-identity [DIR] --gpg-key KEY [--global]
#   git-identity [DIR] --gpg-signing true|false [--global]
#   git-identity --token USERNAME

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  git-identity [DIR] [--global] [--more]
  git-identity [DIR] -u|--user NAME -e|--email EMAIL [--gpg-key KEY] [--gpg-signing true|false] [--global]
  git-identity [DIR] --gpg-key KEY [--global]
  git-identity [DIR] --gpg-signing true|false [--global]
  git-identity --token USERNAME

  DIR               Repository path (default: current directory)
  -u, --user        Local (or --global) user.name; must be paired with -e
  -e, --email       Local (or --global) user.email; must be paired with -u
  --gpg-key         user.signingkey
  --gpg-signing     commit.gpgsign (true|false)
  --token           GitHub username for session GH_TOKEN (handled by zsh wrapper)
  --global          Write/show global config (show: LOCAL + GLOBAL; write: --global)
  --more            Also list other config keys under OTHER LOCAL / OTHER GLOBAL
EOF
}

DIR="."
USER_NAME=""
USER_EMAIL=""
GPG_KEY=""
GPG_SIGNING=""
TOKEN_USER=""
USE_GLOBAL=0
SHOW_MORE=0
USER_SET=0
EMAIL_SET=0
GPG_KEY_SET=0
GPG_SIGNING_SET=0
TOKEN_SET=0

IDENTITY_KEYS=(
  "user.name"
  "user.email"
  "user.signingkey"
  "commit.gpgsign"
)

is_identity_key() {
  local key="$1"
  local k
  for k in "${IDENTITY_KEYS[@]}"; do
    [[ "$key" == "$k" ]] && return 0
  done
  return 1
}

git_get() {
  local scope="$1" key="$2" val
  if val="$(git -C "$DIR" config --"$scope" --get "$key" 2>/dev/null)"; then
    printf '%s' "$val"
  else
    printf '%s' ""
  fi
}

display_or_unset() {
  local val="$1"
  if [[ -z "$val" ]]; then
    printf '(unset)'
  else
    printf '%s' "$val"
  fi
}

print_identity_section() {
  local scope="$1" title="$2"
  local name email key signing
  name="$(git_get "$scope" user.name)"
  email="$(git_get "$scope" user.email)"
  key="$(git_get "$scope" user.signingkey)"
  signing="$(git_get "$scope" commit.gpgsign)"

  printf '%s\n' "$title"
  printf '  %-13s | %s\n' "Name" "$(display_or_unset "$name")"
  printf '  %-13s | %s\n' "Email" "$(display_or_unset "$email")"
  printf '  %-13s | %s\n' "GPG key" "$(display_or_unset "$key")"
  printf '  %-13s | %s\n' "GPG signing" "$(display_or_unset "$signing")"
}

print_other_section() {
  local scope="$1" title="$2"
  local list line key val has_any=0

  printf '%s\n' "$title"
  if ! list="$(git -C "$DIR" config --"$scope" --list 2>/dev/null)"; then
    printf '  (none)\n'
    return 0
  fi

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" ]] && continue
    key="${line%%=*}"
    val="${line#*=}"
    if is_identity_key "$key"; then
      continue
    fi
    has_any=1
    printf '  %s | %s\n' "$key" "$val"
  done <<<"$list"

  if [[ "$has_any" -eq 0 ]]; then
    printf '  (none)\n'
  fi
}

require_repo() {
  if ! git -C "$DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "error: not a git repository: $DIR" >&2
    exit 1
  fi
}

abs_dir() {
  if git -C "$DIR" rev-parse --show-toplevel >/dev/null 2>&1; then
    git -C "$DIR" rev-parse --show-toplevel
  else
    (cd "$DIR" && pwd)
  fi
}

show_identity() {
  require_repo
  local root
  root="$(abs_dir)"
  printf 'Git identity — %s\n\n' "$root"
  print_identity_section local "LOCAL (this repository)"
  if [[ "$USE_GLOBAL" -eq 1 ]]; then
    printf '\n'
    print_identity_section global "GLOBAL"
  fi
  if [[ "$SHOW_MORE" -eq 1 ]]; then
    printf '\n'
    print_other_section local "OTHER LOCAL"
    if [[ "$USE_GLOBAL" -eq 1 ]]; then
      printf '\n'
      print_other_section global "OTHER GLOBAL"
    fi
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -u|--user)
      [[ $# -ge 2 ]] || { echo "error: $1 requires a value" >&2; usage >&2; exit 1; }
      USER_NAME="$2"
      USER_SET=1
      shift 2
      ;;
    -e|--email)
      [[ $# -ge 2 ]] || { echo "error: $1 requires a value" >&2; usage >&2; exit 1; }
      USER_EMAIL="$2"
      EMAIL_SET=1
      shift 2
      ;;
    --gpg-key)
      [[ $# -ge 2 ]] || { echo "error: $1 requires a value" >&2; usage >&2; exit 1; }
      GPG_KEY="$2"
      GPG_KEY_SET=1
      shift 2
      ;;
    --gpg-signing)
      [[ $# -ge 2 ]] || { echo "error: $1 requires a value" >&2; usage >&2; exit 1; }
      GPG_SIGNING="$2"
      GPG_SIGNING_SET=1
      shift 2
      ;;
    --token)
      [[ $# -ge 2 ]] || { echo "error: $1 requires a value" >&2; usage >&2; exit 1; }
      TOKEN_USER="$2"
      TOKEN_SET=1
      shift 2
      ;;
    --global)
      USE_GLOBAL=1
      shift
      ;;
    --more)
      SHOW_MORE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "error: unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      if [[ "$DIR" != "." ]]; then
        echo "error: unexpected argument: $1" >&2
        usage >&2
        exit 1
      fi
      DIR="$1"
      shift
      ;;
  esac
done

if [[ "$TOKEN_SET" -eq 1 && -z "$TOKEN_USER" ]]; then
  echo "error: --token must be non-empty" >&2
  exit 1
fi

if [[ "$USER_SET" -ne "$EMAIL_SET" ]]; then
  echo "error: -u/--user and -e/--email must be passed together" >&2
  usage >&2
  exit 1
fi

if [[ "$USER_SET" -eq 1 ]]; then
  if [[ -z "$USER_NAME" || -z "$USER_EMAIL" ]]; then
    echo "error: -u/--user and -e/--email must be non-empty" >&2
    exit 1
  fi
fi

if [[ "$GPG_KEY_SET" -eq 1 && -z "$GPG_KEY" ]]; then
  echo "error: --gpg-key must be non-empty" >&2
  exit 1
fi

if [[ "$GPG_SIGNING_SET" -eq 1 ]]; then
  case "$GPG_SIGNING" in
    true|false) ;;
    *)
      echo "error: --gpg-signing must be true or false" >&2
      exit 1
      ;;
  esac
fi

SETTING=0
if [[ "$USER_SET" -eq 1 || "$GPG_KEY_SET" -eq 1 || "$GPG_SIGNING_SET" -eq 1 ]]; then
  SETTING=1
fi

# Token-only: no git show/set here; zsh wrapper exports GH_TOKEN.
if [[ "$SETTING" -eq 0 && "$TOKEN_SET" -eq 1 ]]; then
  exit 0
fi

if [[ "$SETTING" -eq 0 ]]; then
  if [[ ! -d "$DIR" ]]; then
    echo "error: directory does not exist: $DIR" >&2
    exit 1
  fi
  show_identity
  exit 0
fi

if [[ ! -d "$DIR" ]]; then
  echo "error: directory does not exist: $DIR" >&2
  exit 1
fi

SCOPE_FLAG=(--local)
if [[ "$USE_GLOBAL" -eq 1 ]]; then
  SCOPE_FLAG=(--global)
  echo "warning: writing global git config (may conflict with Home Manager / XDG managed files)" >&2
else
  require_repo
fi

if [[ "$USER_SET" -eq 1 ]]; then
  git -C "$DIR" config "${SCOPE_FLAG[@]}" user.name "$USER_NAME"
  git -C "$DIR" config "${SCOPE_FLAG[@]}" user.email "$USER_EMAIL"
fi
if [[ "$GPG_KEY_SET" -eq 1 ]]; then
  git -C "$DIR" config "${SCOPE_FLAG[@]}" user.signingkey "$GPG_KEY"
fi
if [[ "$GPG_SIGNING_SET" -eq 1 ]]; then
  git -C "$DIR" config "${SCOPE_FLAG[@]}" commit.gpgsign "$GPG_SIGNING"
fi

if git -C "$DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  printf '\n'
  show_identity
elif [[ "$USE_GLOBAL" -eq 1 ]]; then
  printf 'Updated global git config.\n'
fi
