$ !
$ !	[ SYSBLDCOM ] T R I A L S Y S . C O M
$ !
$ !	This is a batch command file to build a new executive and relink
$ !	all the components that link with the executive symbol table.
$ !
$ !	Both the LNKLIB and LINK phases are executed in order to properly
$ !	link the exec, privileged libraries and other privileged images.
$ !
$ !	It is submitted with the following parameters:
$ !
$ !		TARGDIR = P1 (Required)	The name of the main device/directory
$ !					that contains a [.OBJ] directory
$ !					with the .OLB's and will get the
$ !					.EXE's and a [.LIS] directory
$ !					that will get the .MAP's.
$ !					Directory bracket delimiters are
$ !					optional.  If device not specified,
$ !					OBJD$ is used.
$ !
$ !	    OLBs TO USE = P2 (Optional)	The name(s) of the facilities
$ !					that have their .OLB's in the
$ !					TARGDIR directory.
$ !					If none are specified, SYS is
$ !					the default.
$ !
$ !					example: "SYS,TTDRVR,CLIUTL"
$ !
$ !		CLASSES	= P3 (Optional)	The classes of images that will
$ !					be built with this trialsys.
$ !					Default is ALL.
$ !					Specify BASE for minimum bootable
$ !					system. Other cleasses can be
$ !					included one by one.
$ !					
$ !					Current classes:
$ !
$ !					BASE  - required to boot and use system.
$ !					MP    - multiprocessor images.
$ !					NET   - DECnet specific.
$ !					DATA  - Data integrity (RCP, JNL, etc)
$ !					UTIL  - random utilities
$ !					UETP  - UETP
$ !					TAPE  - mag tape images.
$ !					RSX   - RSX/MCR images.
$ !
$ !
$ !	For each facility listed in P2, TRIALSYS will look in
$ !	['TARGDIR'.COM] for 'FACILITY'BLD.COM, and use it (and all the
$ !	files it calls) from there if it is present. If it is not there,
$ !	the build files from [SYSOBJ.'FACILITY'.COM] are used.  If the
$ !	command files still cannot be found there, the master disk command
$ !	files are used instead.
$ !
$ !
$ ON WARNING THEN GOTO EXIT			! Catch all setup errors
$
$ ! Set up logical name table
$ CREATE/NAME_TABLE/ATTRIBUTES=SUPERSEDE LNM$TRIALSYS
$ DEFINE/TABLE=LNM$PROCESS_DIRECTORY LNM$FILE_DEV -
	LNM$TRIALSYS,LNM$PROCESS,LNM$JOB,LNM$GROUP,LNM$SYSTEM
