$ IF "''BUILD$VERIFY'" .EQS. "" THEN BUILD$VERIFY = "NO"
$ V = 'F$VERIFY(BUILD$VERIFY)'
$ !
$ !	[ SYSBLDCOM ] V M S N E W B L D . C O M
$ !
$ !	This is the batch command file to build VMS.
$ !	It is submitted with the following parameters:
$ !
$ !	PHASES = P1 (Required)	The phases of a system build
$ !				that this run will execute.
$ !				The format is "startphase:endphase".
$ !				END is the phase beyond RESULT.
$ !
$ !	STARTFAC = P2 (Required) The names of the facilities to build.
$ !				The format is either "BEGIN:END" to
$ !				do all facilities, or a single
$ !				facility name.  NOTE: This
$ !				procedure only builds a single
$ !				facility or ALL facilities.
$ !
$ !	TARGDEV = P3 (Required)	The device name of the target
$ !				for this build.
$ !
$ !	INDEV = P4 (Required)	The device name of the source and
$ !				command files.
$ !
$ !	OPTIONS = P5 (Optional)	List of options:
$ !			R -	Restart specifies that the build should
$ !				insulate itself from crashes.  Only one
$ !				copy of this procedure may use this
$ !				option at a time.  This option implies the
$ !				use of SUBMIT/RESTART, and if we are the
$ !				build master, then it controls whether we
$ !				use checkpointing in the build database
$ !
$ !			S -	Set when the current invocation was
$ !				spawned by this procedure as a sub-job.
$ !
$ !			I -	Set if build is in place; i.e., if the
$ !				target disk is the same as the source.
$ !
$ !			B - 	Set if this is a BUG build; i.e., if
$ !				BUG update packets, etc., are to be used.
$ !
$ !			Pn -	Sets the process priority of the build.
$ !				The digit following P specifies the priority.
$ !				If not specified, the default job priority of
$ !				the batch job queue is used (INIT/PRIO).
$ !
$ !			Ni -	Adds a postfix to the process names used.
$ !				i = 0 : _T is added
$ !				i = 1 : _C is added
$ !
$ !
$ !	BLDFIL	= P6 (Optional)	Name of file containing list of
$ !				facilities to rebuild.  The default
$ !				file is SYSBLDCOM$:VMSNEWBLD.DAT, which
$ !				will be copied to the result disk in
$ !				[SYSBLDCOM], unless doing an in-place
$ !				build, in which case SYS$LOGIN is used.
$ !				VMSGEN puts the file in the correct place.
$ !				This file may be read-only only if we are
$ !				doing a single facility build.
$ !
$ !	The phases of a system build are:
$ !
$ !	INIT	Set up directories and or copy files
$ !
$ !	UPDATE	Update the master source with SLP changes
$ !
$ !	SRCLIB	Construct source libraries using MDL and create
$ !		macro libraries etc.
$ !
$ !	ASSEM	Assemble all sources.
$ !
$ !	OBJLIB	Create all object libraries.
$ !
$ !	LNKLIB	Create shareable images and insert into IMAGELIB
$ !
$ !	LINK	Link all images.
$ !
$ !	RESULT	Put the results of the build in consolidated
$ !		accounts for the distribution kit building
$ !		process.
$ !
$ !	If this build is doing all components (i.e. STARTFAC="BEGIN"
$ !	and ENDFAC="END"), then all phases except the INIT phase are done
$ !	by recursively calling this procedure with the appropriate
$ !	parameters several times to create multiple batch streams.
$ !
$ !
$ !	Set job conditions for system build
$ !
$ NODENAME = F$LOGICAL("SYS$NODE") - "_" - "_" - "::"
$ IF F$GETSYI("NODENAME") .NES. "" THEN NODENAME = F$GETSYI("NODENAME")
$ RMS$_RLK = %X182AA			! Record lock error
$ RMS$_RNF = %X182B2			! Record not found error
$ SET PROT=(S:RW,O:RWED,G:R,W:R)/DEFAULT ! For all newly created files
$ COPY == "COPY/PROTECTION=(O:RWED)"	! When copying from master disk files
$					! without delete access.
$ SDL == "SDL/NOLIST"			! An explicit /LIST will override
$ !
$ !	Accept input parameters and apply defaults
$ !
$ PHASE = F$ELEMENT(0,":",P1)
$ ENDPHASE = F$ELEMENT(1,":",P1)
$ IF ENDPHASE .EQS. ":" THEN ENDPHASE = PHASE
$ STARTFAC = F$ELEMENT(0,":",P2)
$ ENDFAC = F$ELEMENT(1,":",P2)
$ IF ENDFAC .EQS. ":" THEN ENDFAC = STARTFAC
$ TARGDEV = P3
$ INDEV = P4
$ OPTIONS = P5
$ BLDFIL = P6
$ IF BLDFIL .EQS. "" THEN BLDFIL = TARGDEV + "[SYSBLDCOM]VMSNEWBLD.DAT"
$ RESTART =	(F$LOCATE("R",OPTIONS) .NE. F$LENGTH(OPTIONS))
$ SUB =		(F$LOCATE("S",OPTIONS) .NE. F$LENGTH(OPTIONS))
$ INPLACE =	(F$LOCATE("I",OPTIONS) .NE. F$LENGTH(OPTIONS))
$ BUGBUILD =	(F$LOCATE("B",OPTIONS) .NE. F$LENGTH(OPTIONS))
$ IF F$LOCATE("P",OPTIONS) .NE. F$LENGTH(OPTIONS) -
 THEN SET PROCESS/PRIORITY='F$EXTRACT(F$LOCATE("P",OPTIONS)+1,1,OPTIONS)'
