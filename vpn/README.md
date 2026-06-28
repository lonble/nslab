# WireGuard Description

## Wireguard Config Description
Router Side (The Server)
- Identity: The router acts as the VPN gateway with the internal tunnel IP 192.168.1.1.
- Listening: It listens for incoming encrypted connections on UDP port 51820.
- Peer (Client) Definition: It specifically allows a peer (the client) with a matching Public Key. It only accepts traffic from that client if the client uses the internal IP 192.168.1.2.
- Security: A PresharedKey is used as an additional layer of symmetric encryption for the tunnel.

Client Side
- Identity: The client is assigned the internal tunnel IP 192.168.1.2.
- DNS: The client is instructed to use the router (192.168.1.1) as its DNS server, preventing DNS leaks.
- Peer (Router) Connection:
    - It connects to the router’s public IP address: 141.76.46.220:51820.
    - AllowedIPs = 0.0.0.0/0: This is the Full Tunnel setting. It tells the client to send all internet traffic through the VPN.
    - PersistentKeepalive: Sends a packet every 25 seconds to keep the connection alive through NAT firewalls.

## Firewall Rules Description

The firewall rules on the router ensure that the VPN traffic can actually go somewhere once it reaches the router.

- Input Chain: Opens UDP port 51820. Without this, the router would block the client's attempt to connect to the VPN.
- Forward Chain: Specifically allows traffic coming from the WireGuard interface (wg0). This allows the client's data to pass through the router to reach the outside internet.
- NAT (Source NAT): It takes any traffic coming from the VPN subnet (192.168.1.0/24) and translates its source address to the router’s public WAN IP. This allows the client to browse the web using the router's internet connection.