$ ASSIGN := ASSIGN/TABLE=LNM$TRIALSYS/NOLOG
$ DEFINE := DEFINE/TABLE=LNM$TRIALSYS/NOLOG
$
$ TARGDIR = P1				! Assume only directory name given
$ IF P2 .EQS. "" THEN P2 = "SYS"	! Default component = SYS only
$ P2 = F$EDIT(P2,"UPCASE,TRIM") + ","	! Upcase, trim blanks, add ","
$ IF P3 .EQS. "" THEN P3 = "ALL"	! Build the world
$ P3 = F$EDIT(P3,"UPCASE,TRIM") 	! trim blanks and upcase
$ IF P4 + P5 + P6 + P7 + P8 .NES. "" THEN GOTO PARAM_ERROR
$
$ ! Output input parameters for log file
$
$ WRITE SYS$OUTPUT ""
$ WRITE SYS$OUTPUT "Trialsys started at ",F$TIME()
$ WRITE SYS$OUTPUT "Inputs to job are:"
$ SHOW SYM TARGDIR
$ OLBS_TO_USE = F$EXT(0,F$LEN(P2)-1,P2)
$ SHOW SYM OLBS_TO_USE
$ CLASSES = P3
$ SHOW SYM CLASSES
$ WRITE SYS$OUTPUT ""
$
$ TARGDIR = F$PARSE(P1,,,"DIRECTORY") - "[" - "]"	! target directory
$ TARGDEV = F$PARSE(P1,"SYS$LOGIN_DEVICE",,"DEVICE")	! Default result disk
$ TARGDEV = "DISK$" + F$GETDVI(TARGDEV,"VOLNAM") + ":"	! DISK$xxx:
$ RESDEV  = "DISK$" + F$GETDVI("RESD$","VOLNAM") + ":"	! DISK$xxx:
$ PERMOBJ := 'RESDEV'[SYSOBJ		! Where to find permanent objects
$ PROCDIR := 'RESDEV'[SYSOBJ		! Where to find permanent procedures
$
$ SET NOON
$ ASSIGN MASD$: SRCD$:
$ ASSIGN 'TARGDEV' COMD$:
$ ASSIGN 'TARGDEV' LB0:
$ ASSIGN 'TARGDEV' LB:
$ ASSIGN 'TARGDEV' OBJD$:
$ ASSIGN 'TARGDEV' LISD$:
$ ASSIGN 'TARGDEV' MAPD$:
$ ASSIGN 'TARGDEV' EXED$:
$ ASSIGN 'TARGDEV' LIBD$:
$ ASSIGN 'TARGDEV' RESD$:
$ ASSIGN EXED$:['TARGDIR'.OBJ] EXE$:
$ ASSIGN MAPD$:['TARGDIR'.LIS] MAP$:
$ ASSIGN LISD$:['TARGDIR'.LIS] LIS$:
$ ASSIGN 'TARGDEV'['TARGDIR'.OBJ] EXSM:
$ ASSIGN 'TARGDEV'['TARGDIR'.OBJ] RESLNK$:
$ ASSIGN 'TARGDEV'['TARGDIR'.OBJ],'PERMOBJ'] RESOBJ$:
$ ASSIGN 'PERMOBJ'] RESEXE$:
$ ASSIGN 'PERMOBJ'] RESMGR$:
$ ASSIGN 'PERMOBJ'] RESUPD$:
$ LINK == "LINK /USERLIB=PROC"		! Use process defaults
$ DEFIN LNK$LIBRARY SYS$LIBRARY:SYSBLDLIB ! *** linker can't use LNM$TRIALSYS yet
$ @SYSBLDCOM$:CPYRESDEF			! Define result copy functions
$ CPYSYSLIB := @SYSBLDCOM$:NULL		! except don't do this
$ CPYRESEXE := @SYSBLDCOM$:NULL		! or this
$ INSHARLIB := @SYSBLDCOM$:NULL		! or this
$ SET NOVERIFY
$ CPYOLB = "N"				! Do not copy results to RESOBJ$
$ PHASE	== "LNKLIB"
$ SUB_PHASE = 0
$ LAST_FAC = "VMSLIB"			!**change if anything after VMSLIB fac
$ IF F$LOG("DATA")  .NES. "" THEN CLOSE DATA	! make sure files are closed
$ IF F$LOG("DATA1") .NES. "" THEN CLOSE DATA1	! make sure files are closed
$ OPEN /ERROR=NODATA DATA RESOBJ$:VMSNEWBLD.DAT	! Open facility data file
$ OPEN /ERROR=NODATA DATA1 RESOBJ$:VMSNEWBLD.DAT
$
$ IF .NOT. $RESTART THEN GOTO NOT_RESTART
$ IF BATCH$RESTART .EQS. "" THEN GOTO NOT_RESTART ! if still null
$ !
$ ! RESTART THIS JOB BY POSITIONING JOB IN FACILITY AND PHASE WHERE IT QUIT
$ !
$ PHASE  = F$EXTRACT(0,F$LOC(",",BATCH$RESTART),BATCH$RESTART)
$ FACNAM = BATCH$RESTART  - PHASE - ","
$ WRITE SYS$OUTPUT "%TRIALSYS-W-RESTART, restarting TRIALSYS"
$ WRITE SYS$OUTPUT "-TRIALSYS-I-PHASEFAC, in ''PHASE' phase of facility ''FACNAM'"
$ READ/NOLOCK /ERROR=ERR_RESTART/INDEX=1 /KEY="''PHASE' "  DATA CMD
$RESTART_1:
$ TSTFACNAM = F$EXT(0,F$LOC(" ",CMD),CMD)
$ IF TSTFACNAM .EQS. FACNAM THEN GOTO RESTART_2
$ READ/NOLOCK /ERROR=ERR_RESTART DATA CMD /END=ERR_RESTART
$ GOTO RESTART_1
$RESTART_2:
$ READ/NOLOCK /ERROR=ERR_RESTART/INDEX=0 /KEY="''FACNAM' " DATA1 CMD1
$ GOTO NXTCMD40	! restart in middle of trialsys
$
$NOT_RESTART: 
$ READ/NOLOCK /ERROR=NEXT_PHASE/INDEX=1 /KEY="''PHASE' " DATA CMD
$ GOTO NXTCMD10
$ !
$ ! GET NEXT FACILITY NAME FROM DATA FILE AND DETERMINE IF IT
$ ! NEEDS TO BE RE-BUILT WITH THE EXECUTIVE SYMBOL TABLE (/EXEC QUALIFIER).
$ !
$NXTCMD:
$ READ/NOLOCK DATA CMD /END=NEXT_PHASE
$NXTCMD10:
$ S1 = F$EXT(16,16,CMD)
$ S1 = F$EXT(0,F$LOC(" ",S1),S1)
$ IF S1 .NES. PHASE THEN GOTO NEXT_PHASE
$ FACNAM = F$EXT(0,F$LOC(" ",CMD),CMD)
$
$ 	! check for /SKIP on PHASE line
$
$ IF F$LOC("/SKIP",CMD) .NE. F$LENGTH(CMD) THEN GOTO NXTCMD70
$NXTCMD20:
$
$	! get AAINFO line, check for /EXEC="class"
$
$ READ /NOLOCK /INDEX=0 /KEY="''FACNAM' " /ERROR=NOFAC DATA1 CMD1
$ GOTO NXTCMD40
$NXTCMD30:
$ READ/NOLOCK /ERROR=NOFAC DATA1 CMD1
$NXTCMD40:
$ IF FACNAM .NE. F$EXT(0,F$LOC(" ",CMD1),CMD1) THEN GOTO NXTCMD  ! NOT FOUND?
$ S1 = F$EXT(16,16,CMD1)
$ S1 = F$EXT(0,F$LOC(" ",S1),S1)
$ IF S1 .NES. "AAINFO" THEN GOTO NXTCMD30
$ IF F$LOCATE("/EXEC",CMD1) .EQ. F$LENGTH(CMD1) THEN GOTO NXTCMD70
$ IF P3 .EQS. "ALL" THEN GOTO DOFAC	 ! Check for Keyword "ALL"
$ !
$ ! GET /EXEC CLASS
$ !
$ E1 = F$EXT(F$LOC("/EXEC",CMD1),99,CMD1)  ! throw away first part of line
$ E1 = F$EXT(F$LOC("=",E1)+1,99,E1)  ! throw away "/EXEC="
$ ! get rid of rest of line
$ IF F$LOC("/",E1) .NE. F$LEN(E1) THEN E1 = F$EXT(0,F$LOC("/",E1),E1)
$ E1 = F$EDIT(E1,"TRIM")
$ IF E1 .NES. "" THEN GOTO E1_OK
$  WRITE SYS$OUTPUT -
	"%TRIALSYS-E-BADEXEC, ''FACNAM' does not have proper /EXEC qualifier"
