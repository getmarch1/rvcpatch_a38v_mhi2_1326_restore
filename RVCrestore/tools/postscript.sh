#!/bin/ksh
# RVC-Fullscreen-Patch (Audi A3 8V, MHI2) - RESTORE-Script
# Stellt die Originaldateien aus den Sicherungen wieder her
# ${2} = Wurzelverzeichnis des Update-Datentraegers (SD-Karte)

MEDIA=${2}
APP=/net/mmx/mnt/app
SYS=/net/mmx/mnt/system
DM_DIR=${SYS}/etc/eso/production
IMG_DIR=${APP}/eso/hmi/lsd/images/HMIEarlyAppsEvoHighScale
KZB_DIR=${APP}/eso/hmi/lsd/kzbs/HMISystemEvoHighScale
LOG=${MEDIA}/rvcrestore.log
SWDL_DIRS="/HBpersistence/SWDL /net/mmx/HBpersistence/SWDL"

log() { echo "$*" >> ${LOG}; }

# SD-Karte schreibbar, Autorun sofort umbenennen (verhindert Update-Schleife)
mount -uw ${MEDIA}
mv ${MEDIA}/SWDLautorun.txt ${MEDIA}/_SWDLautorun.txt
log "=== RVC-Restore gestartet ==="

fail() {
    log "FEHLER: $*"
    log "=== ABGEBROCHEN ==="
    sync
    mount -ur ${APP}
    mount -ur ${SYS}
    exit 1
}

# 1. Partitionen schreibbar
mount -uw ${APP} && mount -uw ${SYS} || fail "mount -uw app/system"

# Vorab-Pruefungen (nichts wird veraendert, bevor alle Sicherungen da sind)
[ -f ${DM_DIR}/displaymanager.json.original ] || fail "Sicherung displaymanager.json.original fehlt"
[ -d ${IMG_DIR}_original ] || fail "Sicherungsordner fehlt: ${IMG_DIR}_original"
[ -d ${KZB_DIR}_original ] || fail "Sicherungsordner fehlt: ${KZB_DIR}_original"
[ -d ${IMG_DIR} ] || fail "Zielordner images fehlt: ${IMG_DIR}"
[ -d ${KZB_DIR} ] || fail "Zielordner kzbs fehlt: ${KZB_DIR}"

# 2. Wiederherstellen (Sicherungen bleiben erhalten)
cp ${DM_DIR}/displaymanager.json.original ${DM_DIR}/displaymanager.json || fail "Restore displaymanager.json"
log "displaymanager.json wiederhergestellt"
cp ${IMG_DIR}_original/* ${IMG_DIR}/ || fail "Restore images"
log "images wiederhergestellt"
cp ${KZB_DIR}_original/* ${KZB_DIR}/ || fail "Restore kzbs"
log "kzbs wiederhergestellt"
sync

# Kontrolle (nur wenn cmp vorhanden)
if type cmp > /dev/null 2>&1; then
    cmp -s ${DM_DIR}/displaymanager.json.original ${DM_DIR}/displaymanager.json || fail "Verify displaymanager.json"
    for f in ${IMG_DIR}_original/*; do
        cmp -s ${f} ${IMG_DIR}/${f##*/} || fail "Verify ${f##*/}"
    done
    for f in ${KZB_DIR}_original/*; do
        cmp -s ${f} ${KZB_DIR}/${f##*/} || fail "Verify ${f##*/}"
    done
    log "Verify ok"
else
    log "cmp nicht vorhanden, Verify uebersprungen"
fi

# SWDL-Installationsmarker bereinigen, damit der Patch erneut installiert werden kann
# (Best effort: ein Fehler hier bricht den Restore nicht ab)
for d in ${SWDL_DIRS}; do
    [ -d ${d} ] || continue
    for m in RVCpatch RVCrestore; do
        if [ -e ${d}/${m} ]; then
            if rm -rf ${d}/${m}; then
                log "Marker entfernt: ${d}/${m}"
            else
                log "WARNUNG: Marker konnte nicht entfernt werden: ${d}/${m}"
            fi
        else
            log "Marker nicht vorhanden: ${d}/${m}"
        fi
    done
done
sync

# Partitionen wieder schreibgeschuetzt
sync
mount -ur ${APP} && mount -ur ${SYS} || log "WARNUNG: mount -ur app/system fehlgeschlagen"

log "=== RVC-Restore erfolgreich ==="
sync
touch /tmp/SWDLScript.Result
