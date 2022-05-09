apt update -y
apt upgrade -y
apt install iptables -y
apt install ocserv -y

curl -O https://raw.githubusercontent.com/githik999/ocserv_one_key/main/ocserv.conf
curl -JLO "https://dl.filippo.io/mkcert/latest?for=linux/amd64"
chmod +x mkcert-v*-linux-amd64
sudo cp mkcert-v*-linux-amd64 /usr/local/bin/mkcert

mkcert -key-file /etc/ocserv/key.pem -cert-file /etc/ocserv/cert.pem ssl.com

echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf && sysctl -p
iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o eth0 -j MASQUERADE
iptables -A FORWARD -s 192.168.1.0/24 -j ACCEPT

touch /etc/ocserv/ocpasswd
echo `Username:debian`
ocpasswd -c /etc/ocserv/ocpasswd debian

systemctl restart ocserv
systemctl status ocserv

