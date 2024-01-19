#!/bin/bash
#switch to root
sudo su

# configure IPTables to route all traffic through TOR, enabling NAT
iptables -F
iptables -t nat -F
iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
iptables -A FORWARD -i wlan0 -o usb0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i usb0 -o wlan0 -j ACCEPT
iptables -A INPUT -i wlan0 -p tcp --dport 5900 -j DROP
iptables -A INPUT -i wlan0 -p tcp --dport 22 -j DROP
iptables -t nat -A PREROUTING -i usb0 -p tcp --dport 5900 -j REDIRECT --to-ports 5900
iptables -t nat -A PREROUTING -i usb0 -p tcp --dport 22 -j REDIRECT --to-ports 22
iptables -t nat -A PREROUTING -i usb0 -p tcp --dport 53 -j REDIRECT --to-ports 53
iptables -t nat -A PREROUTING -i usb0 -p tcp --syn -j REDIRECT --to-ports 9040
sh -c "iptables-save > /etc/iptables/rules.v4"
sh -c "iptables-save > /etc/iptables.ipv4.nat"
echo "net.ipv4.ip_forward=1" > /etc/sysctl.conf
sudo reboot