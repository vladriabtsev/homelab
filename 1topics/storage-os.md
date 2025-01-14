## etcd

### debsos1 on ch1 192.168.108.55
install from iso file
#### network
nano /etc/network/interfaces
iface eth0 inet static
  address 192.168.108.55/24
  broadcast 192.168.108.255
  network 192.168.108.0
  gateway 192.168.108.1

  /etc/init.d/networking restart - not working
  reboot

### debsos2 on ch2 192.168.108.56
### debsos3 on ch 192.168.108.57

### syslog server on synology
put mylog.conf file to /etc/rsyslog.d/mylog.conf configuration file for rsyslog on each client
The priority is one of the following keywords, in ascending order: debug, info, notice, warning, warn (same as warning), err, error (same as err), crit, alert, emerg, panic (same as emerg). The keywords warn, error and panic are deprecated and should not be used anymore. The priority defines the severity of the message.

systemctl restart rsyslog

#### systemd
systemctl
journalctl
#### direct install
https://github.com/etcd-io/etcd/releases

##### Step 1. Create copy on win 10 ubuntu
ETCD_VER=v3.4.15

GOOGLE_URL=https://storage.googleapis.com/etcd # choose either URL
GITHUB_URL=https://github.com/etcd-io/etcd/releases/download
DOWNLOAD_URL=${GOOGLE_URL}

rm -f /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
rm -rf /tmp/etcd-download-test && mkdir -p /tmp/etcd-download-test

curl -L ${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
tar xzvf /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz -C /tmp/etcd-download-test --strip-components=1
rm -f /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz

/tmp/etcd-download-test/etcd --version
/tmp/etcd-download-test/etcdctl version

/tmp/etcd-download-test/etcd # start a local etcd server
/tmp/etcd-download-test/etcdctl --endpoints=localhost:2379 put foo bar # write,read to etcd
/tmp/etcd-download-test/etcdctl --endpoints=localhost:2379 get foo

##### Step 2. Install manually
https://docs.storageos.com/docs/prerequisites/etcd/

- on win 10 ubuntu
cd /tmp/etcd-v${ETCD_VERSION}-linux-amd64
copy on etcd and etcdctl all nodes vlad folder

- on each node do next

- Configure Etcd version and ports
export ETCD_VERSION="3.4.15"
export CLIENT_PORT="2379"
export PEERS_PORT="2380"

cd /home/vlad/etcd
su root 
mv etcd /usr/local/sbin/etcd3
mv etcdctl /usr/local/sbin/etcdctl
chmod 0755 /usr/local/sbin/etcd3 /usr/local/sbin/etcdctl

- Set up persistent Etcd data directory
mkdir /var/lib/storageos-etcd

- Create the systemd environment file /etc/etcd.conf
cp etcd.conf /etc/etcd.conf
https://www.gnu.org/software/coreutils/manual/html_node/chmod-invocation.html#chmod-invocation
https://www.gnu.org/software/coreutils/manual/html_node/Numeric-Modes.html#Numeric-Modes
chmod ug=rw,o=r /etc/etcd.conf  

- Create Certificate Authority  Currently without SSL !!!!!!!!!!!!!!!!!!!!!!!
https://ubuntu.com/server/docs/security-certificates
sudo mkdir /etc/ssl/CA
sudo mkdir /etc/ssl/newcerts
sudo sh -c "echo '01' > /etc/ssl/CA/serial"
sudo touch /etc/ssl/CA/index.txt

/etc/ssl/openssl.cnf
dir             = /etc/ssl              # Where everything is kept
database        = $dir/CA/index.txt     # database index file.
certificate     = $dir/certs/cacert.pem # The CA certificate
serial          = $dir/CA/serial        # The current serial number
private_key     = $dir/private/cakey.pem# The private key

openssl req -new -x509 -extensions v3_ca -keyout cakey.pem -out cacert.pem -days 3650
sudo mv cakey.pem /etc/ssl/private/
sudo mv cacert.pem /etc/ssl/certs/

- generate secure key
openssl genrsa -des3 -out server.key 2048
- get insecure key
openssl rsa -in server.key -out server.key.insecure
mv server.key server.key.secure
mv server.key.insecure server.key
- create the CSR
openssl req -new -key server.key -out server.csr
- create the self-signed certificate
openssl x509 -req -days 3640 -in server.csr -signkey server.key -out server.crt

rename server.key to client-key.pem
rename server.crt to client-cert.pem
copy client-key.pem,  client-key.pem and cacert.pem to places for etcd3.service

copy service file to /etc/systemd/system/etcd3.service

$ systemctl daemon-reload
$ systemctl enable etcd3.service
$ systemctl start  etcd3.service

tail -f /var/log/syslog

### check

ETCDCTL_API=3 etcdctl --endpoints=http://127.0.0.1:2379 member list
ETCDCTL_API=3 etcdctl --endpoints=http://127.0.0.1:${CLIENT_PORT} member list

### storageos operator
https://docs.storageos.com/docs/self-eval/
//curl -sL https://storageos.run > setup.txt

sudo microk8s kubectl create -f https://github.com/storageos/cluster-operator/releases/download/v2.3.4/storageos-operator.yaml

### install storageos

sudo microk8s kubectl create -f storage-os-secret.yml
sudo microk8s kubectl create -f storage-os-cluster-config.yml
sudo microk8s kubectl -n kube-system get pods





- TLS
https://etcd.io/docs/v3.4/op-guide/security/
https://github.com/etcd-io/etcd/tree/master/hack/tls-setup

- Create the systemd unit file for etcd3 service /etc/systemd/system/etcd3.service
https://medium.com/@benmorel/creating-a-linux-service-with-systemd-611b5c8b91d6
https://wiki.debian.org/systemd/Services


#### with ansible
https://blog.ssdnodes.com/blog/ansible-tutorial-getting-started/

https://docs.storageos.com/docs/prerequisites/etcd/
git clone https://github.com/storageos/deploy.git

ansible -i hosts all --list-hosts

ansible-playbook -i hosts install.yaml -vv
