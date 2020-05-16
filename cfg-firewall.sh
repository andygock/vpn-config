#!/bin/sh

# enp0s3 = normal bridged network interface
# tun0 = openvpn virtual interface

echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -F
iptables -X
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -i enp0s3 -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i tun0 -j ACCEPT

# Forwarding
iptables -A FORWARD -o tun0 -i enp0s3 -s 192.168.0.0/24 -m conntrack --ctstate NEW -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A POSTROUTING -o tun0 -t nat -j MASQUERADE

# Allow pings
iptables -A INPUT -p icmp --icmp-type 8 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -p icmp --icmp-type 0 -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow all output
#iptables -A OUTPUT -o tun0 -j ACCEPT
#iptables -A OUTPUT -o enp0s3 -j ACCEPT
iptables -A OUTPUT -j ACCEPT

# Default rules
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

