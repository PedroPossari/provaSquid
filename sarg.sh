#!/bin/bash

echo "----------------------------------------"
echo " Script de instalação e configuração do SARG"
echo " Autor: Pedro Possari"
echo "----------------------------------------"

# Atualizar repositórios
sudo apt update

# Instalar SARG e Apache2
echo "Instalando sarg e apache2..."
sudo apt install -y sarg apache2

# Configurar o SARG
echo "Configurando o sarg.conf..."

sudo sed -i 's|^access_log .*|access_log /var/log/squid/access.log|' /etc/sarg/sarg.conf
sudo sed -i 's|^output_dir .*|output_dir /var/www/html/sarg|' /etc/sarg/sarg.conf
sudo sed -i 's|^language .*|language pt|' /etc/sarg/sarg.conf
sudo sed -i 's|^date_format .*|date_format dd/mm/yyyy|' /etc/sarg/sarg.conf

# Criar diretório de relatórios e ajustar permissões
echo "Criando diretório de relatórios em /var/www/html/sarg..."
sudo mkdir -p /var/www/html/sarg
sudo chown -R www-data:www-data /var/www/html/sarg

# Gerar relatório inicial
echo "Gerando relatório inicial..."
sudo sarg

# Configurar cron job para gerar relatório todo dia às 1h
echo "Configurando cron para gerar relatório diariamente às 1h..."
(crontab -l 2>/dev/null; echo "0 1 * * * /usr/bin/sarg") | crontab -

echo "-----------------------------------------------------"
echo "Instalação e configuração do SARG concluída!"
echo "Acesse o relatório no navegador: http://<IP_DO_SERVIDOR>/sarg/"
echo "-----------------------------------------------------"
