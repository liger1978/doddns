# doddns
Digital Ocean Dynamic DNS Updater

---

## Features

* Resolves your public IPv4 and updates the A‑record only when it changes.
* 60‑second TTL for near‑instant propagation.
* Uses the local DNS resolver first and calls the DigitalOcean API **only when necessary**.
* Lightweight: pure Python 3, systemd‑managed, no root privileges while running.
* One‑step install / uninstall via `make`.

---

## Ubuntu prerequisites

| Purpose            | Package   | Notes                                                                          |
| ------------------ | --------- | ------------------------------------------------------------------------------ |
| Python interpreter | `python3` | Already present on current Ubuntu LTS images but listed here for completeness. |
| Build / automation | `make`    | Needed only for the `make install` / `make uninstall` targets.                 |
| Git (optional)     | `git`     | Only if you clone the repo via Git instead of downloading an archive.          |

```bash
sudo apt update
sudo apt install -y python3 make git python3-requests python3-yaml python3-dnspython
```

---

## Quick start

```bash
# 1. Fetch the code
git clone https://github.com/liger1978/doddns.git
cd doddns

# 2. Install system‑wide (prompts for sudo)
make install
```

This creates:

* `/usr/local/bin/doddns` – executable daemon
* `/etc/doddns.yaml`       – configuration template (root‑only, owned by the `doddns` user)
* `/etc/systemd/system/doddns.service` – service unit
* System user & group `doddns`

The service starts immediately. Tail the journal with:

```bash
journalctl -u doddns -f
```

---

## Configuration

Edit `/etc/doddns.yaml` (root privileges required):

```yaml
name: home.example.com        # FQDN managed by DigitalOcean DNS
token: dop_v1_XXXX...         # Personal access token
interval_minutes: 5           # Polling interval (optional, default 5)
```

After changes:

```bash
sudo systemctl restart doddns
```

---

## Uninstall

Remove everything that the installer added:

```bash
cd doddns   # repo directory
make uninstall
```

---

## Service control snippets

| Command                               | Purpose                   |
| ------------------------------------- | ------------------------- |
| `sudo systemctl status doddns`        | Show service status       |
| `sudo systemctl restart doddns`       | Reload config immediately |
| `sudo systemctl disable --now doddns` | Stop & disable on boot    |

---

## Security notes

* Runs under a dedicated system user with no shell and no home directory (`/nonexistent`).
* Only the token file (`/etc/doddns.yaml`) is readable by that user.
* If you need persistent state or cache files, change the user's home to something like `/var/lib/doddns` and grant write permission only there.

---

Happy low‑latency DNS updates! \:rocket:
