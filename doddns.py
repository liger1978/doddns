#!/usr/bin/env python3
"""
doddns – DigitalOcean Dynamic-DNS updater.
Config: /etc/doddns.yaml   (keys: name, token, interval_minutes)
"""

import argparse, logging, time
from pathlib import Path
import requests, yaml, dns.resolver                # ← new import

TTL = 60                                           # seconds

# ---------- helpers ----------------------------------------------------------
def load_cfg(p: Path) -> dict:
    with p.open() as f:
        return yaml.safe_load(f)

def public_ip() -> str:
    return requests.get("https://api.ipify.org", timeout=10).text.strip()

def split_fqdn(fqdn: str) -> tuple[str, str]:
    parts = fqdn.split(".", 1)
    if len(parts) != 2:
        raise ValueError("config ‘name’ must contain at least one dot")
    return parts[0], parts[1]                      # host, zone

def resolve_a(fqdn: str) -> str | None:
    try:
        ans = dns.resolver.resolve(fqdn, "A", lifetime=5)
        return ans[0].to_text()
    except dns.resolver.NXDOMAIN:
        return None

def do_headers(t: str) -> dict:
    return {"Authorization": f"Bearer {t}"}

def get_rec(zone: str, host: str, tok: str) -> dict | None:
    url = f"https://api.digitalocean.com/v2/domains/{zone}/records"
    r = requests.get(url, headers=do_headers(tok), timeout=15)
    r.raise_for_status()
    for rec in r.json()["domain_records"]:
        if rec["type"] == "A" and rec["name"] == host:
            return rec
    return None

def create_rec(zone: str, host: str, ip: str, tok: str):
    url = f"https://api.digitalocean.com/v2/domains/{zone}/records"
    body = {"type": "A", "name": host, "data": ip, "ttl": TTL}
    requests.post(url, headers=do_headers(tok), json=body, timeout=15).raise_for_status()

def update_rec(zone: str, rec_id: int, ip: str, tok: str):
    url = f"https://api.digitalocean.com/v2/domains/{zone}/records/{rec_id}"
    body = {"data": ip, "ttl": TTL}
    requests.put(url, headers=do_headers(tok), json=body, timeout=15).raise_for_status()

# ---------- daemon -----------------------------------------------------------
def daemon(cfg: dict):
    fqdn = cfg["name"]
    host, zone = split_fqdn(fqdn)
    tok  = cfg["token"]
    intv = int(cfg.get("interval_minutes", 5)) * 60

    logging.info("tracking %s every %ss (TTL=%s)", fqdn, intv, TTL)
    while True:
        try:
            ip_pub = public_ip()
            ip_dns = resolve_a(fqdn)

            if ip_dns == ip_pub:
                logging.debug("match – DNS already %s", ip_pub)

            else:
                rec = get_rec(zone, host, tok)     # API only when mismatch
                if rec is None:
                    logging.info("no record – creating %s", ip_pub)
                    create_rec(zone, host, ip_pub, tok)
                elif rec["data"] != ip_pub or rec.get("ttl") != TTL:
                    logging.info("updating %s → %s (ttl %s→%s)",
                                 rec['data'], ip_pub, rec.get('ttl'), TTL)
                    update_rec(zone, rec["id"], ip_pub, tok)
                else:
                    logging.debug("API shows correct data; resolver lagging")
        except Exception as e:
            logging.exception("cycle error: %s", e)

        time.sleep(intv)

# ---------- entry point ------------------------------------------------------
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("-c", "--config", default="/etc/doddns.yaml")
    args = ap.parse_args()

    logging.basicConfig(level=logging.INFO,
                        format="%(asctime)s %(levelname)s %(message)s",
                        datefmt="%Y-%m-%d %H:%M:%S")
    daemon(load_cfg(Path(args.config)))

if __name__ == "__main__":
    main()
