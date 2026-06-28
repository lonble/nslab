# Transparent Web Proxy

We use **squid** as our transparent web proxy. Squid will run on the same computer as the router.

## Network Configuration

To be transparent we have to redirect web traffic to squid without knowledge of the clients. This is done via *network/squid.nft*.

In *network/squid.nft*, we use DNAT to redirect all outbound HTTP/HTTPS traffic from the LAN to Squid's interception port. In *network/nftables.conf*, we allow the gateway to accept the redirected traffic.

Since Squid cannot handle **HTTP/3**, we also block HTTP/3 traffic through the firewall. This forces web clients to quickly fall back to traditional HTTP.

## Installation

The default Debian `squid` package uses **GnuTLS** as its TLS library, which does not support `ssl-bump`. We need to install the `squid-openssl` package instead.

```sh
apt update
apt install squid-openssl
```

## Configuration

Because HTTPS is encrypted Squid doesnt decode the HTTPS traffic, but can filter for the SNI.

Even though our only goal is to inspect the SNI, Squid must be configured with a CA certificate to listen on HTTPS ports. We can generate this dummy certificate, which will never be used, using the script *ca_pem_maker.sh*. Then copy the certificate to `/etc/squid` directory.

The squid configuration file is *squid.conf*. Copy it to `/etc/squid/squid.conf`.

```sh
ca_pem_maker.sh
copy ca.pem /etc/squid
copy squid.conf /etc/squid/squid.conf
```

## Starting

We can start the squid service using **systemctl**.

```sh
systemctl start squid.service
```
