$ ! UETDNET00.COM  VAX/VMS UETP DECnet Test Command File
$ !	.IDENT	'V03-009'
$ !
$ ! The edit history for this file is at its end.
$ !
$	LOGFILE = F$MODE() .NES. "INTERACTIVE"
$	IF .NOT. LOGFILE THEN GOTO SKIPFILE
$ ! Assume we are running under the Phase Controller if we are not interactive.
$ ! Trick it into reading our error file by creating a SYS$ERROR file with the
$ ! same name as our SYS$OUTPUT file.
$	PROC = F$GETJPI("","PRCNAM")
$	UNDER = 'F$LOCATE("_",PROC)
$	ID = UNDER+1
$	IF  UNDER .GT. 5 THEN UNDER = 5
$	FILENAME := 'F$EXTRACT(0,UNDER,PROC)''F$EXTRACT(ID,4,PROC)'.LOG
$	OPEN/WRITE FILE 'FILENAME
$	DEFINE SYS$ERROR FILE
$	WRITE SYS$ERROR "*** UETDNET00 BEGINNING AT ''F$TIME() ***"
$ !
$ SKIPFILE:
$	WRITE SYS$OUTPUT "*** UETDNET00 BEGINNING AT ''F$TIME() ***"
$ !
$	ON ERROR THEN GOTO ERROR_EXIT
$	ON CONTROL_Y THEN GOTO CLEAN_UP
$ !
$	SET COMMAND TCNTRL
$	STS$K_SUCCESS = 1
$	OLD_PRIVS = F$SETPRV("OPER")
$	MESSAGE = F$ENVIRONMENT("MESSAGE")
$	MD = F$TRNLNM("MODE") + "NORMAL"
$	MD = F$LOCATE("DUMP",MD) .NE. F$LENGTH(MD)
$	RF = F$TRNLNM("REPORT") + "LONG"
$	RF = (F$LOCATE("SHORT",RF) .EQ. F$LENGTH(RF)) .OR. MD
$ !
$ ! Test the EXECUTOR node.
$ !
$	IF RF THEN WRITE SYS$ERROR -
		"%UETP-I-BEGIN, EXECUTOR node testing beginning at ''F$TIME()"
$	RUN SYS$SYSTEM:NCP
	LOOP EXECUTOR COUNT 100 LENGTH 500 WITH MIXED
	LOOP EXECUTOR COUNT 128 LENGTH 10 WITH ONES
	LOOP EXECUTOR COUNT 100 LENGTH 128 WITH ZERO
$	IF RF THEN WRITE SYS$ERROR -
		"%UETP-I-ENDED, EXECUTOR node testing ended at ''F$TIME()"
$ !
$ ! Identify our currently testable DECnet nodes and circuits.  From them,
$ ! create command files to test those circuits, a Phase Controller data
$ ! file to run those command files, a data file so UETNETS00 knows which
$ ! circuits to test, and another command file so we may clear out the
$ ! DECnet counters for those circuits before testing them.
$ ! Typical UETININET.TMP records will look like:
$ !   cirnam            state    substate        loopback adjacent node
$ !   DMC-0             on                       LOOPB    2.161 (NODENM)
$ !   DMC-1.0           on       -starting
$ ! UETININET.DAT records will look like:
$ !   DMC-2 2.23 (MYNODE)
$ !
$	IF RF THEN WRITE SYS$ERROR -
		"%UETP-I-BEGIN, Network sizing beginning at ''F$TIME()"
$	RUN SYS$SYSTEM:NCP
	SHOW ACTIVE CIRCUITS TO UETININET.TMP
$	SEARCH/OUT=UETININET.TMP UETININET.TMP;-1 " on"
$	OPEN/READ NCPFILE UETININET.TMP
$ !
$	OPEN/WRITE NET01 UETDNET01.DAT
$	WRITE NET01 "NAME = UETDNET01"
$	WRITE NET01 "LOG = UETDNET01.LOG"
$ !
$	OPEN/WRITE ZERO ZERO.COM
$	WRITE ZERO "$ RUN SYS$SYSTEM:NCP"
$ !
$	OPEN/WRITE ININET UETININET.DAT
$ !
$	CIRCS = 0
$	ADJNODELOG = ""
$	ADJNODECOM = ""
$ ININET_LOOP:
$	READ/END=DONE NCPFILE RECORD
$	RECORD = F$EDIT(RECORD,"COMPRESS,TRIM")
$	SUBSTATE = F$ELEMENT(2," ",RECORD)
$	IF F$LENGTH(SUBSTATE) .NE. F$LOCATE("-",SUBSTATE) -
		THEN GOTO ININET_LOOP		 ! Ignore if funny substate, too
