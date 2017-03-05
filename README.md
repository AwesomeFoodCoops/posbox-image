# posbox-image

Script de construction d'image pour la posbox personnalisé pour La Louve :
* clavier en français
* activation du compte root
* Module pour TEP ingénico : hw_tellium_payment_terminal
* Module pour monnayeur cashlogy : hw_cashlogy
* Suppression du mode de fonctionnement en RAM (ramdisk) => en test. Pratique mais peu poser problème si les logs sont trop importants
* Intégration d'un reverse proxy Apache permettant de passer la totalisé du serveur en HTTPS sans exclure le 

Étapes d'installation :
1) Exécuter le script posbox_create_image.sh
2) Copier l'image sur une SDCard 
3) Se connecter au raspberry, changer les password des comptes root et pi et relever l'adresse MAC
4) Fixer l'adresse Mac dans le serveur DHCP
5) Paramétrer l'url du proxy dans l'objet pos.config (bien mettre httpS://<ip_posbox>)
6) Se connecter à https://<ip_posbox>/hw_proxy/status depuis le navigateur de la caisse et ajouter l'exception pour le certificat
7) Lancer une session de caisse
