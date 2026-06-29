# Intrusion Detection System

We use **Snort** as our IDS. It runs on the gateway (`192.168.0.1`) in passive **IDS mode**, listening on the LAN-facing interface for suspicious traffic. It does not block or modify any traffic.

Since Snort is a passive libpcap listener and not an inline interceptor like Squid, it needs **no nftables rule**. It just reads whatever traffic already flows through the gateway's LAN interface during normal routing.

## Installation

Snort is no longer in current Debian repos, and the assignment's suggested workaround (`oldoldstable`) no longer resolves to a release that has it — confirmed failing on the actual Grml image. Use this instead, which points directly at Debian 10 (Buster), the last release with a real `snort` package:

```sh
echo "deb http://archive.debian.org/debian buster main contrib non-free" >> /etc/apt/sources.list
echo "deb http://archive.debian.org/debian-security buster/updates main contrib non-free" >> /etc/apt/sources.list
apt-get -o Acquire::Check-Valid-Until=false update
apt install snort
```

Confirmed working on Grml, with one caveat: appending Buster directly to the main `sources.list` means *any* future `apt install`/`apt upgrade` on the gateway could pull in a Buster version of some other package by accident, which could break something a teammate is relying on. If there's time, pin it instead with a dedicated low-priority file rather than touching `sources.list` directly:

```sh
echo "deb http://archive.debian.org/debian buster main contrib non-free" > /etc/apt/sources.list.d/buster.list
echo "deb http://archive.debian.org/debian-security buster/updates main contrib non-free" >> /etc/apt/sources.list.d/buster.list
printf 'Package: *\nPin: release n=buster\nPin-Priority: 100\n' > /etc/apt/preferences.d/buster.pref
apt-get -o Acquire::Check-Valid-Until=false update
apt install -t buster snort
```

Either way — Snort itself is old, unmaintained upstream software. We don't have time to switch to something else, so once it's installed and validated, avoid running general `apt upgrade` on the gateway for the rest of the lab.

During install, debconf asks for:
- **Interface(s) to listen on**: \<lan\>
- **HOME_NET**: `192.168.0.0/24`

The interface must already be up with its IP assigned at this point, or debconf rejects it as "Invalid interface" — so do the gateway's network config first. To redo these prompts later without reinstalling: `dpkg-reconfigure snort`.

Promiscuous mode is not needed — leave it disabled. The gateway isn't tapping a mirrored port, it *is* the router, so LAN↔WAN traffic already passes through its LAN interface.

## Configuration

Copy *snort.conf.patch* values into `/etc/snort/snort.conf` (or just confirm the installer set them correctly):

```sh
grep -E "HOME_NET|EXTERNAL_NET" /etc/snort/snort.conf
```

Copy *local.rules* to `/etc/snort/rules/local.rules`, and confirm it's included in `snort.conf`:

```sh
grep local.rules /etc/snort/snort.conf
```

Three rules are included, each tied to something we trigger live during the demo:

| sid | Detects | Trigger |
| --- | --- | --- |
| 1000001 | ICMP to a LAN host | `ping <gateway-ip>` |
| 1000002 | Port scan (SYN threshold) | `nmap -p 1-100 <gateway-ip>` |
| 1000003 | Connection attempt on port 23 | `nc -zv <gateway-ip> 23` |

sids are kept ≥ 1000000, Snort's reserved range for local rules, to avoid collisions with the stock ruleset. Snort's own bundled rules stay active too (e.g. `sid:384`, ICMP PING) — seeing both fire on the same traffic is expected.

## Validating

```sh
snort -T -c /etc/snort/snort.conf
```

Should end with `Snort successfully validated the configuration!`. If you get `Invalid configuration line` pointing at the end of a rule, check for Windows line endings in `local.rules` (`dos2unix /etc/snort/rules/local.rules` fixes it).

## Starting

This install path doesn't ship a systemd service (confirmed on Grml), so run it directly, in the foreground, for the demo:
```sh
snort -A console -q -i <lan> -c /etc/snort/snort.conf
```

Leave this running in its own terminal/console for the duration of the demo. If you want it logging to a file instead of console:
```sh
snort -D -i <lan> -c /etc/snort/snort.conf -l /var/log/snort
```
Alert log: `/var/log/snort/alert`.

## Demo

From a workstation, in order:

```sh
ping -c 4 <gateway-ip>
nmap -p 1-100 <gateway-ip>
nc -zv <gateway-ip> 23
```

Each should alert on the gateway within a second or two. The telnet test shows "Connection refused" on the workstation — expected, nothing listens on port 23. Snort alerts on the SYN itself, not on a successful connection.
