#!/bin/sh
# session-eleves.sh : réglages de la session Cinnamon du compte des élèves,
# lancés à chaque ouverture de session (/etc/xdg/autostart). Ne fait rien pour
# les autres comptes.
#
# Les élèves se connectent sans mot de passe : un écran verrouillé ne
# pourrait plus être rouvert. On empêche donc tout verrouillage.
COMPTE_ELEVES=oui
ELEVES_IDENTIFIANT=escolans
# shellcheck source=/dev/null
[ -r /etc/ocmintux/ocmintux.conf ] && . /etc/ocmintux/ocmintux.conf
[ "$COMPTE_ELEVES" = oui ] || exit 0
[ "$(id -un)" = "$ELEVES_IDENTIFIANT" ] || exit 0
command -v gsettings >/dev/null || exit 0

gsettings set org.cinnamon.desktop.screensaver lock-enabled false
gsettings set org.cinnamon.desktop.lockdown disable-lock-screen true
gsettings set org.cinnamon.desktop.lockdown disable-user-switching false
gsettings set org.cinnamon.settings-daemon.plugins.power lock-on-suspend false 2>/dev/null || true
