#!/bin/bash
# depot-apt.sh : construit le dépôt apt d'OcMintux (fichiers statiques, servis
# par GitHub Pages) à partir des paquets .deb donnés, et le signe.
#
#   ./construire/depot-apt.sh <dossier-du-depot> <ocmintux_x.y.z_all.deb>...
#
# Le dossier peut déjà contenir un dépôt (branche gh-pages) : les anciens
# paquets de pool/ sont gardés, les index sont refaits. La clé de signature
# est celle du trousseau GNUPGHOME courant (en CI : secret OCMINTUX_CLE_APT).
#
# Sur un PC : deb [signed-by=/usr/share/keyrings/ocmintux.gpg]
#             https://gms64260.github.io/ocmintux ocmintux main
set -euo pipefail

[ $# -ge 2 ] || { echo "usage : $0 <dossier> <paquet.deb>..." >&2; exit 1; }
DEPOT=$(realpath -m "$1"); shift
ICI=$(cd "$(dirname "$0")" && pwd)
for outil in apt-ftparchive gpg; do
    command -v "$outil" >/dev/null || { echo "outil manquant : $outil (apt-utils, gnupg)" >&2; exit 1; }
done

mkdir -p "$DEPOT/pool/main/o/ocmintux" "$DEPOT/dists/ocmintux/main/binary-amd64"
for deb in "$@"; do cp -f "$deb" "$DEPOT/pool/main/o/ocmintux/"; done
cp -f "$ICI/../depot/ocmintux-apt.asc" "$DEPOT/ocmintux-apt.asc"
gpg --batch --yes --dearmor -o "$DEPOT/ocmintux.gpg" "$DEPOT/ocmintux-apt.asc"
cp -f "$ICI/../paquet/ocmintux/etc/apt/sources.list.d/ocmintux.sources" "$DEPOT/ocmintux.sources"

cd "$DEPOT"
# Un seul index (amd64) : le paquet est « Architecture: all ».
apt-ftparchive --arch amd64 packages pool > dists/ocmintux/main/binary-amd64/Packages
gzip -9 -k -f dists/ocmintux/main/binary-amd64/Packages
apt-ftparchive \
    -o APT::FTPArchive::Release::Origin=OcMintux \
    -o APT::FTPArchive::Release::Label=OcMintux \
    -o APT::FTPArchive::Release::Suite=ocmintux \
    -o APT::FTPArchive::Release::Codename=ocmintux \
    -o APT::FTPArchive::Release::Architectures=amd64 \
    -o APT::FTPArchive::Release::Components=main \
    -o "APT::FTPArchive::Release::Description=OcMintux : Linux Mint en occitan pour les Calandretas" \
    release dists/ocmintux > dists/ocmintux/Release
gpg --batch --yes --armor --detach-sign -o dists/ocmintux/Release.gpg dists/ocmintux/Release
gpg --batch --yes --clearsign -o dists/ocmintux/InRelease dists/ocmintux/Release

# Page d'accueil du dépôt.
cat > index.html <<'FIN'
<!doctype html><meta charset="utf-8"><title>Dépôt apt OcMintux</title>
<h1>Dépôt apt d'OcMintux</h1>
<p>Les PC OcMintux reçoivent les mises à jour d'ici tout seuls. Pour un Linux Mint 22 :</p>
<pre>sudo curl -fsSL https://gms64260.github.io/ocmintux/ocmintux.gpg -o /usr/share/keyrings/ocmintux.gpg
sudo curl -fsSL https://gms64260.github.io/ocmintux/ocmintux.sources -o /etc/apt/sources.list.d/ocmintux.sources
sudo apt update &amp;&amp; sudo apt install ocmintux</pre>
<p><a href="https://github.com/GMS64260/ocmintux">Projet OcMintux</a> · <a href="pool/main/o/ocmintux/">paquets</a></p>
FIN
touch .nojekyll
echo "Dépôt prêt dans $DEPOT :"
grep -E '^(Package|Version|Filename):' dists/ocmintux/main/binary-amd64/Packages
