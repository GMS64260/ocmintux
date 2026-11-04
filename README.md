# OcMintux

**Linux Mint en occitan, pour les Calandretas.**
*Linux Mint en occitan, per las Calandretas.*

OcMintux est Linux Mint Cinnamon en occitan, pour les PC des grands de l'école, du CP au CM2, et ceux des enseignants (*regents*). Il ne modifie pas Mint : il y ajoute une couche occitane, un compte pour les élèves et des réglages adaptés à une école tenue par des bénévoles.

C'est le petit frère d'[Occitux](https://github.com/GMS64260/occitux) (PrimTux en occitan), qui reste la distribution des petits : PrimTux a des sessions par âge et un menu simplifié, OcMintux donne aux grands un bureau d'ordinateur ordinaire.

Besoins : ceux de Linux Mint 22.3 : PC 64 bits, 2 Go de mémoire (4 Go recommandés), 30 Go de disque (SSD conseillé).

> **État : version 0.1, en construction.** Paquets et ISO construits à partir de Linux Mint 22.3 Cinnamon. Rien n'a encore été installé sur un vrai PC d'école. Voir la [feuille de route](docs/feuille-de-route.md).

## Ce qu'apporte OcMintux

| | |
|---|---|
| **Langue** | Interface en occitan (`oc_FR`) : Cinnamon, Nemo et les outils de Mint sont déjà traduits. Ce qui ne l'est pas s'affiche en français, pas en anglais. Option béarnais (`LANGUE=bearnes`). |
| **Élèves** | Un compte commun **Escolans** : on clique sur son nom, sans mot de passe. Pas de droits d'administration, écran jamais verrouillé, pas d'écran d'accueil de Mint ni d'icône de mises à jour. Dans Firefox : web filtré par [DNS4EU](https://www.joindns4.eu/) (protection des enfants, sans publicités), réglage verrouillé, page d'accueil Qwant Junior. |
| **Enseignants** | Le compte créé à l'installation (« regent » avec l'installation automatique) administre le PC. |
| **Logiciels** | GCompris, Tux Paint, TuxMath, Tux Typing, KTouch, KLettres, KGeography, Pysiogame, Stellarium, échecs, OpenBoard (paquet `ocmintux-escola`). Firefox et LibreOffice en occitan, dictionnaire occitan. GCompris, qui n'existe pas en occitan, reste en français au lieu de basculer en anglais. |
| **Installation** | ISO OcMintux : session d'essai et installateur en occitan. ISO de déploiement : le PC s'installe sans une question (tout le disque est effacé), nom de PC `ocmintux-xxxx`, compte des enseignants créé avec le mot de passe choisi à la construction. |
| **Clavier** | AZERTY occitan (`fr(oci)`) : les lettres occitanes en accès direct. Pour un clavier Apple (iMac) : `CLAVIER=mac`, disposition « Occitan (Macintosh) » d'OcMintux, symboles à leur place et lettres occitanes avec la touche Option de droite (Option+a á, i í, o ó, p ò, u ú). |
| **Mises à jour** | Celles du gestionnaire de mises à jour de Mint, automatiques, une fois par jour : Ubuntu, Mint et nouvelles versions d'OcMintux (dépôt apt du projet). |
| **iMac passés au SSD** | Le ventilateur du disque, qui tournait vite faute de sonde (4 100 tr/min relevés sur un iMac 2011), est réglé d'après les vraies températures (SSD, alimentation, carte graphique, processeur) : 1 200 tr/min au repos. Le Mac reprend la main au moindre doute. `ocmintux-ventilation --etat` pour voir. |
| **Identité** | Fond d'écran et écran de connexion OcMintux, nom du système (`PRETTY_NAME`), menus de démarrage de la clé. |

Tout se règle dans un seul fichier, `/etc/ocmintux/ocmintux.conf`.

## Ce qu'OcMintux ne fait pas

- **Il ne remplace pas Linux Mint.** Le système, ses outils et ses mises à jour sont ceux de Mint ; le nom technique du système (`ID=linuxmint`) ne change pas, pour que tout continue de fonctionner.
- **Le filtrage du web ne vaut que pour Firefox et le compte des élèves.** Il ne remplace pas un adulte, ni un filtrage sur le réseau de l'école.
- **Les traductions occitanes ne sont pas en gascon** : le système ne connaît qu'un seul occitan. Voir [la question de la langue](https://github.com/GMS64260/occitux/blob/main/docs/lenga.md) dans Occitux.

## Installer

**Sur un PC qui a déjà Linux Mint 22.3 Cinnamon** : télécharger les deux paquets depuis les [versions publiées](https://github.com/GMS64260/ocmintux/releases), puis :

```sh
sudo apt install ./ocmintux_*_all.deb ./ocmintux-escola_*_all.deb
```

Redémarrer le PC. Le paquet ajoute le dépôt apt d'OcMintux (`https://gms64260.github.io/ocmintux`) : les versions suivantes s'installent toutes seules.

**Sur un PC neuf ou reconditionné** : démarrer sur une clé USB faite avec l'ISO OcMintux, puis « Installar OcMintux ». **Pour plusieurs PC** : l'ISO de déploiement, voir le [guide des bénévoles](docs/guide-benevoles.md).

## Changer un réglage

```sh
sudo xed /etc/ocmintux/ocmintux.conf   # LANGUE, CLAVIER (oci, azerty, mac), MISES_A_JOUR_AUTO, compte des élèves, filtrage, VENTILATEUR_DISQUE
sudo ocmintux-config
```

Puis redémarrer le PC.

## Construire

Paquets (Debian ou Ubuntu : `dpkg-deb`, `msgfmt`, `rsvg-convert`) :

```sh
make paquets         # → construction/ocmintux_x.y.z_all.deb, ocmintux-escola_x.y.z_all.deb
make verifier        # shellcheck, catalogues
```

ISO, à partir de l'[ISO officielle de Linux Mint 22.3 Cinnamon](https://www.linuxmint.com/download.php) (somme SHA-256 vérifiée, voir `construire/sources-mint.txt`) ; il faut `xorriso`, `squashfs-tools` et une connexion (les logiciels éducatifs sont téléchargés) :

```sh
make iso ISO=~/Téléchargements/linuxmint-22.3-cinnamon-64bit.iso
make deploiement ISO=~/Téléchargements/linuxmint-22.3-cinnamon-64bit.iso   # demande le mot de passe des enseignants
OCMINTUX_LANGUE=bearnes make iso ISO=...                                   # béarnais par défaut
OCMINTUX_CLAVIER=mac make deploiement ISO=...                              # PC à clavier Apple (iMac)
```

Essai en machine virtuelle : `./construire/essayer-vm.sh construction/ocmintux-x.y.z.iso`.

## Licence

GPL-3.0 ou ultérieure. Logo et fond d'écran : dessins originaux, même licence.
