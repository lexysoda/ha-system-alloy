.DELETE_ON_ERROR:

HAOS_VERSION := 18.3

IMAGE_DIR := image
STATE_DIR := state
KEYS_DIR  := keys

HAOS_XZ    := $(IMAGE_DIR)/haos_ova-$(HAOS_VERSION).qcow2.xz
HAOS_QCOW2 := $(IMAGE_DIR)/haos_ova-$(HAOS_VERSION).qcow2
HAOS_URL   := https://github.com/home-assistant/operating-system/releases/download/$(HAOS_VERSION)/haos_ova-$(HAOS_VERSION).qcow2.xz

OVMF_CODE := $(shell for p in \
	/usr/share/edk2-ovmf/x64/OVMF_CODE.4m.fd \
	/usr/share/edk2/x64/OVMF_CODE.4m.fd \
	/usr/share/ovmf/x64/OVMF_CODE.fd \
	/usr/share/OVMF/OVMF_CODE.fd; \
	do [ -f "$$p" ] && echo "$$p" && break; done)
OVMF_VARS_TEMPLATE := $(subst CODE,VARS,$(OVMF_CODE))

SSH_KEY     := $(KEYS_DIR)/vm_ed25519
CONFIG_IMG  := $(STATE_DIR)/config.img
OVERLAY     := $(STATE_DIR)/overlay.qcow2
OVMF_VARS   := $(STATE_DIR)/OVMF_VARS.fd
PIDFILE     := $(STATE_DIR)/qemu.pid
SERIAL_LOG  := $(STATE_DIR)/serial.log
KNOWN_HOSTS := $(STATE_DIR)/known_hosts

HA_PORT  ?= 8123
SSH_PORT ?= 22222
MEM      ?= 4096
SMP      ?= 2

SSH_OPTS := -i $(SSH_KEY) -p $(SSH_PORT) -o UserKnownHostsFile=$(KNOWN_HOSTS) -o StrictHostKeyChecking=accept-new

export SSH_KEY SSH_PORT KNOWN_HOSTS OVERLAY CONFIG_IMG OVMF_CODE OVMF_VARS PIDFILE SERIAL_LOG HA_PORT MEM SMP SSH_OPTS

.PHONY: up down ssh sync status clean distclean check-deps browse

check-deps:
	@command -v qemu-system-x86_64 >/dev/null || { echo "qemu-system-x86_64 not found (Arch: pacman -S qemu-desktop)"; exit 1; }
	@command -v qemu-img >/dev/null || { echo "qemu-img not found (Arch: pacman -S qemu-img)"; exit 1; }
	@command -v mformat >/dev/null || { echo "mtools not found (Arch: pacman -S mtools)"; exit 1; }
	@command -v curl >/dev/null || { echo "curl not found"; exit 1; }
	@command -v unxz >/dev/null || { echo "unxz not found (Arch: pacman -S xz)"; exit 1; }
	@command -v jq >/dev/null || { echo "jq not found (Arch: pacman -S jq)"; exit 1; }
	@test -n "$(OVMF_CODE)" || { echo "OVMF firmware not found (Arch: pacman -S edk2-ovmf)"; exit 1; }
	@test -f "$(OVMF_VARS_TEMPLATE)" || { echo "OVMF vars template not found at $(OVMF_VARS_TEMPLATE)"; exit 1; }

$(IMAGE_DIR) $(STATE_DIR) $(KEYS_DIR):
	mkdir -p $@

$(HAOS_XZ): | $(IMAGE_DIR)
	curl -fL -o $@ $(HAOS_URL)

$(HAOS_QCOW2): $(HAOS_XZ)
	unxz -f -c $< > $@

$(SSH_KEY) $(SSH_KEY).pub &: | $(KEYS_DIR)
	rm -f $(SSH_KEY) $(SSH_KEY).pub
	ssh-keygen -t ed25519 -N "" -C "haos-e2e-vm" -f $(SSH_KEY)

$(CONFIG_IMG): $(SSH_KEY).pub | $(STATE_DIR)
	rm -f $@
	truncate -s 1M $@
	mformat -i $@ -v CONFIG ::
	mcopy -i $@ $(SSH_KEY).pub ::authorized_keys

$(OVMF_VARS): | $(STATE_DIR)
	cp $(OVMF_VARS_TEMPLATE) $@

$(OVERLAY): $(HAOS_QCOW2) | $(STATE_DIR)
	rm -f $@
	qemu-img create -f qcow2 -F qcow2 -b $(abspath $(HAOS_QCOW2)) $@

up: check-deps $(OVERLAY) $(CONFIG_IMG) $(OVMF_VARS)
	./vm-up.sh

down:
	./vm-down.sh

ssh: $(SSH_KEY)
	ssh $(SSH_OPTS) root@localhost

sync: $(SSH_KEY)
	./sync.sh

browse:
	xdg-open http://localhost:$(HA_PORT)

status:
	@if [ -f $(PIDFILE) ] && kill -0 "$$(cat $(PIDFILE))" 2>/dev/null; then \
		echo "VM running (pid $$(cat $(PIDFILE)))"; \
	else \
		echo "VM not running"; \
	fi

clean: down
	rm -rf $(STATE_DIR) $(KEYS_DIR)

distclean: clean
	rm -rf $(IMAGE_DIR)
