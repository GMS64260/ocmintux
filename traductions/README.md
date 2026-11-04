# Traductions d'OcMintux

Cinnamon, Nemo et les outils de Linux Mint ont déjà une traduction occitane
(paquets de Mint et `language-pack-oc`) : OcMintux ne la refait pas.

- `ocmintux.csv` : textes propres à OcMintux (menus de démarrage, message de
  fin d'installation, noms des comptes), colonnes `clau;frances;occitan;bearnes`.
  Lus par `construire/construire-iso.sh`.
- `gascon/*.po` : catalogues béarnais, installés dans
  `/usr/share/locale/oc@gascon` et utilisés avec `LANGUE=bearnes`. Le premier,
  `tuxpaint.po`, vient d'[Occitux](https://github.com/GMS64260/occitux)
  (`traductions/gascon/`), où se trouvent aussi le glossaire, le corpus et les
  outils de vérification : les reprendre de là plutôt que de les recopier.
- `incertituds.md` : formes à faire relire.

Règles reprises d'Occitux : forme impersonnelle et actions à l'infinitif,
formes attestées (Lo Congrès, Dicod'Òc), incertitudes consignées.
