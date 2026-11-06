#!/bin/ksh
# RVC-Fullscreen-Patch (Audi A3 8V, MHI2) - RESTORE-Script
# Stellt die Originaldateien aus den Sicherungen wieder her
# ${2} = Wurzelverzeichnis des Update-Datentraegers (SD-Karte)

PKG_VERSION="0.11"
SHOW_IMAGES=1        # 1 = Statusbilder im Display anzeigen, 0 = aus

MEDIA=${2}
STATUS=${MEDIA}/RVCrestore/status
APP=/net/mmx/mnt/app
SYS=/net/mmx/mnt/system
DM_DIR=${SYS}/etc/eso/production
IMG_DIR=${APP}/eso/hmi/lsd/images/HMIEarlyAppsEvoHighScale
KZB_DIR=${APP}/eso/hmi/lsd/kzbs/HMISystemEvoHighScale
LOG=${MEDIA}/rvcrestore.log
SWDL_DIRS="/HBpersistence/SWDL /net/mmx/HBpersistence/SWDL"

# Systemprogramme fuer die Bildanzeige
IMGBIN=/net/mmx/eso/bin/apps/loadandshowimage
DMDT=/net/mmx/eso/bin/apps/dmdt
IMGCFG=/net/mmx/etc/imgprocessing.cfg
IMG_ON=0
IMG_FAILED=0
IMGOUT=/tmp/rvc_img.out.$$
DBGTMP=/tmp/rvc_img.dbg.$$
# Umgebung, die die Anzeigeprogramme brauchen (nur fuer deren Aufrufe, siehe imgenv)
IMG_PATH="/proc/boot:/sbin:/bin:/usr/bin:/usr/sbin:/net/mmx/bin:/net/mmx/usr/bin:/net/mmx/usr/sbin:/net/mmx/sbin"
IMG_LIBS="/net/mmx/mnt/app/root/lib-target:/net/mmx/mnt/eso/lib:/net/mmx/eso/lib:/net/mmx/mnt/app/usr/lib:/net/mmx/mnt/app/armle/lib:/net/mmx/mnt/app/armle/lib/dll:/net/mmx/mnt/app/armle/usr/lib"
IMG_IPL=/net/mmx/etc/eso/production
FAILIMG=05_fehler.png

# ---------------------------------------------------------------- Logging

log() { echo "$*" >> ${LOG}; }

# Zeitstempel im Log (zeigt, wie lange die einzelnen Schritte dauern)
stamp() { log "  [zeit] $1: $(date 2> /dev/null)"; }

# ---------------------------------------------------------- Bildanzeige
# Alles hier ist "best effort": Fehler duerfen den Restore nie beeinflussen.
# Jeder Aufruf wird nach spaetestens N Sekunden beendet. Ergebnis und
# Ausgabe der Aufrufe stehen zur Fehlersuche im Log ([img]-Zeilen).

# Fuehrt einen Befehl mit der Umgebung aus, die die Anzeigeprogramme brauchen.
# Wird nur in Hintergrund-/Unterprozessen benutzt, die Umgebung des Scripts
# bleibt unveraendert.
imgenv() {
    PATH=${IMG_PATH}:${PATH}
    LD_LIBRARY_PATH=${IMG_LIBS}
    IPL_CONFIG_DIR=${IMG_IPL}
    LIBIMG_CFGFILE=${IMGCFG}
    export PATH LD_LIBRARY_PATH IPL_CONFIG_DIR LIBIMG_CFGFILE
    "$@"
}

limited() {
    t=$1; shift
    rm -f ${DBGTMP}
    imgenv "$@" > ${DBGTMP} 2>&1 &
    p=$!
    i=0
    while [ ${i} -lt ${t} ] && kill -0 ${p} 2> /dev/null; do
        sleep 1
        i=$((i + 1))
    done
    if kill -0 ${p} 2> /dev/null; then
        kill ${p} 2> /dev/null
        rc="Zeitueberschreitung"
    else
        wait ${p}
        rc="Ende $?"
    fi
    log "  [img] $* -> ${rc} $(cat ${DBGTMP} 2>&1)"
    rm -f ${DBGTMP}
    return 0
}

