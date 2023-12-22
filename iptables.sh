#!/bin/bash

#Vérifie si UFW est installé
UFW_Installed=$(apt list ufw --installed | grep ufw -c)

#Désinstalle UFW si installé
if [ $UFW_Installed -eq 1 ]; then
    echo "Désinstallation de UFW..."
    systemctl disable ufw
    apt autoremove ufw
    #Suppression des règles relatives à UFW dans iptables
    for ufw in `iptables -L |grep ufw|awk '{ print $2 }'`; do iptables -F $ufw; done
    for ufw in `iptables -L |grep ufw|awk '{ print $2 }'`; do iptables -X $ufw; done
else
    echo "UFW n'est pas installé"
fi

#Définition des politiques par défaut à DROP
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

#Autorisation de l'ensemble du traffic sur la boucle locale
#Nécessaire avec certaines applications telles que resolv(DNS) ou mysql
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

#Autorisation en entrée et en sortie des connexions déjà établies
#Implicitement, une connexion établie signifie que l'établissement de la connexion initiale a été autorisée
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

#Autorisation en sortie des requêtes DNS (Nécessaire pour la navigation web)
iptables -A OUTPUT -p udp -m udp --dport 53 -m state --state NEW -j ACCEPT

#Autorisation en sortie des requêtes HTTP/HTTPS pour la navigation web
iptables -A OUTPUT -p tcp -m multiport --dports 80,443 -m state --state NEW -j ACCEPT

#Autorisation en sortie des requêtes NTP pour la synchronisation de l'horloge
iptables -A OUTPUT -p udp -m udp --dport 123 -m state --state NEW -j ACCEPT

#Autorisation en sortie des requêtes ICMP (ping)
iptables -A OUTPUT -p icmp -j ACCEPT

#Autoriser et journaliser les requêtes ICMP entrantes (ping)
iptables -A INPUT -p icmp -j LOG --log-prefix "ICMP_IN: " --log-level 7
iptables -A INPUT -p icmp -j ACCEPT