$ POSTFIX = ""
$ POSTFIXNUM = -1
$ IF F$LOCATE("N",OPTIONS) .NE. F$LENGTH(OPTIONS) THEN -
	POSTFIXNUM = F$EXTRACT(F$LOCATE("N",OPTIONS)+1,1,OPTIONS)
$ IF POSTFIXNUM .EQS. "0" THEN POSTFIX = "_T"
$ IF POSTFIXNUM .EQS. "1" THEN POSTFIX = "_C"
$
$ BUILD_MASTER = (STARTFAC .NES. ENDFAC) ! True if this process is the build
$					! master, and must submit sub-jobs
$					! to do the actual build work
$ BUILD_MASTER_CHECKPOINTING = (BUILD_MASTER .AND. RESTART)
$					! Used to control whether
$					! we write /RESTART records into
$					! database. Implies use of R/W database
$ READ_ONLY_DATABASE = (.NOT. BUILD_MASTER .AND. .NOT. SUB)
$					! (True if this is a single job build)
$					! Controls whether we are allowed to
$					! write build database at all
$ IF BUILD$VERIFY THEN SHOW SYMBOL/ALL
$ !
$ !	Issue message in log indicating we have started
$ !
$ IF BUILD_MASTER THEN SET PROCESS /NAME=BUILD_MASTER
$
$ IF BUILD_MASTER THEN WRITE SYS$OUTPUT -
 "%BUILD-I-MASTERSTARTED, BUILD_MASTER started on node ''NODENAME' at ''F$TIME()'"
$ IF .NOT. BUILD_MASTER THEN WRITE SYS$OUTPUT -
 "%BUILD-I-JOBSTARTED, facility ''STARTFAC' phase ''PHASE' started on node ''NODENAME' at ''F$TIME()'"
$ !
$ !	Define source update functions
$ !
$ UPDATES = "(ENH)"			! assume ENH build
$ IF BUGBUILD THEN UPDATES = "(BUG)"	! If BUG build, use bug updates only
$ SRCUPDATE = "@SYSBLDCOM$:SRCUPDATE"	! Merge SLP files into sources
$ !
$ !	Define logical names used by the component build procedures
$ !
$ @SYSBLDCOM$:BLDLOGNAM 'TARGDEV' 'INDEV' 'INPLACE'
$ !
$ !	Define result phase copy functions
$ !
$ @SYSBLDCOM$:CPYRESDEF		! DEFINE THE RESULT PHASE COPY FUNCTIONS
$ !
$ !	Open the build database.  If we are doing only a single facility
$ !	(i.e. not multiple jobs), then open the build database read-only,
$ !	so that we can run off the build database on the master disk.
$ !
$ IF .NOT. READ_ONLY_DATABASE THEN -
	OPEN_DATABASE := OPEN /SHARE /READ /WRITE DATA$ 'BLDFIL'
