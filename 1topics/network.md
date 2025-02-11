# Interesting Network Hardware

[JetKVM](https://jetkvm.com/docs/getting-started/quick-start)

[PiKVM - Open and inexpensive IP-KVM on Raspberry Pi](https://pikvm.org/)

NanoKVM

* [NanoKVM](https://github.com/sipeed/NanoKVM)
* [NanoKVM doc](https://wiki.sipeed.com/hardware/en/kvm/NanoKVM/introduction.html)

## Universal USB

[Medicat](https://github.com/mon5termatt/medicat_installer)

## Network

Acanac modem: 192.168.11.1, DHCP 21-49, 24h, admin Q123.

[ER605 router](https://www.tp-link.com/ca/search/?q=ER605&t=product&category=support), 192.168.2.1, DHCP 232-254, vlad Q4..

* [How to set up Access Control of TP-Link Omada Router in Standalone and Controller](https://www.tp-link.com/ca/support/faq/4025/)
* [How to create multi networks and manage network behavior with ACL on Omada Gateway in standalone mode](https://www.tp-link.com/ca/support/faq/3061/)
* [The difference between Standalone mode and Controller mode of Business router](https://www.tp-link.com/ca/support/faq/3357/)
* [How to connect to Omada Router using IKEv2 VPN of Android/iOS](https://www.tp-link.com/ca/support/faq/3447/)
* [How to configure WireGuard VPN on Omada Router in Standalone mode?](https://www.tp-link.com/ca/support/faq/3559/)
* [How to Configure TP-Link Omada Gateway as OpenVPN Server on Standalone Mode](https://www.tp-link.com/ca/support/faq/3632/)

Firewall Rules:

* ALL
  * allow DNS
  * Allow SSH from 'admins' PCs
* WIFI: 192.168.13.1, DHCP 51-254, only Internet
  * allow SMB on LAN2
  * block All on LAN, LAN2, K3s
* K3s: 192.168.100.1, DHCP 232-254
  * switch YuLinca 8x2.5G
* LAN is default network, 192.168.0.1, DHCP 100-199
* LAN2: 192.168.2.1, DHCP 232-254
  * ??? [Managed switch TL-SG108E(8x1G)](https://www.tp-link.com/ca/search/?q=TL-SG108E&t=product&category=support), 192.168.2.3, admin Q4




`Test-NetConnection -Port 22 -RemoteAddress "192.168.100.51"`

* [802.1Q VLAN](https://www.tp-link.com/ca/support/faq/788/)

Port 1: VLAN 1.
Port 2: VLAN 1.
Port 3: VLAN 1.
Port 4: VLAN 1.
Port 5: VLAN 1.
Port 6: VLAN 1.
Port 7: VLAN 1.
Port 8: VLAN 1.


* [How to create multi networks and manage network behavior with ACL on Omada Gateway in standalone mode](https://www.tp-link.com/ca/support/faq/3061/)
* [How to set up Access Control of TP-Link Omada Router in Standalone and Controller](https://www.tp-link.com/ca/support/faq/4025/)


https://canyouseeme.org/
https://datacentersupport.lenovo.com/us/en/products/servers/thinkserver/ts140/downloads/driver-list/

### Acanac router

192.168.11.1 Acanac router
192.168.11.2 ER605 router, WAN port

### WIFI network 192.168.13.0

Switch to:

* wired network for basement
* TV on main floor
* WiFi on main floor
* backup server, 192.168.13.222

### LAN2 network switch (24 1G ports)

	192.168.2.1 gateway, ER605 router vlad Q4..
	192.168.2.2 ???
	192.168.2.3 TL-SG106E, admin Q4
	metallb in microk8s -- external load balancer
	192.168.2.11 - 192.168.2.19
	dhcp
	192.168.2.21 - 192.168.2.49

	#192.168.2.71 ch1
	#192.168.2.72 ch2
	#192.168.2.73 dev
	192.168.2.75 updated BIOS TS140, u1
	192.168.2.76 updated BIOS TS140,
	192.168.2.77 updated BIOS TD340
	192.168.2.78 updated BIOS TD340, Windows 10 2004, desktop-dev
	192.168.2.79 updated 2021 BIOS TS140, Windows 10, desktop-dad3
	192.168.100.79 updated 2021 BIOS TS140, Windows 10, desktop-dad3
	192.168.2.81 on ch1
	192.168.2.82 on ch2
	192.168.2.83 on dev
	192.168.2.86 VY8RJ-N29HQ-HJMY2-3VD7H-M4JWF pg12-win2019 PostgreSql DNS: pg12-win2019-2
	192.168.2.91 3dot-IIS
	192.168.2.92 3dot-lp viktor-win10 Windows 10 Professional VG39N-VPHRB-QPQ2B-T3342-YKMP6
	192.168.2.93 viktor-win10 Windows 10 Professional CFD9J-FRNCY-K688F-QK6VP-CKCKG
	192.168.2.94 viktor, 3dot-lp-past
	192.168.2.? viktor-win10 Windows 10 Professional 9NQH7-WTCHD-PFDWQ-T2TK6-V6DGT
	192.168.2.112 win10dev DR8YN-F747D-Y866G-QR8C8-7FR9M
	192.168.2.115 dad-pc, win 8

	192.168.2.121 3d0t-PC Viktor

	192.168.2.200 win2022, updated BIOS TS140
	192.168.2.221 synology downloader, admin Q1.., vladadmin Q1..
	192.168.2.222 synology backup, witness for office cluster
	192.168.100.222 synology backup, witness for office cluster
	192.168.13.222 synology backup, witness for office cluster
	192.168.2.225 synology office1 192.168.2.227, Q1.., vlQ1
	192.168.2.226 synology office2 192.168.2.227
	192.168.2.227 synology office, vladadmin Q1..

	192.168.2.228 k8s-dev VM on synology office, 

	192.168.108.231 Rancher, virtual on dev(.73)
	192.168.108.232 k3s-dev, virtual on synology office, root Q4..
	192.168.108.233 k3s-dev1, Ubuntu on TS140 vlad Q4..
	192.168.108.234 k3s-dev2, Ubuntu on TS140

    192.168.108.241 - 250 load balancer pool

Virtual on synology backup


	192.168.2.70 ch cluster virtual
	192.168.2.227 office cluster, virtual, witness for ch cluster, iSCSI failover for ch
	192.168.2.36 by DHCP, alpine gateway from 108 to 2, anat108to2
   	192.168.2.91 virtual ViktorIIS, 2019



???
	192.168.2.251?(36 by DHCP) alpine gateway ???, ana108to2
	192.168.2.7
	192.168.2.90
	192.168.2.99
	192.168.2.110
	192.168.2.111
	192.168.2.169
	192.168.2.176

### 100 K3s

	192.168.2.50 ODROID-H4, openSuse, Zabbix, 
	192.168.100.48 rancher-docker, VM on win2022(192.168.2.200)
	192.168.100.49 rancher, VM on win2022(192.168.2.200)
	192.168.100.51, k3s1, ODROID-H4 PLUS, openSuse
	192.168.100.52, k3s2, ODROID-H4 PLUS, openSuse
	192.168.100.53, k3s3, TS140, openSuse

	192.168.100.60 win2022
	192.168.2.61 k3sv1, VM on win2022(192.168.2.200)



### 109 switch 8 1G ports
	192.168.109.73 dev
	*192.168.109.75 mk8s1
	*192.168.109.76 mk8s2
	192.168.109.225 office1 synology
	192.168.109.226 office2 synology
	*192.168.109.222 backup synology
	
	virt
	192.168.109.227 office, iSCSI failover for kubernetes

### 108 switch 8 1G ports
	to switch 8 10G ports
	192.168.108.77 k-clr-work3
	192.168.108.78 desktop-dev
	192.168.108.79 desktop-dad3
	192.168.108.222 backup synology
		192.168.108.225 office1 synology
		192.168.108.226 office2 synology
	
### 108 switch 8 10G ports
	to switch 8 1G ports
	192.168.108.71 ch1
	192.168.108.72 ch2	
	192.168.108.73 dev
	192.168.108.75 mk8s1
	192.168.108.76 mk8s2
	192.168.108.225 office1 synology
	192.168.108.226 office2 synology
	
	virt

	192.168.108.1 alpine gateway, anat108to2

	192.168.108.227 office synology, iSCSI main
	//192.168.108.51 mck8s1 on ch1
	//192.168.108.52 mck8s2 on ch2
	192.168.108.53 mck8s3-virt on ch
	192.168.108.55 debsos1 on ch1
	192.168.108.56 debsos2 on ch2
	192.168.108.57 debsos3 on ch
	192.168.108.112 win10dev
	192.168.108.81 VY8RJ-N29HQ-HJMY2-3VD7H-M4JWF sql-2019 MS SQL 2019
	*192.168.108.82 VY8RJ-N29HQ-HJMY2-3VD7H-M4JWF sql-2019-core
	*192.168.108.84 VY8RJ-N29HQ-HJMY2-3VD7H-M4JWF pg12-win2019-core
	192.168.108.85 VY8RJ-N29HQ-HJMY2-3VD7H-M4JWF md-win2019 MariaDb
	192.168.108.86 VY8RJ-N29HQ-HJMY2-3VD7H-M4JWF pg12-win2019 PostgreSql
	192.168.108.87 VY8RJ-N29HQ-HJMY2-3VD7H-M4JWF db2-win2019 DB2
	192.168.108.89 VY8RJ-N29HQ-HJMY2-3VD7H-M4JWF oracle19-win2019 Oracle

### 107 direct 10G connection ch1, ch2
	192.168.107.71 ch1
	192.168.107.72 ch2	

### 107 direct 1G connection office1, office2
	192.168.107.225 office1
	192.168.107.226 office2	
