#!/bin/sh
set -eu

IMAGE="${1:-snell:test}"
PORT_VALUE="${PORT_VALUE:-28345}"
LOG_FILE="$(mktemp)"
CONTAINER_ID=""

cleanup() {
  rm -f "$LOG_FILE"
  if [ -n "$CONTAINER_ID" ]; then
    docker rm -f "$CONTAINER_ID" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

CONTAINER_ID="$(docker run -d --init --network host -e PORT="$PORT_VALUE" -e PSK=abcdefghijkl -e DNS_IP_PREFERENCE=ipv4-only -e LOG_LEVEL=verbose "$IMAGE")"
sleep 2
docker logs "$CONTAINER_ID" >"$LOG_FILE" 2>&1

if [ "$(docker inspect -f '{{.State.Running}}' "$CONTAINER_ID")" != "true" ]; then
  echo "container exited before the smoke test completed" >&2
  cat "$LOG_FILE" >&2
  exit 1
fi

grep -q "PORT:${PORT_VALUE}" "$LOG_FILE"
grep -q 'LOG_LEVEL:verbose' "$LOG_FILE"
grep -q 'DNS_IP_PREFERENCE:ipv4-only' "$LOG_FILE"

if grep -q '^PSK:' "$LOG_FILE"; then
  echo "runtime summary must not expose PSK" >&2
  exit 1
fi

docker stop -t 2 "$CONTAINER_ID" >/dev/null
exit_code="$(docker inspect -f '{{.State.ExitCode}}' "$CONTAINER_ID")"

if [ "$exit_code" -eq 137 ]; then
  echo "container was force-killed instead of exiting gracefully" >&2
  exit 1
fi