$ IF READ_ONLY_DATABASE THEN -
	OPEN_DATABASE := OPEN /SHARE /READ DATA$ 'BLDFIL'
$ 'OPEN_DATABASE'
$
$ IF .NOT. BUILD_MASTER_CHECKPOINTING THEN GOTO START_PHASE_0
$ READ /NOLOCK /INDEX=0 /KEY="BUILD_MASTER" /ERROR=NOMAS DATA$ RECORD
$ S1 = F$EXT(F$LOC("/RESTART=(",RECORD) + F$LEN("/RESTART=("),999,RECORD)
$ PLACE = F$EXT(0,F$LOC(")",S1),S1)
$ S1 = F$EXT(F$LOC("/PHASE=(",RECORD) + F$LEN("/PHASE=("),999,RECORD)
$ S1 = F$EXT(0,F$LOC(")",S1),S1)
$ IF S1 .NES. "" THEN PHASE = S1
$ S1 = F$EXT(F$LOC("/SUB_PHASE=(",RECORD) + F$LEN("/SUB_PHASE=("),999,RECORD)
$ S1 = F$EXT(0,F$LOC(")",S1),S1)
$ SUB_PHASE = 0
$ IF S1 .NES. "" THEN SUB_PHASE = F$INTEGER(S1)
$ WRITE SYS$OUTPUT "%BUILD-I-RESTART, BUILD_MASTER restarted, PHASE=''phase', SUB_PHASE=''sub_phase', PLACE=''place'."
$ IF PLACE .EQS. "" THEN GOTO START_PHASE_0
$ GOTO 'PLACE'
$NOMAS:
$ RECORD[0,16]:=BUILD_MASTER
$ RECORD[16,16]:=ZZZZZZ
$ WRITE DATA$ RECORD
$ !
$ !	Begin processing a build phase.  If we are the build master,
$ !	and checkpointing is enabled, then take a checkpoint here.
$ !
$START_PHASE_0:
$ SUB_PHASE = 0
$ IF F$LOCATE("_",PHASE) .NE. F$LENGTH(PHASE) THEN -
	SUB_PHASE = F$INTEGER(F$ELEMENT(1,"_",PHASE))
$START_PHASE:
$ IF PHASE .EQS. "END" THEN GOTO RESULT
$ IF .NOT. BUILD_MASTER_CHECKPOINTING THEN GOTO PSTART_10
$ READ /INDEX=0 /KEY="BUILD_MASTER" DATA$ RECORD
$ RECORD = F$EXT(0,32,RECORD) + "/RESTART=(START_PHASE)" -
		+ "/PHASE=(''PHASE')/SUB_PHASE=(''SUB_PHASE')"
$ WRITE /UPDATE DATA$ RECORD
$PSTART_10:
$ !
$ !	If this is the LNKLIB or LINK phase, setup build library to use
$ !
$ IF PHASE .NES. "LNKLIB" -
	.AND. PHASE .NES. "LINK" THEN GOTO SKIP_SYSBLDLIB
