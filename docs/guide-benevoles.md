# Guide des bénévoles : installer OcMintux sur les PC de l'école

## Ce qu'il faut

- Une clé USB de 8 Go au moins (elle sera effacée).
- L'ISO de déploiement d'OcMintux, construite avec le mot de passe du compte des enseignants (`make deploiement`), et le mot de passe noté dans le coffre de l'école, pas sur le PC.
- [Balena Etcher](https://etcher.balena.io/) ou l'outil « Créateur de clé USB » de Linux Mint pour écrire l'ISO sur la clé.

## Installer un PC

> **L'installation automatique efface tout le disque du PC**, sans rien demander.

1. Brancher la clé, allumer le PC et ouvrir le menu de démarrage (touche F12, F9, F11 ou Échap selon la marque).
2. Choisir la clé USB. Le menu d'OcMintux s'affiche : sans rien toucher, l'installation commence au bout de 20 secondes.
3. Attendre (15 à 30 minutes). À la fin, l'écran demande de **retirer la clé, puis d'appuyer sur Entrée** : le PC s'éteint.
4. Rallumer : l'écran de connexion propose **Escolans** (les élèves, sans mot de passe) et **Regent** (les enseignants, avec le mot de passe).

Pour essayer OcMintux sans rien effacer, choisir « Ensajar OcMintux » dans le menu de la clé.

## Si le PC plante au démarrage

Sur un PC reconditionné, une barrette de mémoire défectueuse fait souvent planter le démarrage : dans le menu de la clé, « Testar la memòria ».

## Après l'installation

Les mises à jour s'installent toutes seules une fois par jour quand le PC est connecté à Internet. Pour changer un réglage (langue, clavier, filtrage des élèves) : se connecter en Regent, puis voir [Changer un réglage](../README.md#changer-un-réglage).

## iMac 21,5" mi-2011

OcMintux doit tourner sur ces iMac (Core i5 quatre cœurs, Radeon HD 6750M/6770M avec le pilote libre `radeon`, Wi-Fi Atheros) ; pas encore essayé sur l'un d'eux.

- **Démarrer sur la clé** : maintenir la touche **Alt (Option)** à l'allumage, puis choisir « EFI Boot ».
- **ISO pour iMac** : la construire avec `OCMINTUX_CLAVIER=mac make deploiement ISO=...`. Les PC installés ont la disposition « Occitan (Macintosh) » : symboles du clavier Apple à leur place, lettres occitanes avec la touche **Option (alt) de droite** : Option+a → á, Option+i → í, Option+o → ó, Option+p → ò, Option+u → ú (avec Maj : majuscules), Option+^ → œ. Sur un PC déjà installé : `CLAVIER=mac` dans `/etc/ocmintux/ocmintux.conf`, puis `sudo ocmintux-config`.
- **Clavier pour l'installation** : brancher un **clavier USB**. Le clavier sans fil d'Apple n'est pas reconnu par Linux tant qu'il n'est pas appairé : impossible d'appuyer sur Entrée à la fin de l'installation (à défaut, retirer la clé et éteindre avec le bouton).
- **D'abord essayer** : sur le premier iMac, « Ensajar OcMintux » (rien n'est effacé) pour vérifier écran, Wi-Fi et son.
- **Écran noir ou brouillé** : la carte graphique AMD de ces iMac tombe souvent en panne (panne matérielle). Essayer « Ensajar OcMintux (mòde de compatibilitat) ». Si l'image reste brouillée, le PC n'est pas à garder.
- **Mémoire** : 4 Go suffisent, 8 Go sont plus confortables (barrettes DDR3 SO-DIMM 1333 MHz, trappe sous l'écran).
- **Disque** : le disque dur d'origine ralentit tout. Le remplacer par un SSD demande de démonter la vitre et l'écran, et un adaptateur pour le capteur de température d'Apple (sinon les ventilateurs tournent à fond).
