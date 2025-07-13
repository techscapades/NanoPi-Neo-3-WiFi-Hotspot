#!/bin/bash

set -e

echo "Detecting wireless interface..."

# Detect the first active wireless interface
WIFI_IFACE=$(iw dev | awk '$1=="Interface"{print $2}' | head -n1)

if [ -z "$WIFI_IFACE" ]; then
    echo "No wireless interface found. Please plug in your USB Wi-Fi dongle."
    bash ~/wifi_AP/undo_setup_AP.sh
    exit 1
else
    echo "Found wireless interface: $WIFI_IFACE"
fi

# Basic config values
SSID="NanoPiNeo3AP"
PASSPHRASE="helloworld!"
WIFI_IP="192.168.9.1"
DHCP_RANGE_START="192.168.9.10" # increase the IP range manually
DHCP_RANGE_END="192.168.9.100"   # increase the IP range manually
NETMASK="255.255.255.0"
UPLINK_IFACE="end0"

# echo "Installing required packages..."
# apt update
# apt install -y hostapd dnsmasq iptables net-tools iptables-persistent

echo "Stopping existing services..."
systemctl stop hostapd || true
systemctl stop dnsmasq || true
systemctl disable hostapd || true
systemctl disable dnsmasq || true

echo "Cleaning previous configs..."
mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig 2>/dev/null || true

echo "Creating hostapd config..."
cat <<EOF > /etc/hostapd/hostapd.conf
interface=$WIFI_IFACE
driver=nl80211
ssid=$SSID
hw_mode=g
channel=6
auth_algs=1
wmm_enabled=0
wpa=2
wpa_passphrase=$PASSPHRASE
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
EOF

echo "Pointing hostapd to config file..."
sed -i '/^DAEMON_CONF/d' /etc/default/hostapd
echo "DAEMON_CONF=\"/etc/hostapd/hostapd.conf\"" >> /etc/default/hostapd

echo "Creating dnsmasq config..."
cat <<EOF > /etc/dnsmasq.conf
interface=$WIFI_IFACE
dhcp-range=$DHCP_RANGE_START,$DHCP_RANGE_END,12h
domain-needed
bogus-priv
EOF

echo "Creating static IP config for $WIFI_IFACE..."
mkdir -p /etc/systemd/network
cat <<EOF > /etc/systemd/network/10-$WIFI_IFACE.network
[Match]
Name=$WIFI_IFACE

[Network]
Address=$WIFI_IP/24
DHCP=no
EOF

echo "Enabling systemd-networkd..."
systemctl enable systemd-networkd
systemctl restart systemd-networkd

echo "Enabling IP forwarding and setting up NAT..."
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

iptables -t nat -A POSTROUTING -o $UPLINK_IFACE -j MASQUERADE
netfilter-persistent save

echo "Fixing DNS conflicts (disabling systemd-resolved)..."
systemctl disable systemd-resolved || true
systemctl stop systemd-resolved || true
rm -f /etc/resolv.conf
echo "nameserver 1.1.1.1" > /etc/resolv.conf

echo "Enabling and starting services..."
systemctl enable dnsmasq
systemctl unmask hostapd
systemctl enable hostapd
systemctl start dnsmasq
systemctl start hostapd

echo "Wi-Fi Access Point is up and running!"
echo "SSID: $SSID"
echo "Password: $PASSPHRASE"
echo "Interface: $WIFI_IFACE"
echo "Static IP: $WIFI_IP"