$ LINK == "LINK /USERLIB=PROC"		!Only use process library
$ DEFINE LNK$LIBRARY SYS$LIBRARY:SYSBLDLIB
$SKIP_SYSBLDLIB:
$ !
$ !	If this is the INIT phase, then do it in-line here.  This is
$ !	because we need to buy time to let the result disks get mounted
$ !	in the rest of the cluster before we can spawn jobs.
$ !
$ IF BUILD_MASTER .AND. PHASE .EQS. "INIT" THEN GOTO DO_INITPHASE
$ !
$ !	As long as we aren't the build master (i.e. we are either
$ !	the only job, or a spawned job), then go to it.
$ !
$ IF .NOT. BUILD_MASTER THEN GOTO SUB_BEGIN
$ !
$ !	We are the build master, so lets spawn the jobs to do the work.
$ !	Submit one job per facility for each facility that has this phase.
$ !
$ JOBS = 0
$ KEYSTR = "/KEY=""" + PHASE + " """ + "/INDEX=1"
$GETNXTFAC:
$ READ 'KEYSTR' /ERROR=GETNXTFACEND /END=GETNXTFACEND DATA$ RECORD
$ KEYSTR = ""
$ P1 = F$EXT(16,16,RECORD)
$ P1 = F$EXT(0,F$LOC(" ",P1),P1)
$ IF P1 .NES. PHASE THEN GOTO GETNXTFACEND
$ IF F$LOC("/SKIP",RECORD) .NE. F$LENGTH(RECORD) THEN GOTO SKIP_JOB_STEP
$ IF F$LOC("/SUBMIT=",RECORD) .NE. F$LENGTH(RECORD) THEN GOTO GETNXTFAC
$ FIRST = F$EXTRACT(0,F$LOCATE(" ",RECORD),RECORD)
$ PRIO = 4
$ P1 = F$LOC("/QPRI=",RECORD)
$ IF P1 .EQ. F$LEN(RECORD) THEN GOTO NOPRIO
$ PRIO = F$EXT(P1+F$LEN("/QPRI="),999,RECORD)
$ P1 = F$LOC(" ",PRIO)
$ IF F$LOC("/",PRIO) .LT. P1 THEN P1 = F$LOC("/",PRIO)
$ PRIO = F$EXT(0,P1,PRIO)
$NOPRIO:
$ QRESTART = ""
$ IF RESTART THEN QRESTART = "/RESTART"
$ JOBS = JOBS + 1
$ SET VERIFY
$ SUBMIT 'INDEV'[SYSBLDCOM]VMSNEWBLD -
	'QRESTART'/NOPRINT /LOG='TARGDEV'[SYSBLDCOM]'PHASE'_'FIRST' -
	/NAME='PHASE'_'FIRST' -
	/QUEUE=SYS$BUILD -
	/PRIO='PRIO' -
	/PARAM=('PHASE','FIRST','TARGDEV','INDEV',S'OPTIONS','BLDFIL')
$ V = 'F$VERIFY(BUILD$VERIFY)'
$ RECORD[16,16]:=*'F$EXT(16,15,RECORD)'
$ RECORD = RECORD + "/SUBMIT=(" + F$TIME() + ")"
$ WRITE /UPDATE DATA$ RECORD
$ GOTO GETNXTFAC
$SKIP_JOB_STEP:
$ RECORD = RECORD + "/IGNORED=(" + F$TIME() + ")"
$ WRITE /UPDATE DATA$ RECORD
$ GOTO GETNXTFAC
$GETNXTFACEND:
$ !
$ !	If we have just submitted the ASSEM phase jobs, then build the
$ !	tailoring data files while we are waiting.
$ !
$ IF SUB .OR. (PHASE .NES. "ASSEM") THEN GOTO SET_WAIT
$ IF .NOT. BUILD_MASTER_CHECKPOINTING THEN GOTO BUILD_TAILOR
$ READ /INDEX=0 /KEY="BUILD_MASTER" DATA$ RECORD
$ RECORD = F$EXT(0,32,RECORD) +"/RESTART=(BUILD_TAILOR)/PHASE=(" + -
	PHASE + ") ''F$TIME'"
$ WRITE /UPDATE DATA$ RECORD
$BUILD_TAILOR:
$ SET NOON
$ @SYSBLDCOM$:TAILORBLD 'INDEV'[SYSUPD] 'TARGDEV'[SYSUPD] ! Build tailoring files
$ SET ON
$ !
$ !	Wait for spawned jobs to complete.
$ !
$SET_WAIT:
$ IF .NOT. BUILD_MASTER_CHECKPOINTING THEN GOTO WAIT_LOOP
$ READ /INDEX=0 /KEY="BUILD_MASTER" DATA$ RECORD
$ RECORD = F$EXT(0,32,RECORD) + "/RESTART=(WAIT_LOOP)/PHASE=(" +-
		 PHASE + ") ''F$TIME()'"
