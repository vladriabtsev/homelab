cat <<EOF > ~/tmp/dm_crypt_load.service
#!/bin/bash
# /etc/systemd/system/dm_crypt_load.service
[Unit]
Description=Load dm_crypt module for Longhorn
[Service]
Type=oneshot
ExecStart=/bin/sh -c "modprobe dm_crypt"
[Install]
WantedBy=multi-user.target
EOF
mv ~/tmp/dm_crypt_load.service /etc/systemd/system/dm_crypt_load.service
systemctl enable dm_crypt_load.service
modprobe dm_crypt
