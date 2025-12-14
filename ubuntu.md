---
title:          notes for setting up and running a droplet
subtitle:
author:
keywords:
created:        2025/11/16 08:50
last modified:  2025/12/13 14:43
---

# Ubuntu droplet

    apt update
    apt upgrade
    apt install ufw   # firewall
    apt allow from xx.xx.xx.xx/xx to any port 22   # allow ssh from your subnet of addresses
    ufw enable ufw
    systemctl enable ufw
    systemctl start ufw

    apt install fail2ban
    apt install unattended-upgrades
    systemctl enable unattened-upgrades
    systemctl start unattended-upgrades

    # Intrusion detection
    apt install aide
    aide --init --config /etc/aide/aide.conf
    mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db

    # Security Audit
    apt install lynis

    apt install chkrootkit
    apt install rkhunter
