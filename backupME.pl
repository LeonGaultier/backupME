#!/usr/bin/perl

###############################################################################
# 
# Developed with Kate
#
#  (c) 2019 Copyright: Marko Oldenburg (marko.oldenburg at araneaconsult dot de)
#  All rights reserved
#
#
#  This script is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  any later version.
#
#  The GNU General Public License can be found at
#  http://www.gnu.org/copyleft/gpl.html.
#  A copy is found in the textfile GPL.txt and important notices to the license
#  from the author is found in LICENSE.txt distributed with these scripts.
#
#  This script is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#
###############################################################################
#
my $version = '1.0.2';


use strict;
use warnings;
use POSIX;

use Term::ANSIColor;
use IO::Socket::INET;
use Getopt::Long;

##################################################
# Forward declarations
#
sub parseOptions;
sub usageExit;
sub readConfigFile;
sub logMessage($$);
sub MainBackup;
sub checkBackUpPathStructsExist($);
sub createBackUpPathStructs($);
sub toCleanUp($);
sub rotateDailyBackupfiles;
sub createDBdump;
sub runBackup($);
sub _sendStateToFHEM($);
sub checkSendFHEMConnect($);
sub MainSystemBackup;

##################################################
# Variables:
my $self = {};



###################################################
# Start the program
my ($conffile,$debug,$acount);
$debug = 0;

my ($conffilestring,$mode) = parseOptions;
my @conffiles = split(/,/,$conffilestring);
$self->{configfiles} = \@conffiles;
$self->{mode} = $mode;

$self->{config}->{TARCMDPATH} = qx(which tar);
chomp($self->{config}->{TARCMDPATH});
unless ( defined($self->{config}->{TARCMDPATH}) and $self->{config}->{TARCMDPATH} ) {
    logMessage(3,'can\'t find tar command');
    exit 1;
}

MainBackup if ( $self->{mode} eq 'backup' );
MainSystemBackup if ( $self->{mode} eq 'system' );

exit 0;


##### SUBS for Backup ####

sub MainBackup {
    
    unless ( readConfigFile ) {
        logMessage(3,'cant\'t read config file');
        return 0;
    }

    my $fnState = 0;
    my @bckPathStructur = ('archive','daily');

    if ( not checkBackUpPathStructsExist($self->{config}->{BACKUPPATH}) and $self->{config}->{SPECIALCHECK_BACKUPPATH} ) {
        logMessage(3,'can\'t find ' . $self->{config}->{BACKUPPATH} . '! check special mount?(encf,NFS,SMB)');
        checkSendFHEMConnect(1);
        return 0;
    }

    foreach (@bckPathStructur) {
        createBackUpPathStructs($_) unless ( checkBackUpPathStructsExist($_) );
    }
    
    if ( defined($self->{config}->{CLEAN_UP_PATHS}) and $self->{config}->{CLEAN_UP_PATHS} ) {
        logMessage(1,'Start cleanup Procedure');
        
        $self->{config}->{FINDCMDPATH} = qx(which find);
        chomp($self->{config}->{FINDCMDPATH});
        
        if ( defined($self->{config}->{FINDCMDPATH}) and $self->{config}->{FINDCMDPATH} ) {
            foreach (split(/,/,$self->{config}->{CLEAN_UP_PATHS})) {
                toCleanUp($_);
            }
        } else { logMessage(3,'no find command found'); checkSendFHEMConnect(1); return 0 }
    }
        
    $fnState = rotateDailyBackupfiles unless ($fnState);
    $fnState = createDBdump() if ( $self->{config}->{MYSQLDUMP} and not $fnState );
    $fnState = runBackup(( (split(" ", localtime(time)))[0] =~ /^(Sun)$/ ? 'archive' : 'daily' )) unless ($fnState);

    checkSendFHEMConnect($fnState);

    MainBackup if( scalar(@{$self->{configfiles}}) > 0 );
}

sub runBackup($) {
    my $bckarchiv = shift;
    
    my $state = 1;
    my $filesToBackUpString;
    foreach (split(/,/,$self->{config}->{FILES_TO_BACKUP})) {
        $filesToBackUpString .= $self->{config}->{SOURCEPATH} . '/' . $_ . ' ';
    }

    if ( open( CMD, "$self->{config}->{TARCMDPATH} -cvjf $self->{config}->{BACKUPPATH}/$self->{config}->{BACKUPDIRNAME}/$bckarchiv/$self->{config}->{BACKUPFILENAME}.1.tar.bz2 $filesToBackUpString 2>&1 |" ) ) {
        while ( my $line = <CMD> ) {
            chomp($line);
            print qq($line\n) if ( $debug == 1 );

            if ( $line =~ m#($self->{config}->{SOURCEPATH}.*)# ) {
                logMessage(1,'Erstelle Backup von ' . $1 . ' nach ' . $self->{config}->{BACKUPPATH}.'/'.$self->{config}->{BACKUPDIRNAME}.'/'.$bckarchiv.'/'.$self->{config}->{BACKUPFILENAME}.'.1.tar.bz2');
                $state = 0;
            }
        }
        close(CMD);
    }
    else {
        logMessage(3,"Couldn't use CMD: $!");
        $state = 1;
    }
    
    return $state;
}

