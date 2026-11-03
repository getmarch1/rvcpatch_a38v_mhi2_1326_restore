# rvcpatch_a38v_mhi2_1326_restore
Restore Backups from rvcpatch_a38v_mhi2_1326 if something goes wrong...


# Changelog – RVC-Restore (Audi A3 8V, MHI2_ER_AU37x_P5089_MU1326)

Stellt die Originaldateien des RVC-Fullscreen-Patches aus den Sicherungen wieder her.
Nach jeder Änderung am `postscript.sh` muss `scriptPostCheckSum` in der `metainfo2.txt` neu berechnet werden.

## v0.05
- Entfernt: das Schreibbar-/Schreibgeschützt-Setzen von `SWDL_DIRS` (`hb_writable`, `hb_readonly`, `RO_MOUNTS`) aus v0.04. Der Installer arbeitet auch ohne Rechteänderung, daher nicht nötig.
- Die Marker-Bereinigung aus v0.03 (`RVCpatch`, `RVCrestore`) bleibt unverändert erhalten und läuft weiterhin Best Effort.
- Script-SHA1: `AE3A607C2AB5BCD33CA5875A65F87FF5B86E9200`

## v0.04
- `/HBpersistence/SWDL` und `/net/mmx/HBpersistence/SWDL` werden am Anfang bei Bedarf schreibbar gemacht (`hb_writable`).
- Am Ende (und im Fehlerfall über `fail()`) werden nur die Mountpunkte wieder schreibgeschützt, die das Script selbst umgestellt hat (`hb_readonly`).
- Schreibbarkeit wird per temporärer Testdatei geprüft, bereits schreibbare Pfade bleiben unverändert.
- Alles Best Effort, Warnungen landen in `rvcrestore.log`.
- Script-SHA1: `644048547A5F119534294B79118D76B4D16BC86E`

## v0.03
- Neu: Bereinigung der SWDL-Installationsmarker `RVCpatch` und `RVCrestore` unter `/HBpersistence/SWDL` (und `/net/mmx/HBpersistence/SWDL`), damit der Patch erneut installiert werden kann.
- Bereinigung erfolgt nur nach erfolgreichem Restore und Verify.
- Fehler beim Löschen brechen den Restore nicht ab, sie werden nur im Log vermerkt.
- Neue Variable `SWDL_DIRS`.
- Script-SHA1: `AE3A607C2AB5BCD33CA5875A65F87FF5B86E9200`

## v0.02
- Paket von `RVCpatch` auf `RVCrestore` umbenannt, damit es nicht mit dem Patch-Paket kollidiert.
- Geändert in `metainfo2.txt`: Release, Sektionsnamen, `DeviceDescription`, `DisplayName`, `DownloadGroup`, `Source`, `Destination` (`/HBpersistence/SWDL/RVCrestore`) und `scriptPost` (`./RVCrestore/tools/postscript.sh`).
- Neue Ordnerstruktur: `RVCrestore/RVCrestore` (Marker-Datei) und `RVCrestore/tools/postscript.sh`.
- Das Script selbst blieb unverändert, die Prüfsummen haben sich nicht geändert.
- Script-SHA1: `F7337F9DEBF9A894BAD527515BB92EF6C62F534D`
- Marker-Datei-SHA1: `E5FA44F2B31C1FB553B6021E7360D07D5D91FF5E`

## v0.01
- Erste Version des Restore-Scripts.
- `SWDLautorun.txt` wird sofort in `_SWDLautorun.txt` umbenannt (verhindert eine Update-Schleife).
- `/app` und `/system` werden schreibbar gemountet.
- Vorab-Prüfung, ob alle Sicherungen vorhanden sind (`displaymanager.json.original`, `HMIEarlyAppsEvoHighScale_original`, `HMISystemEvoHighScale_original`), sonst Abbruch ohne Änderung.
- Wiederherstellung von `displaymanager.json`, Bildern und KZBs aus den Sicherungen, die Sicherungen bleiben erhalten.
- Verify per `cmp` (falls vorhanden).
- Partitionen werden wieder schreibgeschützt, Protokoll in `rvcrestore.log` auf der SD-Karte.
- Script-SHA1: `F7337F9DEBF9A894BAD527515BB92EF6C62F534D`

## Bekannte Einschränkungen
- Ungetestet, Nutzung auf eigenes Risiko, vorher ein Backup anlegen.
- Dateien, die der Patch neu angelegt hat und die im Original nicht existierten, werden nicht entfernt.
- Ob das Löschen des `RVCrestore`-Markers wirkt, hängt von der Reihenfolge im Installer ab.
