#!/bin/sh
set -eu

SOURCE="${1:-https://kb.nssurge.com/surge-knowledge-base/release-notes/snell}"
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

load_release_notes() {
  if [ -f "$SOURCE" ]; then
    cat "$SOURCE"
  else
    curl -fsSL "$SOURCE"
  fi
}

extract_versions() {
  load_release_notes |
    grep -Eo 'snell-server-v[0-9]+\.[0-9]+\.[0-9]+(b[0-9]+)?-linux-[[:alnum:]]+\.zip' |
    sed -E 's/^snell-server-(v[0-9]+\.[0-9]+\.[0-9]+(b[0-9]+)?)-linux-[[:alnum:]]+\.zip$/\1/' |
    sort -u
}

versions="$(extract_versions || true)"
if [ -z "$versions" ]; then
  echo "failed to extract Snell versions from $SOURCE" >&2
  exit 1
fi

latest_version="$(printf '%s\n' "$versions" | sh "$SCRIPT_DIR/select-snell-version.sh")"

if [ ! -f "$SOURCE" ]; then
  curl -fsSLI -o /dev/null "https://dl.nssurge.com/snell/snell-server-${latest_version}-linux-amd64.zip"
fi

printf '%s\n' "$latest_version"
