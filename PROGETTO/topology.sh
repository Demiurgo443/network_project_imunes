sudo himage router1 sed -i -e s/zebra=no/zebra=yes/g /etc/quagga/daemons
sudo himage router1 sed -i -e s/ospfd=no/ospfd=yes/g /etc/quagga/daemons
sudo himage router1 service quagga restart
cat configRouter1 | sudo himage router1 vtysh
sudo sleep 1

#assegno tutti gli indirizzi ip statici
sudo himage DNS ip addr add 192.168.0.1/24 dev eth0
sudo himage DHCP ip addr add 192.168.0.2/24 dev eth0
sudo himage pc2 ip addr add dev eth0 10.0.0.2/24
#configuro server HTTP
sudo himage HTTP ip addr add 192.168.0.4/24 dev eth0
sudo xterm -e 'himage HTTP python -m SimpleHTTPServer' &
#configuro server FTP
sudo himage FTP ip addr add 192.168.0.3/24 dev eth0
sudo hcp kitvsftpd/* FTP:/
sudo himage FTP useradd ftp 
sudo himage FTP mkdir -p /var/run/vsftpd/empty
sudo xterm -e 'himage FTP vsftpd' &


#Configuro DNS
sudo himage DNS mkdir /var/log/named
sudo hcp rndc.key DNS:/etc/bind/rndc.key
sudo hcp rndc.conf DNS:/etc/bind/rndc.conf
sudo hcp named.conf.local DNS:/etc/bind/named.conf.local
sudo hcp db.progetto.eu DNS:/etc/bind/db.progetto.eu
sudo hcp 0.168.192.in-addr.arpa DNS:/etc/bind/0.168.192.in-addr.arpa
sudo himage DNS named-checkconf
sudo himage DNS named-checkzone progetto.eu /etc/bind/db.progetto.eu
sudo himage DNS named-checkzone 0.168.192.in-addr.arpa /etc/bind/0.168.192.in-addr.arpa
sudo himage DNS named
sudo sleep 2

sudo himage pc2 bash -c 'cat > /etc/resolv.conf << EOF
nameserver 192.168.0.1
EOF'
	
#Configuro DHCP
sudo hcp rndc.key DHCP:/etc/bind/rndc.key
sudo hcp rndc.conf DHCP:/etc/bind/rndc.conf
sudo himage DHCP sh -c 'echo > /etc/dhcp/dhcpd.conf' #serve per svuotare il file
sudo hcp dhcpd.conf DHCP:/etc/dhcp/dhcpd.conf #copio il file di configurazione locale dalla cartella al percorso all'interno del server dhcp
sudo xterm -e 'himage DHCP dhcpd -d' & #avvio server DHCP
sudo xterm -e 'himage DHCP tcpdump' &
sudo himage pc1 dhclient eth0 #richiesta di indirizzo fatta da pc1 al server dhcp con conseguente assegnamento

#creo le rotte
sudo himage pc2 ip route add 0.0.0.0/0 via 10.0.0.1 dev eth0
sudo himage DHCP ip route add 0.0.0.0/0 via 192.168.0.254 dev eth0
sudo himage DNS ip route add 0.0.0.0/0 via 192.168.0.254 dev eth0
sudo himage HTTP ip route add 0.0.0.0/0 via 192.168.0.254 dev eth0
sudo himage FTP ip route add 0.0.0.0/0 via 192.168.0.254 dev eth0

#ping di verifica per rotte propagate
sudo himage pc2 bash -c 'until ping -c1 192.168.0.5 &>/dev/null; do :; done;'
sudo himage pc1 nslookup HTTP.progetto.eu.
sudo himage pc1 ping -c3 HTTP.progetto.eu.
sudo himage pc2 nslookup FTP.progetto.eu.
sudo himage pc2 ping -c3 FTP.progetto.eu.
#traceroute
sudo himage pc1 traceroute 10.0.0.2
sudo himage pc2 traceroute 192.168.0.5
#comando per risolvere in modo inverso: parto da ip per avere nome
sudo himage pc1 dig -x 192.168.0.5
sudo himage pc1 ping -c3 pc1
sudo himage pc2 ping -c3 pc1.progetto.eu
sudo himage pc2 curl http://HTTP.progetto.eu:8000
read