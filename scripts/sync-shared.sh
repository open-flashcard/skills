#!/usr/bin/env bash
# Copies shared/ reference files into each skill's references/ folder, so every skill folder stays
# self-contained (skills are installed and uploaded one folder at a time).
# Usage: scripts/sync-shared.sh          write the copies
#        scripts/sync-shared.sh --check  exit 1 if any copy is out of date (for CI)
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
skills="$root/plugins/ofc/skills"

# shared file -> skills that bundle it
targets() {
  case "$1" in
    spec-rules.md)   echo ofc-author ofc-validate ofc-convert ofc-review ;;
    card-quality.md) echo ofc-author ofc-review ;;
  esac
}

check=false
[[ "${1:-}" == "--check" ]] && check=true
stale=0

for src in "$root"/shared/*.md; do
  name="$(basename "$src")"
  for skill in $(targets "$name"); do
    dest="$skills/$skill/references/$name"
    if $check; then
      if ! cmp -s "$src" "$dest"; then
        echo "out of date: ${dest#"$root"/}"
        stale=1
      fi
    else
      mkdir -p "$(dirname "$dest")"
      cp "$src" "$dest"
      echo "synced: ${dest#"$root"/}"
    fi
  done
done

if $check && [[ $stale -ne 0 ]]; then
  echo "run scripts/sync-shared.sh to update" >&2
  exit 1
fi
