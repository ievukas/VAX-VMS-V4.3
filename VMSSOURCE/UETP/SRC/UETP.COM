$ VERIFY = F$VERIFY(0)
$!
$! UETP.COM  VAX/VMS UETP COMMAND FILE
$!	.IDENT	'V03-019'
$!
$! The edit history is at the end of this file.
$!
$! Set up those things we need in order to start the UETP:
$!
$!...a beginning sentinel...
$ IF F$MODE() .NES. "INTERACTIVE" THEN -
	WRITE SYS$OUTPUT "UETP STARTED AT ''F$TIME()'"
$!
$!...commands for a tailored system...
$ DEFINE CONVERT SYS$SYSTEM:CONVERT.EXE,LIB$SYSTEM:CONVERT.EXE ! UETP
$ DEFINE CONVSHR SYS$LIBRARY:CONVSHR.EXE,LIB$LIBRARY:CONVSHR.EXE ! UETP
$ DEFINE/GROUP CDU SYS$SYSTEM:CDU.EXE,LIB$SYSTEM:CDU.EXE ! UETP, UETDNET00
$ DEFINE/GROUP DIFF SYS$SYSTEM:DIFF.EXE,LIB$SYSTEM:DIFF.EXE ! UETDNET00
$ DEFINE/GROUP HELPLIB SYS$HELP:HELPLIB.HLB,LIB$HELP:HELPLIB.HLB ! UETLOAD05
$ DEFINE/GROUP SEARCH SYS$SYSTEM:SEARCH.EXE,LIB$SYSTEM:SEARCH.EXE ! UETDNET00
$ DEFINE/GROUP SYS$TEST SYS$SYSROOT:[SYSTEST],LIB$SYSROOT:[SYSTEST] ! UETP, UETDNET00
$!
$!...the command set to run UETPHAS00...
$ SET COMMAND TCNTRL
$!
$! ...determining if DECnet is available for testing (look for device NET0:)...
$ NET = F$GETDVI("NET0:","EXISTS")
$ IF NET THEN NET = F$GETDVI("NET0:","MNT")
$!
$! ...determining if a LAT will interfere (look for device LTA0:)...
$ LAT = F$GETDVI("LTA0:","EXISTS")
$ IF .NOT. LAT THEN GOTO NOLAT
$ LCP = "$LATCP"
$ DEFINE/USER SYS$OUTPUT LAT.TMP
$ LCP SHOW CHAR
$ SET MESSAGE/NOFACILITY/NOSEVERITY/NOIDENT/NOTEXT
$ SEARCH LAT.TMP;-1 /OUTPUT=LAT.TMP INACTIVE
$ LAT = '$SEVERITY .EQ. 3
$ DELETE LAT.TMP;*
$ SET MESSAGE/FACILITY/SEVERITY/IDENT/TEXT
$NOLAT:
$!
$!...and abort sequences
$ ON ERROR THEN GOTO END
$ ON CONTROLY THEN GOTO CNTRLY
$!
$!
$!			--- INITIALIZATION PHASE ---
$!
$ IF F$SEARCH("OLDUETP.LOG") .NES. "" THEN DELETE OLDUETP.LOG;*
$ IF F$SEARCH("UETP.LOG") .NES. "" THEN RENAME UETP.LOG;* OLDUETP.LOG;*
$!
$ RUN UETINIT00
$ IF $SEVERITY .NE. 1 THEN EXIT $STATUS
$ REPORT = F$TRNLNM("REPORT")
$ UETPPHASE = F$TRNLNM("UETPPHASE")
$ LOADS = F$TRNLNM("LOADS")
$!
$! We need to run UETINIT01 only if we will be running the device test phase.
$ IF F$LOCATE("DEVICE",UETPPHASE) .EQ. F$LENGTH(UETPPHASE) THEN GOTO SKIP_INIT01
$!
$! Deallocate communication devices owned by DECnet while running UETINIT01.
$ DECNET_RETURN := INIT01
$ GOTO DISABLE_DECNET
$INIT01:
$!
$ RUN UETINIT01
$ INIT01_STATUS = '$STATUS
$ INIT01_SEVERITY = INIT01_STATUS .AND. %X7
$ APPEND UETINIT01.LOG UETP.LOG
$ DELETE UETINIT01.LOG;*
$!
$ DECNET_RETURN := INIT01_END
$ GOTO ENABLE_DECNET
$INIT01_END:
$!
$ IF INIT01_SEVERITY .NE. 1 THEN EXIT INIT01_STATUS
$SKIP_INIT01:
$!
$!
$ PASS = 0
$ SET NOON
$! For each pass of the UETP, create a new version of UETP.LOG.
$LOOP:
$ IF PASS .NE. 0 THEN CREATE UETP.LOG
$ PASS = PASS+1
$!
$!
$!
$!			--- DEVICE TEST PHASE ---
$!
$ IF F$LOCATE("DEVICE",UETPPHASE) .EQ. F$LENGTH(UETPPHASE) THEN GOTO SKIP_DEVICE
$!
$! Deallocate communication devices owned by DECnet during device test phase.
$ DECNET_RETURN := DEVICE
$ GOTO DISABLE_DECNET
$DEVICE:
$!
$ PARCNT = F$TRNLNM("TEST_COUNT")
$ IF PARCNT .GT. LOADS THEN PARCNT = LOADS
$!
$ TCNTRL UETCONT00.DAT /PARALLEL_COUNT='PARCNT /REPORT_TYPE='REPORT
$ APPEND UETPDEV00.LOG UETP.LOG
$ DELETE UETPDEV00.LOG;*
$!
$ DECNET_RETURN := DEVICE_END
$ GOTO ENABLE_DECNET
$DEVICE_END:
$!
$SKIP_DEVICE:
$!
$!
$!
$!			--- LOAD TEST PHASE ---
$!
$ IF F$LOCATE("LOAD",UETPPHASE) .EQ. F$LENGTH(UETPPHASE) THEN GOTO SKIP_LOAD
$!
$ TCNTRL UETLOAD00.DAT /PARALLEL_COUNT='LOADS /REPORT_TYPE='REPORT
$ APPEND UETLOAD00.LOG UETP.LOG
$ DELETE UETLO*.LOG;*
$!
$SKIP_LOAD:
$!
$!
$!
$!			--- DECNET TEST PHASE ---
$!
$ IF F$LOCATE("DECNET",UETPPHASE) .EQ. F$LENGTH(UETPPHASE) THEN GOTO SKIP_DECNET
$!
$ IF NET THEN GOTO DO_DECNET
$ NONET := "''F$FAO(-
	"!/!14* ** NOTE **!/DECnet is not available and cannot be tested.!/")'"
