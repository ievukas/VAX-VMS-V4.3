$ ! UETLOAD11.COM
$ !
$ ! MODIFIED BY:
$ !
$ !	V03-001	RNH0004		Richard N. Holstein,	11-Feb-1983
$ !		Items from the V3B UETP workplan.
$ !
$ !--
$ LOGFILE = "''F$MODE()'" .NES. "INTERACTIVE"
$ IF .NOT. LOGFILE THEN GOTO SKIPFILE
$ ! Form a filename of the first five characters of our process name
$ ! concatenated with the Phase Controller sequence number.
$ PROC := 'F$GETJPI("","PRCNAM")
$ UNDER = 'F$LOCATE("_",PROC)
$ ID = UNDER+1
$ IF UNDER .GT. 5 THEN UNDER = 5
$ FILENAME := 'F$EXTRACT(0,UNDER,PROC)''F$EXTRACT(ID,4,PROC)'.LOG
$ ! Use the filename to create an error file so that the Phase Controller
$ ! will see only errors.
$ OPEN/WRITE FILE 'FILENAME
$ DEFINE SYS$ERROR FILE
$ WRITE SYS$ERROR "*** UETLOAD11 BEGINNING AT ''F$TIME() ***"
$ !
$SKIPFILE:
$ WRITE SYS$OUTPUT "*** UETLOAD11 BEGINNING AT ''F$TIME() ***"
$ !
$ PRN := 'F$PROC()
$ OFFST = 'F$LENGTH(PRN)'-4
$ PRN = 'F$EXTR(OFFST,4,PRN)'+1
$ WRITE SYS$OUTPUT "YOU ARE USER ''PRN' OUT OF ''F$LOGI("LOADS")'."
$ !
$ SET VERIFY
$ !
$ SHOW DAY
$ SHOW LOGI/ALL
$ SHOW PROC/PRIV
$ SHOW TIME
$ WAIT 00:01:23
$ SHOW TIME
$ SHOW SYST
$ DIRE/BRIE *.COM
$ SHOW STAT
$ RUN UETFORT03
$ !
$ WRITE SYS$OUTPUT "*** UETLOAD11 ENDED AT ''F$TIME() ***"
$ IF LOGFILE THEN WRITE SYS$ERROR "*** UETLOAD11 ENDED AT ''F$TIME() ***"
