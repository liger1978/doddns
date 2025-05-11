# doddns Makefile  – install / uninstall

# ---------------------------------------------------------------------
# Tunables
PREFIX      ?= /usr/local      # change if you prefer /usr
BIN_DIR     := $(PREFIX)/bin
SERVICE_DIR := /etc/systemd/system

CONFIG_FILE  := /etc/doddns.yaml
SERVICE_FILE := $(SERVICE_DIR)/doddns.service
PY_SRC       := doddns.py

USR := doddns
GRP := doddns

# ---------------------------------------------------------------------
.PHONY: install uninstall

install:
	@echo "==> Installing doddns"
	@echo "   (requires: python3 make git python3-requests python3-yaml python3-dnspython)"
	# 1. system user & group
	@if ! getent group $(GRP) >/dev/null;  then sudo groupadd --system $(GRP); fi
	@if ! id -u $(USR) >/dev/null 2>&1;    then \
	    sudo useradd --system --gid $(GRP) --shell /usr/sbin/nologin --home /nonexistent $(USR); fi
	# 2. executable
	sudo install -Dm755 $(PY_SRC) $(BIN_DIR)/doddns
	# 3. default config (only if absent)
	@if [ ! -f $(CONFIG_FILE) ]; then sudo install -Dm640 doddns.yaml $(CONFIG_FILE); fi
	sudo chown $(USR):$(GRP) $(CONFIG_FILE)
	# 4. systemd unit
	sudo install -Dm644 doddns.service $(SERVICE_FILE)
	# 5. enable & start
	sudo systemctl daemon-reload
	sudo systemctl enable --now doddns.service
	@echo "doddns installed and running."

uninstall:
	@echo "==> Uninstalling doddns"
	- sudo systemctl disable --now doddns.service
	- sudo rm -f $(SERVICE_FILE)
	- sudo rm -f $(BIN_DIR)/doddns
	- sudo rm -f $(CONFIG_FILE)
	sudo systemctl daemon-reload
	- sudo userdel $(USR)
	- sudo groupdel $(GRP)
	@echo "doddns fully removed."