$  GOTO DOFAC	! Assume none means required
$E1_OK:
$ IF F$LOC(E1,P3) .NE. F$LEN(P3) THEN GOTO DOFAC
$ WRITE SYS$OUTPUT "%TRIALSYS-I-SKIP, Skipping Facility ",facnam
$
$NXTCMD70:
$ IF FACNAM .EQS. LAST_FAC THEN GOTO NEXT_PHASE
$ GOTO NXTCMD
$
$DOFAC: 
$ RESTART_SYM = PHASE + "," + FACNAM
$ SET RESTART_VALUE = "''RESTART_SYM'"	! save for restart
$ !
$ ! WE NOW HAVE A FACILITY TO DO FOR THIS PHASE
$ !
$ ! DETERMINE IF FACILITY'S .OLB IS IN [TARGDIR.OBJ] OR [SYSOBJ]
$ !
$ IF F$LOC(FACNAM+",",P2) .NE. F$LEN(P2) THEN GOTO TARGDIR_FAC
$ !
$ ! FACILITY'S .OLB IS NOT IN [TARGDIR.OBJ]
$ !
$ ASSIGN 'PERMOBJ'] OBJ$:
$ ASSIGN 'PERMOBJ'] LIB$:
$ GOTO SYSOBJ_COM
$ !
$ ! FACILITY'S .OLB IS IN [TARGDIR.OBJ]
$ !
$TARGDIR_FAC:
$ ASSIGN OBJD$:['TARGDIR'.OBJ] OBJ$:
$ ASSIGN LIBD$:['TARGDIR'.OBJ] LIB$:
$ !
$ ! SEE IF USER COMMAND FILES ARE ALSO PRESENT
$ !
$ IF F$SEARCH("COMD$:[''TARGDIR'.COM]''FACNAM'BLD.COM") .EQS. "" -
	THEN GOTO SYSOBJ_COM
$ ASSIGN COMD$:['TARGDIR'.COM] COM$:
$ GOTO BUILD_IT
$ !
$ ! SEE IF PERMANENT COMMAND FILES ARE PRESENT IN [SYSOBJ...]
$ !
$SYSOBJ_COM:
$ IF F$SEARCH("''PERMOBJ'.''FACNAM'.COM]''FACNAM'BLD.COM") .EQS. "" -
		THEN GOTO MASTER_COM
