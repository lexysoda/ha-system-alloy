#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

: "${PIDFILE:?}" "${SSH_OPTS:?}"

read -ra SSH_OPTS <<< "${SSH_OPTS}"

if [ ! -f "${PIDFILE}" ] || ! kill -0 "$(cat "${PIDFILE}")" 2>/dev/null; then
    echo "VM not running."
    exit 0
fi

ssh -o BatchMode=yes -o ConnectTimeout=3 "${SSH_OPTS[@]}" root@localhost poweroff 2>/dev/null || true

pid="$(cat "${PIDFILE}")"
for _ in $(seq 1 20); do
    if ! kill -0 "${pid}" 2>/dev/null; then
        rm -f "${PIDFILE}"
        echo "VM stopped."
        exit 0
    fi
    sleep 1
done

echo "VM did not shut down gracefully, killing..."
kill "${pid}" 2>/dev/null || true
rm -f "${PIDFILE}"
