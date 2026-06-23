# Web Server

We chose **Caddy** as our web server because of its clean configuration file, sensible defaults, and fully open-source nature. Most importantly, it supports **automatic HTTPS**, which significantly reduces the burden of TLS state management and server configuration, giving it the advantage of being "**secure by default**".

## Installation

Because Grml uses a snapshot of Debian Testing as its source, and Caddy happened to be removed from Testing on the day that snapshot was taken, we cannot install Caddy directly via the apt command. Instead, we can add the first-party source first, and then install it using apt.

```sh
curl -sL 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -sL 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' -o /etc/apt/sources.list.d/caddy-stable.list
apt update
apt install caddy
```

## Configuration

Caddy supports both JSON and Caddyfile as configuration formats. We chose Caddyfile because it is simpler and more human-friendly.

Just copy the *Caddyfile* from the repo to `/etc/caddy/Caddyfile`, and copy *index.html* to the `/srv/http` directory. And, don't forget our magical video!

This will set up a static file server and serve our webpage. Also, it will automatically obtain a TLS certificate, enable HTTPS, and redirect all HTTP requests to HTTPS.

## Starting

On Debian-based systems, we can start the Caddy service using **systemctl**.

```sh
systemctl start caddy.service
```
