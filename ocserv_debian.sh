version_check(){
	tmp=`cat /etc/debian_version`
	ver=${tmp: 0: 1}
	if [ "$ver" -gt "1" ];then
		echo $tmp
		echo 'only support debian_version >= 10'
		exit
	fi
}

install_ocserv(){
	apt update -y
	apt upgrade -y
	apt install iptables -y
	apt install ocserv -y
}

edit_conf(){
	echo -n "Server Address " > /etc/ocserv/server.address
	echo -n $1 >> /etc/ocserv/server.address
	echo ":3389(Port MUST Not Blocked)" >> /etc/ocserv/server.address
	curl -o /etc/ocserv/ocserv.conf https://raw.githubusercontent.com/githik999/ocserv_one_key/main/ocserv.conf 
	echo "no-route=$1/24" >> /etc/ocserv/ocserv.conf
}

edit_iptables(){
	echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
	echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
	echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
	sysctl -p
	iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o eth0 -j MASQUERADE
	iptables -A FORWARD -s 192.168.1.0/24 -j ACCEPT
}

create_cert(){
	curl -JLO "https://dl.filippo.io/mkcert/latest?for=linux/amd64"
	chmod +x mkcert-v*-linux-amd64
	sudo cp mkcert-v*-linux-amd64 /usr/local/bin/mkcert
	mkcert -key-file /etc/ocserv/private.key -cert-file /etc/ocserv/public.crt $1
}

version_check
public_ip=`curl ifconfig.me`
install_ocserv
edit_conf $public_ip
edit_iptables

if [ ! -f "private.key" ];then
  create_cert $public_ip
else
  echo "already have private.key mkcert will skip"
  mv public.crt /etc/ocserv/public.crt
  mv private.key /etc/ocserv/private.key
fi


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

