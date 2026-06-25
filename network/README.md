# Network

This document describes how to configure the **gateway** network, including setting the IP addresses and subnet masks for the WAN and LAN interfaces, configuring the default route, setting the DNS addresses, and configuring NAT, port forwarding, as well as the firewall.

In all configuration files and commands, replace *\<wan\>* with the WAN interface and *\<lan\>* with the LAN interface.

## IP Configuration

This section describes how to configure the IP addresses, subnet masks, default route, and DNS addresses.

Grml uses **udev** in conjunction with **ifupdown** to manage network interfaces, so we cannot configure the interfaces directly using the **ip** command; otherwise, our configuration will be overwritten by ifupdown when the interface state changes. Instead, we configure them by editing the ifupdown configuration file to ensure a stable configuration.

Before starting any configuration, uninstall **resolvconf** using the command below. It interferes with our DNS configuration and will torment us during the **dnsmasq** setup.

```sh
apt remove resolvconf
```

After getting rid of that trouble, use the command below to bring the interfaces down.

```sh
ifdown <wan> <lan>
```

This will not only bring the interface down but also terminate the dhcpcd service running on it.

Next, edit the ifupdown configuration file. Open `/etc/network/interfaces`, find the following line:

```
iface <wan> inet dhcp
```

Replace it as follows:

```
iface <wan> inet static
address 141.76.46.220/24
gateway 141.76.46.254
```

Also find the following line:

```
iface <lan> inet dhcp
```

Replace it as follows:

```
iface <lan> inet static
address 192.168.0.1/24
```

After saving the changes, use the command below to bring the interfaces back up.

```sh
ifup <wan> <lan>
```

Finally, set the DNS addresses. Replace the contents of `/etc/resolv.conf` with the following:

```
nameserver 141.30.1.1
nameserver 1.1.1.1
```

## Packet Filter Configuration

This section introduces NAT, port forwarding, and the firewall.

We prefer **nftables** over **iptables** due to its more elegant and structured configuration file format.

Unfortunately, nftables is not pre-installed on Grml. Use the command below to install it.

```sh
apt update
apt install nftables
```

Next, copy *nftables.conf* to `/etc/nftables.conf`, and copy *dhcp.nft*, *dns.nft*, and *web_server.nft* to the `/etc/nftables.d/` directory.

Finally, use the command below to apply these rules.

```sh
nft -f /etc/nftables.conf
```

With these rules, we apply NAT to allow LAN devices to access the WAN, and configure port forwarding for the web server so that it can be accessed from the WAN. We also implement a strict firewall that only permits traffic from the LAN to the WAN, but not vice versa. Furthermore, the gateway itself rejects all incoming traffic, with the exception of ICMP, as well as DNS and DHCP requests from the LAN side.

## Kernel Configuration

As a gateway, we also need to modify some kernel parameters. Copy *sysctl.conf* to `/etc/sysctl.conf`, and then run the command below to apply these configurations.

```sh
sysctl -p
```

With these configurations, we enable kernel IP forwarding to achieve routing functionality. For security reasons, we also enable reverse path filtering, disable source routing and ICMP redirects, and enable TCP SYN Cookies to mitigate SYN Flood attacks.