show_image() {
    [ "${SHOW_IMAGES}" = "1" ] || return 0
    [ ${IMG_FAILED} = 0 ] || return 0
    [ -f "${STATUS}/$1" ] || { log "  [img] Datei fehlt: ${STATUS}/$1"; return 0; }
    # das vorherige Bild beenden
    [ ${IMG_ON} = 1 ] && limited 3 on -f mmx ${IMGBIN} 1 2 3 4 5
    rm -f ${IMGOUT}
    imgenv on -f mmx ${IMGBIN} "${STATUS}/$1" > ${IMGOUT} 2>&1 &
    ip=$!
    sleep 2
    if kill -0 ${ip} 2> /dev/null; then
        # Programm laeuft: Bildschirm auf die Bildebene umschalten
        limited 3 on -f mmx ${DMDT} sc 0 -9
        IMG_ON=1
        log "  [img] zeige $1"
    else
        # Programm ist beendet/abgestuerzt: nicht umschalten (sonst schwarzer
        # Bildschirm) und keine weiteren Versuche in diesem Lauf
        IMG_ON=0
        IMG_FAILED=1
        log "  [img] Anzeige fehlgeschlagen bei $1, keine weiteren Bilder: $(cat ${IMGOUT} 2>&1)"
    fi
    return 0
}

hide_image() {
    [ ${IMG_ON} = 1 ] || return 0
    limited 3 on -f mmx ${IMGBIN} 1 2 3 4 5
    limited 3 on -f mmx ${DMDT} sb 0
    rm -f ${IMGOUT}
    IMG_ON=0
    return 0
}

# ------------------------------------------------------------------ Fehler

fail() {
    log "FEHLER: $*"
    log "=== ABGEBROCHEN ==="
    show_image ${FAILIMG}
    sync
    mount -ur ${APP}
    mount -ur ${SYS}
    sleep 8
    hide_image
    exit 1
}

# Fehlende Sicherung: eigenes Fehlerbild, es wurde nichts veraendert
nobackup() {
    FAILIMG=06_keine_sicherung.png
    fail "$*"
}

# ------------------------------------------------------------ Verify-Tool
# Pruefsumme statt cmp (cmp fehlt auf manchen Units).
# Reihenfolge: sha1sum, sha1sum vom rcc-Knoten, md5sum, cksum; zuletzt cmp

SUMTOOL=""
for t in sha1sum /net/rcc/usr/bin/sha1sum md5sum cksum cmp; do
    case ${t} in
        /*) [ -x ${t} ] && { SUMTOOL=${t}; break; } ;;
        *)  type ${t} > /dev/null 2>&1 && { SUMTOOL=${t}; break; } ;;
    esac
done

# Pruefsumme einer Datei (leer, wenn nicht lesbar)
sumof() {
    set -- $(${SUMTOOL} "$1" 2> /dev/null)
    if [ "${SUMTOOL}" = "cksum" ]; then
        echo "$1 $2"
    else
        echo "$1"
    fi
}

# same <Quelle> <Ziel>: 0 = identisch
same() {
    if [ "${SUMTOOL}" = "cmp" ]; then
        cmp -s "$1" "$2"
    else
        a=$(sumof "$1")
        b=$(sumof "$2")
        [ -n "${a}" ] && [ "${a}" = "${b}" ]
    fi
}

# Dateien aus einer Sicherung zurueckkopieren; Unterordner (z.B. von frueheren
# manuellen Versuchen) werden uebersprungen und im Log vermerkt
# restore_dir <Sicherungsordner> <Zielordner> <Name fuers Log>
restore_dir() {
    n=0
    for f in ${1}/*; do
        if [ -f ${f} ]; then
            cp ${f} ${2}/ || fail "Restore ${3}: ${f##*/}"
            n=$((n + 1))
        else
            log "Uebersprungen (keine Datei): ${3}/${f##*/}"
        fi
    done
    [ ${n} -gt 0 ] || fail "Sicherung enthaelt keine Dateien: ${1}"
    log "${3} wiederhergestellt (${n} Dateien)"
}