sub createDBdump {
    $self->{config}->{MYSQLDUMPCMDPATH} = qx(which mysqldump);
    chomp($self->{config}->{MYSQLDUMPCMDPATH});
    
    return logMessage(3,'can\'t find mysqldump command') unless ( defined($self->{config}->{MYSQLDUMPCMDPATH}) and $self->{config}->{MYSQLDUMPCMDPATH} );
    
    my $state;
    foreach (split(/,/,$self->{config}->{DBNAMES})) {
        $state = 1;
        if ( open( CMD, "$self->{config}->{MYSQLDUMPCMDPATH} --user=$self->{config}->{DBUSER} --password=$self->{config}->{DBPASS} -Q $_ | gzip > $self->{config}->{DBBACKUPPATH}/$_\_\"`date +%d-%m-%Y`\".sql.gz 2>&1 |" ) ) {
            logMessage(1,'Erstelle Datenbank Dump für DB '.$_);
            $state = 0;
            close(CMD);
        }
        else {
            logMessage(3,"Couldn't use CMD: $!");
            return 1;
        }
    }
    
    return $state;
}

sub rotateDailyBackupfiles {
    my $count;
    my $state = 1;

    for ($count=$self->{config}->{DAILY_DATA_BACKUPS}-1;$count>0;$count--) {
        if ( -f $self->{config}->{BACKUPPATH} . '/' . $self->{config}->{BACKUPDIRNAME} . '/daily/' . $self->{config}->{BACKUPFILENAME} . '.' . $count . '.tar.bz2' ) {
            my $countNew = $count + 1;
            if ( open( CMD, "mv -v $self->{config}->{BACKUPPATH}/$self->{config}->{BACKUPDIRNAME}/daily/$self->{config}->{BACKUPFILENAME}.$count.tar.bz2 $self->{config}->{BACKUPPATH}/$self->{config}->{BACKUPDIRNAME}/daily/$self->{config}->{BACKUPFILENAME}.$countNew.tar.bz2 2>&1 |" ) ) {
                while ( my $line = <CMD> ) {
                    chomp($line);
                    print qq($line\n) if ( $debug == 1 );

                    if ( $line =~ m#^\S+($self->{config}->{BACKUPFILENAME}\S+)'\s.+\s\S+($self->{config}->{BACKUPFILENAME}\S+)'$# ) {
                        logMessage(1,'Räume Backupverzeichnis auf. Move Backupfile '.$1.' to '.$2);
                        $state = 0;
                    }
                }
                close(CMD);
            }
            else {
                logMessage(3,"Couldn't use CMD: $!");
                return 1;
            }
        }
    }

    return $state
}

sub toCleanUp($) {
#### spezielle Angabe des cleanUpPath mit !EXPERT also !EXPERT/home/marko/test/* wird ausserhalb von SOURCEPATH behandelt
    my $cleanUpPath = shift;

    $cleanUpPath = ( (split('EXPERT',$cleanUpPath))[0] eq '!' ? (split('EXPERT',$cleanUpPath))[1] : $self->{config}->{SOURCEPATH} . $cleanUpPath );

    my $state = 1;
    if ( open( CMD, "$self->{config}->{FINDCMDPATH} $cleanUpPath -mtime +$self->{config}->{CLEAN_UP_DAYS} -exec rm -vrf {} \\; 2>&1 |" ) ) {
        
        while ( my $line = <CMD> ) {
            chomp($line);
            print qq($line\n) if ( $debug == 1 );

            if ( $line =~ m#^^'(.+)'.+entfernt$# ) {
                logMessage(1,$1.' wurde entfernt');
                $state = 0;
            }
        }

        close(CMD);
    }
    else {
        logMessage(3,"Couldn't use CMD: $!");
        return 1;
    }
    
    return $state;
}

sub readConfigFile {
    my $conffile = shift(@{$self->{configfiles}});

    if ( open(CF, "<$conffile") ) {
        while ( my $line = <CF> ) {
            chomp($line);
            print qq($line\n) if ( $debug == 1 );

            if ( $line =~ m#^([A-Z]+|[A-Z]+_[A-Z]+|[A-Z]+_[A-Z]+_[A-Z]+)=(.*)$# ) {
                $self->{config}->{$1} = $2;
            }
        }

        close(CF);
    }
    else {
        return 0;
    }
    
    return 1;
}

sub parseOptions {
    my $conffiles                   = undef;
    my $mode                        = 'backup';

    GetOptions(
        'backupMode|mode|m=s'      => \$mode,
        'configfiles|configs|c=s'   => \$conffiles
    ) or usageExit;
    
    $mode =~ m/^backup|system$/ or usageExit;
    defined($conffiles) or usageExit;

    return ($conffiles,$mode);
}

