# backupME

### Voraussetzungen
- minimum Perl > 5.12 erwartet
- die Konsolenprogramme tar und bzip2
- optional für den MySQL Dump das Programm mysqldump
- optional für CleanUp das Programm find

Alle Abhängikeiten werden vor dem eigentlichen Start geprüft. Die optionalen werden nur bei aktiver Verwendung überprüft.

### Anwenden
```
backupME.pl backupME.conf
```

Es ist möglich mehrere Konfigurationsdateien an zu legen und backupME zu übergeben.
```
/usr/local/bin/backupME.pl -c /usr/local/etc/backupME_FHEM.conf

/usr/local/bin/backupME.pl --configs /usr/local/etc/backupME_DOKUWIKI.conf

/usr/local/bin/backupME.pl -c /usr/local/etc/backupME_FHEM.conf,/usr/local/etc/backupME_DOKUWIKI.conf

/usr/local/bin/backupME.pl --configs /usr/local/etc/backupME_FHEM.conf,/usr/local/etc/backupME_DOKUWIKI.conf

/usr/local/bin/backupME.pl --configfiles /usr/local/etc/backupME_FHEM.conf,/usr/local/etc/backupME_DOKUWIKI.conf
```

Da ein Backup zu meist Abends oder in der Nacht alleine laufen soll/kann, empfehle ich einen Eintrag in der crontab. Also das einrichten eines Cronjobs


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

#### # Verzeichnisse oder Dateien unterhalb von SOURCEPATH, welche aufgeräumt werden sollen. Löschen aller Daten älter CLEAN_UP_DAYS Tage. Kommasepariert
CLEAN_UP_PATHS=/*

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



### Konfigurationsbeispiel:
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
