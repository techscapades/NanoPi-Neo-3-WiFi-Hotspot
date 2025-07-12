#!/bin/bash

set -e

echo "🧹 Reverting Wi-Fi Access Point setup..."

# Detect wireless interface
WIFI_IFACE=$(iw dev | awk '$1=="Interface"{print $2}' | head -n1)

if [ -z "$WIFI_IFACE" ]; then
    echo "❌ No wireless interface found."
    exit 1
else
    echo "✅ Found wireless interface: $WIFI_IFACE"
fi

echo "🛑 Stopping services..."
systemctl stop hostapd || true
systemctl stop dnsmasq || true
systemctl disable hostapd || true
systemctl disable dnsmasq || true

echo "📦 Restoring dnsmasq config (if backup exists)..."
if [ -f /etc/dnsmasq.conf.orig ]; then
    mv /etc/dnsmasq.conf.orig /etc/dnsmasq.conf
else
    rm -f /etc/dnsmasq.conf
fi

echo "🧽 Removing hostapd config..."
rm -f /etc/hostapd/hostapd.conf
sed -i '/^DAEMON_CONF/d' /etc/default/hostapd

echo "📁 Removing static systemd-networkd config..."
rm -f /etc/systemd/network/10-$WIFI_IFACE.network

echo "📡 Restarting systemd-networkd..."
systemctl restart systemd-networkd

echo "🌐 Re-enabling DHCP client on $WIFI_IFACE..."
ip link set $WIFI_IFACE down
ip addr flush dev $WIFI_IFACE
ip link set $WIFI_IFACE up
dhclient $WIFI_IFACE || echo "⚠️ DHCP client may be managed by NetworkManager or netplan."

echo "🔁 Re-enabling systemd-resolved..."
systemctl enable systemd-resolved
systemctl start systemd-resolved
rm -f /etc/resolv.conf
ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf

echo "🔥 Flushing iptables NAT rules..."
iptables -t nat -D POSTROUTING -o end0 -j MASQUERADE || true
iptables -F
iptables -X
netfilter-persistent save

echo "🚫 Disabling IP forwarding..."
sed -i '/net.ipv4.ip_forward=1/d' /etc/sysctl.conf
sysctl -w net.ipv4.ip_forward=0

echo "✅ Cleanup complete."