$ WRITE SYS$OUTPUT NONET
$ OPEN/APPEND UETPLOG UETP.LOG
$ WRITE UETPLOG NONET
$ CLOSE UETPLOG
$ GOTO SKIP_DECNET
$!
$DO_DECNET:
$ TCNTRL UETDNET00.DAT /REPORT_TYPE='REPORT
$ CONVERT/APPEND UETDN0000.LOG UETP.LOG
$ DELETE UETDN0000.LOG;*,UETDNET00.LOG;*
$!
$SKIP_DECNET:
$!
$!
$!
$!			--- CLUSTER INTEGRATION PHASE ---
$!
$ IF F$LOCATE("CLUSTER",UETPPHASE) .EQ. F$LENGTH(UETPPHASE) THEN -
	GOTO SKIP_CLUSTER
$!
$ IF F$GETSYI("CLUSTER_MEMBER") THEN GOTO DO_CLUSTER
$ NOCLUSTER := "''F$FAO(-
	"!/!14* ** NOTE **!/This system is not a member of a cluster.!/")'"
$ WRITE SYS$OUTPUT NOCLUSTER
$ OPEN/APPEND UETPLOG UETP.LOG
$ WRITE UETPLOG NOCLUSTER
$ CLOSE UETPLOG
$ GOTO SKIP_CLUSTER
$!
$DO_CLUSTER:
$ TCNTRL UETCLIG00.DAT /REPORT_TYPE='REPORT
$ APPEND UETCLIG00.LOG UETP.LOG
$ DELETE UETCLIG00.LOG;*
$!
$SKIP_CLUSTER:
$!
$!
$ WRITE SYS$OUTPUT " ***************************************************"
$ WRITE SYS$OUTPUT " *                                                 *"
$ WRITE SYS$OUTPUT "    END OF UETP PASS ''PASS AT ''F$TIME()    "
$ WRITE SYS$OUTPUT " *                                                 *"
$ WRITE SYS$OUTPUT " ***************************************************"
$ IF PASS .LT. F$TRNLNM("PASSCNT") THEN GOTO LOOP
$ GOTO END
$!
$!
$CNTRLY:
$ WRITE SYS$OUTPUT "UETP Aborted via CTRL/Y at ''F$TIME()."
$!
$END:
$ SET NOON
$ MESSAGE = F$ENVIRONMENT("MESSAGE")
$ SET MESSAGE/NOFACILITY/NOIDENTIFICATION/NOSEVERITY/NOTEXT
$ SET COMMAND /DELETE=TCNTRL
$ DELETE UETCONT00.DAT;*
$ DEASSIGN CONVERT
$ DEASSIGN CONVSHR
$ DEASSIGN/GROUP SYS$TEST
$ DEASSIGN/GROUP CDU
$ DEASSIGN/GROUP DIFF
$ DEASSIGN/GROUP HELPLIB
$ DEASSIGN/GROUP SEARCH
$ DEASSIGN/GROUP TEST_COUNT
$ DEASSIGN/GROUP LOADS
$ DEASSIGN/GROUP PASSCNT
$ DEASSIGN/GROUP REPORT
$ DEASSIGN/GROUP MODE
$ DEASSIGN/GROUP UETPPHASE
$ DEASSIGN/GROUP UET$MAGTAP
$ SET MESSAGE'MESSAGE
$!
$!
$! Write an ending sentinel
$ IF F$MODE() .NES. "INTERACTIVE" THEN -
	WRITE SYS$OUTPUT "UETP STOPPED AT ''F$TIME()"
