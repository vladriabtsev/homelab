## Alpine linux
setup-alpine
apk update
apk upgrade
reboot
### SSH
https://wiki.alpinelinux.org/wiki/Setting_up_a_ssh-server
apk add openssh
rc-update add sshd
rc-status
/etc/init.d/sshd start
### Router
#### Routing
https://github.com/bobfraser1/alpine-router
https://medium.com/@privb0x23/airfield-altitude-building-a-network-gateway-with-alpine-linux-454a56457d53
https://wiki.alpinelinux.org/wiki/Linux_Router_with_VPN_on_a_Raspberry_Pi

apk add iptables
rc-update add iptables

echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf

eth0 should be assigned to the external or public network
eth1 should be assigned to the internal or private network

iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i eth1 -j ACCEPT
service iptables save

rc-update add sysctl
#### DHCP
apk add dhcp
/etc/dhcp/dhcpd.conf
```
$ vi /etc/dhcp/dhcpd.conf
subnet 192.168.108.0 netmask 255.255.255.0 {
  #option domain-name "hiroom2.com";
  option domain-name-servers 192.168.108.81, 192.168.108.81;
  option routers 192.168.108.1;
  range 192.168.108.11 192.168.108.50;
}
```
rc-update add dhcpd
rc-service dhcpd start
rc-status
Test
```
$ ip a s
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast
state UP qlen 1000
    link/ether 52:54:00:c0:07:60 brd ff:ff:ff:ff:ff:ff
    inet 192.168.11.250/24 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::5054:ff:fec0:760/64 scope link
       valid_lft forever preferred_lft forever
```
DNS servers are provided.
```
$ cat /etc/resolv.conf
search hiroom2.com
nameserver 192.168.11.2
nameserver 192.168.11.1
```
