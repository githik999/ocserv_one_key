create_cert(){
	curl -JLO "https://dl.filippo.io/mkcert/latest?for=linux/amd64"
	chmod +x mkcert-v*-linux-amd64
	sudo cp mkcert-v*-linux-amd64 /usr/local/bin/mkcert

	mkcert -key-file /etc/ocserv/private.key -cert-file /etc/ocserv/public.cert $1
}

tmp=`cat /etc/debian_version`
ver=${tmp: 0: 1}
if [ "$ver" -gt "1" ];then
	echo $tmp
	echo 'only support debian_version >= 10'
	exit
fi

apt update -y
apt upgrade -y
apt install iptables -y
apt install ocserv -y

public_ip=`curl ifconfig.me`
echo -n "Server Address " > /etc/ocserv/server.address
echo -n $public_ip >> /etc/ocserv/server.address
echo ":3389(Port MUST Not Blocked)" >> /etc/ocserv/server.address
curl -o /etc/ocserv/ocserv.conf https://gitee.com/chrisrock/ocserv_one_key/raw/main/ocserv.conf
echo "no-route=$public_ip/24" >> /etc/ocserv/ocserv.conf

if [ ! -f "private.key" ];then
  echo "already have private.key mkcert will skip"
else
  create_cert $public_ip
fi


echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf

sysctl -p

iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o eth0 -j MASQUERADE
iptables -A FORWARD -s 192.168.1.0/24 -j ACCEPT


touch /etc/ocserv/ocpasswd
echo "---------------------------------------------------------"
cat /etc/ocserv/server.address
echo "---------------------------------------------------------"
echo "Username admin"
echo "---------------------------------------------------------"
echo "now set password"
ocpasswd -c /etc/ocserv/ocpasswd admin


systemctl restart ocserv
systemctl status ocserv

