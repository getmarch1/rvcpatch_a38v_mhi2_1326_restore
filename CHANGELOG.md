# Changelog – RVC-Restore (Audi A3 8V, MHI2_ER_AU37x_P5089_MU1326)

Stellt die Originaldateien des RVC-Fullscreen-Patches aus den Sicherungen wieder her.
Nach jeder Änderung am `postscript.sh` muss `scriptPostCheckSum` in der `metainfo2.txt` neu berechnet werden.

## v0.12
- Die Marker-Bereinigung unter `/HBpersistence/SWDL` ist komplett entfernt (auch `RVCpatch`). Beim Test von v0.11 zeigte die Zusammenfassung des SWDL `RVCpatch` als `[NOK]`, den Eintrag, dessen Marker das Script gelöscht hatte. Die Marker werden jetzt nicht mehr angefasst. Die Variable `SWDL_DIRS` entfällt.
- Der Patch lässt sich nach dem Restore trotzdem erneut installieren (Marker sind dafür nicht nötig).
- Script-SHA1: `BAE02CA9144923CCA7A7D6FDBB0FF183E5744759`

## v0.11
- Der Marker dieses Restore-Pakets (`/HBpersistence/SWDL/RVCrestore`) wird nicht mehr gelöscht, nur noch der Marker des Patches (`RVCpatch`). Grund: Beim Test von v0.10 zeigte der SWDL nach einem sauberen Script-Lauf NOK und startete den Lauf erneut. Möglicherweise erwartet er seinen eigenen Marker nach dem Script. Das ist eine Vermutung und wird mit dieser Version getestet.
- Zeitstempel im Log (`[zeit]`) nach Vorab-Prüfung, Wiederherstellung, Verify und Ende, um die Laufzeit der Schritte zu sehen (Grenze des SWDL: `scriptPostMaxTime = 300` Sekunden).
- Script-SHA1: `5D9A6CE309222162CFFC45D451CF67A3A95AE973`

## v0.10
- Fix: Enthält ein Sicherungsordner (`..._original`) Unterordner, etwa durch frühere manuelle Kopierversuche, brach der Verify mit `FEHLER: Verify HMISystemEvoHighScale` ab, weil eine Prüfsumme über einen Ordner nicht möglich ist. Das Script kopiert und prüft jetzt nur noch Dateien. Unterordner werden übersprungen und im Log vermerkt (`Uebersprungen (keine Datei): ...`).
- Ist eine Sicherung ohne Dateien, bricht das Script mit einer klaren Meldung ab. Das Log nennt die Anzahl der wiederhergestellten Dateien je Ordner.
- Durch den Abbruch lief in v0.09 die Marker-Bereinigung nicht mehr. Mit v0.10 läuft sie wieder bis zum Ende durch.
- Script-SHA1: `37B8051570EDA7B736D97DB2804DF221975D0BF5`

## v0.09
- Erfolgsbild \`04_erfolg.png\`: neuer Text „Das Gerät startet jetzt neu. Bitte im Anschluss die Rückdokumentation abbrechen.“ (zweizeilig). Der Hinweis zur SD-Karte entfällt.
- Script nur in der Versionsnummer geändert, neue Script-SHA1: \`1D5D54A2AEE5E3866F05B6B013FCC489264CE988\`

## v0.08
- **Statusbilder im Display** wie beim Patch-Paket (gleiche Anzeigefunktionen, gleiches Layout, 800×480): `01_pruefung`, `02_wiederherstellung`, `03_kontrolle`, `04_erfolg`, `05_fehler` und `06_keine_sicherung` im Ordner `RVCrestore/status/`. `SHOW_IMAGES=0` am Anfang des Scripts schaltet sie ab (danach `scriptPostCheckSum` neu berechnen). Fehler bei der Anzeige beeinflussen den Restore nie, die Gründe stehen als `[img]`-Zeilen im Log.
- Eigenes Fehlerbild, wenn eine Sicherung fehlt (es wurde dann nichts verändert).
- **Marker-Datei an den richtigen Ort verschoben:** `RVCrestore/version/0/default/RVCrestore` (wie im Patch-Paket `RVCpatch/version/0/default/RVCpatch`). Vorher lag sie in `RVCrestore/RVCrestore` und passte nicht zum Sektionsnamen der `metainfo2.txt`. Das war vermutlich die Ursache des `metainfo`-Fehlers.
- `metainfo2.txt` jetzt 1:1 aus dem funktionierenden Patch-Paket abgeleitet (Zeilenenden wie dort, `[Signature]`-Block wieder enthalten, in v0.06 hatte ich ihn entfernt). Geändert sind nur die Namen und `scriptPostCheckSum`.
- Prüfsummen-Verify sucht zusätzlich `/net/rcc/usr/bin/sha1sum` (wie beim Patch-Paket).
- Log enthält jetzt Paketversion, Datum und Medium.
- Script-SHA1: `6CD14DE6F2F1A2B14021D8B72CCE2D6B7596AE42`

## v0.07
- Verify arbeitet jetzt per Prüfsumme statt nur mit `cmp` (cmp fehlt auf manchen Units). Das Script nimmt das erste vorhandene Tool aus: `sha1sum`, `md5sum`, `cksum`, zuletzt `cmp`. Ist keines vorhanden, wird die Kontrolle übersprungen und im Log vermerkt.
- Das verwendete Tool steht im Log (`Verify mit ...`). Bei einer abweichenden Datei bricht das Script wie bisher ab.
- Neu: Ablaufdiagramm `docs/ablauf_restore.png`.
- Script-SHA1: `7B6486E9B243A2EC7C5983D9A798458C5E77832E`

## v0.06
- `metainfo2.txt`: Der `[Signature]`-Block wurde entfernt. Die Signaturen stammten aus der kopierten Navi-Vorlage und passen nicht zum geänderten Inhalt. Die Signatur-/Variantenprüfung ist ohnehin über `skipCheckSignatureAndVariant = "true"` abgeschaltet.
- Script, Marker-Datei und alle Prüfsummen unverändert (Script-SHA1: `AE3A607C2AB5BCD33CA5875A65F87FF5B86E9200`).

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
