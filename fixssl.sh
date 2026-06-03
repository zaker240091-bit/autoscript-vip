#!/bin/bash
DOMAIN="my.drakvpn.site"
EMAIL="admin@my.drakvpn.site"

echo ">>> Step 1: Uninstall old acme.sh"
~/.acme.sh/acme.sh --uninstall 2>/dev/null
rm -rf /root/.acme.sh

echo ">>> Step 2: Reinstall acme.sh"
curl -s https://get.acme.sh | sh -s email=$EMAIL
source ~/.bashrc

echo ">>> Step 3: Switch to ZeroSSL"
~/.acme.sh/acme.sh --set-default-ca --server zerossl

echo ">>> Step 4: Register account"
~/.acme.sh/acme.sh --register-account -m $EMAIL --server zerossl

echo ">>> Step 5: Stop nginx & issue cert"
systemctl stop nginx
~/.acme.sh/acme.sh --issue --standalone -d $DOMAIN --server zerossl

echo ">>> Step 6: Install cert"
~/.acme.sh/acme.sh --install-cert -d $DOMAIN \
  --key-file /etc/xray/xray.key \
  --fullchain-file /etc/xray/xray.crt \
  --reloadcmd "systemctl restart nginx"

echo ">>> Step 7: Restart services"
systemctl start nginx
systemctl restart haproxy
systemctl restart xray

echo ">>> Done! Checking status..."
systemctl is-active nginx && echo "nginx: OK" || echo "nginx: FAILED"
systemctl is-active haproxy && echo "haproxy: OK" || echo "haproxy: FAILED"
systemctl is-active xray && echo "xray: OK" || echo "xray: FAILED"
