#!/bin/bash
# First become root
sudo su

# update OS and install compenents
apt update -y && apt-get dist-upgrade -y
apt install tor vim dnsmasq iptables-persistent macchanger monit -y

# disable IPv6
echo "net.ipv6.conf.all.disable_ipv6=1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6=1" >> /etc/sysctl.conf
echo "net.ipv6.conf.lo.disable_ipv6=1" >> /etc/sysctl.conf
echo "net.ipv6.conf.eth0.disable_ipv6=1" >> /etc/sysctl.conf
echo "net.ipv6.conf.wlan0.disable_ipv6=1" >> /etc/sysctl.conf

# configure DHCP for the USB0 connection
echo "interface usb0" >> /etc/dhcpcd.conf
echo "static ip_address=192.168.1.1/24" >> /etc/dhcpcd.conf
echo "static domain_name_servers=208.67.222.222 208.67.220.220" >> /etc/dhcpcd.conf

# configure DNSMasq for the USB0 connection
echo "interface=usb0" >> /etc/dnsmasq.conf
echo "dhcp-range=192.168.1.1,192.168.1.30,255.255.255.0,24h" >> /etc/dnsmasq.conf

# configuring TOR
echo "VirtualAddrNetwork 10.192.0.0/10" >> /etc/tor/torrc
echo "AutomapHostsSuffixes .onion,.exit" >> /etc/tor/torrc
echo "AutomapHostsOnResolve 1" >> /etc/tor/torrc
echo "Transport 192.168.1.1:9040" >> /etc/tor/torrc
echo "DNSPort 192.168.1.1:53" >> /etc/tor/torrc
echo "RunAsDaemon 1" >> /etc/tor/torrc
echo "CircuitBuildTimeout 10" >> /etc/tor/torrc
echo "LearnCircuitBuildTimeout 0" >> /etc/tor/torrc
echo "MaxCircuitDirtiness 10" >> /etc/tor/torrc
sudo sed -i "s/NoNewPrivileges=yes/NoNewPrivileges=no/g" /lib/systemd/system/tor@default.service
sudo sed -i "s/NoNewPrivileges=yes/NoNewPrivileges=no/g" /lib/systemd/system/tor@.service

# adding tor to start automatically on Boot
update-rc.d tor enable
systemctl start tor.service
systemctl enable tor.service

# configuring monit to start Tor if it doesnt start on boot
echo "check process gdm with pidfile /var/run/tor/tor.pid" >> /etc/monit/monitrc
echo " start program = \"/etc/init.d/tor start\"" >> /etc/monit/monitrc
echo " stop program = \"/etc/init.d/tor stop\"" >> /etc/monit/monitrc
systemctl restart monit
systemctl enable monit

# creating a scri[p]t to randomize MAC addresses for wlan0 and USB0 on startup
echo '#!/bin/bash' > /etc/init.d/machangerstartup
echo "ifconfig wlan0 down" >> /etc/init.d/macchangerstartup
echo "ifconfig usb0 down" >> /etc/init.d/macchangerstartup
echo "macchanger -r wlan0" >> /etc/init.d/macchangerstartup
echo "macchanger -r usb0" >> /etc/init.d/macchangerstartup
echo "ifconfig wlan0 up" >> /etc/init.d/macchangerstartup
echo "ifconfig usb0 up" >> /etc/init.d/macchangerstartup
chmod +x /etc/init.d/macchangerstartup

# configure or create /etc/rc.local to run macchangerstartup script on boot
echo '#!/bin/sh -e' > /etc/rc.local
echo "/etc/init.d/macchangerstartup" >> /etc/rc.local
echo "service procps reload" >> /etc/rc.local
echo "exit 0" >> /etc/rc.local
chmod 755 /etc/rc.local

# configure /var/log as tmpfs kill logs after reboot
rm -R /var/log/*
echo "tmpfs /var/log tmpfs nodev,nosuid,size=40m 0 0" >> /etc/fstab
mount -a