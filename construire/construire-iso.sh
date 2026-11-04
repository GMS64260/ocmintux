#!/bin/bash
# construire-iso.sh : fabrique l'ISO OcMintux à partir de l'ISO officielle de
# Linux Mint Cinnamon.
#
#   sudo ./construire/construire-iso.sh <linuxmint.iso> <sortie.iso> <paquet.deb>...
#
# Les paquets sont ceux d'OcMintux (make paquets) : ocmintux et ocmintux-escola.
#
# OCMINTUX_LANGUE=oc|bearnes|fr : langue par défaut des PC installés depuis
#   cette ISO, de la session d'essai et des menus de démarrage (par défaut : oc).
# OCMINTUX_CLAVIER=oci|azerty|mac : clavier par défaut (par défaut : oci ;
#   mac pour les claviers Apple, par exemple des iMac).
# OCMINTUX_INSTALLATION=automatique : ISO de déploiement. Sans rien toucher,
#   le PC démarré sur la clé installe OcMintux tout seul après 20 secondes,
#   EN EFFAÇANT TOUT SON DISQUE, puis s'éteint. Le compte des enseignants
#   (« regent ») est créé avec le mot de passe de OCMINTUX_SENHAL, demandé
#   s'il n'est pas donné ; seule son empreinte va sur l'ISO.
#   Sans cette variable, pas d'installation automatique : « Essayer » et
#   « Installer » (l'installateur pose ses questions, dont le compte).
#
# On ouvre le système de l'ISO (casper/filesystem.squashfs), on y installe les
# paquets, on le referme, et xorriso recopie l'ISO d'origine en ne remplaçant
# que les fichiers modifiés : le démarrage BIOS et UEFI de Mint est conservé.
set -euo pipefail

ICI=$(cd "$(dirname "$0")" && pwd)
SOURCES="$ICI/sources-mint.txt"
PRESEED="$ICI/preseed"
TEXTES="$ICI/../traductions/ocmintux.csv"

die() { echo "construire-iso : $*" >&2; exit 1; }

[ $# -ge 3 ] || die "usage : sudo $0 <linuxmint.iso> <sortie.iso> <paquet.deb>..."
ISO=$(realpath "$1")
SORTIE=$(realpath -m "$2")
shift 2
DEBS=()
for deb in "$@"; do DEBS+=("$(realpath "$deb")"); done

LANGUE=${OCMINTUX_LANGUE:-oc}
case "$LANGUE" in
    bearnes|oc|fr) ;;
    *) die "OCMINTUX_LANGUE=$LANGUE inconnue (oc, bearnes ou fr)" ;;
esac
INSTALLATION=${OCMINTUX_INSTALLATION:-menu}
case "$INSTALLATION" in
    menu|automatique) ;;
    *) die "OCMINTUX_INSTALLATION=$INSTALLATION inconnue (menu ou automatique)" ;;
esac
case "$LANGUE" in
    fr) LOCALE=fr_FR.UTF-8 ;;
    *)  LOCALE=oc_FR.UTF-8 ;;
esac
CLAVIER=${OCMINTUX_CLAVIER:-oci}
# Session d'essai et installateur : dispositions connues de Mint (fr(mac) pour
# un clavier Apple) ; le PC installé reçoit celle d'OcMintux au premier
# démarrage (ocmintux-config).
case "$CLAVIER" in
    oci)    VARIANTE_INSTALLATEUR=oci ;;
    azerty) VARIANTE_INSTALLATEUR= ;;
    mac)    VARIANTE_INSTALLATEUR=mac ;;
    *) die "OCMINTUX_CLAVIER=$CLAVIER inconnu (oci, azerty ou mac)" ;;
esac

