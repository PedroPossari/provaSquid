#!/bin/bash

echo "----------------------------------------"
echo " Script de configuração de rede"
echo " Autor: Pedro Possari"
echo "----------------------------------------"

# Atualização do sistema
sudo apt update && sudo apt upgrade -y

# Instalação dos pacotes necessários
echo "Instalando DHCP, Squid e iptables-persistent..."
sudo apt install isc-dhcp-server squid iptables-persistent -y

# Modificando o arquivo 50-cloud-init.yaml
echo "Configurando IP fixo na interface enp0s8 dentro do 50-cloud-init.yaml..."
sudo cp /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.bkp

sudo tee /etc/netplan/50-cloud-init.yaml > /dev/null <<EOF
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: true
    enp0s8:
      addresses: [192.168.20.1/24]
EOF

sudo netplan apply

# Habilitando o encaminhamento de pacotes
echo "Habilitando o encaminhamento de pacotes..."
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Regras de NAT com iptables
echo "Adicionando regras de NAT para compartilhamento de internet..."
sudo iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE
sudo iptables -A FORWARD -i enp0s8 -o enp0s3 -j ACCEPT
sudo iptables -A FORWARD -i enp0s3 -o enp0s8 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Salvando regras do iptables
sudo netfilter-persistent save

# Configuração do DHCP
echo "Configurando o servidor DHCP para enp0s8..."
sudo sed -i 's/INTERFACESv4=""/INTERFACESv4="enp0s8"/' /etc/default/isc-dhcp-server

echo "Definindo o escopo de IPs para DHCP..."
cat <<EOF | sudo tee /etc/dhcp/dhcpd.conf
authoritative;
default-lease-time 600;
max-lease-time 7200;

subnet 192.168.20.0 netmask 255.255.255.0 {
  range 192.168.20.100 192.168.20.120;
  option routers 192.168.20.1;
  option domain-name-servers 8.8.8.8, 8.8.4.4;
}
EOF

sudo systemctl restart isc-dhcp-server
sudo systemctl enable isc-dhcp-server

# Configuração do Squid
echo "Configurando o Squid com regras básicas..."
sudo tee /etc/squid/squid.conf > /dev/null <<EOF
http_port 3128
acl rede_interna src 192.168.20.0/24
http_access allow rede_interna
http_access deny all
visible_hostname servidor-squid
EOF

sudo systemctl restart squid
sudo systemctl enable squid

echo "Servidor configurado com sucesso: DHCP + Proxy Squid + Compartilhamento de Internet."
