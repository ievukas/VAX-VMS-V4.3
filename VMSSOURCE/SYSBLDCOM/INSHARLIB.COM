$ !
$ ! Insert shareable images into IMAGELIB
$ !
$ ! INPUTS:
$ !
$ ! P1	- filename string for IMAGELIB
$ ! P2  - file list of input shareable images
$ !
$ SET NOON
$ PRCNAM = F$GETJPI ("","PRCNAM")
$ UPDATE_TRIES = 24	! Retry up to 24 times (two minutes @5 secs)
$ !
$UPDATE_LIBRARY:
$ LIBRARY /SHARE 'P1' 'P2'
$ EXIT_STATUS = $STATUS
$ IF EXIT_STATUS .NE. %X1086109C THEN GOTO DONE	! Skip if not %LIBRAR-F-OPENIN,
$ IF UPDATE_TRIES .LT. 0 THEN GOTO DONE
$ NAME = "WAIT" + F$EXTRACT(4,12,PRCNAM)
$ SET PROCESS /NAME='NAME'
$ WAIT 0:0:5
$ UPDATE_TRIES = UPDATE_TRIES - 1
$ GOTO UPDATE_LIBRARY
$ !
$DONE:
$ SET PROCESS /NAME="''PRCNAM'"
$ EXIT EXIT_STATUS
