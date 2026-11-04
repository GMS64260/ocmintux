VERSION := $(shell sed -n 's/^Version: //p' paquet/ocmintux/DEBIAN/control)
DEB     := construction/ocmintux_$(VERSION)_all.deb
ESCOLA_VERSION := $(shell sed -n 's/^Version: //p' paquet/ocmintux-escola/DEBIAN/control)
ESCOLA  := construction/ocmintux-escola_$(ESCOLA_VERSION)_all.deb
SCRIPTS := paquet/ocmintux/usr/sbin/ocmintux-config paquet/ocmintux/usr/share/ocmintux/session-eleves.sh \
           paquet/ocmintux/DEBIAN/postinst paquet/ocmintux/DEBIAN/prerm paquet/ocmintux/DEBIAN/postrm \
           construire/construire-iso.sh construire/essayer-vm.sh construire/depot-apt.sh \
           construire/preseed/choisir-disque.sh construire/preseed/apres-installation.sh

# Catalogues béarnais : traductions/gascon/<domaine>.po → <domaine>.mo, dans
# /usr/share/locale/oc@gascon (LANGUE=bearnes : LANGUAGE=oc_FR@gascon:oc:fr).
PO      := $(wildcard traductions/gascon/*.po)
RACINE  := construction/racine
CATALOGUES := $(RACINE)/usr/share/locale/oc@gascon/LC_MESSAGES

.PHONY: paquets iso deploiement verifier propre

paquets: $(DEB) $(ESCOLA)

$(DEB): $(shell find paquet/ocmintux -type f) $(PO) identite/ocmintux.svg identite/fons.svg depot/ocmintux-apt.asc
	rm -rf $(RACINE)
	mkdir -p $(RACINE)
	cp -a paquet/ocmintux/. $(RACINE)/
	chmod 0755 $(RACINE)/usr/sbin/ocmintux-config $(RACINE)/usr/share/ocmintux/session-eleves.sh \
	           $(RACINE)/DEBIAN/postinst $(RACINE)/DEBIAN/prerm $(RACINE)/DEBIAN/postrm
	mkdir -p $(RACINE)/usr/share/ocmintux/identite $(RACINE)/usr/share/backgrounds/ocmintux \
	         $(RACINE)/usr/share/keyrings $(RACINE)/usr/share/pixmaps
	cp identite/ocmintux.svg $(RACINE)/usr/share/ocmintux/identite/
	rsvg-convert -w 256 -h 256 identite/ocmintux.svg -o $(RACINE)/usr/share/ocmintux/identite/escolans.png
	rsvg-convert -w 128 -h 128 identite/ocmintux.svg -o $(RACINE)/usr/share/pixmaps/ocmintux.png
	rsvg-convert -w 1920 -h 1080 identite/fons.svg -o $(RACINE)/usr/share/backgrounds/ocmintux/ocmintux.png
	gpg --batch --yes --dearmor -o $(RACINE)/usr/share/keyrings/ocmintux.gpg depot/ocmintux-apt.asc
	mkdir -p $(CATALOGUES)
	for po in $(PO); do \
		msgfmt --check -o $(CATALOGUES)/$$(basename $$po .po).mo $$po || exit 1; \
	done
	dpkg-deb --root-owner-group -Zxz --build $(RACINE) $@

$(ESCOLA): paquet/ocmintux-escola/DEBIAN/control
	mkdir -p construction
	dpkg-deb --root-owner-group -Zxz --build paquet/ocmintux-escola $@

# make iso ISO=/chemin/linuxmint-22.3-cinnamon-64bit.iso
iso: paquets
	@test -n "$(ISO)" || { echo "usage : make iso ISO=/chemin/vers/linuxmint-22.3-cinnamon-64bit.iso"; exit 1; }
	sudo ./construire/construire-iso.sh "$(ISO)" construction/ocmintux-$(VERSION).iso $(DEB) $(ESCOLA)

# ISO de déploiement : installation sans un clic, EFFACE LE DISQUE du PC.
# make deploiement ISO=... : le mot de passe du compte des enseignants est demandé.
deploiement: paquets
	@test -n "$(ISO)" || { echo "usage : make deploiement ISO=/chemin/vers/linuxmint.iso"; exit 1; }
	sudo OCMINTUX_INSTALLATION=automatique \
	    ./construire/construire-iso.sh "$(ISO)" construction/ocmintux-$(VERSION)-deploiement.iso $(DEB) $(ESCOLA)

# Disposition occitane pour clavier Apple : doit se compiler avec xkbcomp.
XKB_OCMINTUX := paquet/ocmintux/usr/share/X11/xkb
verifier:
	shellcheck $(SCRIPTS)
	for po in $(PO); do msgfmt --check -o /dev/null $$po || exit 1; done
	printf 'xkb_keymap { xkb_keycodes { include "evdev+aliases(azerty)" }; xkb_types { include "complete" }; xkb_compat { include "complete" }; xkb_symbols { include "pc+ocmintux(mac)+inet(evdev)" }; };' \
	    | xkbcomp -w0 -I$(XKB_OCMINTUX) -I/usr/share/X11/xkb - -xkb -o - | grep -q 'ograve'

propre:
	rm -rf construction
