#!/bin/bash
# Zivpn UDP Module installer
# Creator Zahid Islam

echo -e "Updating server"
sudo apt update -y
sudo apt install ufw -y
systemctl stop zivpn.service 1> /dev/null 2> /dev/null
echo -e "Downloading UDP Service"
wget https://raw.githubusercontent.com/manggaduajayaonline-create/cfxhttp/refs/heads/main/udp-zivpn-linux-amd64 -O /usr/local/bin/zivpn 1> /dev/null 2> /dev/null
chmod +x /usr/local/bin/zivpn
mkdir /etc/zivpn 1> /dev/null 2> /dev/null
wget https://raw.githubusercontent.com/manggaduajayaonline-create/cfxhttp/refs/heads/main/config.json -O /etc/zivpn/config.json 1> /dev/null 2> /dev/null

echo "Generating cert files:"
openssl genrsa -out /etc/zivpn/hysteria.ca.key prime256v1  prime256v1
openssl req -new -x509 -sha256 -days 3650 -key /etc/zivpn/hysteria.ca.key -subj "/C=CN/ST=GD/L=SZ/O=Hysteria, Inc./CN=Hysteria Root CA" -out /etc/zivpn/hysteria.ca.crt
openssl req -newkey rsa:2048 -nodes -keyout /etc/zivpn/hysteria.server.key -subj "/C=CN/ST=GD/L=SZ/O=Hysteria, Inc./CN=server.manggaduajaya.qzz.io
" -out /etc/zivpn/hysteria.server.csr
openssl x509 -req -extfile <(printf "subjectAltName=DNS:server.manggaduajaya.qzz.io
,DNS:server.manggaduajaya.qzz.io
") -days 3650 -in /etc/zivpn/hysteria.server.csr -CA /etc/zivpn/hysteria.ca.crt -CAkey /etc/zivpn/hysteria.ca.key -CAcreateserial -out /etc/zivpn/hysteria.server.crt
openssl genpkey -algorithm RSA -out /etc/zivpn/hysteria.ca.key
openssl req -x509 -new -nodes -key /etc/zivpn/hysteria.ca.key -days 9999 -out /etc/zivpn/hysteria.ca.crt -subj "/C=CN/ST=GD/L=SZ/O=Hysteria, Inc./CN=Hysteria Root CA"
openssl req -newkey rsa:prime256v1 -nodes -keyout /etc/zivpn/hysteria.server.key -subj "/C=CN/ST=GD/L=SZ/O=Hysteria, Inc./CN=server.manggaduajaya.qzz.io
" -out /etc/zivpn/hysteria.server.csr
openssl x509 -req -extfile <(printf "subjectAltName=DNS:server.manggaduajaya.qzz.io
") -days 3650 -in /etc/zivpn/hysteria.server.csr -CA /etc/zivpn/hysteria.ca.crt -CAkey /etc/zivpn/hysteria.ca.key -CAcreateserial -out /etc/zivpn/hysteria.server.crt
sysctl -w net.core.rmem_max=16777216 1> /dev/null 2> /dev/null
sysctl -w net.core.wmem_max=16777216 1> /dev/null 2> /dev/null
cat <<EOF > /etc/systemd/system/zivpn.service
[Unit]
Description=zivpn VPN Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/zivpn
ExecStart=/usr/local/bin/zivpn server -c /etc/zivpn/config.json
Restart=always
RestartSec=3
Environment=ZIVPN_LOG_LEVEL=info
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

echo -e "ZIVPN UDP Passwords"
read -p "Enter passwords separated by commas, example: pass1,pass2 (Press enter for Default 'zi'): " input_config

if [ -n "$input_config" ]; then
    IFS=',' read -r -a config <<< "$input_config"
    if [ ${#config[@]} -eq 1 ]; then
        config+=(${config[0]})
    fi
else
    config=("zi")
fi

new_config_str="\"config\": [$(printf "\"%s\"," "${config[@]}" | sed 's/,$//')]"

sed -i -E "s/\"config\": ?\[[[:space:]]*\"zi\"[[:space:]]*\]/${new_config_str}/g" /etc/zivpn/config.json


systemctl enable zivpn.service
systemctl start zivpn.service
iptables -t nat -A PREROUTING -i $(ip -4 route ls|grep default|grep -Po '(?<=dev )(\S+)'|head -1) -p udp --dport 11000:29999 -j DNAT --to-destination :5300
ufw allow 11000:29999/udp
ufw allow 5300/udp
rm zi.* 1> /dev/null 2> /dev/null
echo -e "ZIVPN UDP Installed"
