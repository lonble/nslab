# DNS & DHCP

We chose **dnsmasq** as our DNS server. It is much more lightweight and simpler than **BIND**, and is sufficient for use as a recursive DNS server. Additionally, it can act as a **DHCP** server, which helps simplify our network configuration

## Network Configuration

No configuration is required. Just make sure it is deployed on the gateway and identify which network interface is for the LAN.

## Installation

Grml has dnsmasq installed by default.

The only thing we need to make sure of is that **resolvconf** has been uninstalled.

## Configuration

Just copy the *dnsmasq.conf* from the repo to `/etc/dnsmasq.conf`. Every configuration option is commented to explain its purpose.

## Starting

Start the dnsmasq service using **systemctl**.

```sh
systemctl start dnsmasq.service
```
