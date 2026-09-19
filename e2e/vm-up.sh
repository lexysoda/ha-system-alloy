#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

: "${OVERLAY:?}" "${CONFIG_IMG:?}" "${OVMF_CODE:?}" "${OVMF_VARS:?}" "${PIDFILE:?}" \
  "${SERIAL_LOG:?}" "${HA_PORT:?}" "${SSH_PORT:?}" "${MEM:?}" "${SMP:?}" "${SSH_OPTS:?}"

read -ra SSH_OPTS <<< "${SSH_OPTS}"

if [ -f "${PIDFILE}" ] && kill -0 "$(cat "${PIDFILE}")" 2>/dev/null; then
    echo "VM already running (pid $(cat "${PIDFILE}"))."
    exit 0
fi

ACCEL="tcg"
[ -e /dev/kvm ] && ACCEL="kvm"

start_qemu() {
    qemu-system-x86_64 \
        -name haos-e2e \
        -machine "q35,accel=${ACCEL}" \
        -cpu host \
        -m "${MEM}" -smp "${SMP}" \
        -drive if=pflash,unit=0,format=raw,readonly=on,file="${OVMF_CODE}" \
        -drive if=pflash,unit=1,format=raw,file="${OVMF_VARS}" \
        -device virtio-scsi-pci,id=scsi0 \
        -drive file="${OVERLAY}",if=none,id=drive0,format=qcow2,discard=unmap \
        -device scsi-hd,bus=scsi0.0,drive=drive0 \
        -drive file="${CONFIG_IMG}",if=virtio,format=raw \
        -netdev "user,id=net0,hostfwd=tcp::${HA_PORT}-:80,hostfwd=tcp::${SSH_PORT}-:22222" \
        -device virtio-net-pci,netdev=net0 \
        -serial file:"${SERIAL_LOG}" \
        -display none \
        -daemonize \
        -pidfile "${PIDFILE}"
}

wait_for_ssh() {
    local timeout="$1" waited=0
    while [ "${waited}" -lt "${timeout}" ]; do
        if ssh -o BatchMode=yes -o ConnectTimeout=3 "${SSH_OPTS[@]}" root@localhost true 2>/dev/null; then
            return 0
        fi
        sleep 3
        waited=$((waited + 3))
    done
    return 1
}

on_ssh_ready() {
    ./bootstrap-onboarding.sh
    echo "VM is up: ssh on port ${SSH_PORT}, Home Assistant on http://localhost:${HA_PORT}"
    exit 0
}

echo "Starting HAOS VM (accel=${ACCEL})..."
start_qemu

echo "Waiting for SSH (first boot can take a couple of minutes)..."
if wait_for_ssh 180; then
    on_ssh_ready
fi

echo "SSH not reachable yet - the CONFIG key import likely needs a reboot cycle. Restarting the VM once..."
kill "$(cat "${PIDFILE}")" 2>/dev/null || true
sleep 3
start_qemu

if wait_for_ssh 180; then
    on_ssh_ready
fi

echo "VM did not come up. Check ${SERIAL_LOG} for boot output." >&2
exit 1
