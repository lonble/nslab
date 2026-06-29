# Intrusion Detection System (Suricata backup)

This is a backup option for the IDS component, in case Snort's install (see `README.md`) runs into trouble during the lab. Suricata is the modern, actively maintained replacement for Snort — it reads the same rule syntax, runs the same way (passive listener, no nftables rule needed), and installs cleanly from current Debian repos with no archive pinning.

## Installation

```sh
apt update
apt install suricata -y
```

No debconf prompts, no extra repo lines — Suricata is in the normal repos.

## Configuration

Edit `/etc/suricata/suricata.yaml`. Find the `HOME_NET` line under `vars: -> address-groups:` and set it:

```yaml
HOME_NET: "[192.168.0.0/24]"
```

The default config lists a long set of Emerging Threats rule files under `rule-files:`, most of them commented out, a couple enabled by default (e.g. `botcc.rules`). Those default-enabled ones aren't actually present on disk after a plain install and will fail validation. Comment out any `rule-files:` entry that isn't actually in `/etc/suricata/rules/`, and add ours:

```yaml
rule-files:
# - botcc.rules
# - ciarmy.rules
 - local.rules
```

Copy *local.rules* to `/etc/suricata/rules/local.rules` (same file used for Snort — Suricata reads Snort rule syntax natively, no changes needed).

## Validating

```sh
suricata -T -c /etc/suricata/suricata.yaml -v
```

Confirm it loads `local.rules` with no errors. If it complains a rule file doesn't match any pattern, that file is still listed in `rule-files:` but missing from `/etc/suricata/rules/` — comment it out.

## Running

Suricata doesn't print alerts straight to the console the way Snort's `-A console` does — alerts go to a log file. Run it as a background daemon so the terminal stays free:

```sh
suricata -D -c /etc/suricata/suricata.yaml -i <lan>
```

Check it's running:
```sh
ps aux | grep suricata
```

Watch alerts live:
```sh
tail -f /var/log/suricata/fast.log
```

(`/var/log/suricata/eve.json` also exists, with the same alerts in structured JSON, if more detail is needed.)

To stop it:
```sh
pkill suricata
```
If that doesn't work (seen this hang once locally), use `pkill -9 suricata` or find the PID with `ps aux | grep suricata` and `kill -9 <PID>`.

## Demo

Same as the Snort version — from a workstation:

```sh
ping -c 4 <gateway-ip>
nmap -p 1-100 <gateway-ip>
nc -zv <gateway-ip> 23
```

Each produces a line in `fast.log` with the matching sid (1000001, 1000002, 1000003) and message text.