$ WRITE /UPDATE DATA$ RECORD
$WAIT_LOOP:
$ S1 = F$LOG("BUILD$WAIT_TIME")	! Re-compute wait time in case of restart
$ IF S1 .EQS. "" THEN S1 = "00:02:00"
$ WAIT 'S1'
$ IF F$LOGICAL("STOP_BUILD") .NES. "" THEN GOTO EXIT
$ READ /NOLOCK /ERROR=WAIT_CHECK /INDEX=1 /KEY="*''PHASE' " DATA$ RECORD
$ GOTO WAIT_LOOP
$WAIT_CHECK:
$ L1 = $STATUS
$ IF L1 .EQ. RMS$_RLK THEN GOTO WAIT_LOOP	!Record locked, keep waiting
$ WRITE SYS$OUTPUT -
	"%BUILD-I-WAITENDED, wait ended at ''F$TIME()', status = ''L1'"
$ IF L1 .NE. RMS$_RNF THEN GOTO NOT_RNF
$ IF READ_ONLY_DATABASE THEN GOTO NXTPHASE
$ ! CLOSE DATA$					!? Kludge to handle rms errors
$ ! CONVERT /STAT /NOSORT 'BLDFIL' 'BLDFIL'
$ ! RENAME /LOG 'BLDFIL';-1 .OLD
$ ! OPEN_DATABASE
$  GOTO NXTPHASE
$NOT_RNF:
$ WRITE SYS$OUTPUT -
	"%BUILD-W-WRONGSTATUS, status ''L1' is not ''RMS$_RNF', waiting again"
$ CLOSE DATA$
$ OPEN_DATABASE
$ GOTO WAIT_LOOP
$ !
$ !	The time has come to do the real work.
$ !
$SUB_BEGIN:
$ READ /NOLOCK /INDEX=0 /KEY="''STARTFAC' " /ERROR=NOTFOUND DATA$ CMD
$ IF F$LOC("/DISABLE",CMD) .EQ. F$LENGTH(CMD) THEN GOTO NXTCMD10
$ WRITE SYS$OUTPUT "%BUILD-W-DISABLED, Facility ''STARTFAC' is disabled."
$ GOTO EXIT
$NOTFOUND:
$ WRITE SYS$OUTPUT "Component not found in component list."
$ GOTO EXIT
$
$SUB_BEGIN_10:
$ L1 = $STATUS
$ IF L1 .EQ. RMS$_RLK THEN GOTO SUB_BEGIN_20
$ WRITE SYS$OUTPUT -
	"%BUILD-W-WRONGSTATUS, status ''L1' is not ''RMS$_RLK', retrying..."
$ CLOSE DATA$
$ OPEN_DATABASE
$SUB_BEGIN_20:
$ WAIT 00:00:05
$ GOTO SUB_BEGIN
$ !
$ !	We have found the first record for this facility.  Find the record
$ !	describing the current phase.
$ !
$NXTCMD:
$ IF F$LOGICAL("STOP_BUILD") .NES. "" THEN GOTO EXIT
$ READ /ERROR=SUB_BEGIN_10 /END=NXTPHASE DATA$ CMD
$NXTCMD10:
$ FACNAM = F$EXT(0,F$LOC(" ",CMD),CMD)
$ IF FACNAM .NES. STARTFAC THEN GOTO NXTPHASE
$ S1 = F$EXT(16,16,CMD) - "*"
$ S1 = F$EXT(0,F$LOC(" ",S1),S1)
$ IF S1 .NES. PHASE THEN GOTO NXTCMD
$ ! Found the record for this facility/phase
$ IF F$LOC("/COMPLETED=(",CMD) .NE. F$LEN(CMD) THEN GOTO NXTPHASE
$ CMD = F$EXTRACT(0,F$LOCATE("/START",CMD),CMD) -
	+ "/START=(''F$TIME()', ''NODENAME')"
