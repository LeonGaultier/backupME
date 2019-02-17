# backupME
### Konfiguration
#### wie soll das Verzeichnis heißen wo die Backups hin geschrieben werden
BACKUPDIRNAME=fhem_backups

#### Name der Backupdatei
BACKUPFILENAME=fhem_backup

#### Startverzeichnis wo Daten liegen zum sichern
SOURCEPATH=/opt/fhem/backup

#### Dateien Komma getrennt welche gesichert werden sollen. Kann auch zum Beispiel mittels *.md oder * fur alles lauten. Muss sich aber unterhalb von SOURCEPATH befinden
FILES_TO_BACKUP=FHEM-"`date +%Y%m%d`"*.tar.gz

#### Verzeichnis unter welches die Backupstruktur aufgebaut werden soll.
BACKUPPATH=/home/marko/Google_Drive_Secure/pi-webapp01_BACKUPS

#### wie viele Backups sollen aufgehoben werden.
DAILY_DATA_BACKUPS=6


### Special Konfiguration
#### Soll bei nicht vorhanden sein des Backupverzeichnis das Skript abgebrochen werden. Sinnvoll bei encfs oder eingebundenen Netzwerkverzeichnissen. 0 nein 1 ja
SPECIALCHECK_BACKUPPATH=1

#### Verzeichnisse welche aufgeräumt werden sollen. Löschen aller Daten älter CLEAN_UP_DAYS Tage
CLEAN_UP_PATHS=/opt/fhem/backup/*

#### löschen älter X Tage
CLEAN_UP_DAYS=4

#### soll das Ergebnis des Backups (ok|error) in ein FHEM Dummy geschrieben werden? 0 nein 1 ja. telnet Instanz muss ohne SSL und Passwort vorhanden sein
FHEMSUPPORT=1

#### Name des FHEM Dummys für das schreiben des Ergebnisses
FHEMDUMMY=dummyBackupScript


### MySQL DB Dumps
#### soll ein MYSQL Dump erstellt werden  0 nein 1 ja
MYSQLDUMP=0

#### Datenbank User
DBUSER=

#### Datenbank User Passwort
DBPASS=

#### Instanzname der Datenbank
DBNAMES=fhemLogHistory

#### wo soll der Dump hingeschrieben werden
DBBACKUPPATH=/opt/fhem/backup


```
BACKUPDIRNAME=fhem_backups
BACKUPFILENAME=fhem_backup
SOURCEPATH=/opt/fhem/backup
FILES_TO_BACKUP=FHEM-"`date +%Y%m%d`"*.tar.gz
BACKUPPATH=/home/marko/Google_Drive_Secure/pi-webapp01_BACKUPS
DAILY_DATA_BACKUPS=6

SPECIALCHECK_BACKUPPATH=1
CLEAN_UP_PATHS=/opt/fhem/backup/*
CLEAN_UP_DAYS=4

FHEMSUPPORT=1
FHEMDUMMY=dummyBackupScript

MYSQLDUMP=0
DBUSER=
DBPASS=
DBNAMES=fhemLogHistory
DBBACKUPPATH=/opt/fhem/backup
```