# ------------------------------------------------------------------ Start

# SD-Karte schreibbar, Autorun sofort umbenennen (verhindert Update-Schleife, auch bei Abbruch)
mount -uw ${MEDIA}
mv ${MEDIA}/SWDLautorun.txt ${MEDIA}/_SWDLautorun.txt
log "=== RVC-Restore gestartet ==="
log "Paketversion: ${PKG_VERSION}"
log "Datum: $(date 2> /dev/null)"
log "Medium: ${MEDIA}"
show_image 01_pruefung.png

# 1. Partitionen schreibbar
mount -uw ${APP} && mount -uw ${SYS} || fail "mount -uw app/system"

# Vorab-Pruefungen (nichts wird veraendert, bevor alle Sicherungen da sind)
[ -f ${DM_DIR}/displaymanager.json.original ] || nobackup "Sicherung displaymanager.json.original fehlt"
[ -d ${IMG_DIR}_original ] || nobackup "Sicherungsordner fehlt: ${IMG_DIR}_original"
[ -d ${KZB_DIR}_original ] || nobackup "Sicherungsordner fehlt: ${KZB_DIR}_original"
[ -d ${IMG_DIR} ] || fail "Zielordner images fehlt: ${IMG_DIR}"
[ -d ${KZB_DIR} ] || fail "Zielordner kzbs fehlt: ${KZB_DIR}"
log "Vorab-Pruefungen ok"
stamp "Vorab-Pruefungen"

# 2. Wiederherstellen (Sicherungen bleiben erhalten)
show_image 02_wiederherstellung.png
cp ${DM_DIR}/displaymanager.json.original ${DM_DIR}/displaymanager.json || fail "Restore displaymanager.json"
log "displaymanager.json wiederhergestellt"
restore_dir ${IMG_DIR}_original ${IMG_DIR} images
restore_dir ${KZB_DIR}_original ${KZB_DIR} kzbs
sync

stamp "Wiederherstellung"

# 3. Kontrolle per Pruefsumme
show_image 03_kontrolle.png
if [ -n "${SUMTOOL}" ]; then
    log "Verify mit ${SUMTOOL}"
    same ${DM_DIR}/displaymanager.json.original ${DM_DIR}/displaymanager.json || fail "Verify displaymanager.json"
    for f in ${IMG_DIR}_original/*; do
        [ -f ${f} ] || continue
        same ${f} ${IMG_DIR}/${f##*/} || fail "Verify ${f##*/}"
    done
    for f in ${KZB_DIR}_original/*; do
        [ -f ${f} ] || continue
        same ${f} ${KZB_DIR}/${f##*/} || fail "Verify ${f##*/}"
    done
    log "Verify ok"
else
    log "kein Pruefsummen-Tool vorhanden, Verify uebersprungen"
fi

stamp "Verify"

# Marker des Patches entfernen, damit der Patch erneut installiert werden kann.
# Der Marker dieses Restore-Pakets (RVCrestore) wird absichtlich NICHT angefasst,
# er gehoert dem SWDL. (Best effort: ein Fehler hier bricht den Restore nicht ab)
for d in ${SWDL_DIRS}; do
    [ -d ${d} ] || continue
    if [ -e ${d}/RVCpatch ]; then
        if rm -rf ${d}/RVCpatch; then
            log "Marker entfernt: ${d}/RVCpatch"
        else
            log "WARNUNG: Marker konnte nicht entfernt werden: ${d}/RVCpatch"
        fi
    else
        log "Marker nicht vorhanden: ${d}/RVCpatch"
    fi
done
sync

# Partitionen wieder schreibgeschuetzt
sync
mount -ur ${APP} && mount -ur ${SYS} || log "WARNUNG: mount -ur app/system fehlgeschlagen"

stamp "Ende"
log "=== RVC-Restore erfolgreich ==="
show_image 04_erfolg.png
sync
sleep 6
hide_image
touch /tmp/SWDLScript.Result