$ IF SUB THEN WRITE /UPDATE DATA$ CMD
$ WRITE SYS$OUTPUT "***************************************************************************"
$ WRITE SYS$OUTPUT "*									     *"
$ WRITE SYS$OUTPUT "*			BUILD	''FACNAM'   (''PHASE' PHASE)			     *"
$ WRITE SYS$OUTPUT "*									     *"
$ WRITE SYS$OUTPUT "***************************************************************************"
$ SET DEFAULT 'TARGDEV'['FACNAM']
$ GOTO DOFAC	!* Comment out line to get facility timing data
$ APPQUAL = "/APPEND"
$ TEMP = ""
$ TEMP = F$SEARCH("''TARGDEV'[''FACNAM']TIMING.DAT")
$ IF  TEMP .EQS. "" THEN APPQUAL = "/WRITE"
$ OPEN /ERROR=DOFAC 'APPQUAL' F1 'TARGDEV'['FACNAM']TIMING.DAT
$ APPQUAL = F$FAO("!20%D !6AS !10UL !15UL !10UL !10UL !8UL !5UL",-
		0,PHASE,-
		F$GETJPI(0,"BUFIO"),F$GETJPI(0,"CPUTIM"),-
		F$GETJPI(0,"DIRIO"),F$GETJPI(0,"PAGEFLTS"),-
		F$GETJPI(0,"VIRTPEAK"),F$GETJPI(0,"WSPEAK"))
$ WRITE F1 APPQUAL
$ CLOSE F1
$DOFAC:
$ SAVE_PHASE = PHASE
$ PHASE = F$EXT(0,F$LOC("_",PHASE),PHASE)
$ !
$ ! WHEN CPYOLB HAS THE VALUE "Y" SOME FACILITIES WILL COPY THEIR OBJECT
$ ! LIBRARIES TO RESOBJ$:.  ALL FACILITIES WHICH SHARE OBJECT MODULES
$ ! WITH OTHER FACILITIES AND ALL THAT LINK WITH THE EXEC SYMBOL TABLE
$ ! SHOULD COPY THEIR OBJECT LIBRARIES IF THIS GLOBAL FLAG IS SET.
$ !
$ CPYOLB = "N"
$ IF PHASE .EQS. "OBJLIB" .OR. PHASE .EQS. "LNKLIB" THEN CPYOLB = "Y"
$ !
$ SET VERIFY
$ ON ERROR THEN GOTO FACFAIL
$ SET PROCESS/NAME='PHASE'_'FACNAM''POSTFIX'
$ ON ERROR THEN CONTINUE
$ @COM$:'FACNAM'BLD
$ SAVE_SEVERITY = $SEVERITY
$ V = 'F$VERIFY(BUILD$VERIFY)'
$ PHASE = SAVE_PHASE
$ GOTO CHKSEV	!* Comment out line to get timing data
$ APPQUAL = "/APPEND"
$ IF F$SEARCH("''TARGDEV'[''FACNAM']TIMING.DAT") .EQS. "" THEN APPQUAL = "/WRITE"
$ OPEN /ERROR=CHKSEV 'APPQUAL' F1 'TARGDEV'['FACNAM']TIMING.DAT
$ APPQUAL = F$FAO("!20%D !6AS !10UL !15UL !10UL !10UL !8UL !5UL",-
		0,PHASE,-
		F$GETJPI(0,"BUFIO"),F$GETJPI(0,"CPUTIM"),-
		F$GETJPI(0,"DIRIO"),F$GETJPI(0,"PAGEFLTS"),-
		F$GETJPI(0,"VIRTPEAK"),F$GETJPI(0,"WSPEAK"))
