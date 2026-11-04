# Feuille de route

## 0.1 : la base (en cours)

- [x] Paquet `ocmintux` : occitan avec repli en français (aussi dans la session Cinnamon), clavier occitan, mises à jour automatiques de Mint, nom du système, fond d'écran et écran de connexion
- [x] Compte des élèves sans mot de passe, sans droits, écran jamais verrouillé ; Firefox filtré (DNS4EU) et verrouillé pour lui
- [x] Paquet `ocmintux-escola` : logiciels éducatifs du CP au CM2
- [x] ISO à partir de l'ISO officielle de Mint 22.3 Cinnamon : session d'essai et installateur en occitan, menus de démarrage traduits, français conservé après l'installation
- [x] ISO de déploiement : installation sans un clic, compte des enseignants, nom de PC `ocmintux-xxxx`
- [x] Essai en machine virtuelle (UEFI, 2026-11-04) : installation automatique en occitan en ~8 min, message « retirer la clé » visible, extinction, premier démarrage : comptes Regent (administrateur) et Escolans (sans mot de passe), session des élèves en occitan avec repli en français, fond OcMintux
- [ ] Essai en machine virtuelle de la session d'essai (« Ensajar ») et du démarrage BIOS
- [ ] Essai sur un vrai PC : iMac 21,5" mi-2011 de l'école (voir le guide des bénévoles) ; frappe au clavier occitan ; GCompris en français
- [x] Réglage `CLAVIER=mac` : disposition « Occitan (Macintosh) » (fr(mac) + lettres occitanes sur Option de droite), inscrite dans la liste des dispositions de XKB pour Cinnamon ; vérifié en VM (frappe dans Xed, écran de connexion)
- [ ] Vérifier `CLAVIER=mac` avec un vrai clavier Apple (touches @ et <, Option de droite)
- [ ] Publier le dépôt GitHub, puis le dépôt apt (avant tout déploiement : sans lui, `apt update` signale une erreur)

## 0.2 : finitions

- [ ] Diaporama de l'installateur : déjà en occitan chez Mint (vu en VM) ; y présenter OcMintux et les Calandretas
- [ ] Logo OcMintux dans le menu Cinnamon et au démarrage (Plymouth)
- [ ] Compte des élèves remis à neuf chaque jour (en gardant leurs documents) ?
- [ ] Raccourcis des logiciels éducatifs sur le bureau des élèves, menu rangé par matière
- [ ] Catalogues béarnais pour Cinnamon et Nemo (base : Occitux)
- [ ] Choix de la Calandreta à l'installation (nom des PC)

## Linux Mint 23 (prévu pour Noël 2026)

Mint 23 passe à Ubuntu 26.04 et **remplace l'installateur Ubiquity par celui de LMDE** : l'installation automatique (preseed Ubiquity) sera à refaire. OcMintux reste sur Mint 22.3 (suivie jusqu'en 2029) tant que ce n'est pas fait.