sub usageExit {

    print('usage:' . "\n");
    printf("\t" . '-c <configfile1>,<configfile2>... -m <backup|system>' . "\n");
    printf("\t" . '-configs <configfile1>,<configfile2>... -mode <backup|system>' . "\n");
    printf("\t" . '--configfiles <configfile1>,<configfile2> ...--backupMode <backup|system>' . "\n");
    exit(1);
}

sub logMessage($$) {
    my ($level,$text) = @_;
    my %levels = (  1 => 'Info - ',
                    2 => "\tWarning - ",
                    3 => "\t\tERROR!!! - ",
        );

    print($levels{$level} . $text . "\n");
}

sub checkBackUpPathStructsExist($) {
    my $bckDir = shift;

    if ( $bckDir ne $self->{config}->{BACKUPPATH} ) {
        if ( -d $self->{config}->{BACKUPPATH} . '/' . $self->{config}->{BACKUPDIRNAME} . '/' . $bckDir ) { return 1 } else { return 0 }
    } elsif ( $bckDir eq $self->{config}->{BACKUPPATH} ) {
        if ( -d $bckDir ) { return 1 } else { return 0 }
    }
}

sub createBackUpPathStructs($) {
    my $bckDir = shift;
    
    my $state = 1;
    if ( open( CMD, "mkdir -vp $self->{config}->{BACKUPPATH}/$self->{config}->{BACKUPDIRNAME}/$bckDir 2>&1 |" ) ) {
        while ( my $line = <CMD> ) {
            chomp($line);
            print qq($line\n) if ( $debug == 1 );

            if ( $line =~ m#^mkdir:.+\s'(.+)'\sangelegt$# ) {
                logMessage(1,'Create Backupdirectory '.$1);
                $state = 0;
            }
        }

        close(CMD);
        $state = 0;
    }
    else {
        logMessage(3,"Couldn't use CMD: $!");
        return 1;
    }

    return $state;
}


##### SUBS for Systembackup ####


sub MainSystemBackup {



}

##### SUBS for FHEM ####

sub checkSendFHEMConnect($) {
    my $fnState = shift;

    if ( $self->{config}->{FHEMSUPPORT} ) {
        logMessage(3,'can\'t connect to FHEM Instance')
            unless ( _sendStateToFHEM(($fnState ? 'error' : 'ok')) );
    }
}

sub _sendStateToFHEM($) {
    my $bckState = shift;

    my $socket = IO::Socket::INET->new('PeerAddr' => $self->{config}->{FHEMHOST},'PeerPort' => $self->{config}->{TELNETPORT},'Proto' => 'tcp')
        or return 0;

    print($socket 'setreading ' . $self->{config}->{FHEMDUMMY} . ' state ' . $bckState . "\n");
    print($socket 'setreading ' . $self->{config}->{FHEMDUMMY} . ' dbBackup ' . ($self->{config}->{MYSQLDUMP} ? 'yes' : 'no') . "\n");
    print($socket 'setreading ' . $self->{config}->{FHEMDUMMY} . ' cleanUpSourcePath ' . ((defined($self->{config}->{CLEAN_UP_PATHS}) and $self->{config}->{CLEAN_UP_PATHS}) ? 'yes' : 'no') . "\n");
    print($socket 'setreading ' . $self->{config}->{FHEMDUMMY} . ' cleanUpSourcePaths ' . $self->{config}->{CLEAN_UP_PATHS} . "\n") if ( defined($self->{config}->{CLEAN_UP_PATHS}) );
    print($socket 'setreading ' . $self->{config}->{FHEMDUMMY} . ' BACKUPDIRNAME ' . $self->{config}->{BACKUPDIRNAME} . "\n");
    print($socket 'setreading ' . $self->{config}->{FHEMDUMMY} . ' BACKUPFILENAME ' . $self->{config}->{BACKUPFILENAME} . "\n");
    print($socket 'setreading ' . $self->{config}->{FHEMDUMMY} . ' SOURCEPATH ' . $self->{config}->{SOURCEPATH} ."\n");
    print($socket 'setreading ' . $self->{config}->{FHEMDUMMY} . ' FILES_TO_BACKUP ' . $self->{config}->{FILES_TO_BACKUP} . "\n");
    print($socket 'setreading ' . $self->{config}->{FHEMDUMMY} . ' BACKUPPATH ' . $self->{config}->{BACKUPPATH} ."\n");
    print($socket 'setreading ' . $self->{config}->{FHEMDUMMY} . ' DAILY_DATA_BACKUPS ' . $self->{config}->{DAILY_DATA_BACKUPS} . "\n");
    print($socket 'setreading ' . $self->{config}->{FHEMDUMMY} . ' DBNAMES ' . $self->{config}->{DBNAMES} . "\n") if ( $self->{config}->{MYSQLDUMP} );
    print($socket 'setreading ' . $self->{config}->{FHEMDUMMY} . ' scriptVersion ' . $version . "\n");
    $socket->close;
    return 1;
}