$ WRITE F1 APPQUAL
$ CLOSE F1
$CHKSEV:
$ IF SAVE_SEVERITY THEN GOTO DONE
$ !
$FACFAIL:
$ V = 'F$VERIFY(BUILD$VERIFY)'
$ PHASE = SAVE_PHASE
$ WRITE SYS$OUTPUT "%BUILD-F-FAIL, >>>>>>> ''FACNAM' FAILURE <<<<<<"
$ ON ERROR THEN CONTINUE
$ !
$DONE:
$ !
$ !	Mark this phase as done.  First find the record again
$ !
$ IF .NOT. SUB THEN GOTO NXTPHASE
$ S2 = 0
$DONE5:
$ READ /NOLOCK /ERROR=DONE40 /END=DONE30 /INDEX=0 /KEY="''STARTFAC' " DATA$ CMD
$DONE10:
$ IF F$EXT(0,F$LOC(" ",CMD),CMD) .NES. STARTFAC THEN GOTO NXTPHASE
$ S1 = F$EXT(16,16,CMD) - "*"
$ S1 = F$EXT(0,F$LOC(" ",S1),S1)
$ IF S1 .EQS. PHASE THEN GOTO DONE20
$DONE15:
$ READ /ERROR=DONE40 /END=DONE30 DATA$ CMD
$ GOTO DONE10
$DONE20:
$ S1 = F$EXT(16,16,CMD) - "*"
$ CMD[16,16]:='S1'
$ CMD = CMD + "/COMPLETED=(''SAVE_SEVERITY'," + F$TIME() + ",''NODENAME')"
$ WRITE /UPDATE DATA$ CMD
$ GOTO NXTPHASE
$DONE30:
$ IF S2 .NE. 0 THEN GOTO NXTPHASE
$ CLOSE DATA$
$ OPEN_DATABASE
$ S2 = 1
$ GOTO DONE5
$DONE40:
$ L1 = $STATUS
$ IF L1 .EQ. RMS$_RLK THEN GOTO DONE50
$ WRITE SYS$OUTPUT -
	"%BUILD-W-WRONGSTATUS, status ''L1' is not ''RMS$_RLK', retrying..."
$ CLOSE DATA$
$ OPEN_DATABASE
$DONE50:
$ WAIT 00:00:05
$ GOTO DONE5
$ !
$ !	Set up to do the next phase of the build
$ !
$NXTPHASE:
$ SHOW TIME		! Show time between phases
$ IF (SUB_PHASE .NE. 0) .AND. (PHASE .EQS. ENDPHASE) THEN GOTO NORMALEXIT
$ IF SUB .AND. (PHASE .EQS. ENDPHASE) THEN GOTO NORMALEXIT
$ IF F$LOGICAL("STOP_BUILD") .NES. "" THEN GOTO NORMALEXIT
$ SUB_PHASE = SUB_PHASE + 1
$ PHASE = F$EXT(0,F$LOC("_",PHASE),PHASE)
$ PHASE = PHASE + "_''SUB_PHASE'"
$ READ /NOLOCK /INDEX=1 /KEY="''PHASE' " /ERROR=DISP10 DATA$ CMD
$ GOTO START_PHASE
$DISP10:
$ L1 = $STATUS
$ IF L1 .EQ. RMS$_RNF THEN GOTO DISP20
$ WRITE SYS$OUTPUT -
	"%BUILD-W-WRONGSTATUS, status ''L1' is not ''RMS$_RNF', check logs!..."
