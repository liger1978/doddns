# doddns Makefile
#
# Build system: none (pure Python). This Makefile only handles install/uninstall.
#
# Required Ubuntu packages:
#   sudo apt install -y python3 make git python3-requests python3-yaml python3-dnspython
# (python3 is usually pre-installed on every Ubuntu image.)

# ---------------------------------------------------------------------
# Tunables
PREFIX       ?= /usr/local           # change if you prefer /usr
BIN_DIR      := $(PREFIX)/bin
SERVICE_DIR  := /etc/systemd/system

CONFIG_FILE  := /etc/doddns.yaml
SERVICE_FILE := $(SERVICE_DIR)/doddns.service
PY_SRC       := doddns.py

USR          := doddns               # system user that runs the daemon
GRP          := doddns               # matching group

# ---------------------------------------------------------------------
.PHONY: install uninstall

install:
	@echo "==> Installing doddns"
	@echo "   (ensure the Ubuntu packages python3-requests python3-yaml python3-dnspython are installed)"
	# 1. create system group & user if absent
	@if ! getent group $(GRP) >/dev/null;  then sudo groupadd --system $(GRP); fi
	@if ! id -u $(USR) >/dev/null 2>&1;    then sudo useradd --system --gid $(GRP) \
	                              --shell /usr/sbin/nologin --home /nonexistent $(USR); fi
	# 2. install executable
	sudo install -Dm755 $(PY_SRC) $(BIN_DIR)/doddns
	# 3. install default config only if missing
	@if [ ! -f $(CONFIG_FILE) ]; then sudo install -Dm640 doddns.yaml $(CONFIG_FILE); fi
	sudo chown $(USR):$(GRP) $(CONFIG_FILE)
	# 4. install systemd unit
	sudo install -Dm644 doddns.service $(SERVICE_FILE)
	# 5. enable & start service
	sudo systemctl daemon-reload
	sudo systemctl enable --now doddns.service
	@echo "doddns installed and running."

uninstall:
	@echo "==> Uninstalling doddns"
	# stop and disable service (ignore errors if not running)
	- sudo systemctl disable --now doddns.service
	# remove installed files
	- sudo rm -f $(SERVICE_FILE)
	- sudo rm -f $(BIN_DIR)/doddns
	- sudo rm -f $(CONFIG_FILE)
	# reload systemd
	sudo systemctl daemon-reload
	# optionally delete user & group (will fail if still referenced elsewhere)
	- sudo userdel $(USR)
	- sudo groupdel $(GRP)
	@echo "doddns fully removed."