$ ASSIGN 'PERMOBJ'.'FACNAM'.COM] COM$:
$ GOTO BUILD_IT
$ !
$ ! IF COMMAND FILES NOT FOUND IN EITHER USER DIRECTORY OR [SYSOBJ...]
$ ! THEN USE THE ONES ON THE MASTER DISK.
$ !
$MASTER_COM:
$ ASSIGN MASD$:['FACNAM'.COM] COM$:
$ !
$ !	RE-LINK THE COMPONENT WITH THE NEW EXECUTIVE
$ !
$BUILD_IT:
$ 
$ SAVE_PHASE = PHASE
$ PHASE = F$EXT(0,F$LOC("_",PHASE),PHASE)
$ WRITE SYS$OUTPUT "!*****************************************************************************"
$ WRITE SYS$OUTPUT "!*									     *"
$ WRITE SYS$OUTPUT "!*			BUILD	''FACNAM'   (''PHASE' PHASE)			     *"
$ WRITE SYS$OUTPUT "!*									     *"
$ WRITE SYS$OUTPUT "!*****************************************************************************"
$ WRITE SYS$OUTPUT ""
$ WRITE SYS$OUTPUT "Logical names to be used:"
$ WRITE SYS$OUTPUT "	COM$ = ",F$TRNLNM("COM$","LNM$TRIALSYS")
$ WRITE SYS$OUTPUT "	OBJ$ = ",F$TRNLNM("OBJ$","LNM$TRIALSYS")
$ WRITE SYS$OUTPUT "	LIB$ = ",F$TRNLNM("LIB$","LNM$TRIALSYS")
$ WRITE SYS$OUTPUT ""
$
$ SET DEFAULT ['FACNAM']
$ IF FACNAM .EQS. "SYS" .AND. PHASE .EQS. "LNKLIB" -
		THEN @SYSBLDCOM$:NEXTVERS 'TARGDIR'  ! INCREMENT VERSION
$BLD:
$ ON ERROR THEN CONTINUE
$ SET VERIFY
$ @COM$:'FACNAM'BLD
$ SET NOVERIFY
$ PHASE = SAVE_PHASE
$ IF .NOT.(FACNAM .EQS. "SYS" .AND. PHASE .EQS. "LNKLIB") THEN GOTO NXTCMD
$
$ ! SYS JUST LINKED, CHECK STATUS
$
$ SHO SYM TRIAL$SEVERITY
$ IF TRIAL$SEVERITY .EQ. 1 THEN GOTO NXTCMD
$ WRITE SYS$OUTPUT "%TRIALSYS-F-BADSYS, SYS.EXE has link errors
$ WRITE SYS$OUTPUT "-TRIALSYS-E-ABORT, Aborting trialsys
$ GOTO EXIT
$
$NEXT_PHASE:
$ SUB_PHASE = SUB_PHASE + 1
$ PHASE = F$EXT(0,F$LOC("_",PHASE),PHASE)
$ PHASE = PHASE +"_''SUB_PHASE'"
$NEXT_PHASE5:
$ READ/NOLOCK  /INDEX=1 /KEY="''PHASE' " /ERROR=NEXT_PHASE10 DATA CMD
$ GOTO NXTCMD10
$NEXT_PHASE10:
$ IF SUB_PHASE .NE. 0 .AND. F$EXT(0,F$LOC("_",PHASE),PHASE) .EQS. "LINK" -
		THEN GOTO EXIT
$ PHASE = "LINK"
$ SUB_PHASE = 0
$ READ/NOLOCK  /INDEX=1/KEY="''PHASE' " /ERROR=EXIT DATA CMD
$ GOTO NXTCMD10
$
$EXIT:
$ CLOSE DATA
$ CLOSE DATA1
$ PURGE EXE$:*.EXE,MAP$:*.MAP
$ DEASSIGN/TABLE=LNM$PROCESS_DIRECTORY LNM$TRIALSYS
$ DEASSIGN/TABLE=LNM$PROCESS_DIRECTORY LNM$FILE_DEV
$ EXIT
$
$NOINFO:
$ WRITE SYS$OUTPUT "% TRIALSYS-E-NOINFO, AAINFO record not found in RESOBJ$:VMSNEWBLD.DAT"
$ GOTO EXIT
$NOFAC:
$ WRITE SYS$OUTPUT "% TRIALSYS-E-NOFAC, Facility ''FACNAM' disappeared from RESOBJ$:VMSNEWBLD.DAT"
$ GOTO EXIT
$NODATA:
$ WRITE SYS$OUTPUT "% TRIALSYS-E-NODATA, Error opening RESOBJ$:VMSNEWBLD.DAT"
$ GOTO EXIT
$PARAM_ERROR:
$ WRITE SYS$OUTPUT "% TRIALSYS-E-BADPARAM, P4 - P8 non-null"
$ GOTO EXIT
$ERR_RESTART:
$ WRITE SYS$OUTPUT "% TRIALSYS-E-NORESTART, error doing restart, abort"
$ GOTO EXIT