$	CIRNAM = F$ELEMENT(0," ",RECORD)	 ! Extract the circuit name
$	ADDRESS = F$ELEMENT(2," ",RECORD)	 ! Extract the adj node address
$	NODE = F$ELEMENT(3," ",RECORD)		 ! Extract the adj node name
$	IF NODE .EQS. " " .AND. ADDRESS .EQS. " " THEN GOTO ININET_LOOP
$	FIRSTCHAR = F$EXTRACT(0,1,ADDRESS)	 ! Check to see...
$	IF (F$CVUI(0,8,FIRSTCHAR) .LT. 48) .OR. -! ...if there's a loopback...
		(F$CVUI(0,8,FIRSTCHAR) .GT. 57)- ! ...preceding address...
		THEN ADDRESS = NODE		 ! ...and account for it if so
$	IF F$LENGTH(NODE) .EQ. F$LOCATE("(",NODE) - ! Could we pick off...
		THEN NODE = F$ELEMENT(4," ",RECORD) ! ...name? Try again if not
$	CIRCS = CIRCS + 1
$	FFN = CIRNAM - "-" - "-" - "."		 ! Make command procedure name
$	FFN = FFN + ADDRESS - "."
$	FFC = FFN + ".COM"
$	ADJNODELOG = ADJNODELOG + "," + F$EXTRACT(0,5,FFN) + "*.LOG;*"
$	ADJNODECOM = ADJNODECOM + ","+F$EXTRACT(0,5,FFN)+"*.LOG;*"+","+FFC+";*"
$	NODESPEC = ADDRESS
$	IF F$LENGTH(ADDRESS) .EQ. F$LOCATE(".",ADDRESS) -
		THEN NODESPEC = "0." + ADDRESS
$	NODESPEC = 'F$ELEMENT(0,".",NODESPEC) -	 ! Figure 16-bit node number
		* 1024 + F$ELEMENT(1,".",NODESPEC)
$ 	OPEN/WRITE NCPCOM 'FFC'			 ! Create .COM file to test it
$	WRITE NCPCOM "$ RUN SYS$SYSTEM:NCP"
$	WRITE NCPCOM "SHOW NODE ",ADDRESS," STATUS"
$ 	WRITE NCPCOM "LOOP NODE ",ADDRESS," COUNT 100 LENGTH 500 WITH ONES"
$ 	WRITE NCPCOM "LOOP NODE ",ADDRESS," COUNT 100 LENGTH 10 WITH ZERO"
$	WRITE NCPCOM "LOOP NODE ",ADDRESS," COUNT 100 LENGTH 128 WITH MIXED"
$	WRITE NCPCOM "SHOW COUNTERS NODE ",ADDRESS
$	WRITE NCPCOM "SHOW COUNTERS CIRCUIT ",CIRNAM
$ !
$ 	WRITE NCPCOM "$ ON ERROR THEN GOTO REMOTE_ERROR"
$ 	WRITE NCPCOM "$ COPY UETP.COM ",NODESPEC,"""""::",FFN,".D'P1'"
$	WRITE NCPCOM "$ COPY ",NODESPEC,"""""::",FFN,".D'P1' *"
$	WRITE NCPCOM "$ DELETE ",NODESPEC,"""""::",FFN,".D'P1';*"
$	WRITE NCPCOM "$ DIFF /OUT=SYS$ERROR UETP.COM ",FFN,".D'P1'"
$	WRITE NCPCOM "$ DELETE ",FFN,".D'P1';*"
$ 	WRITE NCPCOM "$REMOTE_ERROR:"
$	WRITE NCPCOM "$ STATUS = '$STATUS"
$	WRITE NCPCOM "$ SEVERITY = 0"
$	WRITE NCPCOM "$ SEVERITY[0,3] = 'STATUS"
$	WRITE NCPCOM "$ IF SEVERITY .NE. ''STS$K_SUCCESS' THEN WRITE -"
$	WRITE NCPCOM "SYS$ERROR ""%UETP-"", -"
$	WRITE NCPCOM """E-TEXT, Remote file test data error"""
$	WRITE NCPCOM "$ EXIT 'STATUS"
$ 	CLOSE NCPCOM
$	IF MD THEN TYPE 'FFC'
$ !
$	WRITE ZERO "ZERO NODE ",ADDRESS," COUNTERS"
$	WRITE ZERO "ZERO CIRCUIT ",CIRNAM," COUNTERS"
$ !
$	WRITE NET01 "Y Y ",FFC," ""1"""
$	WRITE NET01 "Y Y ",FFC," ""2"""
$ !
$	IF NODE .NES. " " THEN WRITE ININET CIRNAM," ",ADDRESS," ",NODE
$	IF NODE .EQS. " " THEN WRITE ININET CIRNAM," ",ADDRESS
$ !
$	IF RF THEN WRITE SYS$ERROR -
		"	Testing circuit ",CIRNAM," to node ",ADDRESS," ",NODE
