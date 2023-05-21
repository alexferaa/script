#!/bin/bash

#get UUID
echo Enter a valid gen4 UUID:
read UUID

#get Email
echo Enter a valid EMAIL:
read EMAIL

#set timezone to Colombo
sudo timedatectl set-timezone Asia/Colombo

bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

rm -rf /usr/local/etc/xray/config.json
cat << EOF > /usr/local/etc/xray/config.json
{
  "log": {
    "loglevel": "warning"
  },
  "dns": {
    "servers": [
      "1.1.1.1"
    ],
    "queryStrategy": "UseIPv4"
  },
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {
        "type": "field",
        "ip": [
          "1.1.1.1"
        ],
        "outboundTag": "direct"
      },
      {
        "type": "field",
        "domain": [
          "geosite:category-ads-all"
        ],
        "outboundTag": "block"
      },
      {
        "type": "field",
        "ip": [
          "geoip:private"
        ],
        "outboundTag": "block"
      }
    ]
  },
  "inbounds": [
    {
      "port": 80,
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "$UUID"
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "tcpSettings": {
          "header": {
            "type": "http",
            "response": {
              "version": "1.1",
              "status": "200",
              "reason": "OK",
              "headers": {
                "Content-Type": [
                  "application/octet-stream",
                  "video/mpeg",
                  "application/x-msdownload",
                  "text/html",
                  "application/x-shockwave-flash"
                ],
                "Transfer-Encoding": [
                  "chunked"
                ],
                "Connection": [
                  "keep-alive"
                ],
                "Pragma": "no-cache"
              }
            }
          }
        },
        "security": "none"
      }
    },
	{
        "port": 443,
        "protocol": "trojan",
        "settings": {
            "clients": [
                {
                 "password":"$UUID",
                 "flow": "xtls-rprx-direct",
				 "level": 0,
				 "email": "$EMAIL"
                }
            ],
            "fallbacks": [
                {
				 "dest": "80"
                }
                 
            ]
        },
        "streamSettings": {
            "network": "tcp",
            "security": "xtls",
            "xtlsSettings": {
                "alpn": [
                    "http/1.1",
                    "h2"
                ],
                "certificates": [
                    {
                     "certificateFile": "/etc/xray/xray.crt",  
                     "keyFile": "/etc/xray/xray.key"
					}
                ],
                "minVersion": "1.3"
            }
        }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {
        "domainStrategy": "UseIPv4"
      },
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "settings": {
        "response": {
          "type": "http"
        }
      },
      "tag": "block"
    }
  ]
}
EOF

#accuring a ssl certificate (self-sigend openssl)

mkdir /etc/xray
cp xray.key /etc/xray/xray.key
cp xray.crt /etc/xray/xray.crt
chmod 644 /etc/xray/xray.key

#starting xray core on sytem startup

systemctl enable xray
systemctl restart xray

#install bbr

mkdir ~/across
git clone https://github.com/teddysun/across ~/across
chmod 777 ~/across
bash ~/across/bbr.sh
