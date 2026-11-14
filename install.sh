#!/usr/bin/env bash
set -euo pipefail

force=false
legacy=false
for argument in "$@"; do
  case "$argument" in
    --force) force=true ;;
    --legacy) legacy=true ;;
    *)
      printf '%s\n' 'usage: ./install.sh [--force] [--legacy]' >&2
      exit 2
      ;;
  esac
done

package_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)"
if [[ -z "${HOME:-}" || "$HOME" == "/" ]]; then
  printf '%s\n' 'HOME must identify a user directory.' >&2
  exit 1
fi

if [[ "$legacy" == true ]]; then
  codex_root="${CODEX_HOME:-$HOME/.codex}"
  if [[ -z "$codex_root" || "$codex_root" == "/" ]]; then
    printf '%s\n' 'Refusing an empty or filesystem-root CODEX_HOME.' >&2
    exit 1
  fi
  skills_root="$codex_root/skills"
  backup_root="$codex_root/skill-backups"
else
  skills_root="$HOME/.agents/skills"
  backup_root="$HOME/.agents/skill-backups"
fi

mkdir -p "$skills_root"
timestamp="$(date -u '+%Y%m%dT%H%M%SZ')-$$"

directory_matches() {
  diff -rq "$1" "$2" >/dev/null 2>&1
}

install_skill() {
  local name="$1"
  local source="$package_dir/skills/$name"
  local target="$skills_root/$name"

  if [[ ! -d "$source" || -L "$source" ]]; then
    printf 'Invalid package skill: %s\n' "$source" >&2
    exit 1
  fi
  if [[ -L "$target" ]]; then
    printf 'Refusing to replace a symlinked target: %s\n' "$target" >&2
    exit 1
  fi
  if [[ -d "$target" ]] && directory_matches "$source" "$target"; then
    printf 'Skill already matches: %s\n' "$target"
    return
  fi
  if [[ -e "$target" && ! -d "$target" ]]; then
    printf 'Target exists and is not a directory: %s\n' "$target" >&2
    exit 1
  fi
  if [[ -d "$target" ]]; then
    if [[ "$force" != true ]]; then
      printf 'Target differs; review it before using --force: %s\n' "$target" >&2
      exit 1
    fi
    mkdir -p "$backup_root"
    local backup="$backup_root/$name.before-v04-$timestamp"
    mv -- "$target" "$backup"
    printf 'Preserved previous target: %s\n' "$backup"
  fi

  mkdir -p "$target"
  cp -R "$source/." "$target/"
  printf 'Installed skill: %s\n' "$target"
}

install_skill "codex-collab-switch"
printf '%s\n' 'Installation complete. No Codex config.toml or custom agent was changed.'
