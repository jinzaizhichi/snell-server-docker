#!/bin/sh
set -eu

SELECT_SCRIPT=".github/scripts/select-snell-version.sh"
RESOLVE_SCRIPT=".github/scripts/resolve-latest-snell-version.sh"
HTML_FILE="$(mktemp)"
EMPTY_FILE="$(mktemp)"
LOG_FILE="$(mktemp)"

cleanup() {
  rm -f "$HTML_FILE" "$EMPTY_FILE" "$LOG_FILE"
}
trap cleanup EXIT

[ "$(printf 'v6.0.0b4\nv6.0.0b5\n' | sh "$SELECT_SCRIPT")" = "v6.0.0b5" ]
[ "$(printf 'v6.0.0b4\nv6.0.0\n' | sh "$SELECT_SCRIPT")" = "v6.0.0" ]

cat >"$HTML_FILE" <<'EOF'
<a href="https://dl.nssurge.com/snell/snell-server-v5.0.1-linux-amd64.zip">v5.0.1</a>
<a href="https://dl.nssurge.com/snell/snell-server-v6.0.0b4-linux-amd64.zip">v6.0.0b4</a>
<a href="https://dl.nssurge.com/snell/snell-server-v6.0.0-linux-amd64.zip">v6.0.0</a>
<a href="https://dl.nssurge.com/snell/snell-server-v6.0.0b4-linux-aarch64.zip">v6.0.0b4 arm64</a>
EOF

[ "$(sh "$RESOLVE_SCRIPT" "$HTML_FILE")" = "v6.0.0" ]

if sh "$RESOLVE_SCRIPT" "$EMPTY_FILE" >"$LOG_FILE" 2>&1; then
  echo "expected empty release notes input to fail" >&2
  cat "$LOG_FILE" >&2
  exit 1
fi

grep -q 'failed to extract Snell versions' "$LOG_FILE"
