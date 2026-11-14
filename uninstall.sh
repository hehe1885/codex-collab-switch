#!/usr/bin/env bash
set -euo pipefail

legacy=false
if [[ "$#" -gt 1 ]]; then
  printf '%s\n' 'usage: ./uninstall.sh [--legacy]' >&2
  exit 2
fi
if [[ "$#" -eq 1 ]]; then
  if [[ "$1" != "--legacy" ]]; then
    printf '%s\n' 'usage: ./uninstall.sh [--legacy]' >&2
    exit 2
  fi
  legacy=true
fi

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

timestamp="$(date -u '+%Y%m%dT%H%M%SZ')-$$"

uninstall_skill() {
  local name="$1"
  local source="$package_dir/skills/$name"
  local target="$skills_root/$name"
  local marker="$target/.codex-collab-switch-v04"

  if [[ ! -d "$target" || -L "$target" || ! -f "$marker" ]] || ! diff -rq "$source" "$target" >/dev/null 2>&1; then
    printf 'Skipped missing, unowned, or modified skill: %s\n' "$target"
    return
  fi
  mkdir -p "$backup_root"
  local backup="$backup_root/$name.uninstalled-v04-$timestamp"
  mv -- "$target" "$backup"
  printf 'Moved installed skill to recoverable backup: %s\n' "$backup"
}

uninstall_skill "codex-collab-switch"
printf '%s\n' 'Uninstall complete. No Codex config.toml or custom agent was changed.'
