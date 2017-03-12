# posbox-image

Script de construction d'image pour la posbox personnalisé pour La Louve :
* clavier en français
* activation du compte root
* Module pour TEP ingénico : hw_tellium_payment_terminal
* Module pour monnayeur cashlogy : hw_cashlogy
* Suppression du mode de fonctionnement en RAM (ramdisk) => en test. Pratique mais peu poser problème si les logs sont trop importants
* Intégration d'un reverse proxy Apache permettant de passer la totalisé du serveur en HTTPS sans exclure le 

Étapes d'installation :

1. Exécuter le script posbox_create_image.sh
1. Copier l'image sur une SDCard 
1. Se connecter au raspberry, changer les password des comptes root et pi et relever l'adresse MAC (ou la récupérer via les baux temporaires du serveur DHCP).
1. Fixer l'adresse Mac dans le serveur DHCP
1. Paramétrer l'url du proxy dans l'objet pos.config (bien mettre httpS://<ip_posbox>) de la base Odoo
1. Se connecter à https://<ip_posbox>/hw_proxy/status depuis le navigateur de la caisse et ajouter l'exception pour le certificat
1. Lancer une session de caisse

TODO :
* FIX the Odoo systemD service : the Odoo service is currently launched by the /etc/rc.local at boot time because SystemD service crash.
* make the image in readonly (fstab ro and ramdisk) or or be sure the log file are often emptied (avoid no-space-left problem)
* change the pi and root system users password during the creating script (find them in a .gitignore file and if not ask them interactively to the image creator).
