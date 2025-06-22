#!/bin/bash

echo "🔧 Instalando e configurando BIND9 com zona direta e reversa..."

# Instala BIND9 (caso ainda não esteja instalado)
sudo apt install bind9 bind9utils -y

# BACKUP dos arquivos originais
sudo cp /etc/bind/named.conf.options /etc/bind/named.conf.options.bkp
sudo cp /etc/bind/named.conf.local /etc/bind/named.conf.local.bkp

# CONFIGURAÇÃO DO FORWARDER
echo "Configurando forwarders no named.conf.options..."
sudo tee /etc/bind/named.conf.options > /dev/null <<EOF
options {
    directory "/var/cache/bind";

    listen-on port 53 { 127.0.0.1; 192.168.10.1; };
    allow-query { any; };

    forwarders {
        8.8.8.8;
    };

    recursion yes;
    dnssec-validation auto;
    auth-nxdomain no;
    listen-on-v6 { none; };
};
EOF

# CONFIGURAÇÃO DAS ZONAS
echo "Configurando zonas direta e reversa no named.conf.local..."
sudo tee /etc/bind/named.conf.local > /dev/null <<EOF
zone "meudominioprova.com.br" {
    type master;
    file "/etc/bind/db.meudominioprova.com.br";
};

zone "10.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/db.192";
};
EOF

# CRIAÇÃO DOS ARQUIVOS DE ZONA

cd /etc/bind

# Zona direta
sudo cp db.local db.meudominioprova.com.br
sudo tee /etc/bind/db.meudominioprova.com.br > /dev/null <<EOF
\$TTL 604800
@       IN      SOA     ns1.meudominioprova.com.br. admin.meudominioprova.com.br. (
                             2025062201 ; Serial
                                  604800 ; Refresh
                                   86400 ; Retry
                                 2419200 ; Expire
                                  604800 ) ; Negative Cache TTL
;
@       IN      NS      ns1.meudominioprova.com.br.
ns1     IN      A       192.168.10.1
servidor IN     A       192.168.10.1
pc-cliente IN   A       192.168.10.100
EOF

# Zona reversa
sudo cp db.127 db.192
sudo tee /etc/bind/db.192 > /dev/null <<EOF
\$TTL 604800
@       IN      SOA     ns1.meudominioprova.com.br. admin.meudominioprova.com.br. (
                             2025062201 ; Serial
                                  604800 ; Refresh
                                   86400 ; Retry
                                 2419200 ; Expire
                                  604800 ) ; Negative Cache TTL
;
@       IN      NS      ns1.meudominioprova.com.br.
1       IN      PTR     servidor.meudominioprova.com.br.
100     IN      PTR     pc-cliente.meudominioprova.com.br.
EOF

# REINICIA O SERVIÇO DNS
echo "Reiniciando o BIND9..."
sudo systemctl restart bind9
sudo systemctl enable bind9

# CONFIGURA O DNS LOCAL NO SERVIDOR
echo "Configurando o servidor para usar o próprio DNS..."

sudo sed -i 's/^#DNS=.*/DNS=192.168.10.1 8.8.8.8/' /etc/systemd/resolved.conf
sudo sed -i 's/^#Domains=.*/Domains=meudominioprova.com.br/' /etc/systemd/resolved.conf

sudo systemctl restart systemd-resolved
sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf

echo "✅ BIND9 configurado com zonas de DNS direta e reversa em 192.168.10.1!"