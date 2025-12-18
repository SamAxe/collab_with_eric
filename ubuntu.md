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

    # Log analyzer and blocks ip addresses that look like they are abusing the server
    apt install fail2ban
    systemctl enable fail2ban
    systemctl start fail2ban

    # Ensures that security patches are applied regularily
    apt install unattended-upgrades
    systemctl enable unattened-upgrades
    systemctl start unattended-upgrades

    # Intrusion detection
    apt install aide
    aide --init --config /etc/aide/aide.conf
    mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db

    # Security Audit
    apt install lynis

    # Security scanner
    apt install chkrootkit

    # Exploit scanner
    apt install rkhunter

All of these services should be configured for the purpose/risk tolerance of the system, often by updating `/etc/<service>/...` configuration files.

* `systemctl enable <service>` effectively allows the service to be run and restarts the service after reboots
* `systemctl start <service>` starts the service
* `systemctl status <service>` shows the status
* `systemctl restart <service>` restart the service 

# Background/motivation

These notes presume a need for a host to be on the internet and that you might be a hobbiest more than setting up an enterprise platform.  
There are a number of risks of putting a machine on __the internet__ and these notes will attempt to capture some of risks and make some suggestions for consideration for
your trade-offs.

* Assume that the host will eventually become compromised, likely for pursposes of sending email spam, crypto mining, or becoming part of a botnet that will be used in future malicious activity.
  - I.e. there should be backups/recovery method
  - I.e. limit the compromise to the specific platform by not hosting from your house and spreading to other devices.
  - I.e. use a cloud provider, apply security patches, and take advantage of cloud provider infrastructure where it makes sense to do so.
  - I.e. don't put any information on the internet that you want to keep private.
* Limit the attack surface to compromise by limiting the number of ports/services that are open and facing the internet.  For the ports/services that are open,
  consider limiting access with some sort of authentication mechanism.
* There are network scanners that will bombard your platform contineously, usually probing for a follow up attack.
* There are network scrapers that will use what is scraped for many purposes, e.g. indexing, training LLMs, etc.
* Your cloud provider probably charges by a number of metrics including file storage, network traffic (maybe including DNS, routes, etc), and cpu usage.

# Risks

Each risk mitigation strategy will be different depending on the evaluation of each situation an individual has.  E.g. if it's no big deal to be down 
for a couple of weeks and willing to rebuild platform from backups, then can focus on that and maybe less on other parts.  These notes will assume some
simple middle ground that attempts to minimize the attack surface by limiting the services and hardening the services, but this can vary a lot by what the
purpose of the platform is.  An email server with a web interface may only need to enable https access and a port for receiving mail.  An email server
that allows access to 3rd party clients or the ability to send/relay mail will need to open up more remote access.

Programs that run in containers can be particicularily tricky to ensure they are not exposing additional services/ports unexpectedly (which is one of the reasons
why these notes are being written down, in that I don't know all the tricky cases yet).

* Monetary -- cloud providers charge by cpu, network, and filesystem utilization
* Downtime -- Resource is not available to your audience
* System administration -- monitoring, backups, restoring from backups, applying security packages and package updates
* Legal -- I'm sure it varies from situation to situation and jurisdiction and suggest speaking with legal counsel if this applies to your situation
* Reputation -- domain/ip can get added to banned or block lists.

## docker

I think the simple approach is:
  * Bind to localhost and then use a reverse proxy to expose the port...
    E.g. don't do `docker run -p 80:80 nginx`, do `docker run -p 127.0.0.1:80:80 nginx`
  * Beyond that, then there is quite a lift that involves understanding ip tables and how Docker iteracts with them.  In short, docker will bypass
    simple firewalls, such as the `ufw` setup described earlier and may expose docker ports on the host.
