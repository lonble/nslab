# Web Server

We chose **Caddy** as our web server because of its clean configuration file, sensible defaults, and fully open-source nature. Most importantly, it supports **automatic HTTPS**, which significantly reduces the burden of TLS state management and server configuration, giving it the advantage of being "**secure by default**".

## Installation

```sh
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
