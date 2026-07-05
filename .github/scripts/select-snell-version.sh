#!/bin/sh
set -eu

selected_version="$({
  awk '
    function emit(original, normalized, parts, major, minor, patch, stability, prerelease_num) {
      normalized = original
      stability = 1
      prerelease_num = 0

      if (normalized ~ /^v[0-9]+\.[0-9]+\.[0-9]+b[0-9]+$/) {
        stability = 0
        sub(/^v/, "", normalized)
        split(normalized, parts, /[.b]/)
        major = parts[1] + 0
        minor = parts[2] + 0
        patch = parts[3] + 0
        prerelease_num = parts[4] + 0
      } else if (normalized ~ /^v[0-9]+\.[0-9]+\.[0-9]+$/) {
        sub(/^v/, "", normalized)
        split(normalized, parts, /\./)
        major = parts[1] + 0
        minor = parts[2] + 0
        patch = parts[3] + 0
      } else {
        return
      }

      printf "%09d %09d %09d %01d %09d %s\n", major, minor, patch, stability, prerelease_num, original
    }

    { emit($0) }
  ' | sort | tail -n 1 | awk '{print $6}'
} || true)"

if [ -z "$selected_version" ]; then
  echo "no valid Snell versions provided" >&2
  exit 1
fi

printf '%s\n' "$selected_version"
