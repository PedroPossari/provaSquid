#!/bin/bash

echo "⏳ Atualizando pacotes..."
sudo apt update && sudo apt upgrade -y

echo "📦 Instalando serviços necessários: DHCP, Squid, iptables-persistent..."
sudo apt install isc-dhcp-server squid iptables-persistent -y

echo "🛜 Configurando IP fixo na interface enp0s8 (rede interna)..."
cat <<EOF | sudo tee /etc/netplan/01-netcfg.yaml
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: true
    enp0s8:
      addresses: [192.168.10.1/24]
EOF

sudo netplan apply

echo "🔁 Ativando encaminhamento de pacotes..."
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

echo "🔥 Adicionando regras de NAT com iptables..."
sudo iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE
sudo iptables -A FORWARD -i enp0s8 -o enp0s3 -j ACCEPT
sudo iptables -A FORWARD -i enp0s3 -o enp0s8 -m state --state RELATED,ESTABLISHED -j ACCEPT

echo "💾 Salvando regras do iptables..."
sudo netfilter-persistent save

echo "🧭 Configurando interface para o servidor DHCP..."
sudo sed -i 's/INTERFACESv4=""/INTERFACESv4="enp0s8"/' /etc/default/isc-dhcp-server

echo "📝 Configurando escopo do DHCP..."
cat <<EOF | sudo tee /etc/dhcp/dhcpd.conf
authoritative;
default-lease-time 600;
max-lease-time 7200;

subnet 192.168.10.0 netmask 255.255.255.0 {
  range 192.168.10.100 192.168.10.200;
  option routers 192.168.10.1;
  option domain-name-servers 8.8.8.8, 1.1.1.1;
}
EOF

echo "🔁 Reiniciando serviço DHCP..."
sudo systemctl restart isc-dhcp-server
sudo systemctl enable isc-dhcp-server

echo "🧼 Limpando e reescrevendo squid.conf com configuração mínima..."
sudo tee /etc/squid/squid.conf > /dev/null <<EOF
http_port 3128
acl rede_interna src 192.168.10.0/24
http_access allow rede_interna
http_access deny all
visible_hostname servidor-squid
EOF

echo "🔁 Reiniciando serviço Squid..."
sudo systemctl restart squid
sudo systemctl enable squid

echo "✅ Configuração finalizada com sucesso!"
