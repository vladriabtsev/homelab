<!-- markdownlint-disable MD004 -->

# Home network

<!-- Markdown All in One -->
- [Home network](#home-network)
  - [TODO](#todo)
    - [Network monitor](#network-monitor)
    - [Load Balancer](#load-balancer)
    - [Pi-hole](#pi-hole)
    - [bash](#bash)
      - [Dashboard](#dashboard)
        - [Beszel](#beszel)
        - [Other](#other)
      - [Kubernetes](#kubernetes)
    - [Remote access](#remote-access)
  - [My PC](#my-pc)
    - [WSL utils](#wsl-utils)
    - [WSL](#wsl)
      - [Bash](#bash-1)
        - [Bashmatic](#bashmatic)
      - [GO](#go)
    - [Visual Studio Code](#visual-studio-code)
      - [Kubernetes](#kubernetes-1)
      - [Harvester](#harvester)
  - [Monitoring](#monitoring)
  - [ISP](#isp)
  - [Network Firewall](#network-firewall)
    - [Freebsd Docker and VirtualBox NIY](#freebsd-docker-and-virtualbox-niy)
    - [Netboot XYZ on Docker NIY](#netboot-xyz-on-docker-niy)
    - [Pi-hole or AdGuard NIY](#pi-hole-or-adguard-niy)
- [Kubernetes environment](#kubernetes-environment)
  - [Storage](#storage)
  - [Docker](#docker)
  - [Synology](#synology)
    - [LDAP](#ldap)
  - [BACKUP](#backup)
    - [DNS](#dns)
      - [192.168.2.227 as DNS server for registrator](#1921682227-as-dns-server-for-registrator)
    - [MAIL](#mail)
    - [How to use Docker on a Synology NAS](#how-to-use-docker-on-a-synology-nas)
    - [Gitea](#gitea)
  - [ETCD node hardware](#etcd-node-hardware)
  - [Worker node hardware for DRBD](#worker-node-hardware-for-drbd)
  - [WSL2](#wsl2)
  - [Virtual](#virtual)
  - [Kubernetes](#kubernetes-2)
    - [Operators](#operators)
    - [External Load Balancer](#external-load-balancer)
      - [kube-vip](#kube-vip)
      - [Build Linux Alpine VM image](#build-linux-alpine-vm-image)
      - [Build FreeNginx](#build-freenginx)
    - [Helm](#helm)
    - [Rancher](#rancher)
      - [Rancher machine](#rancher-machine)
      - [Dev cluster](#dev-cluster)
        - [Setup kubectl and helm access](#setup-kubectl-and-helm-access)
        - [Applications](#applications)
          - [Traefik](#traefik)
          - [HA](#ha)
          - [Volumes](#volumes)
          - [Postgre](#postgre)
    - [Talos Linux](#talos-linux)
      - [Talos bootstrap](#talos-bootstrap)
    - [Dev Environment setup](#dev-environment-setup)
      - [VM on Synology](#vm-on-synology)
      - [K8plane](#k8plane)
        - [Boot image](#boot-image)
      - [K8worker](#k8worker)
        - [Boot image](#boot-image-1)
      - [Getting Started](#getting-started)
        - [Worker](#worker)
      - [Management](#management)
      - [Storage](#storage-1)
        - [NFS](#nfs)
        - [Longhorn](#longhorn)
        - [sql-server-linux-overview](#sql-server-linux-overview)
        - [iscsi-tools](#iscsi-tools)
        - [DRBD](#drbd)
      - [Secure, remote access](#secure-remote-access)
    - [Kubernetes how to](#kubernetes-how-to)
    - [Applications](#applications-1)
      - [gitea](#gitea-1)
      - [PostgreSQL](#postgresql)

## TODO

### Network monitor

* [Sniffnet](https://sniffnet.net/)
  * https://github.com/GyulyVGC/sniffnet
* [Wireshark lets you dive deep into your network traffic](https://www.wireshark.org/)

### Load Balancer

https://addozhang.medium.com/from-lb-ingress-to-ztm-a-new-approach-to-cluster-service-exposure-99d32a3065ec
https://github.com/flomesh-io/ztm
https://github.com/flomesh-io/fsm
https://kubernetes.io/docs/concepts/services-networking/gateway/

### Pi-hole

https://drfrankenstein.co.uk/pi-hole-in-container-manager-on-a-synology-nas/
https://mariushosting.com/how-to-install-pi-hole-on-your-synology-nas/
https://www.wundertech.net/how-to-setup-pi-hole-on-a-synology-nas-two-methods/
https://pimylifeup.com/pi-hole-synology-nas/
https://mischavandenburg.com/zet/i-set-up-pi-hole-on-my-synology-nas/

### bash

[Awesome Shel](https://github.com/alebcay/awesome-shell?tab=readme-ov-file#shells)
[Awesome Bash](https://github.com/awesome-lists/awesome-bash)

[DevOps Bash Tools](https://github.com/HariSekhon/DevOps-Bash-tools)
[devops-resources](https://github.com/bregman-arie/devops-resources)
[Git UI](https://github.com/extrawurst/gitui)
[Script-server is a Web UI for scripts](https://github.com/bugy/script-server)
[bash_menu_ui](https://github.com/dxj19831029/bash_menu_ui)
[BASHUI](https://github.com/vaniacer/bashui)

dialog: https://invisible-island.net/dialog/
More dialog screenshots: https://linuxgazette.net/101/sunil.html
whiptail: https://en.wikibooks.org/wiki/Bash_Shell_Scripting/Whiptail
zenity: https://wiki.gnome.org/action/show/Projects/Zenity
Xdialog: https://linux.die.net/man/1/xdialog

https://www.linux-magazine.com/Issues/2019/228/Let-s-Dialog
https://www.geeksforgeeks.org/creating-dialog-boxes-with-the-dialog-tool-in-linux/
https://linuxcommand.org/lc3_adv_dialog.php
https://www.geeksforgeeks.org/shell-scripting-dialog-boxes/

https://en.wikibooks.org/wiki/Bash_Shell_Scripting/Whiptail
https://github.com/JazerBarclay/whiptail-examples
https://manpages.ubuntu.com/manpages/oracular/en/man1/whiptail.1.html

#### Dashboard

##### Beszel

https://www.youtube.com/watch?v=O_9wT-5LoHM

https://github.com/henrygd/beszel

##### Other

https://www.virtualizationhowto.com/2024/12/docker-dashboard-new-tool-lets-you-see-containers-across-multiple-hosts/
https://www.youtube.com/watch?v=eJHDyRV-0lk
https://github.com/brandonleegit/docker-dashboard

#### Kubernetes

[kainstall = kubeadm install kubernetes](https://github.com/lework/kainstall)
[kube-ps1: Kubernetes prompt for bash and zsh](https://github.com/jonmosco/kube-ps1)
[kube-aliases](https://github.com/Dbz/kube-aliases)
[Kubetail](https://github.com/johanhaleby/kubetail)
[Kubernetes bash scheduler](https://github.com/rothgar/bashScheduler)
[Shell-operator is a tool for running event-driven scripts in a Kubernetes cluster](https://github.com/flant/shell-operator)
[Backup a Kubernetes cluster as a yaml manifest](https://github.com/WoozyMasta/kube-dump)

Show current exported kubernetes config

https://www.youtube.com/watch?v=2yplBzPCghA
https://github.com/dreamsofautonomy/homelab
https://github.com/DrewThomasson/ebook2audiobook

### Remote access

https://tailscale.com/tailscale-ssh?msclkid=0ad88343710811daa292e4ca55015387&utm_source=bing&utm_medium=cpc&utm_campaign=B-PMax-SSH-US&utm_term=tailscale.com&utm_content=B-PMax-SSH-US

https://www.youtube.com/watch?v=1lZ3FQSv-wI
https://www.twingate.com/docs/guides

## My PC

### WSL utils

[How do I install upstream versions of popular CLI apps?](https://askubuntu.com/questions/1446390/how-do-i-install-upstream-versions-of-popular-cli-apps-nano-htop-tmux-and-lna)

* [htop](https://htop.dev/)
* [nano](https://www.nano-editor.org/)
* [tmux](https://github.com/tmux/tmux/wiki)
* [Log File Navigator](https://lnav.org/)

[The Tools I Use](https://nickjanetakis.com/blog/the-tools-i-use)

* [neovim](https://neovim.io/)
* [Microsoft terminal](https://github.com/microsoft/terminal)
* [fzf](https://nickjanetakis.com/blog/fuzzy-search-your-bash-history-in-style-with-fzf)
* [Dexpot](https://www.dexpot.de/?lang=en)
  * [Dexpot for managing virtual work spaces](https://nickjanetakis.com/blog/see-how-virtual-desktops-let-you-get-more-done-in-less-time)
* [Ditto](https://ditto-cp.sourceforge.io/)
  * [Boosting Software Developer Productivity with a Clipboard Manager](https://nickjanetakis.com/blog/boosting-software-developer-productivity-with-a-clipboard-manager)
* Finances
  * GnuCash, Ledger or XYZ
  * https://github.com/nickjj/plutus

### WSL

* [Advanced settings configuration in WSL](https://learn.microsoft.com/en-us/windows/wsl/wsl-config)
* [Welcome to WSLg](https://github.com/microsoft/wslg?tab=readme-ov-file#installing-wslg)
* General additional Linux components for dev env in WSL distro
  * Copy .ssl from Ubuntu
    * `sudo chown -R owner:users directory`
    * `sudo chmod -R o-rwx directory` remove access for other users
    * `sudo chmod -R g-rwx directory` remove access for groups
    * `sudo chmod -R u+rwX directory` add read/write file and read/write/exec access for user only
* [openSUSE](https://en.opensuse.org/openSUSE:WSL)
  * [Install and Set Up kubectl on Linux](https://v1-32.docs.kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
    * `cat <<EOF | sudo tee /etc/zypp/repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.32/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.32/rpm/repodata/repomd.xml.key
EOF`
    * `sudo zypper update`
    * `sudo zypper install -y kubectl`
  * [Install k3d](https://k3d.io/stable/)
    * Specific release `wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | TAG=v5.0.0 bash`
    * Latest `wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash`
  * ??? [Backup and migrate Kubernetes resources and persistent volumes](https://velero.io/)
  * `sudo yast2`
    * password-store [pass](https://www.passwordstore.org/)
    * yq [yq](https://github.com/mikefarah/yq)
* Ubuntu
  * `sudo apt-get install`
    * pass

[DNS settings:](https://superuser.com/questions/1533291/how-do-i-change-the-dns-settings-for-wsl2)

1 Turn off generation of /etc/resolv.conf by adding in /etc/wsl.conf: edit `[network]`, `generateResolvConf = false`
2 Create file /etc/resolv.conf and add `nameserver 192.168.2.227` in it
3 Restart WSL. Exit all of your Linux prompts and run the following Powershell command. Restart the WSL2 Virtual Machine `wsl --shutdown`
4 Restart WSL. Start a new Linux prompt

[wsl-config](https://learn.microsoft.com/en-us/windows/wsl/wsl-config)

Windows explorer linux files: `\\wsl$`

#### Bash

[Bash Startup Files](https://www.gnu.org/savannah-checkouts/gnu/bash/manual/bash.html#Bash-Startup-Files)

##### Bashmatic

[Bashmatic® — BASH-based DSL helpers for humans, sysadmins, and fun](https://github.com/kigster/bashmatic)

* Loading Bashmatic at Startup
* Comment out banner show call. See last line in 'function __bashmatic.banner()', file `~/.bashmatic/init.sh`.

#### GO

Install new version:

* Remove previous version `sudo rm -rf /usr/local/go* && sudo rm -rf /usr/local/go`
* Get selected version `wget https://go.dev/dl/go1.23.4.linux-amd64.tar.gz`, `tar -xvf go1.23.4.linux-amd64.tar.gz`, `mv go go-1.23.4`, `sudo mv go-1.23.4 /usr/local`
* Edit `~/.bashrc`, add `export GOROOT=/usr/local/go-1.23.4`, `export GOPATH=$HOME/go`, `export PATH=$GOPATH/bin:$GOROOT/bin:$PATH`
* Restart command line and check `go version`

### Visual Studio Code

[Manage Docker & Kubernetes Remotely with VS Code!](https://www.youtube.com/watch?v=IA070wtt2iU)

[JimsGarage](https://github.com/JamesTurland/JimsGarage)

#### [Kubernetes](https://code.visualstudio.com/docs/azure/kubernetes)

[Latest Rancher Stack Versions](https://dzver.rfed.io/)

[Simple RKE2, Longhorn, NeuVector and Rancher Install - Updated for 2024](https://github.com/clemenko/rke_install_blog)

[RKE2: One-Click Deployment - Time To Switch From K3S!?](https://www.youtube.com/watch?v=RC7NeTh-cf8)

[NeuVector](https://github.com/neuvector/neuvector)

#### Harvester

[Harvester Workshop](https://github.com/clemenko/harvester_workshop)

## Monitoring

[Zabbix Installation & Pi-hole Monitoring: Step-by-Step Guide](https://www.youtube.com/watch?v=-340x3cjPvo)

[Best Server & Application Monitor for free with Checkmk](https://www.youtube.com/watch?v=KVRCpBI493Y), [Checkmk pricing](https://checkmk.com/pricing?currency=USD)

## ISP

[DDNS](https://www.synoforum.com/threads/best-solution-for-ddns-setup.8838/)

[How to Access a Synology NAS Remotely with DDNS](https://www.wundertech.net/how-to-access-a-synology-nas-remotely/) Certificate ???

[Secure Synology NAS with a custom domain, dynamic DNS and a free SSL certificate](https://medium.com/@ferarias/secure-synology-nas-with-a-custom-domain-dynamic-dns-and-a-free-certificate-e61fd8e607a8)

[Dynu DDNS on Synology](https://www.dynu.com/DynamicDNS/IPUpdateClient/SynologyNAS)

## Network Firewall

Hardware:
* [ODROID-H4 PLUS](https://www.hardkernel.com/shop/odroid-h4-plus/)
* [Net Card 2 for H-series](https://www.hardkernel.com/shop/h3-h2-net-card-2/)

Update BIOS from [ODROID-H4/bios](https://dn.odroid.com/ODROID-H4/bios/)
* [BIOS update instructions](https://wiki.odroid.com/odroid-h4/hardware/h4_bios_update)

pfSense:
* [pfSense Beginner's Guide - Installation & Hardware](https://www.youtube.com/watch?v=ZnT29rP-11s)
* [Virtual pfSense - Discussing the Options & Why](https://www.youtube.com/watch?v=IDspUBS8_-M)
* [pfSense Configuration Guide - Zero to Hero!](https://www.youtube.com/watch?v=he3ENpMLMsc)

### Freebsd Docker and VirtualBox NIY

* [FreeBSD as a Host with bhyve](https://docs.freebsd.org/en/books/handbook/virtualization/#virtualization-host-bhyve)
* [bhyve man pages](https://man.freebsd.org/cgi/man.cgi?query=bhyve&sektion=8&n=1)
* [bhyve](https://wiki.freebsd.org/bhyve)
* [Native webadmin / control panel for FreeBSD Bhyve](https://bhyve.npulse.net/installation)


* [Freebsd docker](https://wiki.freebsd.org/Docker)
* [VirtualBox](https://wiki.freebsd.org/VirtualBox)

### Netboot XYZ on Docker NIY

[The Ultimate Guide to Netboot XYZ on Docker: Step-by-Step pfSense Tutorial](https://www.youtube.com/watch?v=GHs5JJZEsXI)

https://netboot.xyz/
https://www.youtube.com/watch?v=4btW5x_clpg

https://syncthing.net/downloads/
https://www.youtube.com/watch?v=se4V-CgO7ZM

### Pi-hole or AdGuard NIY

[AdGuardHome](https://github.com/AdguardTeam/AdGuardHome)

[Pi-hole and OPNsense](https://pi-hole.net/blog/2021/09/30/pi-hole-and-opnsense/#page-content)

# Kubernetes environment




[Live-demo: FluxCD в действии - Георг Гаал !!!](https://www.youtube.com/watch?v=T4fkWIGahiQ)
https://github.com/khuedoan/homelab
https://github.com/Diaoul/home-ops/blob/main/cluster/core/rook-ceph/direct-mount/deployment.yaml
https://github.com/intel/kubernetes-power-manager

## Storage

https://www.youtube.com/watch?v=BNKb-SOnoKk

## Docker

[Docker desktop](https://www.docker.com/products/docker-desktop/)
[Using SQL Server Containers for Dev](https://www.youtube.com/watch?v=GRWYHzOfmnc)

## Synology

vladadmin Q1..

Alpine linux VM
root Q4..
IP:  192.168.2.232
DNS: 192.168.2.222
EST
apk add haproxy

[Cluster Load Balancer](https://docs.k3s.io/datastore/cluster-loadbalancer)



[How do I set up a DNS server on my Synology NAS?](https://kb.synology.com/en-us/DSM/tutorial/How_to_set_up_your_domain_with_Synology_DNS_Server)

[Synology on PC](https://www.youtube.com/watch?v=OdZbGaCxT9g)

[Play list](https://www.youtube.com/playlist?list=PLBOHxXgnuKOkAn6AaheY1j8dJb9dkuh4L)

[Synology_High_Availability_Guide](https://kb.synology.com/en-global/UG/Synology_High_Availability_Guide_7_2/1)

### LDAP

[Sync users between Synology's - Setting up an LDAP server on Synology NAS](https://www.youtube.com/watch?v=Ac4FVy9N068)

## BACKUP

[The Complete Hyper Backup Guide For Synology NAS (YOU NEED TO BACKUP YOUR NAS)](https://www.youtube.com/watch?v=7Retrqnr9eM)

### DNS

[How do I set up a DNS server on my Synology NAS?](https://kb.synology.com/en-us/DSM/tutorial/How_to_set_up_your_domain_with_Synology_DNS_Server)

[How to use a Synology as a DNS Server](https://www.youtube.com/watch?v=knD5TjXGBqA&t=332s)

Set two DNS: 192.168.2.227 (HA), 192.168.108.222

[How can I query DNS records with the nslookup command?](https://kb.synology.com/en-us/DSM/tutorial/dns_nslookup)

#### 192.168.2.227 as DNS server for registrator

[How do I set up a DNS server on my Synology NAS?](https://kb.synology.com/en-us/DSM/tutorial/How_to_set_up_your_domain_with_Synology_DNS_Server)

[How do I configure DNS records for a mail server?](https://kb.synology.com/en-us/DSM/tutorial/How_to_configure_DNS_for_MailPlus)

[hosting-dns-servers-for-your-domain](https://www.itgeared.com/hosting-dns-servers-for-your-domain/)

* open 53 port for TCP and UDP on NAS
* open 53 port for TCP and UDP on router - WIP

Old records:
A pop 216.58.36.97
A www 216.58.36.97
A office 216.58.36.97
A mail 216.58.36.97
A * 216.58.36.97
CNAME dkim._domainkey cur.dkim.v.eigmail.net
TXT @ "v=spf1 mx -all"

Primary forwarding zone
* NS ns.vladnet.ca
* NS vladnet-office.synology.me
* TXT "v=spf1 mx -all"  [SPF](http://www.open-spf.org/SPF_Record_Syntax/)
* deprecated SPF "v=spf1 mx -all"

Primary recurcive zone

Tests
* `nslookup -q=all vladnet.ca 192.168.2.227`
* `nslookup 216.58.36.97 192.168.2.227`

### MAIL

[How do I set up Synology MailPlus?](https://kb.synology.com/en-us/DSM/tutorial/How_to_set_up_MailPlus_Server_on_your_Synology_NAS)

### How to use Docker on a Synology NAS
1. Video: [How to use Docker on a Synology NAS (Tutorial)](https://www.youtube.com/watch?v=xzMhZoUs7uw) Blog:[How to use Docker on a Synology NAS](https://www.wundertech.net/how-to-use-docker-on-a-synology-nas/)

[Best Docker Containers for Synology NAS](https://www.youtube.com/watch?v=-ApgO4P3DWc)

Introduction to running Docker containers on Synology NAS - 0:00
Why Synology is a great NAS solution - 0:54
Great security reputation - 1:20
Why use a Synology NAS device as a Docker container host? 1:38
How to install the Docker Engine on your Synology NAS - 2:36
The best docker container - media server using Jellyfin - 2:59
Running home automation with Home Assistant - 4:02
Running your own Git repository with Gitlab - 4:57
Running your own email services that integrate with modern notifications - 5:49
Introducing Apprise and Mailrise - 6:08
Self-hosting a VPN solution on your Synology NAS with Twingate - 7:04
Running your Unifi Network Controller on your Synology NAS - 8:04
Portainer container management - 8:49
Running Pihole on your Synology NAS for DNS filtering, blocking ads, ransomware, etc - 9:36
Running a home lab dashboard using Dashy on your Synology NAS - 10:12
Wrapping up thinking about the best Docker containers on your Synology NAS - 11:22

[Best Docker Containers for Synology NAS](https://www.virtualizationhowto.com/2023/01/best-docker-containers-for-synology-nas/)

[Best Docker Containers for Home Server](https://www.virtualizationhowto.com/2022/05/best-docker-containers-for-home-server/)

[Monitor docker containers with 6 Free tools](https://www.virtualizationhowto.com/2022/12/monitor-docker-containers-with-6-free-tools/)

### Gitea

[Gitea - Keep Your Repo Private At Home!]{https://www.youtube.com/watch?v=VU-K4djix7Y}

https://github.com/JamesTurland/JimsGarage/tree/main/Gitea
https://www.youtube.com/watch?v=KKQOKQ3Gihk

Parameters

* Container Name: gitea
* Enable resource limitation: medium, 1Gb
* Enable auto-restart
* Enable web portal via Web Station: 3000 HTTP, 22 TCP

## ETCD node hardware

[ODROID-H4 no disks](https://www.hardkernel.com/shop/odroid-h4/)
[ODROID-H4-PLUS !!!](https://www.hardkernel.com/shop/odroid-h4-plus/)
[Memory](https://www.hardkernel.com/shop/samsung-8gb-ddr5-5600-so-dimm/)
[Case](https://www.hardkernel.com/shop/odroid-h4-case-type-1/)
[Power](https://www.hardkernel.com/shop/15v-4a-power-supply-us-plug/)
[Fan](https://www.hardkernel.com/shop/92x92x15mm-dc-cooling-fan-w-pwm-speed-sensor-tacho/)
[Mount](https://www.hardkernel.com/shop/vesa-mount-kit/)
[Disk](https://www.newegg.ca/p/pl?N=100011700%20601286601)

https://www.friendlyelec.com/index.php?route=product/product&path=60&product_id=294

## Worker node hardware for DRBD

[10Gb NIC Dual RJ45 Port PCIe Network Card with Intel X540-AT2 Controller](https://www.amazon.com/dp/B01IR7T7PG/ref=sspa_dk_detail_4?pd_rd_i=B01IR7T7PG&pd_rd_w=31GEI&content-id=amzn1.sym.386c274b-4bfe-4421-9052-a1a56db557ab&pf_rd_p=386c274b-4bfe-4421-9052-a1a56db557ab&pf_rd_r=FGJJFFMRKCSMBAZS1JE5&pd_rd_wg=TAd8W&pd_rd_r=7e70b250-3da0-4857-9a7e-c093a1dcd983&s=pc&sp_csd=d2lkZ2V0TmFtZT1zcF9kZXRhaWxfdGhlbWF0aWM&smid=AK4611NBN3D7D&th=1)
[10Gb Dual LAN Base-T PCI-e Network Card, Intel X540 Controller](https://www.amazon.com/dp/B0BG2F2B7R/ref=sspa_dk_detail_0?psc=1&pd_rd_i=B0BG2F2B7R&pd_rd_w=31GEI&content-id=amzn1.sym.386c274b-4bfe-4421-9052-a1a56db557ab&pf_rd_p=386c274b-4bfe-4421-9052-a1a56db557ab&pf_rd_r=FGJJFFMRKCSMBAZS1JE5&pd_rd_wg=TAd8W&pd_rd_r=7e70b250-3da0-4857-9a7e-c093a1dcd983&s=pc&sp_csd=d2lkZ2V0TmFtZT1zcF9kZXRhaWxfdGhlbWF0aWM)

## WSL2

[Developing in WSL](https://code.visualstudio.com/docs/remote/wsl)
[Terminal Basics](https://code.visualstudio.com/docs/terminal/basics)
[Remote development in WSL](https://code.visualstudio.com/docs/remote/wsl-tutorial)
[Develop with containers](https://code.visualstudio.com/learn/develop-cloud/containers)
[Developing inside a Container](https://code.visualstudio.com/docs/devcontainers/containers)

## Virtual

[Proxmox](https://www.proxmox.com/en/)

## Kubernetes

* [Tutorials](https://github.com/antonputra/tutorials)
* [!!! Kubernetes Roadmap - Complete Step-by-Step Learning Path](https://www.youtube.com/watch?v=S8eX0MxfnB4)

https://kubernetes.io/blog/2024/04/05/diy-create-your-own-cloud-with-kubernetes-part-1/
https://fernandocejas.com/blog/engineering/2023-01-06-over-engineered-home-lab-docker-kubernetes/

[Tech & Homelab Nerd](https://github.com/christianlempa)

### Operators

* [MetalLB Operator](https://operatorhub.io/operator/metallb-operator)
* NFS
  * [NFS Operator](https://operatorhub.io/operator/nfs-operator) 
  * [NFS Provisioner Operator](https://operatorhub.io/operator/nfs-provisioner-operator)
* Postgres
  * !!! [CloudNativePG](https://operatorhub.io/operator/cloudnative-pg)
  * [Crunchy Postgres for Kubernetes](https://operatorhub.io/operator/postgresql/v5/postgresoperator.v5.6.0)
  * [Postgres-Operator](https://operatorhub.io/operator/postgres-operator)
* [Grafana Operator](https://operatorhub.io/operator/grafana-operator)
* [Prometheus Operator](https://operatorhub.io/operator/prometheus)

### External Load Balancer

* [How to Configure HAProxy to Load Balance TCP Traffic](https://webhostinggeeks.com/howto/how-to-configure-haproxy-to-load-balance-tcp-traffic/)
* [HAProxy](https://www.haproxy.com/documentation/haproxy-configuration-tutorials/load-balancing/tcp/)
* [Configuration Manual](https://docs.haproxy.org/3.0/configuration.html#5.2)
* [Ucarp Virtual IP Manager](https://wiki.alpinelinux.org/wiki/High_Availability_High_Performance_Web_Cache#Ucarp_Virtual_IP_Manager)
* [HA Proxy Load Balancer](https://wiki.alpinelinux.org/wiki/High_Availability_High_Performance_Web_Cache#HA_Proxy_Load_Balancer)

#### kube-vip

[rancher desktop](https://kube-vip.io/docs/usage/rancher-desktop/)

#### Build Linux Alpine VM image

[alpine-linux-cheat-sheet](https://github.com/masoudei/alpine-linux-cheat-sheet/blob/main/README.md)


[Make Alpine Linux VM Image](https://github.com/alpinelinux/alpine-make-vm-image)

`
wget https://raw.githubusercontent.com/alpinelinux/alpine-make-vm-image/v0.13.0/alpine-make-vm-image \
    && echo '0fe2deca927bc91eb8ab32584574eee72a23d033  alpine-make-vm-image' | sha1sum -c \
    || exit 1

sudo apt-get install -y --no-install-recommends binfmt-support qemu-user-static
update-binfmts --enable
sh alpine-make-vm-image alpine.img
`

#### Build FreeNginx

[HIGH AVAILABILITY k3s (Kubernetes) in minutes!](https://www.youtube.com/watch?v=UoOcLXfa8EU)

[High Availability Rancher on a Kubernetes Cluster](https://www.youtube.com/watch?v=APsZJbnluXg)

[How to build NGINX from source - and optimize it for security and performance. Including TLS.](https://otland.net/threads/how-to-build-nginx-from-source-and-optimize-it-for-security-and-performance-including-tls.288892/)

`
sudo apt update
sudo apt dist-upgrade
sudo apt install build-essential libpcre3-dev libssl-dev zlib1g-dev libgd-dev
wget http://nginx.org/download/nginx-1.26.2.tar.gz
tar -xzvf nginx-1.26.2.tar.gz
cd nginx-1.26.2
`

`
sudo adduser --system --no-create-home --shell /bin/false --disabled-login --group nginx
`

Now let's build the installer for NGINX using all recommended modules.
`
./configure --prefix=/var/www/html --sbin-path=/usr/sbin/nginx --modules-path=/etc/nginx/modules --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --pid-path=/etc/nginx/nginx.pid --lock-path=/etc/nginx/nginx.lock --user=nginx --group=nginx --with-threads --with-file-aio --with-http_ssl_module --with-http_v2_module --with-http_realip_module --with-http_addition_module --with-http_image_filter_module=dynamic --with-http_sub_module --with-http_mp4_module --with-http_gzip_static_module --with-http_auth_request_module --with-http_secure_link_module --with-http_slice_module --with-http_stub_status_module --http-log-path=/var/log/nginx/access.log --with-stream --with-stream_ssl_module --with-stream_realip_module --with-compat --with-pcre-jit
`
`
make -j4
sudo make install
`


### [Helm](https://helm.sh/)

[Charts](https://artifacthub.io/)

`helm repo add bitnami https://charts.bitnami.com/bitnami`
`helm repo list`
`helm search repo nginx`
`helm install webserver bitnami/nginx`
`helm list`

### Rancher

* [Harvester](https://docs.harvesterhci.io/v1.3/)
* [Running your own Kubernetes cluster with Rancher](https://www.youtube.com/watch?v=1j5lhDzlFUM)
* [Introduction to Rancher: On-prem Kubernetes](https://github.com/marcel-dempers/docker-development-youtube-series/tree/master/kubernetes/rancher)
* [k8s-sample-application](https://github.com/virtualelephant?tab=repositories)
* [Longhorn](https://github.com/JamesTurland/JimsGarage/tree/main/Kubernetes/Longhorn)
* [longhorn examples](https://github.com/longhorn/longhorn/tree/master/examples)
* [Advanced Kubernetes Networking with Multus (It's easier than you think)](https://www.youtube.com/watch?v=atfLTiW5yvM)


#### Rancher machine
Ubuntu VM 192.168.2.231

sudo apt update
sudo apt upgrade
sudo apt install -y nano net-tools openssh-server
sudo systemctl enable ssh
sudo ufw allow ssh
sudo systemctl start ssh

my development machine (.79)
[Quick start](https://www.rancher.com/quick-start)  jM2TpWnaExJ41MSf

ssh vlad@192.168.2.231

curl -sSL https://get.docker.com/ | sh
sudo usermod -aG docker $(whoami)
sudo service docker start

docker run -d --name rancher-server  -v ${PWD}/rancher-data:/var/lib/rancher --restart=unless-stopped -p 80:80 -p 443:443 --privileged rancher/rancher

docker logs rancher-server > rancher.log

admin Q4..

#### Dev cluster

Now it single node cluster with Ubuntu.

Power management. Not changed yet.

* [Power management](https://help.cesbo.com/misc/tools-and-utilities/linux/cpupower)
* [governors](https://www.kernel.org/doc/Documentation/cpu-freq/governors.txt)
* cpupower frequency-info
* [Multus](https://github.com/k8snetworkplumbingwg/multus-cni?tab=readme-ov-file#comprehensive-documentation)

k8dev1 TS140

* IP 192.168.2.233 vlad Q4..
* Join to cluster by running sample command from rancher

[Setup additional disks for Longhorn](https://help.ubuntu.com/community/InstallingANewHardDrive)

* Get list disk devices `sudo fdisk -l`
  * Disk /dev/nvme0n1 - 465 GiB
    * Start parted `parted /dev/nvme0n1`. Print partition info `print`.
    * Create label `mklabel`, `gpt`. 
    * Create partition `mkpart`, `primary`, `ext4`, `0%`, `90%`. My choice only 90% ??? 
    * Close parted `quit`.
    * List partition path `sudo fdisk -l`
    * Format disk `sudo mkfs -t ext4 /dev/nvme0n1p1`
  * Disk /dev/sda - 465 GiB
    * Start parted `parted /dev/sda`. Print partition info `print`. 
    * Create label `mklabel`, `gpt`. 
    * Create partition `mkpart`, `primary`, `ext4`, `0%`, `90%`. My choice only 90% ??? 
    * Close parted `quit`.
    * List partition path `sudo fdisk -l`
    * Format disk `sudo mkfs -t ext4 /dev/sda1`
  * Disk /dev/sdb - 111 GiB
* Setup automount /etc/fstab
  * Create directories for mounting disks
    * `sudo mkdir /media/ssd1`
    * `sudo mkdir /media/nvme1`
  * Edit /etc/fstab file
    * Add record `/dev/sda1 /media/ssd1 ext4 defaults 0 2`
    * Add record `/dev/nvme0n1p1 /media/nvme1 ext4 defaults 0 2`
  * Reload `sudo systemctl daemon-reload`
  * Mount `sudo mount -a`

Setup usage additional disk in Longhorn.

k8dev2 TS140, 192.168.2.234

##### Setup kubectl and helm access

Load dev cluster config from rancher. Modify .kube to have access to cluster with kubectl.

* [Install and Set Up kubectl on Windows](https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/)
* [Install and Set Up kubectl on Linux](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)

##### Applications

###### Traefik

* [traefik](https://doc.traefik.io/traefik/providers/kubernetes-ingress/)
* [K3s Traefik dashboard](https://qdnqn.com/k3s-traefik-dashboard/)

kubectl apply -f traefik-custom-config.yaml

* [Kubernetes Ingress Tutorial for Beginners](https://www.youtube.com/watch?v=80Ew_fsV4rM)
* [Bare-metal considerations](https://kubernetes.github.io/ingress-nginx/deploy/baremetal/)

###### HA

[MetalLB](https://metallb.universe.tf/)
[Istio](https://istio.io/latest/docs/overview/what-is-istio/)
[HA and load balancer](https://kube-vip.io/)

###### Volumes

[drbd](https://www.sous-chefs.org/cookbooks/drbd/README)

###### Postgre

### Talos Linux

https://www.talos.dev/
https://www.siderolabs.com/
https://github.com/siderolabs/talos

#### Talos bootstrap

https://github.com/aenix-io/talos-bootstrap/
https://mirceanton.com/posts/2023-11-28-the-best-os-for-kubernetes/
https://www.talos.dev/v1.7/talos-guides/configuration/patching/

### Dev Environment setup

`curl -X GET https://factory.talos.dev/versions`
`curl -X GET https://factory.talos.dev/version/v1.7.1/extensions/official`

#### VM on Synology

Your image schematic ID is: 376567988ad370138ad8b2698212367b8edcb69b5fd68c80be1f2ec7d603b4ba

#### K8plane

##### Boot image
ISO
https://factory.talos.dev/image/376567988ad370138ad8b2698212367b8edcb69b5fd68c80be1f2ec7d603b4ba/v1.7.1/metal-amd64.iso

Initial Install
For the initial Talos Linux install (doesn't apply to disk image boot) put the following installer image to the machine configuration:
factory.talos.dev/installer/376567988ad370138ad8b2698212367b8edcb69b5fd68c80be1f2ec7d603b4ba:v1.7.1

#### K8worker

##### Boot image
[Load Talos with extensions](https://www.youtube.com/watch?v=wjDtoe-CYoI)

Getting boot image from [Image factory](https://factory.talos.dev/)
Your image schematic ID is: 98727da06263b40c5bcb84f9033aaba1b6afcd3b76c06730c57af8e7fe1b81fd
customization:
    systemExtensions:
        officialExtensions:
            - siderolabs/drbd
            - siderolabs/iscsi-tools
            - siderolabs/util-linux-tools

First Boot ISO
https://factory.talos.dev/image/98727da06263b40c5bcb84f9033aaba1b6afcd3b76c06730c57af8e7fe1b81fd/v1.7.6/metal-amd64.iso

Upgrade:
talosctl upgrade --image factory.talos.dev/installer/d5c48a0729fcfb282c2cd912a43f59b7367dffee6a04408619f3abd297859bc7:v1.7.1 -m powercycle -f -e 192.168.2.75 -n 192.168.2.75

#### [Getting Started](https://www.talos.dev/v1.7/introduction/getting-started/)

Install talosctl on developer main PC
`curl -sL https://talos.dev/install | sh`

`talosctl -n 192.168.2.28 disks --insecure` check disks on node and modify controlplane.yaml to install on appropriate disk `/dev/sda` for vm on synology

Configure Talos Linux
`talosctl gen config <cluster-name> <cluster-endpoint>` where cluster-name is 'vladnetK8s', cluster-endpoint is ip address first cluster node (from DHCP)
`talosctl gen config k8s-dev https://192.168.2.28:6443`

Check network interface names by using user interface [Network Config] on computer

For k8s-dev VM on synology it is `enx02113229240f`

Modify controlplane.yaml to set IP : dev 192.168.2.228/24, dns 192.168.2.227, gate 192.168.2.1

Modify controlplane.yaml file and apply to control plane node
`talosctl apply-config --insecure --nodes 192.168.2.28 --file controlplane.yaml --mode=try`

Bootstrap. Expected KUBELET already healthy 
`talosctl bootstrap -e 192.168.2.75 --nodes 192.168.2.75 --talosconfig=./talosconfig`

When ALL healthy. Add (merge) you new cluster into your local Kubernetes configuration.
`talosctl kubeconfig -e 192.168.2.75 --nodes 192.168.2.75 --talosconfig=./talosconfig`

You should now be able to connect to Kubernetes and see your nodes:
`kubectl get nodes`

`talosctl apply-config -e 192.168.2.75 --nodes 192.168.2.75 --file controlplane.yaml --talosconfig=./talosconfig`

`talosctl kubeconfig -e 192.168.2.75 --nodes 192.168.2.75 --talosconfig=./talosconfig health`

Upgrade with extensions
[Get image ID with extension](https://factory.talos.dev/)
Save customization in file 'customization.extension.yaml' file.
`talosctl upgrade --image factory.talos.dev/installer/c20c097120034fbe6d4b6f268700dc16afdf450e5da785fe270acfe8b13dddd6:v1.7.0 -m powercycle -e 192.168.2.75 --nodes 192.168.2.75 --talosconfig=./talosconfig`

Get network interfaces
`talosctl list /sys/class/net`

##### Worker

Find disk for booting
`talosctl disks --insecure --nodes 192.168.2.40`

Modify worker.yaml. Apply config.
`talosctl apply-config --insecure --nodes 192.168.2.40 --file worker.yaml --mode=try`

Reboot. It will join cluster

#### Management

[kubernetes management tools comparison](https://www.youtube.com/watch?v=R0HlJsugOAE)

[Lens](https://k8slens.dev/)

[K9](https://k9scli.io/), [Github](https://github.com/derailed/k9s?tab=readme-ov-file)

#### Storage

##### NFS
[Connect Kubernetes to your Synology NAS NFS share](https://www.youtube.com/watch?v=uPt3VKQOMBs)

[NFS Subdir External Provisioner: Connect Your NAS with Kubernetes](https://www.virtualizationhowto.com/2023/11/nfs-subdir-external-provisioner-connect-your-nas-with-kubernetes/)

[Dynamically provision NFS persistent volumes in Kubernetes](https://www.youtube.com/watch?v=AavnQzWDTEk&t=37s)

##### Longhorn

[Longhorn](https://hackmd.io/@QI-AN/Install-Longhorn-on-Talos-Kubernetes?utm_source=preview-mode&utm_medium=rec)

##### [sql-server-linux-overview](https://learn.microsoft.com/en-us/sql/linux/sql-server-linux-overview?view=sql-server-ver16)

##### [iscsi-tools](https://github.com/siderolabs/extensions/tree/main/storage/iscsi-tools)

`./scripts/deploy.sh install --basic`



[Install GO](https://go.dev/doc/install)

[synology-csi-talos](https://github.com/zebernst/synology-csi-talos)

Install CRDs:

`git clone https://github.com/kubernetes-csi/external-snapshotter.git`

Change current directory to ../synology-csi-talos. All install:
`./scripts/deploy.sh install --all`

All uninstall
`./scripts/uninstall.sh uninstall`

Apply CRDs:
`kubectl apply -f snapshot.storage.k8s.io_volumesnapshotclasses.yaml`
`kubectl apply -f snapshot.storage.k8s.io_volumesnapshotcontents.yaml`
`kubectl apply -f snapshot.storage.k8s.io_volumesnapshots.yaml`
`kubectl apply -f external-snapshotter/deploy/kubernetes/snapshot-controller/rbac-snapshot-controller.yaml`
`kubectl apply -f external-snapshotter/deploy/kubernetes/snapshot-controller/setup-snapshot-controller.yaml`

[SynologyOpenSource](https://github.com/SynologyOpenSource/synology-csi)

##### [DRBD](https://github.com/siderolabs/extensions/tree/main/storage/drbd)

[piraeus-operator](https://github.com/piraeusdatastore/piraeus-operator/blob/v2/docs/how-to/talos.md)

[Piraeus Operator, get-started](https://github.com/piraeusdatastore/piraeus-operator/blob/v2/docs/tutorial/get-started.md)

Install Piraeus Operator
`kubectl apply --server-side -k "https://github.com/piraeusdatastore/piraeus-operator//config/default?ref=v2.5.1"
namespace/piraeus-datastore configured`

'kubectl get pods -A'

Deploy Piraeus Datastore
`kubectl apply -f - <<EOF
apiVersion: piraeus.io/v1
kind: LinstorCluster
metadata:
  name: linstorcluster
spec: {}
EOF`

`talosctl -n 192.168.2.75 read /proc/modules`

#### [Secure, remote access](https://tailscale.com/)

[Tailscale extension](https://github.com/siderolabs/extensions/tree/main/network/tailscale)

### Kubernetes how to

[declarative-config](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/declarative-config/)
[API](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.30/)

### Applications

[artifacthub](https://artifacthub.io/packages/search?kind=0)

#### [gitea](https://docs.gitea.com/installation/install-on-kubernetes)

#### [PostgreSQL](https://refine.dev/blog/postgres-on-kubernetes/#configure-yaml-files-for-pv-and-pvc)

[sumologic postgres](https://www.sumologic.com/blog/kubernetes-deploy-postgres/)
[bitnami postgresql](https://github.com/bitnami/charts/tree/main/bitnami/postgresql)