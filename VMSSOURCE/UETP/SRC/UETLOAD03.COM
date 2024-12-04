$ ! UETLOAD03.COM
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
$ WRITE SYS$ERROR "*** UETLOAD03 BEGINNING AT ''F$TIME() ***"
$ !
$SKIPFILE:
$ WRITE SYS$OUTPUT "*** UETLOAD03 BEGINNING AT ''F$TIME() ***"
$ !
$ PRN := 'F$PROC()
$ OFFST = 'F$LENGTH(PRN)'-4
$ PRN = 'F$EXTR(OFFST,4,PRN)'+1
$ WRITE SYS$OUTPUT "YOU ARE USER ''PRN' OUT OF ''F$LOGI("LOADS")'."
$ !
$ SET VERIFY
$ !
$ SHOW DAY
$ SHOW DEFAULT
$ ! NOW LOOP RUNNING UETFORT02 20 TIMES.
$ ASSI TEMP.'PRN SYS$OUTPUT
$ SET NOVERIFY
$ COUNT = 0
$LOOP:
$ RUN UETFORT02
$ COUNT = COUNT + 1
$ IF COUNT .LE. 20 THEN GOTO LOOP
$ SET VERIFY
$ DEAS SYS$OUTPUT
$ DELE TEMP.'PRN';*
$ SHOW LOGI/ALL
$ SHOW STAT
$ DIRE [*]SYS.*/FULL
$ !
$ WRITE SYS$OUTPUT "*** UETLOAD03 ENDED AT ''F$TIME() ***"
$ IF LOGFILE THEN WRITE SYS$ERROR "*** UETLOAD03 ENDED AT ''F$TIME() ***"