# Texte d'une clé de traductions/ocmintux.csv (clau;frances;occitan;bearnes)
# dans la langue de l'ISO, ou le texte français donné en second argument.
texte() {
    local cle=$1 francais=$2 colonne traduit=
    case "$LANGUE" in bearnes) colonne=bearnes ;; oc) colonne=occitan ;; *) colonne= ;; esac
    if [ -n "$colonne" ] && [ -f "$TEXTES" ]; then
        traduit=$(awk -F';' -v c="$cle" -v col="$colonne" '
            NR == 1 { for (i = 1; i <= NF; i++) if ($i == col) n = i; next }
            $1 == c && n { print $n }' "$TEXTES")
    fi
    echo "${traduit:-$francais}"
}
# isolinux n'affiche pas les lettres accentuées : on les remplace.
sans_accents() { echo "$1" | iconv -f UTF-8 -t ASCII//TRANSLIT | tr -d '^`"~'; }

TITRE=$(texte demarrage.titre "Bienvenue sur OcMintux")
ESSAYER=$(texte demarrage.essayer "Essayer OcMintux")
ESSAYER_COMPAT=$(texte demarrage.essayer_compat "Essayer OcMintux (mode de compatibilité)")
INSTALLER=$(texte demarrage.installer "Installer OcMintux")
INSTALLER_AUTO=$(texte demarrage.installer_auto "Installer OcMintux automatiquement (efface tout le disque)")
OEM=$(texte demarrage.oem "Installation pour les fabricants (OEM)")
MEMOIRE=$(texte demarrage.memoire "Tester la mémoire")
VOLUME_SUIVANT=$(texte demarrage.volume_suivant "Démarrer sur le disque suivant")
MICROLOGICIEL=$(texte demarrage.micrologiciel "Réglages du micrologiciel UEFI")
DISQUE_LOCAL=$(texte demarrage.disque_local "Démarrer sur le disque dur")
MATERIEL=$(texte demarrage.materiel "Détection du matériel")
AVERTISSEMENT=$(texte demarrage.avertissement_auto "ATTENTION : dans 20 secondes, OcMintux s'installe tout seul et efface tout le disque de ce PC. Pour l'éviter, retirez la clé et redémarrez.")
REGENT=$(texte compte.enseignants "Enseignant")

[ "$(id -u)" -eq 0 ] || die "à lancer avec sudo (montages et chroot)"
[ -f "$ISO" ] || die "ISO introuvable : $ISO"
for deb in "${DEBS[@]}"; do [ -f "$deb" ] || die "paquet introuvable : $deb"; done
for f in ocmintux.seed choisir-disque.sh apres-installation.sh; do
    [ -f "$PRESEED/$f" ] || die "fichier manquant : $PRESEED/$f"
done
for outil in xorriso unsquashfs mksquashfs sha256sum md5sum iconv openssl; do
    command -v "$outil" >/dev/null || die "outil manquant : $outil (sudo apt install xorriso squashfs-tools openssl)"
done

# Mot de passe du compte des enseignants (ISO de déploiement seulement).
EMPREINTE=
if [ "$INSTALLATION" = automatique ]; then
    SENHAL=${OCMINTUX_SENHAL:-}
    if [ -z "$SENHAL" ]; then
        [ -t 0 ] || die "OCMINTUX_SENHAL vide : mot de passe du compte des enseignants à donner"
        read -rsp "Mot de passe du compte des enseignants (regent) : " SENHAL; echo
        read -rsp "Encore une fois : " confirmation; echo
        [ "$SENHAL" = "$confirmation" ] || die "les deux mots de passe diffèrent"
    fi
    [ ${#SENHAL} -ge 6 ] || die "mot de passe trop court (6 caractères au moins)"
    EMPREINTE=$(printf '%s' "$SENHAL" | openssl passwd -6 -stdin)
    unset SENHAL confirmation
fi

# 1. L'ISO doit être une version de Mint connue et intacte.
nom=$(basename "$ISO")
attendu=$(awk -v n="$nom" '$1 == n { print $2 }' "$SOURCES")
[ -n "$attendu" ] || die "$nom n'est pas dans $SOURCES : ajouter sa somme SHA-256 après l'avoir vérifiée"
echo "Vérification de $nom..."
echo "$attendu  $ISO" | sha256sum --check --status || die "somme SHA-256 incorrecte pour $nom"

TRAVAIL=$(mktemp -d "${TMPDIR:-/var/tmp}/ocmintux.XXXXXX")
RACINE="$TRAVAIL/racine"
MONTAGES=()

# Arrête les processus restés dans le système, sinon /dev/pts refuse de se
# démonter.
arreter_processus_chroot() {
    local signal p
    for signal in TERM KILL; do
        for p in /proc/[0-9]*; do
            if [ "$(readlink "$p/root" 2>/dev/null)" = "$RACINE" ]; then
                kill "-$signal" "${p#/proc/}" 2>/dev/null || true
            fi
        done
        sleep 2
    done
    return 0
}

# shellcheck disable=SC2317 # appelée par le trap EXIT
nettoyer() {
    local i
    arreter_processus_chroot
    for ((i = ${#MONTAGES[@]} - 1; i >= 0; i--)); do
        umount -l "${MONTAGES[i]}" 2>/dev/null || true
    done
    rm -rf "$TRAVAIL"
}
trap nettoyer EXIT

# Lit un fichier de l'ISO dans le dossier de travail ; échoue si absent.
extraire() {
    xorriso -osirrox on -indev "$ISO" -extract "$1" "$2" >/dev/null 2>&1 || return 1
    chmod u+w "$2"
}

# 2. Extraction du système.
echo "Extraction du système (plusieurs minutes)..."
extraire /casper/filesystem.squashfs "$TRAVAIL/filesystem.squashfs" \
    || die "pas de /casper/filesystem.squashfs dans l'ISO : est-ce bien une ISO de Linux Mint ?"
extraire /md5sum.txt "$TRAVAIL/md5sum.txt" || true
extraire /casper/filesystem.manifest-remove "$TRAVAIL/filesystem.manifest-remove" || true
COMPRESSION=$(unsquashfs -s "$TRAVAIL/filesystem.squashfs" | awk '/^Compression/ { print $2 }')
unsquashfs -q -d "$RACINE" "$TRAVAIL/filesystem.squashfs"
rm "$TRAVAIL/filesystem.squashfs"

# 3. Installation des paquets dans le système, sans lancer de service.
for m in dev dev/pts proc sys run; do
    mount --bind "/$m" "$RACINE/$m"
    MONTAGES+=("$RACINE/$m")
done
mv "$RACINE/etc/resolv.conf" "$TRAVAIL/resolv.conf.origine"
cp -L /etc/resolv.conf "$RACINE/etc/resolv.conf"
printf '#!/bin/sh\nexit 101\n' > "$RACINE/usr/sbin/policy-rc.d"
chmod 755 "$RACINE/usr/sbin/policy-rc.d"
mkdir -p "$RACINE/tmp/ocmintux"
cp "${DEBS[@]}" "$RACINE/tmp/ocmintux/"

echo "Installation de $(for d in "${DEBS[@]}"; do dpkg-deb -f "$d" Package Version | paste -sd' '; done | paste -sd,) dans le système..."
# OCMINTUX_CONSTRUCTION : le compte des élèves attend le premier démarrage du
# PC installé (voir appliquer_eleves dans ocmintux-config).
# Deux temps : ocmintux ajoute les dépôts de PrimTux et d'OnlyOffice, d'où
# viennent une partie des logiciels d'ocmintux-escola ; apt doit les lire
# avant d'installer celui-ci.
PREMIERS=() ESCOLA=()
for deb in "${DEBS[@]}"; do
    if [ "$(dpkg-deb -f "$deb" Package)" = ocmintux-escola ]; then
        ESCOLA+=("/tmp/ocmintux/$(basename "$deb")")
    else
        PREMIERS+=("/tmp/ocmintux/$(basename "$deb")")
    fi
done
chroot "$RACINE" /usr/bin/env DEBIAN_FRONTEND=noninteractive LC_ALL=C.UTF-8 OCMINTUX_CONSTRUCTION=1 sh -c '
    apt-get update -q &&
    apt-get install -y -q --install-recommends "$@"
' sh "${PREMIERS[@]}"
if [ ${#ESCOLA[@]} -gt 0 ]; then
    echo "Logiciels de l'école (PrimTux, OnlyOffice : plusieurs Go à télécharger)..."
    chroot "$RACINE" /usr/bin/env DEBIAN_FRONTEND=noninteractive LC_ALL=C.UTF-8 OCMINTUX_CONSTRUCTION=1 sh -c '
        apt-get update -q &&
        apt-get install -y -q --install-recommends "$@"
    ' sh "${ESCOLA[@]}"
fi
chroot "$RACINE" apt-get clean
echo "Langue par défaut : $LANGUE"
echo "Clavier par défaut : $CLAVIER"
sed -i -e "s/^LANGUE=.*/LANGUE=$LANGUE/" -e "s/^CLAVIER=.*/CLAVIER=$CLAVIER/" "$RACINE/etc/ocmintux/ocmintux.conf"
chroot "$RACINE" /usr/bin/env LC_ALL=C.UTF-8 OCMINTUX_CONSTRUCTION=1 ocmintux-config
# Un compte ordinaire dans le système copié, et l'installateur ne créerait
# pas celui des enseignants (is_system_user d'Ubiquity) : PC sans administrateur.
comptes=$(awk -F: '$3 >= 1000 && $3 < 60000 { print $1 }' "$RACINE/etc/passwd" | paste -sd' ')
[ -z "$comptes" ] || die "comptes présents dans le système de l'ISO ($comptes) : l'installateur ne créerait pas le compte des enseignants"
# Langue de la session d'essai et de l'installateur (aussi donnée au noyau).
chroot "$RACINE" /usr/bin/env LC_ALL=C.UTF-8 update-locale LANG="$LOCALE"

# Lanceur « Installer » de la session d'essai.
LANCEUR="$RACINE/usr/share/applications/ubiquity.desktop"
if [ -f "$LANCEUR" ]; then
    sed -i -e '/^Name\[oc\]=/d' \
           -e 's/^Name=.*/Name=Install OcMintux/' \
           -e 's/^Name\[fr\]=.*/Name[fr]=Installer OcMintux/' "$LANCEUR"
    sed -i "/^Name=Install OcMintux\$/a Name[oc]=$(texte demarrage.installer "Installer OcMintux")" "$LANCEUR"
fi
# Message de fin (retirer la clé), en anglais dans casper : traduit sur la clé.
RETIRER=$(texte fin.retirer_cle "Retirez la clé USB, puis appuyez sur Entrée : ")
RETIRER_REDEMARRER=$(texte fin.retirer_cle_redemarrer "Retirez la clé USB, puis redémarrez.")
if [ -f "$RACINE/usr/sbin/casper-stop" ]; then
    sed -i -e "s|^\(\s*MSG=\)\"Please remove the installation medium, then press ENTER: \"|\1\"$RETIRER\"|" \
           -e "s|^\(\s*MSG_FALLBACK=\)\"Please remove the installation medium, then reboot.\"|\1\"$RETIRER_REDEMARRER\"|" \
           "$RACINE/usr/sbin/casper-stop"
fi

rm -rf "$RACINE/tmp/ocmintux" "$RACINE/usr/sbin/policy-rc.d"
rm -f "$RACINE/etc/resolv.conf"
mv "$TRAVAIL/resolv.conf.origine" "$RACINE/etc/resolv.conf"
# shellcheck disable=SC2016 # format de dpkg-query, pas une variable du shell
chroot "$RACINE" dpkg-query -W --showformat='${Package} ${Version}\n' > "$TRAVAIL/filesystem.manifest"
arreter_processus_chroot
for ((i = ${#MONTAGES[@]} - 1; i >= 0; i--)); do umount "${MONTAGES[i]}"; done
MONTAGES=()

# 4. Fermeture du système, avec la compression d'origine.
echo "Compression du système ($COMPRESSION, plusieurs minutes)..."
du -sx --block-size=1 "$RACINE" | cut -f1 > "$TRAVAIL/filesystem.size"
mksquashfs "$RACINE" "$TRAVAIL/filesystem.squashfs" -comp "$COMPRESSION" -noappend -quiet

REMPLACER=(
    -map "$TRAVAIL/filesystem.squashfs" /casper/filesystem.squashfs
    -map "$TRAVAIL/filesystem.manifest" /casper/filesystem.manifest
    -map "$TRAVAIL/filesystem.size" /casper/filesystem.size
)

# Paquets que l'installateur retire en fin d'installation : ceux des langues
# autres que celle choisie. Le français doit rester, c'est la langue de repli
# de l'occitan (Firefox, LibreOffice, dictionnaire, traductions d'Ubuntu).
if [ -f "$TRAVAIL/filesystem.manifest-remove" ]; then
    sed -i -E '/^(language-pack(-gnome)?-fr(-base)?|(firefox|thunderbird)-locale-fr|libreoffice-(l10n|help)-fr|hunspell-fr(-classical)?|hyphen-fr|mythes-fr|wfrench)$/d' \
        "$TRAVAIL/filesystem.manifest-remove"
    REMPLACER+=(-map "$TRAVAIL/filesystem.manifest-remove" /casper/filesystem.manifest-remove)
fi

# 5. Installation automatique : réponses de l'installateur et scripts.
if [ "$INSTALLATION" = automatique ]; then
    mkdir -p "$TRAVAIL/preseed"
    cp "$PRESEED/ocmintux.seed" "$PRESEED/choisir-disque.sh" "$PRESEED/apres-installation.sh" "$TRAVAIL/preseed/"
    sed -i -e "s|^d-i debian-installer/locale string .*|d-i debian-installer/locale string $LOCALE|" \
           -e "s|^d-i passwd/user-fullname string .*|d-i passwd/user-fullname string $REGENT|" \
           -e "s|^d-i keyboard-configuration/variantcode string .*|d-i keyboard-configuration/variantcode string $VARIANTE_INSTALLATEUR|" \
           -e "s|^d-i keyboard-configuration/xkb-keymap select .*|d-i keyboard-configuration/xkb-keymap select fr${VARIANTE_INSTALLATEUR:+($VARIANTE_INSTALLATEUR)}|" \
           -e "s|^d-i passwd/user-password-crypted password .*|d-i passwd/user-password-crypted password $EMPREINTE|" \
           "$TRAVAIL/preseed/ocmintux.seed"
    for f in ocmintux.seed choisir-disque.sh apres-installation.sh; do
        REMPLACER+=(-map "$TRAVAIL/preseed/$f" "/preseed/$f")
    done
fi

# 6. Menus de démarrage UEFI (GRUB) et BIOS (isolinux), réécrits en entier :
# ceux de Mint sont courts et en anglais. On garde l'identifiant de l'ISO
# (uuid=), par lequel casper retrouve la clé.
extraire /boot/grub/grub.cfg "$TRAVAIL/grub.cfg.mint" || die "pas de /boot/grub/grub.cfg dans l'ISO"
UUID=$(grep -o 'uuid=[0-9a-f-]*' "$TRAVAIL/grub.cfg.mint" | head -n1)
[ -n "$UUID" ] || die "identifiant uuid= introuvable dans le grub.cfg de Mint"
# Langue et clavier de la session d'essai et de l'installateur.
LANGUE_NOYAU="locale=$LOCALE keyboard-configuration/layoutcode=fr keyboard-configuration/variantcode=$VARIANTE_INSTALLATEUR"
COMMUN="boot=casper $UUID username=mint hostname=ocmintux $LANGUE_NOYAU"
PARAMS_ESSAI="$COMMUN quiet splash --"
PARAMS_COMPAT="$COMMUN noapic noacpi nosplash irqpoll nomodeset --"
PARAMS_INSTALLER="$COMMUN only-ubiquity quiet splash --"
PARAMS_OEM="oem-config/enable=true only-ubiquity $COMMUN quiet splash --"
# Sans « noprompt » : à la fin, le PC demande de retirer la clé avant de
# s'éteindre, sinon il redémarrerait dessus et recommencerait l'installation.
PARAMS_AUTO="$COMMUN fsck.mode=skip file=/cdrom/preseed/ocmintux.seed only-ubiquity automatic-ubiquity quiet splash --"

{
    echo "loadfont unicode"
    echo
    echo "set color_normal=white/black"
    echo "set color_highlight=black/light-gray"
    if [ "$INSTALLATION" = automatique ]; then
        # Entrées : 0 Essayer, 1 Installer, 2 Installer automatiquement.
        echo "set default=2"
        echo "set timeout=20"
        echo "echo \"$AVERTISSEMENT\""
    fi
    for entree in "ESSAYER|$PARAMS_ESSAI|--class linuxmint" "INSTALLER|$PARAMS_INSTALLER|--class linuxmint" \
                  "AUTO|$PARAMS_AUTO|" "COMPAT|$PARAMS_COMPAT|" "OEM|$PARAMS_OEM|"; do
        IFS='|' read -r quoi params classe <<<"$entree"
        case "$quoi" in
            ESSAYER) titre=$ESSAYER ;; INSTALLER) titre=$INSTALLER ;; COMPAT) titre=$ESSAYER_COMPAT ;; OEM) titre=$OEM ;;
            AUTO) [ "$INSTALLATION" = automatique ] || continue; titre=$INSTALLER_AUTO ;;
        esac
        echo
        echo "menuentry \"$titre\" $classe {"
        [ "$quoi" = COMPAT ] || echo "	set gfxpayload=keep"
        echo "	linux	/casper/vmlinuz $params"
        echo "	initrd	/casper/initrd.lz"
        echo "}"
    done
    cat <<FIN

grub_platform
if [ "\$grub_platform" = "efi" ]; then
menuentry "$VOLUME_SUIVANT" {
	exit 1
}
menuentry "$MICROLOGICIEL" {
	fwsetup
}
menuentry "$MEMOIRE" {
	linux	/boot/memtest.efi
}
fi
FIN
} > "$TRAVAIL/grub.cfg"
# iso-scan/filename : démarrage depuis un fichier ISO (Ventoy, GRUB loopback).
# shellcheck disable=SC2016 # ${iso_path} est une variable de GRUB
sed -i '/^\s*linux\s\+\/casper\/vmlinuz /s| boot=casper | boot=casper iso-scan/filename=${iso_path} |' "$TRAVAIL/grub.cfg"
REMPLACER+=(-map "$TRAVAIL/grub.cfg" /boot/grub/grub.cfg)

if extraire /isolinux/live.cfg "$TRAVAIL/live.cfg.mint"; then
    {
        # En-tête de Mint (couleurs, dimensions), titre remplacé.
        sed -n '/^label /q; p' "$TRAVAIL/live.cfg.mint" \
            | sed "s|^menu title .*|menu title $(sans_accents "$([ "$INSTALLATION" = automatique ] && echo "$AVERTISSEMENT" || echo "$TITRE")")|"
        entree_isolinux() {
            echo "label $1"
            echo "	menu label $(sans_accents "$2")"
            [ "$1" = "$DEFAUT" ] && echo "	menu default"
            echo "	kernel /casper/vmlinuz"
            echo "	append initrd=/casper/initrd.lz $3"
            echo
        }
        DEFAUT=live
        [ "$INSTALLATION" = automatique ] && DEFAUT=installauto
        entree_isolinux live "$ESSAYER" "$PARAMS_ESSAI"
        entree_isolinux install "$INSTALLER" "$PARAMS_INSTALLER"
        [ "$INSTALLATION" = automatique ] && entree_isolinux installauto "$INSTALLER_AUTO" "$PARAMS_AUTO"
        entree_isolinux compat "$ESSAYER_COMPAT" "$PARAMS_COMPAT"
        entree_isolinux oem "$OEM" "$PARAMS_OEM"
        cat <<FIN
label hdt
	menu label $(sans_accents "$MATERIEL")
	kernel hdt.c32

label local
	menu label $(sans_accents "$DISQUE_LOCAL")
	COM32 chain.c32
	APPEND hd0

label memtest
	menu label $(sans_accents "$MEMOIRE")
	linux /boot/memtest.bin
FIN
    } > "$TRAVAIL/live.cfg"
    if [ "$INSTALLATION" = automatique ]; then
        sed -i 's/^timeout .*/timeout 200/' "$TRAVAIL/live.cfg"
    fi
    REMPLACER+=(-map "$TRAVAIL/live.cfg" /isolinux/live.cfg)
fi

# Le contrôle d'intégrité lit md5sum.txt : sommes des fichiers remplacés.
if [ -f "$TRAVAIL/md5sum.txt" ]; then
    for ((i = 0; i < ${#REMPLACER[@]}; i += 3)); do
        source_fichier=${REMPLACER[i + 1]}
        chemin=${REMPLACER[i + 2]}
        somme=$(md5sum "$source_fichier" | cut -d' ' -f1)
        if grep -q "  \.${chemin}\$" "$TRAVAIL/md5sum.txt"; then
            sed -i "s|^[0-9a-f]\{32\}  \.${chemin}\$|$somme  .${chemin}|" "$TRAVAIL/md5sum.txt"
        else
            echo "$somme  .${chemin}" >> "$TRAVAIL/md5sum.txt"
        fi
    done
    REMPLACER+=(-map "$TRAVAIL/md5sum.txt" /md5sum.txt)
fi

# 7. Nouvelle ISO : copie de l'originale, fichiers modifiés remplacés.
echo "Écriture de $SORTIE..."
rm -f "$SORTIE"
xorriso -indev "$ISO" -outdev "$SORTIE" \
    -compliance iso_9660_level=3 \
    -volid "OcMintux" \
    "${REMPLACER[@]}" \
    -boot_image any replay
(cd "$(dirname "$SORTIE")" && sha256sum "$(basename "$SORTIE")" > "$(basename "$SORTIE").sha256")

echo "Terminé : $SORTIE"
[ "$INSTALLATION" = automatique ] && echo "ISO de déploiement : tout PC démarré dessus s'installe seul et perd son disque."
exit 0
