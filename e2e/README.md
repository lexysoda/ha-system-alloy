# e2e test setup

Boots a real Home Assistant OS VM (QEMU) to test the `alloy-system` app end
to end, without needing real hardware. First boot auto-onboards with a fixed
admin login (`admin` / `admin`) and no browser interaction is required.

## Requirements

`qemu-desktop`, `mtools`, `edk2-ovmf`, `jq`, plus `curl`/`unxz`/`openssh`
(usually already installed).

## Usage

Run from the repo root or from this directory:

- `make up` — download/build VM state as needed, then boot it
- `make sync` — push the local `alloy-system/` app into the VM and rebuild it (does not start it - configure it in the UI first)
- `make ssh` — root shell on the VM
- `make status` — check if the VM is running
- `make down` — stop the VM
- `make clean` — stop the VM and wipe disposable state (keeps the downloaded base image)
- `make distclean` — `clean`, plus delete the downloaded base image

Home Assistant is reachable at http://localhost:8123.

## TODO
- [ ] Add grafana instance to test against locally.
