echo "Configurando o Squid com ACLs de whitelist, blacklist e palavras bloqueadas..."

# Criando arquivo whitelist.txt
sudo tee /etc/squid/whitelist.txt > /dev/null <<EOF
.youtube.com
.google.com
EOF

# Criando arquivo blacklist.txt
sudo tee /etc/squid/blacklist.txt > /dev/null <<EOF
.facebook.com
.twitter.com
EOF

# Criando arquivo blocked_words.txt
sudo tee /etc/squid/blocked_words.txt > /dev/null <<EOF
adult
gambling
torrent
EOF

# Configurando squid.conf com as ACLs usando os arquivos txt
sudo tee /etc/squid/squid.conf > /dev/null <<EOF
http_port 3128

# ACL rede interna
acl rede_interna src 192.168.10.0/24

# ACLs baseadas em arquivos
acl whitelist dstdomain "/etc/squid/whitelist.txt"
acl blacklist dstdomain "/etc/squid/blacklist.txt"
acl blocked_words url_regex -i "/etc/squid/blocked_words.txt"

# Regras Squid:
# - bloqueia blacklist
http_access deny blacklist

# - bloqueia URLs com palavras bloqueadas
http_access deny blocked_words

# - libera whitelist para a rede interna
http_access allow rede_interna whitelist

# - nega tudo que não está na whitelist para a rede interna
http_access deny rede_interna

# nega o resto do mundo
http_access deny all

visible_hostname servidor-squid
EOF

sudo systemctl restart squid
sudo systemctl enable squid