$ VERIFY = F$VERIFY(VERIFY)
$ EXIT

$DISABLE_DECNET:
$ IF LAT THEN LCP STOP/NOLOG
$ IF .NOT. NET THEN GOTO 'DECNET_RETURN
$ PRIVSTATE = F$SETPRV("OPER")
$ RUN SYS$SYSTEM:NCP
SET KNOWN CIRCUITS STATE OFF
SET KNOWN LINES STATE OFF
CLEAR KNOWN LINES ALL
CLEAR KNOWN CIRCUITS ALL
EXIT
$ SET PROCESS/PRIVILEGE='PRIVSTATE
$ GOTO 'DECNET_RETURN

$ENABLE_DECNET:
$ IF .NOT. NET THEN GOTO ENABLE_LCP
$ PRIVSTATE = F$SETPRV("OPER")
$ RUN SYS$SYSTEM:NCP
SET KNOWN LINES ALL
SET KNOWN CIRCUITS ALL
EXIT
$ SET PROCESS/PRIVILEGE='PRIVSTATE
$ENABLE_LCP:
$ IF LAT THEN LCP START/NOLOG
$ GOTO 'DECNET_RETURN

!++

 CREATED BY: Larry Jones, 18-Mar-1981

 MODIFIED BY:

	V03-019	RNH0008		Richard N. Holstein,	06-Aug-1984
		Silence commands to start and stop LAT.

	V03-018	PEL0001		Patti E. Lutsky,	21-Jun-1984
		Add logical name for SEARCH and add commands to turn off
		the LAT.

	V03-017	RNH0007		Richard N. Holstein,	21-Mar-1984
		Add message for not cluster member.

	V03-016	RNH0006		Richard N. Holstein,	04-Jan-1984
		Allow for any subset of phases to be selected.

	V03-015	RNH0005		Richard N. Holstein,	15-Sep-1983
		Be more cautious regarding DECnet's testability.  Set up
		logical names for a tailored system.

	V03-014	RNH0004		Richard N. Holstein,	10-Jul-1983
		Cleanup prior to field test.  Add Cluster Integration phase.

	V03-013	BAA0004		Brian A. Axtell,	29-Mar-1983
		Changed the qualifier names for UETPHAS00.

	V03-012	BAA0003		Brian A. Axtell,	14-Jan-1983
		Changed the way that we were determining whether or 
		not DECnet was active.

	V03-011	BAA0002		Brian A. Axtell,	10-Dec-1982
		Changed the way the input for UETPHAS00 were defined to
		correspond to the new version of UETPHAS00.
		Removed phases for RMS32, system services, native utilities,
		and compatibility mode tests.

	V03-010 BAA0001		Brian A. Axtell,	18-Nov-1982
		Put in set noverify command and commands to write beginning
		and ending sentinels so that UETP can be run under 
		UETPHAS00.  Changed "end-of-pass" message to say that it
		was the UETP that ended.

!**
!--
