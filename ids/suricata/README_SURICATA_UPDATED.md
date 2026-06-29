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

Check `default-rule-path` near the top of the file:

```sh
grep "default-rule-path" /etc/suricata/suricata.yaml
```

On Grml this is set to `/var/lib/suricata/rules`, which doesn't exist by default — if left as-is, `local.rules` will never be found no matter where you put it. Change it to:

```yaml
default-rule-path: /etc/suricata/rules
```

The default config lists a long set of Emerging Threats rule files under `rule-files:`, most of them commented out, a couple enabled by default (e.g. `botcc.rules`). Those default-enabled ones aren't actually present on disk after a plain install and will fail validation. Comment out any `rule-files:` entry that isn't actually in `/etc/suricata/rules/`, and add ours:

```yaml
rule-files:
# - botcc.rules
# - ciarmy.rules
 - local.rules
```

Copy *local.rules* to `/etc/suricata/rules/local.rules` (same file used for Snort — Suricata reads Snort rule syntax natively, no changes needed).


## Configuring the interface

If we're going to use the systemd service (`systemctl start suricata`), Suricata must know which interface to monitor. The service does **not** pass `-i <interface>` on the command line, so the interface must be configured in the `af-packet` section of `suricata.yaml`.

First, identify the LAN interface:

```sh
ip addr
```

Look for the interface connected to our internal network (e.g. `192.168.0.0/24`).

Then edit `/etc/suricata/suricata.yaml` and find the `af-packet:` section. It looks similar to:

```yaml
af-packet:
  - interface: eth0
```

Replace the interface with our LAN interface, for example:

```yaml
af-packet:
  - interface: eth1
```

If we're running Suricata manually using `-i <interface>`, this step isn't necessary because the command-line option overrides the configuration.

## Validating

```sh
suricata -T -c /etc/suricata/suricata.yaml -v
```

Confirm it loads `local.rules` with no errors. If it complains a rule file doesn't match any pattern, check two things:
- That file is still listed in `rule-files:` but missing from the rules directory — comment it out.
- **On Grml specifically**: the default config sets `default-rule-path: /var/lib/suricata/rules`, which doesn't exist by default. This means `local.rules` won't be found there even though it's correctly listed in `rule-files:`. Either move `local.rules` to that path, or change the setting itself:
  ```yaml
  default-rule-path: /etc/suricata/rules
  ```
  to match where we actually put `local.rules`.

## Running

Using the systemd service:

```sh
systemctl start suricata
systemctl status suricata
```

This starts Suricata using the interface configured in the `af-packet` section of `/etc/suricata/suricata.yaml`.

If we'd rather run it manually instead (e.g. to specify the interface directly without editing the `af-packet` section):

```sh
suricata -D -c /etc/suricata/suricata.yaml -i <lan>
```

Either way, check it's running:

```sh
ps aux | grep suricata
```

Alerts don't print to console like Snort's `-A console` — they go to a log file:
```sh
tail -f /var/log/suricata/fast.log
```

(`/var/log/suricata/eve.json` also exists, same alerts in structured JSON, if more detail is needed.)

To stop it:
```sh
systemctl stop suricata
```
or, if started manually: `pkill suricata`. If that doesn't work (seen this hang once locally), use `pkill -9 suricata` or find the PID with `ps aux | grep suricata` and `kill -9 <PID>`.

## Demo

Same as the Snort version — from a workstation:

```sh
ping -c 4 <gateway-ip>
nmap -p 1-100 <gateway-ip>
nc -zv <gateway-ip> 23
```

Each produces a line in `fast.log` with the matching sid (1000001, 1000002, 1000003) and message text.