$DISP20:
$ PHASE = F$EXT(0,F$LOC("_",PHASE),PHASE)
$ IF PHASE .EQS. ENDPHASE THEN GOTO NORMALEXIT
$ GOTO 'PHASE'
$INIT:
$ PHASE = "UPDATE"
$ GOTO START_PHASE_0
$UPDATE:
$ PHASE = "SRCLIB"
$ GOTO START_PHASE_0
$SRCLIB:
$ PHASE = "ASSEM"
$ GOTO START_PHASE_0
$ASSEM:
$ PHASE = "OBJLIB"
$ GOTO START_PHASE_0
$OBJLIB:
$ PHASE = "LNKLIB"
$ GOTO START_PHASE_0
$LNKLIB:
$ PHASE = "LINK"
$ GOTO START_PHASE_0
$LINK:
$ PHASE = "RESULT"
$ GOTO START_PHASE_0
$RESULT:
$ IF ENDPHASE .NES. "END" THEN GOTO NORMALEXIT
$ READ /KEY="BUILD_MASTER" /ERROR=RESULT_10 DATA$ RECORD
$ RECORD = F$EXT(0,32,RECORD) + "/RESTART=(RESULT)/PHASE=(RESULT)''F$TIME()'"
$ IF BUILD_MASTER_CHECKPOINTING THEN WRITE /UPDATE /ERROR=RESULT_5 DATA$ RECORD
$ GOTO RESULT_10
$RESULT_5:
$ WRITE SYS$OUTPUT "%BUILD-E-WRITEERR, Error writing VMSNEWBLD.DAT,''F$MESSAGE($STATUS)'"
$RESULT_10:
$ @SYSBLDCOM$:BLDRESULT 'TARGDEV' 'INDEV'
$ @SYSBLDCOM$:RESCOMCPY 'TARGDEV' 'INDEV'
$ ! BLDRESULT copies 'INDEV'[SYSBLDCOM]VMSNEWBLD.DAT to 'TARGDEV'[SYSBLDCOM]
$ ! as VMSNEWBLD.VIR.  Rename it to .DAT here.  This reduces the window for
$ ! the system crashing, and then having the build master restart using a
$ ! virgin VMSNEWBLD.DAT, rather than the one in use during the build.
$ RENAME 'TARGDEV'[SYSBLDCOM]VMSNEWBLD.VIR .DAT
$NORMALEXIT:
$EXIT:
$ IF F$LOG("DATA$") .NES. "" THEN CLOSE DATA$
$ EXIT
$
$ !
$ !	INIT phase done here
$ !
$DO_INITPHASE:
$ !
$ !	Copy library files needed for build compiles
$ !
$ SET NOON
$ CPYRES SYS$LIBRARY: 'INDEV'[SYSLIB]XPORT.OLB		! For RUNOFF
$ BLISS/LIBRARY=SYS$LIBRARY:XPORT.L32 -			! For RUNOFF
	/NOLISTING -
	'INDEV'[SYSLIB]XPORT.REQ
$ CPYRES SYS$LIBRARY: 'INDEV'[SYSLIB]PLISYSDEF.TLB
$ CPYRES SYS$LIBRARY: 'INDEV'[SYSLIB]PL1RTLIB.OLB
$ CPYRES SYS$LIBRARY: 'INDEV'[SYSLIB]LIBDEF.PAS
$ CPYRES SYS$LIBRARY: 'INDEV'[SYSLIB]MTHDEF.PAS
$ CPYRES SYS$LIBRARY: 'INDEV'[SYSLIB]OPASDEF.PAS
$ CPYRES SYS$LIBRARY: 'INDEV'[SYSLIB]PASDEF.PAS
$ CPYRES SYS$LIBRARY: 'INDEV'[SYSLIB]SIGDEF.PAS
$ CPYRES SYS$LIBRARY: 'INDEV'[SYSLIB]PASSTATUS.PAS
$ CPYRES SYS$LIBRARY: 'INDEV'[SYSLIB]STARLET.PEN
$ SET ON
$ !
$ ! Begin reading the database to get the list of facilities to initialize
$ !
$ READ /ERROR=END_INIT /INDEX=1 /KEY="INIT " DATA$ CMD
$ GOTO DOINIT_20
$DOINIT_10:
$ READ /ERROR=END_INIT DATA$ CMD
$DOINIT_20:
$ IF F$LOC("/SKIP",CMD) .NE. F$LEN(CMD) THEN GOTO DOINIT_10
$ IF F$EXT(16,4,CMD) .NES. "INIT" THEN GOTO END_INIT
$ FACNAM = F$EXT(0,F$LOC(" ",CMD),CMD)
$ SET PROCESS /NAME=INIT_'FACNAM'
$ SET DEFAULT 'TARGDEV'['FACNAM']
$ @SYSBLDCOM$:CREATEDIR
$ GOTO DOINIT_10
$END_INIT:
$ SET PROCESS /NAME=BUILD_MASTER
$ !
$ ! Only if the MSGFIL component is present in the build file will the message
$ ! text library be initialized.
$ !
$ READ /NOLOCK /INDEX=0 /KEY="MSGFIL" /ERROR=NXTPHASE DATA$ CMD
$ LIBRARY /TEXT /CREATE SRCD$:[SYSMSG]SYSMSG		!For MSGFIL component
$ GOTO NXTPHASE
