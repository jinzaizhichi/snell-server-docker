#!/bin/sh
set -eu

LIFECYCLE_SCRIPT=".github/scripts/snell-version-lifecycle.sh"
EXPECTED_VERSION="$(awk -F= '/^ARG SNELL_VERSION=/{print $2; exit}' Dockerfile)"
LOG_FILE="$(mktemp)"
DUPLICATE_DOCKERFILE="$(mktemp)"

cleanup() {
  rm -f "$LOG_FILE" "$DUPLICATE_DOCKERFILE"
}
trap cleanup EXIT

if [ -z "$EXPECTED_VERSION" ]; then
  echo "failed to read SNELL_VERSION from Dockerfile" >&2
  exit 1
fi

ACTUAL_VERSION="$(sh "$LIFECYCLE_SCRIPT" validate-current)"
[ "$ACTUAL_VERSION" = "$EXPECTED_VERSION" ]

GITHUB_REF_TYPE=tag GITHUB_REF_NAME="$EXPECTED_VERSION" sh "$LIFECYCLE_SCRIPT" validate-current >/dev/null

if GITHUB_REF_TYPE=tag GITHUB_REF_NAME=v0.0.0 sh "$LIFECYCLE_SCRIPT" validate-current >"$LOG_FILE" 2>&1; then
  echo "expected mismatched tag to fail" >&2
  cat "$LOG_FILE" >&2
  exit 1
fi

grep -q 'does not match SNELL_VERSION' "$LOG_FILE"

{
  cat Dockerfile
  echo 'ARG SNELL_VERSION=v0.0.0'
} >"$DUPLICATE_DOCKERFILE"

if sh "$LIFECYCLE_SCRIPT" validate-current "$DUPLICATE_DOCKERFILE" >"$LOG_FILE" 2>&1; then
  echo "expected duplicate SNELL_VERSION defaults to fail" >&2
  cat "$LOG_FILE" >&2
  exit 1
fi

grep -q 'exactly one defaulted ARG SNELL_VERSION' "$LOG_FILE"
