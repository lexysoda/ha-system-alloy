#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

: "${SSH_OPTS:?}"

APP_SLUG="alloy-system"
APP_SRC="../alloy-system/"
REMOTE_PATH="/mnt/data/supervisor/apps/local/${APP_SLUG}"
LOCAL_SLUG="local_${APP_SLUG}"

read -ra SSH_OPTS <<< "${SSH_OPTS}"

echo "==> Running local pre-flight checks..."
bash -n "${APP_SRC}rootfs/etc/alloy/init.sh"
bash -n "${APP_SRC}rootfs/etc/s6-overlay/s6-rc.d/alloy/run"

echo "==> Syncing ${APP_SRC} -> vm:${REMOTE_PATH} via tar over ssh..."
ssh "${SSH_OPTS[@]}" root@localhost "rm -rf '${REMOTE_PATH}' && mkdir -p '${REMOTE_PATH}'"
tar -C "${APP_SRC}" -cf - . | ssh "${SSH_OPTS[@]}" root@localhost "tar -C '${REMOTE_PATH}' -xf -"

echo "==> Reloading store..."
ssh "${SSH_OPTS[@]}" root@localhost "ha store reload"

echo "==> Ensuring ${LOCAL_SLUG} is installed..."
ssh "${SSH_OPTS[@]}" root@localhost "ha apps install ${LOCAL_SLUG}" || true

echo "==> Rebuilding ${LOCAL_SLUG}..."
ssh "${SSH_OPTS[@]}" root@localhost "ha apps rebuild ${LOCAL_SLUG}"

echo "==> Sync complete! Check '${LOCAL_SLUG}' at http://localhost:${HA_PORT:-8123}"
