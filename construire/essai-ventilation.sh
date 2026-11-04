#!/bin/bash
# essai-ventilation.sh : essaie ocmintux-ventilation sur une fausse puce SMC
# d'iMac (dossiers à la place de /sys), sans Mac. Lancé par la CI.
set -euo pipefail
ICI=$(cd "$(dirname "$0")" && pwd)
V="$ICI/../paquet/ocmintux/usr/sbin/ocmintux-ventilation"
T=$(mktemp -d); trap 'rm -r "$T"' EXIT
m=$T/smc; h=$T/hwmon
mkdir -p "$m" "$h/hwmon0" "$h/hwmon1"
# iMac12,1 passé au SSD : sonde du disque absente (9 °C), ventilateur à 4 100 tr/min.
printf 'HDD \n' > "$m/fan3_label"; echo 4100 > "$m/fan3_input"; echo 1100 > "$m/fan3_min"
echo 6300 > "$m/fan3_max"; echo 0 > "$m/fan3_manual"; echo 0 > "$m/fan3_output"
printf 'Tp2H\n' > "$m/temp1_label"; echo 51000 > "$m/temp1_input"
printf 'TG0D\n' > "$m/temp2_label"; echo 40000 > "$m/temp2_input"
printf 'TH0O\n' > "$m/temp3_label"; echo 9000 > "$m/temp3_input"
echo drivetemp > "$h/hwmon0/name"; echo 26000 > "$h/hwmon0/temp1_input"
echo coretemp > "$h/hwmon1/name"; echo 37000 > "$h/hwmon1/temp1_input"
lancer() { OCMINTUX_CONF=/dev/null OCMINTUX_SMC=$m OCMINTUX_HWMON=$h VENTILATEUR_DISQUE=ssd "$V" "$@"; }
attendu() { [ "$(cat "$m/fan3_$1")" = "$2" ] || { echo "fan3_$1 = $(cat "$m/fan3_$1"), attendu $2" >&2; exit 1; }; }

lancer --une-fois;                    attendu manual 1; attendu output 1200   # au froid : le plancher
echo 55000 > "$h/hwmon0/temp1_input"; lancer --une-fois; attendu output 3750  # SSD chaud
echo 26000 > "$h/hwmon0/temp1_input"; echo 85000 > "$m/temp1_input"
lancer --une-fois;                    attendu output 6300                     # alimentation très chaude : maximum
echo 51000 > "$m/temp1_input"; rm "$h/hwmon0/temp1_input"
lancer --une-fois 2>/dev/null;        attendu manual 0                        # SSD illisible : la SMC reprend
echo 26000 > "$h/hwmon0/temp1_input"; lancer --une-fois; lancer --auto; attendu manual 0
OCMINTUX_CONF=/dev/null OCMINTUX_SMC=$m OCMINTUX_HWMON=$h VENTILATEUR_DISQUE=non "$V" >/dev/null; attendu manual 0
echo "ventilation : essais réussis"