$	GOTO ININET_LOOP
$ DONE:
$	IF CIRCS .NE. 0 THEN GOTO TESTABLE
$	WRITE SYS$ERROR "%UETP-W-TEXT, No active circuits to test."
$	GOTO TEST_END
$ TESTABLE:
$	ADJNODELOG = ADJNODELOG - ","
$	ADJNODECOM = ADJNODECOM - ","
$	WRITE ININET "END OF UETININET.DAT"
$	CLOSE NCPFILE
$	CLOSE ININET
$	CLOSE NET01
$	CLOSE ZERO
$	IF RF THEN WRITE SYS$ERROR -
		"%UETP-I-ENDED, Network sizing ended at ''F$TIME()"
$ !
$ ! Do remote circuit testing.  Zero node and circuit counters and run all the
$ ! test command files (in parallel if the maximum load count permits us).
$ !
$	@ZERO
$	X = 1
$	IF F$TRNLNM("LOADS") .NES. "" THEN X = 'F$TRNLNM("LOADS")
$	IF X .GT. (2*CIRCS) THEN X = 2*CIRCS
$	IF RF THEN WRITE SYS$ERROR -
		"%UETP-I-BEGIN, Remote circuit testing beginning at ''F$TIME()"
$	TCNTRL UETDNET01.DAT /NODELETE /PAR='X
$	SET MESSAGE/NOFACILITY/NOIDENTIFICATION/NOSEVERITY/NOTEXT
$	SEARCH/OUTPUT=SYS$ERROR/NOHEADING 'ADJNODELOG "-I-","-W-","-E-","-F-"
$	STATUS = $STATUS
$	SET MESSAGE'MESSAGE
$	IF STATUS .EQ. STS$K_SUCCESS THEN WRITE SYS$ERROR -
		"%UETP-I-TEXT, Remote circuit test errors are listed above"
$	IF MD .OR. STATUS .EQ. STS$K_SUCCESS THEN TYPE 'ADJNODELOG
$	IF RF THEN WRITE SYS$ERROR -
		"%UETP-I-ENDED, Remote circuit testing ended at ''F$TIME()"
$ !
$ ! Do a counter check.
$ !
$	RUN UETNETS00
$ 	GOTO TEST_END
$ !
$ ERROR_EXIT:
$	STATUS = F$MESSAGE($STATUS)
$	WRITE SYS$ERROR -
		"%UETP-I-TEXT, Error status is: ",STATUS
$ 	GOTO TEST_END
$ CLEAN_UP:
$	WRITE SYS$ERROR -
		"%UETP-I-TEXT, DECnet UETP test aborted by CONTROL-Y"
$ TEST_END:
$	SET NOON
$	SET MESSAGE/NOFACILITY/NOIDENTIFICATION/NOSEVERITY/NOTEXT
$	SET PROCESS/PRIVILEGE='OLD_PRIVS
$	CLOSE NCPFILE
$	CLOSE NCPCOM
$	CLOSE ININET
$	CLOSE NET01
$	CLOSE ZERO
$	DELETE 'ADJNODECOM
$	DELETE UETININET.TMP;*,UETININET.DAT;*,ZERO.COM;*,-
		UETDNET01.DAT;*,UETDNET01.LOG;*,UETNETS00.LOG;*
$	SET COMMAND /DELETE=TCNTRL
$	SET MESSAGE'MESSAGE
$	WRITE SYS$OUTPUT "*** UETDNET00 ENDED AT ''F$TIME() ***"
$	IF .NOT. LOGFILE THEN EXIT
$	WRITE SYS$ERROR "*** UETDNET00 ENDED AT ''F$TIME() ***"
$	CLOSE FILE
$	DEASSIGN SYS$ERROR
$	EXIT				! End of DECnet TEST

!++
!
! CREATED BY: Paul Jenq, 28-Aug-1981
!
! MODIFIED BY:
!
!	V03-009	RNH0004		Richard N. Holstein,	27-Jun-1984
!		Fix bugs in collecting list of files to clean up and in being
!		too stringent in deciding if a remote node test succeeded.
!
!	V03-008	RNH0003		Richard N. Holstein,	07-Apr-1984
!		Report back errors from remote node testing.
!
!	V03-007	RNH0002		Richard N. Holstein,	22-Feb-1984
!		Allow a node name to be null.
!
!	V03-006	RNH0001		Richard N. Holstein,	27-Sep-1983
!		Fix miscellaneous bugs and cleanup.
!
!	V03-005 LDJ0004		Larry D. Jones,		07-Apr-1983
!		Updated to conform to the new TCNTRL command format.
!
!	V03-004 LDJ0003		Larry D. Jones,		24-Jan-1983
!		Updated to area DECnet changes. Removed the sequential
!		test part.
