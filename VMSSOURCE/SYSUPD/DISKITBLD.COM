$ !++
$ !
$ !
$ ! DISKITBLD.COM - Build a VMS or MicroVMS distribution kit (all options)
$ !
$ ! AUTHOR:	Greg Robert		14-Aug-1981
$ !		Trudy Matthews		(FT1)
$ !		Kathleen D. Morse	15-Nov-1983
$ !		Mike Rosenblum		15-Nov-1983
$ !		Jack Speight		10-Sep-1984
$ !
$ ! ABSTRACT:	This command procedure builds MicroVMS distribution kits
$ !		on RX50s.
$ !
$ ! INPUT:	P1 - Source device and topsys, assumed mounted
$ !		P2 - Intermediate scratch disk, assumed loaded, not mounted
$ !		P3 - Target device, assumed loaded, not mounted
$ !		P4 - Comma separated list of options
$ !		P5 - Source device and directory for VMSKITBLD.COM, .DAT, and
$ !		     for STABACKIT.COM.
$ !		     Default device = SOURCE, default directory = [SYSUPD]
$ !		P6 - Type of kit to build
$ !			"" - DEFAULT is standard kit
$ !			"RL02" - RL02 distribution kit
$ !			"MICROVMS" - RX50 distribution kit
$ !		P7 - Version of kit - in the form:
$ !			vvu - where vv is the version number, and u is the
$ !			      update number.
$ !
$ !		Requires privileges: 
$ !			SETPRV
$ !
$ ! OPTIONS:	PAUSE	- Pauses at the end of each pass to allow the
$ !			  scratch media to be saved
$ !
$ !		RESTART - Allows the procedure to be restarted at any of the
$ !			  VMSKITBLD invocations (PASS1, PASS2, PASS3, or PASS4)
$ !			  or at any of the BACKUP invocations (PASS1_B, PASS2_B,
$ !			  or PASS3_B, PASS4_B) for a VMS kit.
$ !			  For a MicroVMS kit, the procedure can be restarted
$ !			  at pass 1 (VMSKITBLD equivalent) or 2 (BACKUP 
$ !			  invocation) for any layered option or the base kit.
$ !		NONE	- No options specified. (this is the default)
$ !
$ ! DESCRIPTION: This is a four pass procedure.  Each pass consists of
$ !		a VMSKITBLD operation from the source device to the inter-
$ !		mediate device, followed by a backup operation from the
$ !		intermediate device to the target device.  Each pass results
$ !		in a saveset on the target media.
$ !
$ ! SAVESETS:	VMSver - Command file set (to drive upgrade procedure)
$ !		REQUIRED - Required file set
$ !		LIBRARY - Library file set
$ !		OPTIONAL - Optional file set
$ !
$ ! NOTE:	If the target device is a disk with a capacity of
$ !		fewer than 25,000 blocks, then the optional save
$ !		set is placed on a second volume, with the required
$ !		files (i.e. the optional volume is bootable).
$ !--
$
$BEGIN:
$	COPY = "COPY"
$	BACKUP = "BACKUP"
$	SCRATCH = ""
$	TARGET = ""
$	TOPSYS = "SYS0."
$	ROOT = TOPSYS - "."
$	DEFDIR = F$ENV("DEFAULT")
$	DEFPROT = F$ENV("PROTECTION")
$	DEFUIC = F$USER()
$	SAY :== WRITE SYS$OUTPUT
$	DC$_DISK = 1
$	DC$_TAPE = 2
$	ON ERROR THEN GOTO RUNDOWN
$	ON CONTROL_Y THEN GOTO CONTROLY
$	WRITE SYS$OUTPUT "Build a distribution kit."
$	PREV_PRIV = F$SETPRV("CMEXEC, CMKRNL, VOLPRO, LOG_IO, SYSPRV, OPER")
$	SET UIC  [001,004]
$	SET PROTECTION=(S=RWED,O=RWED,G=RE,W=RE) /DEFAULT
$	SOURCE	 = P1
$	SCRATCH	 = P2
$	TARGET	 = P3
$	ERROR_COUNT = 0
$	START_ERROR_COUNT = 0
$	MOUNT_TARGET = "MOUNT"
$	SUMMARY = " *** FAILURE ***, distribution kit is not complete"
$
$	!
$	! Determine version number
$	!
$GET_VERSION:
$	VERSION = P7
$	IF VERSION .NES. "" THEN GOTO CHECK_VERSION
$	SAY ""
$	SAY "The version number is the 4 character string returned by"
$	SAY "F$GETSYI("VERSION") (V4.0, T4.1, X2M9, for instance).  For field"
$	SAY "test versions (both of major releases and maintenance updates)"
$	SAY "the test is two-part.  The first character on the kit must be less"
$	SAY "than or equal to that of the system on which it is applied.  The"
$	SAY "last three characters must match exactly.  For released software,"
$	SAY "the version must be greater than or equal to, and the major"
$	SAY "version number must match exactly."
$	SAY ""
$ASK_VERSION:
$	INQUIRE VERSION "Enter the verison number"
$CHECK_VERSION:
$	IF VERSION .EQS. "" THEN GOTO ASK_VERSION
$	IF F$LENGTH(VERSION) .NE. 4 THEN GOTO BAD_VERSION
$	IF F$EXTRACT(0,1,VERSION) .EQS. "V" THEN GOTO CVVRLS
$	IF F$LOCATE(".",VERSION) .EQ. F$LENGTH(VERSION) THEN GOTO CVVMFT
$	GOTO CVVUPG
$BAD_VERSION:
$	SAY ""
$	SAY "You entered an illegal version number."
$	GOTO GET_VERSION	
$CVVRLS:
$	VERSION = F$EDIT(VERSION,"TRIM,UPCASE")
$	VERSION = VERSION - "V" - "."
$	VERSION = "0" + VERSION
$	VRSN = VERSION
$	GOTO PARSE_OPTIONS
$CVVMFT:
$	VERSION = F$EDIT(VERSION,"TRIM,UPCASE")
$	VERSION = F$EXTRACT(1,999,VERSION)
$	VRSN = VERSION + "040"
$	GOTO PARSE_OPTIONS
$CVVUPG:
$	IF F$LOCATE(".",VERSION) .EQ. 4 THEN GOTO BAD_VERSION
$	VERSION = F$EDIT(VERSION,"TRIM,UPCASE")
$	VERSION = VERSION - F$EXTRACT(0,1,VERSION) - "."
$	VERSION = "0" + VERSION
$	VRSN = VERSION
$PARSE_OPTIONS:
$	!
$	! Parse options
$	!
$	OPTIONS	= "," + P4 + ","
$	OPTLEN = F$LENGTH (OPTIONS)
$
$	PAUSE  =  0
$	RESTART  =  0
$	!
$	! Determine type of kit being built:  RL02,MICROVMS,STANDARD
$	!
$	KIT_TYPE = P6
$	LEGAL_KITS = "RL02,MICROVMS,STANDARD"
$	IF KIT_TYPE .EQS. "" THEN KIT_TYPE = "STANDARD"
$	IF F$LOCATE(KIT_TYPE,LEGAL_KITS) .EQ. F$LENGTH(LEGAL_KITS) THEN -
		GOTO BAD_TYPE
$	IF F$LOC (",NONE,", OPTIONS) .NE. OPTLEN THEN GOTO GETSOURCE
$
$	IF F$LOC (",PAUSE,", OPTIONS) .NE. OPTLEN THEN PAUSE = 1
$	OPTIONS = OPTIONS - ",PAUSE"
$
$	IF F$LOC(",RESTART,",OPTIONS) .NE. OPTLEN THEN RESTART = 1
$	OPTIONS = OPTIONS - ",RESTART"
$
$	IF OPTIONS .EQS. "," .OR. OPTIONS .EQS. ",," THEN GOTO GETSOURCE
$	WRITE SYS$OUTPUT "''OPTIONS' is an unrecognized option"
$	GOTO RUNDOWN
$	!
$	! Request any missing parameters, allocate and intialize devices
$	!
$GETSOURCE:
$	ON WARNING THEN GOTO GETSOURCE
$	IF P1 .NES. "" THEN GOTO 10$
$	INQUIRE SOURCE "Specify source device (DDCU:[topsys])"
$	IF SOURCE .EQS. "" THEN GOTO GETSOURCE
$10$:	P1 = ""
$	DEFAULT_SOURCE_TOPSYS = "NONE"
$	COLON_POS = F$LOCATE(":",SOURCE)+1
$	SOURCE_TOPSYS = F$EXTRACT(COLON_POS,132,SOURCE)
$	SOURCE = F$EXTRACT(0,COLON_POS,SOURCE)
$	SOURCE = SOURCE - ":" + ":"
$	IF .NOT. F$GETDVI(SOURCE,"EXISTS") THEN GOTO GETSOURCE
$	SOURCE = F$GETDVI(SOURCE,"DEVNAM")
$	TEMP = F$SEARCH("''SOURCE'[0,0]SYS0.DIR;1")
$	IF TEMP .NES. "" THEN DEFAULT_SOURCE_TOPSYS = "SYS0"
$	SOURCE_TOPSYS = SOURCE_TOPSYS - "[" - "<" - "]" - ">"
$	IF SOURCE_TOPSYS .EQS. "" THEN SOURCE_TOPSYS = DEFAULT_SOURCE_TOPSYS
$	IF SOURCE_TOPSYS .EQS. "NONE" THEN SOURCE_TOPSYS = ""
$	SOURCE_TOPSYS_DOT = ""
$	IF SOURCE_TOPSYS .NES. "" THEN SOURCE_TOPSYS_DOT = SOURCE_TOPSYS + "."
$	SOURCE_TOPSYS_DIR = ""
$	IF SOURCE_TOPSYS .NES. "" THEN -
		SOURCE_TOPSYS_DIR = "[" + SOURCE_TOPSYS + "]"
$	IF F$GETDVI (SOURCE, "MNT") THEN GOTO GETSCRATCH
$	WRITE SYS$OUTPUT "Source device must be mounted"
$	GOTO GETSOURCE
$
$GETSCRATCH:
$	ON WARNING THEN GOTO GETSCRATCH
$	IF P2 .NES. "" THEN GOTO 20$
$	INQUIRE SCRATCH "Specify scratch device (DDCU:)"
$	IF SCRATCH .EQS. "" THEN GOTO GETSCRATCH
$20$:	P2 = ""
$	SCRATCH = SCRATCH - ":"
$	IF .NOT. F$GETDVI(SCRATCH,"EXISTS") THEN GOTO GETSCRATCH
$	SCRATCH = F$GETDVI(SCRATCH,"DEVNAM")
$	IF .NOT. F$GETDVI (SCRATCH, "MNT") THEN GOTO 25$
$	WRITE SYS$OUTPUT "Scratch disk ''SCRATCH' already mounted"
$	GOTO GETTARGET
$25$:	ALLOCATE 'SCRATCH
$
$GETTARGET:
$	ON WARNING THEN GOTO GETTARGET
$	IF P3 .NES. "" THEN GOTO 30$
$	INQUIRE TARGET "Specify target device (DDCU:)"
$	IF TARGET .EQS. "" THEN GOTO GETTARGET
$30$:	P3 = ""
$	TARGET = TARGET - ":"
$	IF .NOT. F$GETDVI(TARGET,"EXISTS") THEN GOTO GETTARGET
$	TARGET = F$GETDVI(TARGET,"DEVNAM")
$	IF .NOT. F$GETDVI (TARGET, "MNT") THEN GOTO PREPARE_MEDIA
$	WRITE SYS$OUTPUT "Target disk ''TARGET' already mounted"
$	GOTO GETTARGET
$
$PREPARE_MEDIA:
$	INIT_TARGET = "INIT"
$	IF F$GETDVI (TARGET, "DEVCLASS") .EQ. 1 THEN INIT_TARGET = "INIT /MAXIMUM_FILES=700/headers=700
$	IF F$GETDVI (TARGET, "DEVCLASS") .EQ. DC$_TAPE THEN MOUNT_TARGET= "MOUNT /FOREIGN"
$	START_ERROR_COUNT = F$GETDVI (TARGET, "ERRCNT")
$	IF KIT_TYPE .EQS. "MICROVMS" THEN GOTO SKIP_MNT_TARGET
$	IF F$MODE () .NES. "INTERACTIVE" THEN GOTO INIT_TARGET
$	WRITE SYS$OUTPUT -
"Please place the PRIMARY kit medium in the target drive, ''TARGET'."
$DO_OVER:
$	INIMNT = "initialized"
$	IF RESTART THEN INIMNT = "mounted"
$	INQUIRE OK "Is ''TARGET' ready to be ''INIMNT? (Y/N)"
$	IF .NOT. OK THEN GOTO DO_OVER
$	WRITE SYS$OUTPUT -
"Please place the scratch RL02 in the scratch drive, ''SCRATCH'."
$DO_AGAIN:
$	INQUIRE ANSWER "Is ''SCRATCH' ready to be initialized? (Y/N)"
$	IF .NOT. ANSWER THEN GOTO DO_AGAIN
$
$INIT_TARGET:
$	IF .NOT. RESTART THEN INIT_TARGET 'TARGET VMS'VERSION'
$
$MNT_TARGET:
$	MOUNT_TARGET 'TARGET /OV=ID
$
$SKIP_MNT_TARGET:
$
$START:
$	COMMAND	:= 'P5
$	IF COMMAND .EQS. "" THEN -
		COMMAND = SOURCE + "[" + SOURCE_TOPSYS_DOT + "SYSUPD]"
$START_20:
$	WRITE SYS$OUTPUT "Build a ''KIT_TYPE' distribution kit."
$	BLOCKSIZE = ""		! Assume target device is a disk.
$	IF F$GETDVI (TARGET, "DEVCLASS") .EQ. DC$_TAPE THEN -	! If its a magtape...
	BLOCKSIZE = "/BLOCK_SIZE=7952"
$100:
$	IF KIT_TYPE .EQS. "MICROVMS" THEN GOTO MICROVMS_1
$	DESTINATION = "PASS1"	! Assume a fresh build.
$	IF RESTART THEN INQUIRE DESTINATION -
"Enter PASS1, PASS1_B, PASS2, PASS2_B, PASS3, PASS3_B, PASS4, or PASS4_B"
$	GOTO 'DESTINATION
$
$PASS1:
$	WRITE SYS$OUTPUT ""
$	WRITE SYS$OUTPUT "	* * * * *   PASS1   * * * * *"
$	WRITE SYS$OUTPUT ""
$	ON ERROR THEN GOTO RUNDOWN
$	!
$	! Do a VMSKITBLD of the required file set.
$	!
$	@'COMMAND'VMSKITBLD -		! Kitbuild command procedure
		'COMMAND'VMSKITBLD.DAT -! Kitbuild data file
		"" -			! Default mask -- standard kit
		'SOURCE''SOURCE_TOPSYS_DIR' - ! Source disk and topsys
		'SCRATCH'VAXVMSRL4 -	! Target disk
		REQ -			! Required fileset
		"" -			! n/a
		BUILD -			! Fresh build operation
		NOPROMPT		! Device already confirmed
$	!
$	! BACKUP the scratch disk to the target media
$	!
$
$PASS1_B:
$	WRITE SYS$OUTPUT ""
$	WRITE SYS$OUTPUT "	* * * * *   PASS1_B   * * * * *"
$	WRITE SYS$OUTPUT ""
$	ON ERROR THEN GOTO RUNDOWN
$	MOUNT 'SCRATCH' VAXVMSRL4
$	SET DEFAULT 'SCRATCH'['TOPSYS'SYSEXE]
$150:
$	IF F$GETDVI(TARGET,"DEVCLASS") .EQ. DC$_DISK THEN BLOCKSIZE = "/BLOCKSIZE=2048"
$	BACKUP 'SOURCE'['SOURCE_TOPSYS_DOT'SYSUPD]KITINSTAL.COM;, -
		MOVE.COM;,DIRCLENUP.COM;, -
		'SOURCE'['SOURCE_TOPSYS_DOT'SYSEXE]STARTUP.UP*;, -
		'SOURCE'['SOURCE_TOPSYS_DOT'SYSEXE]BOOT58.EXE;, -
		'SOURCE'['SOURCE_TOPSYS_DOT'SYSEXE]CHGSYSPAR.EXE;,-
		'SOURCE'['SOURCE_TOPSYS_DOT'SYSUPD]AUTOGEN.COM;,  -
		'SOURCE'['SOURCE_TOPSYS_DOT'SYSUPD]VMSKITBLD.V3N; -
		'TARGET'[000000]VMS040.A /SAVESET -
		/INTERCHANGE -
		'BLOCKSIZE' -
		/NOINIT -
		/LABEL = VMS'VERSION'
$	IF F$GETDVI(TARGET,"DEVCLASS") .EQ. DC$_DISK THEN BLOCKSIZE = ""
$	!
$	! Set the default system generation parameters for the upgrade.
$	! Make STARTUP.INS be used the first time the new system
$	! is booted, as it will restore the LIB and OPT savesets.
$	!
$	SET DEFAULT 'SCRATCH'['TOPSYS'SYSEXE]
$	DEFINE/USER SYS$LIBRARY 'SCRATCH'['TOPSYS'SYSLIB]
$	DEFINE/USER SYS$SYSTEM 'SCRATCH'['TOPSYS'SYSEXE]
$	RUN SYSGEN
		USE DEFAULT
		SET /STARTUP SYS$SYSTEM:STARTUP.INS	! Installation command proc
		SET SCSSYSTEMID	65534
		SET SCSNODE	"SALONE"
		SET VAXCLUSTER 0
		WRITE CURRENT
$	SET DEFAULT 'DEFDIR'
$	COPY 'SOURCE'['SOURCE_TOPSYS_DOT'SYSEXE]STARTUP.INS -
			'SCRATCH'['TOPSYS'SYSEXE]
$!***	DELETE 'SCRATCH'['TOPSYS'SYSEXE]SYSUAF.DAT;*	! Rely on .RL2 copy
$	BACKUP 'SCRATCH' 'TARGET'[000000]REQUIRED /SAVESET -
		'BLOCKSIZE' -
		/IMAGE -
		/INTERCHANGE -
		/NOINIT -
		/NOREWIND -
		/LABEL = VMS'VERSION'
$	DISMOUNT /NOUNLOAD 'SCRATCH'
$	!
$	! Copy the standalone backup kit to the Required disk.
$	!
$	IF F$GETDVI (TARGET, "DEVCLASS") .NE. DC$_DISK THEN GOTO PASS2
$	SET NOON
$	@'COMMAND'STABACKIT 'TARGET' [SYS0.SYSEXE] 'SOURCE'['SOURCE_TOPSYS_DOT'SYSEXE]
$	IF .NOT. F$GETDVI(TARGET,"MNT") THEN MOUNT_TARGET 'TARGET /OV=ID
$	SET ON
$	IF KIT_TYPE .EQS. "RL02" THEN GOTO PASS3
$PASS2:
$	WRITE SYS$OUTPUT ""
$	WRITE SYS$OUTPUT "	* * * * *   PASS2   * * * * *"
$	WRITE SYS$OUTPUT ""
$	IF F$MODE () .NES. "INTERACTIVE" THEN GOTO 200$
$	IF PAUSE THEN INQUIRE ANSWER "Press RETURN to begin pass 2"
$200$:	ON ERROR THEN GOTO RUNDOWN
$
$	@'COMMAND'VMSKITBLD -			! Kitbuild command procedure
		'COMMAND'VMSKITBLD.DAT -	! Kitbuild data file
		"" -				! Default mask -- standard kit
		'SOURCE''SOURCE_TOPSYS_DIR' -	! Source disk and topsys
		'SCRATCH'VAXVMSLB4	-	! Target disk
		LIB -				! Optional fileset
		"" -				! n/a
		BUILD -				! Fresh build operation
		NOPROMPT			! Device already confirmed
$PASS2_B:
$	WRITE SYS$OUTPUT ""
$	WRITE SYS$OUTPUT "	* * * * *   PASS2_B   * * * * *"
$	WRITE SYS$OUTPUT ""
$	ON ERROR THEN GOTO RUNDOWN
$	!
$	! BACKUP the scratch disk to the target media
$	!
$	MOUNT 'SCRATCH' VAXVMSLB4
$	BACKUP 'SCRATCH' 'TARGET'[000000]LIBRARY /SAVESET -
		'BLOCKSIZE' -
		/INTERCHANGE -
		/IMAGE -
		/NOINIT -
		/NOREWIND			! If tape, then append
$	DISM /NOUNLOAD 'SCRATCH'
$	IF KIT_TYPE .NES. "RL02" THEN GOTO PASS3
$	@'COMMAND'STABACKIT 'TARGET' [SYS0.SYSEXE] 'SOURCE'['SOURCE_TOPSYS_DOT'SYSEXE]
$	GOTO COMPLETION
$PASS3:
$	WRITE SYS$OUTPUT ""
$	WRITE SYS$OUTPUT "	* * * * *   PASS3   * * * * *"
$	WRITE SYS$OUTPUT ""
$	IF F$MODE () .NES. "INTERACTIVE" THEN GOTO 300$
$	IF PAUSE THEN INQUIRE ANSWER "Press RETURN to begin pass 3"
$300$:	ON ERROR THEN GOTO RUNDOWN
$	!
$	! Do a VMSKITBLD of the optional file set
$	!
$	@'COMMAND'VMSKITBLD -			! Kitbuild command procedure
		'COMMAND'VMSKITBLD.DAT -	! Kitbuild data file
		"" -				! Default mask -- standard kit
		'SOURCE''SOURCE_TOPSYS_DIR' -	! Source disk and topsys
		'SCRATCH'VAXVMSOP4	-	! Target disk
		OPT -				! Optional fileset
		"" -				! n/a
		BUILD -				! Fresh build operation
		NOPROMPT			! Device already confirmed
$PASS3_B:
$	WRITE SYS$OUTPUT ""
$	WRITE SYS$OUTPUT "	* * * * *   PASS3_B   * * * * *"
$	WRITE SYS$OUTPUT ""
$	ON ERROR THEN GOTO RUNDOWN
$	!
$	! BACKUP the scratch disk to the target media
$	!
$	MOUNT 'SCRATCH' VAXVMSOP4
$	BACKUP 'SCRATCH' 'TARGET'[000000]OPTIONAL /SAVESET -
		'BLOCKSIZE' -
		/IMAGE -
		/INTERCHANGE -
		/NOINIT -
		/NOREWIND			! If tape, then append
$	DISMOUNT /NOUNLOAD 'SCRATCH'
$	IF KIT_TYPE .NES. "RL02" THEN GOTO COMPLETION
$	DISMOUNT /NOUNLOAD 'TARGET'
$GET_FRESH_RL02:
$	WRITE SYS$OUTPUT ""
$	WRITE SYS$OUTPUT "Remove the pack from ''target', and insert a blank pack."
$	INQUIRE OK "Are you ready to continue"
$	IF .NOT. OK THEN GOTO GET_FRESH_RL02
$	INIT_TARGET 'TARGET VMS'VERSION'LIB
$	MOUNT_TARGET 'TARGET /OV=ID
$	GOTO PASS2
$COMPLETION:
$	SUMMARY = " Completed distribution kit is on device ''TARGET'"
$	GOTO RUNDOWN
$
$MICROVMS_1:
$	ON ERROR THEN GOTO RUNDOWN
$	LEGAL_UVMS = "BASE,UTIL,USER,NET,PROG,SYSP,INTE,"
$LAYERED_OPTION_LOOP:
$	UVMS_OPTION = F$ELEMENT(0,",",LEGAL_UVMS)
$	IF UVMS_OPTION .EQS. "" THEN GOTO COMPLETION
$	LEGAL_UVMS = LEGAL_UVMS - "''UVMS_OPTION',"
$	LABEL = "UV" + F$EXTRACT(0,5,UVMS_OPTION)
$	IF UVMS_OPTION .EQS. "BASE" THEN LABEL = "MICROVMS"
$REPEAT_IT3:
$	OK = 1
$	IF RESTART THEN INQUIRE OK "Do you want to start with option ''UVMS_OPTION'? (Y/N)"
$	IF OK .EQS. "" THEN GOTO REPEAT_IT3
$	IF .NOT. OK THEN GOTO LAYERED_OPTION_LOOP
$REPEAT_IT4:
$	DESTINATION == "1"
$	IF RESTART THEN INQUIRE DESTINATION -
"Which pass do you want to start with (1 or 2)"
$	IF (DESTINATION .NES. "1") .AND. (DESTINATION .NES. "2") THEN -
		WRITE SYS$OUTPUT "Illegal pass option.  Enter only 1 or 2"
$	IF (DESTINATION .NES. "1") .AND. (DESTINATION .NES. "2") THEN GOTO REPEAT_IT4
$	WRITE SYS$OUTPUT ""
$	WRITE SYS$OUTPUT "	* * * * *   MICROVMS_",UVMS_OPTION,"_1   * * * * *"
$	WRITE SYS$OUTPUT ""
$	WRITE SYS$OUTPUT -
"Please place the kit medium in the target drive, ''TARGET'."
$REPEAT_IT:
$	INQUIRE OK "Is ''TARGET' ready to be initialized? (Y/N)"
$	IF .NOT. OK THEN GOTO REPEAT_IT
$	INIT_TARGET 'TARGET 'LABEL'
$	MOUNT_TARGET 'TARGET' /OVER=ID/FOREIGN
$	WRITE SYS$OUTPUT -
"Please place the scratch RL02 in the scratch drive, ''SCRATCH'."
$REPEAT_IT2:
$	OK = "YES"
$	IF (RESTART) .AND. (DESTINATION .EQS. "2") THEN GOTO MICROVMS_2
$	IF RESTART THEN	INQUIRE OK "Do you want to initialize ''SCRATCH'? (Y/N)"
$	IF .NOT. OK THEN GOTO MNT_SCRATCH_ONLY
$	INQUIRE OK "Is ''SCRATCH' ready to be initialized? (Y/N)"
$	IF .NOT. OK THEN GOTO REPEAT_IT2
$	INIT_TARGET 'SCRATCH 'LABEL'
$MNT_SCRATCH_ONLY:
$	!
$	! Do a VMSKITBLD of the MicroVMS option.
$	!
$	IF UVMS_OPTION .NES. "BASE" THEN GOTO LAYERED_OPTION_1
$	MASK = 1+8+64+256+4096		! Standard default mask + MicroVMS-spec
$	@'COMMAND'VMSKITBLD.COM -	! Kitbuild command procedure
		'COMMAND'VMSKITBLD.DAT -! Kitbuild data file
		'MASK' -		! Include MicroVMS mask bit
		'SOURCE''SOURCE_TOPSYS_DIR' - ! Source disk and topsys
		'SCRATCH''LABEL' -	! Target disk
		"" -			! n/a (saveset)
		'UVMS_OPTION' -		! MicroVMS option
		BUILD -			! Fresh build operation
		NOPROMPT		! Device already confirmed
$	MOUNT 'SCRATCH' 'LABEL'
$	IF F$GETDVI(TARGET,"DEVCLASS") .EQ. DC$_DISK THEN BLOCKSIZE = ""
$	!
$	! Set the default system parameters for the base MicroVMS system.
$	!
$	! NOTE:  If these are changed, then [UVMS.SRC]MODPARAMS.DAT must be
$	!	 changed also!!!
$	!
$	SET DEFAULT 'SCRATCH'['TOPSYS'SYSEXE]
$	SET VOLUME 'SCRATCH'/NOHIGHWATER
$	DEFINE/USER SYS$LIBRARY 'SCRATCH'['TOPSYS'SYSLIB]
$	DEFINE/USER SYS$SYSTEM 'SCRATCH'['TOPSYS'SYSEXE]
$	RUN SYSGEN
		USE DEFAULT
		SET KFILSTCNT		16
		SET GBLSECTIONS		50
		SET GBLPAGES		1400
		SET MAXPROCESSCNT	12
		SET SYSMWCNT		400
		SET BALSETCNT		10
		SET IRPCOUNT		30
		SET IRPCOUNTV		1500
		SET WSMAX		512
		SET NPAGEDYN		120000
		SET NPAGEVIR		256000
		SET PAGEDYN		70000
		SET SPTREQ		896
		SET LRPCOUNT		8
		SET LRPCOUNTV		60
		SET SRPCOUNT		60
		SET SRPCOUNTV		600
		SET MPW_HILIMIT		250
		SET MPW_LOLIMIT		120
		SET SWPOUTPGCNT		80
		SET FREELIM		32
		SET BORROWLIM		120
		SET GROWLIM		60
		SET FREEGOAL		120
		SET CLISYMTBL		80
		SET LOCKIDTBL		40
		SET LOCKIDTBL_MAX	2048
		SET RESHASHTBL		20
		SET DEADLOCK_WAIT	1
		SET SCSBUFFCNT		3
		SET SCSCONNCNT		4
		SET SCSRESPCNT		20
		SET SCSSYSTEMID		65534
		SET SCSNODE		"SALONE"
		SET PAMAXPORT		14
		SET PAPOLLINTERVAL	5
		SET CJFLOAD		0
		SET TTY_DEFCHAR2	4106
		SET RMS_EXTEND_SIZE	80
		SET ACP_HDRCACHE	28
		SET ACP_DIRCACHE	28
		SET ACP_QUOCACHE	20
		SET ACP_SYSACC		4
		SET ACP_MAXREAD		6
		SET ACP_DATACHECK	2
		SET ACP_SWAPFLGS	14
		SET IJOBLIM		8
		SET RJOBLIM		10
		SET RECNXINTERVAL	20
		SET VAXCLUSTER		0
	 	SET LGI_BRK_TMO		0
		SET LGI_HID_TIM		0
		WRITE CURRENT
$	!
$	! The following lines finish the MicroVMS base system kit here, since
$	! there is no way to do them via VMSKITBLD.DAT.
$	!
$	LIBR/CREATE 'SCRATCH'['TOPSYS'SYSLIB]STARLET.OLB/LOG
$	LIBR/CREATE=(MODULES=200)/HELP 'SCRATCH'['TOPSYS'SYSHLP]HELPLIB.HLB/LOG
$	SET PROT=(S=RWED,O=RWED,G=RWED,W=RE) 'SCRATCH'['TOPSYS'SYSLIB]STARLET.OLB;
$	SET PROT=(S=RWED,O=RWED,G=RWED,W=RE) 'SCRATCH'['TOPSYS'SYSHLP]HELPLIB.HLB;
$	SET PROT=(S=RWED,O=RWED,G=RWED,W=RE) 'SCRATCH'['TOPSYS'SYSEXE]NOTICE.TXT;
$	SET PROT=(S=RWE,O=RWE,G=RWE,W) 'SCRATCH'['TOPSYS'SYSEXE]SYSUAF.DAT;
$	SET PROT=(S=RWE,O=RWE,G=RWE,W) 'SCRATCH'['TOPSYS'SYSEXE]SYSALF.DAT;
$	CREATE/DIR 'SCRATCH'[USER]/OWNER=([200,200])
$	COPY 'SCRATCH'['TOPSYS'SYSMGR]EDTINI.EDT 'SCRATCH'[USER]EDTINI.EDT
$	SET FILE/OWNER=([200,200]) /PROT=W=RE 'SCRATCH'[USER]EDTINI.EDT
$	COPY 'SCRATCH'['TOPSYS'SYSMGR]LOGIN.COM 'SCRATCH'[USER]LOGIN.COM
$	SET FILE/OWNER=([200,200]) /PROT=W=RE 'SCRATCH'[USER]LOGIN.COM
$	SET DEFAULT 'SCRATCH'['TOPSYS'SYSEXE]
$	DELETE SYS$LOGIN:RIGHTSLIST.DAT;*
$	DEFINE/SYSTEM/EXEC RIGHTSLIST 'F$TRNLNM("SYS$LOGIN")'RIGHTSLIST.DAT
$	MCR AUTHORIZE
		ADD USERP/UIC=[200,200]/PRIV=ALL/DEV=$DISK1:
		MODIFY USERP/DIR=[USER]/WSDEFAULT=300/WSQUOTA=512/WSEXTENT=1024
		ADD USER/UIC=[200,200]/PRIV=(NETMBX,TMPMBX)
		MODIFY USERP/PWDLIFETIME=0/PWDMINIMUM=0/NOPASSWORD
		MODIFY USER/DEV=$DISK1:/DIR=[USER]
		MODIFY USER/WSDEFAULT=300/WSQUOTA=512/WSEXTENT=1024
		MODIFY USER/PWDLIFETIME=0/PWDMINIMUM=0/NOPASSWORD
		MODIFY SYSTEM/PWDLIFETIME=0/PWDMINIMUM=0/NOPASSWORD
		MODIFY DEFAULT/DEV=$DISK1:
		MODIFY DEFAULT/WSDEFAULT=300/WSQUOTA=512/WSEXTENT=1024
		REMOVE FIELD
		REMOVE SYSTEST
		REMOVE SYSTEST_CLIG
		CREATE/RIGHTS
		ADD/IDENTIFIER/USER=SYSTEM
		ADD/IDENTIFIER/USER=USER
		EXIT
$	DEASSIGN /SYSTEM /EXEC RIGHTSLIST
$	COPY SYS$LOGIN:RIGHTSLIST.DAT 'SCRATCH'['TOPSYS'SYSEXE]
$	DELETE SYS$LOGIN:RIGHTSLIST.DAT;*
$	SET PROT=(S=RWE,O=RWE,G=RWE,W=R) 'SCRATCH'['TOPSYS'SYSEXE]RIGHTSLIST.DAT
$	PURGE 'SCRATCH'['TOPSYS'SYSEXE]SYSUAF.DAT
$	DISMOUNT/NOUNLOAD 'SCRATCH'
$	SET DEFAULT 'DEFDIR'
$	!
$	! BACKUP the scratch disk to the target media
$	!
$
$MICROVMS_2:
$	IF UVMS_OPTION .NES. "BASE" THEN GOTO LAYERED_OPTION_2
$	WRITE SYS$OUTPUT ""
$	WRITE SYS$OUTPUT "	* * * * *   MICROVMS_",UVMS_OPTION,"_2   * * * * *"
$	WRITE SYS$OUTPUT ""
$	ON ERROR THEN GOTO RUNDOWN
$	MOUNT 'SCRATCH' 'LABEL'
$	INIT_IT = "/NOINIT"
$	IF UVMS_OPTION .NES. "BASE" THEN GOTO MICROVMS_2A
$	INIT_IT = "/INIT/IMAGE"
$	SET DEFAULT 'DEFDIR'
$set ver
$	BACKUP 'SCRATCH' 'TARGET'[000000]'LABEL' /SAVESET -
		'BLOCKSIZE' -
		/INTERCHANGE -
		'INIT_IT' -
		/NOREWIND -
		/LABEL = 'LABEL'
$set nover
$	DISMOUNT /NOUNLOAD 'SCRATCH'
$	DISMOUNT /NOUNLOAD 'TARGET'
$	GOTO LAYERED_OPTION_LOOP
$LAYERED_OPTION_1:
$	IF .NOT. F$GETDVI (SCRATCH, "MNT") THEN MOUNT 'SCRATCH' /OVER=ID
$	CREATE/DIR 'SCRATCH'['UVMS_OPTION']
$	ON ERROR THEN CONTINUE
$	DELETE 'SCRATCH'['UVMS_OPTION'.*]*.*;*
$	DELETE 'SCRATCH'['UVMS_OPTION']*.*;*/EXCLUDE=*.DIR;1
$	ON ERROR THEN GOTO RUNDOWN
$	KIT_NAME = UVMS_OPTION
$	GOTO NEW_KIT	! inputs:  KIT_NAME
$NEW_KIT_DONE:
$	ON ERROR THEN GOTO NO_DATAF
$	SAVESET_NAME = "A"
$	SEQUENCE_CHAR = F$CVSI(0,8,"A")
$	SEQUENCE_CHAR = SEQUENCE_CHAR - 1
$SAVESET_LOOP:
$	SEQUENCE_CHAR = SEQUENCE_CHAR + 1
$	SAVESET_NAME[0,8]=SEQUENCE_CHAR
$	If SAVESET_NAME .GTS. "Z" THEN GOTO SAVESET_NAME_ERR
$	SEARCH 'COMMAND'VMSKITBLD.DAT "''UVMS_OPTION'_''SAVESET_NAME'","UVMS=ALL" -
		/OUTPUT='SCRATCH'['UVMS_OPTION']UVOPTION.DAT
$	SEARCH/OUTPUT=NL: 'SCRATCH'['UVMS_OPTION']UVOPTION.DAT "''UVMS_OPTION'_''SAVESET_NAME'"
$	IF $STATUS .EQ. %X08D78053 THEN GOTO EO_KIT
$	OPEN/READ DATAF	'SCRATCH'['UVMS_OPTION']UVOPTION.DAT
$RECORD_LOOP:
$	!
$	! This is the main loop that is executed for each record in the data file.
$	!
$	READ/END_OF_FILE=EO_SAVESET DATAF RECORD
$	IF F$EXTRACT(0,1,RECORD) .EQS. "$" THEN GOTO RECORD_LOOP
$	IF F$EXTRACT(0,1,RECORD) .EQS. "!" THEN GOTO GET_SAVESET
$	IF F$EXTRACT(0,1,RECORD) .EQS. "," THEN GOTO RECORD_LOOP
$	GOTO GET_NAME
$GET_SAVESET:
$	!
$	! The saveset name and text description line starts with "!*" and
$	! the text description portion follows the name and is delimited
$	! by "*"s.
$	!
$	IF F$EXTRACT(1,1,RECORD) .NES. "*" THEN GOTO RECORD_LOOP
$	SAVESET_TEXT = F$EXTRACT(F$LOCATE("''UVMS_OPTION'_''SAVESET_NAME'",RECORD),132,RECORD)
$	SAVESET_TEXT = F$EXTRACT(F$LOCATE("*",SAVESET_TEXT)+1,132,SAVESET_TEXT)
$	SAVESET_TEXT = F$EXTRACT(0,F$LOCATE("*",SAVESET_TEXT),SAVESET_TEXT)
$	WRITE SYS$OUTPUT "	* * * * *   Saveset - ",SAVESET_NAME," ",SAVESET_TEXT,"   * * * * *"
$	GOTO NEW_SAVESET	! inputs:  SAVESET_NAME, SAVESET_TEXT
$NEW_SAVESET_DONE:
$	GOTO RECORD_LOOP
$GET_NAME:
$	!
$	! Get the name from the current record.  (The name is always the first field
$	! in the record, and doesn't have a keyword associated with it.)
$	!
$	FILE_NAME = F$EXTRACT(0,F$LOCATE(",",RECORD),RECORD)
$GET_OPERATION:
$	!
$	! Get the operation.  It will be "SET" or nothing for file copy.
$	!
$	! NOTE:  This procedure does not handle any other operations:
$	! RENAME_C, SYSGEN, CREATE, CONTIG, BUILD, or ENTER.
$	!
$	OPERATION = F$EXTRACT(F$LOCATE("OP=",RECORD)+3,132,RECORD)
$	IF OPERATION .EQS. "" THEN GOTO COPY_FILE
$	OPERATION = F$EXTRACT(0,F$LOCATE(",",OPERATION),OPERATION)
$	IF OPERATION .EQS. "SET" THEN GOTO SET_DEST_DIR
$	IF OPERATION .EQS. "RENAME_B" THEN GOTO RENAME_OPERATION
$	GOTO BAD_OPERATION
$
$SET_DEST_DIR:
$	DEST_DIR = FILE_NAME
$	GOTO RECORD_LOOP
$
$RENAME_OPERATION:
$	IF F$SEARCH("''SOURCE'[''SOURCE_TOPSYS_DOT'''DEST_DIR']''FILE_NAME'") .EQS. "" -
		THEN GOTO NO_SUCH_FILE
$	DEST_NAME = F$EXTRACT(F$LOCATE("DEST=",RECORD)+5,132,RECORD)
$	DEST_NAME = F$EXTRACT(0,F$LOCATE(",",DEST_NAME),DEST_NAME)
$	GOTO RENAME_FILE
$RENAME_FILE_DONE:
$	GOTO RECORD_LOOP
$COPY_FILE:
$	IF F$SEARCH("''SOURCE'[''SOURCE_TOPSYS_DOT'''DEST_DIR']''FILE_NAME'") .EQS. "" -
		THEN GOTO NO_SUCH_FILE
$	FILE_SIZE = F$FILE("''SOURCE'[''SOURCE_TOPSYS_DOT'''DEST_DIR']''FILE_NAME'","EOF")
$GOT_FILE_SIZE:
$	GOTO NEW_FILE	! inputs:  FILE_NAME, FILE_SIZE, DEST_DIR
$NEW_FILE_DONE:
$	GOTO RECORD_LOOP
$
$NO_SUCH_FILE:
$	WRITE SYS$OUTPUT "%WARNING - No such file:  ","[''DEST_DIR']''FILE_NAME'"
$	WRITE 'SAVESET_NAME' "[''DEST_DIR']''FILE_NAME'","	(??)"
$	GOTO RECORD_LOOP
$
$EO_SAVESET:
$	CLOSE DATAF
$	DELETE 'SCRATCH'['UVMS_OPTION']UVOPTION.DAT;
$	GOTO END_SAVESET	! inputs:  NONE
$END_SAVESET_DONE:
$	GOTO SAVESET_LOOP
$EO_KIT:
$	GOTO CREATE_ISAM_CHECK
$END_KIT_DONE:
$ set nover
$	GOTO LAYERED_OPTION_2
$ !
$ !	Here the backup commands are executed to build the savesets
$ !	on a layered option kit for MicroVMS.
$ !
$LAYERED_OPTION_2:
$	WRITE SYS$OUTPUT ""
$	WRITE SYS$OUTPUT "		* * * * *   MICROVMS_",UVMS_OPTION,"_2   * * * * *"
$	WRITE SYS$OUTPUT ""
$	IF .NOT. F$GETDVI (SCRATCH, "MNT") THEN MOUNT 'SCRATCH' /OVER=ID
$ @'SCRATCH'['UVMS_OPTION']'UVMS_OPTION'BACKUP.COM
$	GOTO LAYERED_OPTION_LOOP
$ !
$ !	Error exits.
$ !
$SAVESET_NAME_ERR:
$	WRITE SYS$OUTPUT "ERROR - More than 26 savesets requested."
$	GOTO RUNDOWN
$NO_DATAF:
$	WRITE SYS$OUTPUT -
	" Unable to open data parameter file ",'COMMAND',"VMSKITBLD.DAT."
$	GOTO RUNDOWN
$BAD_TYPE:
$	WRITE SYS$OUTPUT "Invalid kit type ''KIT_TYPE'"
$	GOTO RUNDOWN
$BAD_OPERATION:
$	WRITE SYS$OUTPUT -
	" Procedure does not handle an operation of",'OPERATION',"."
$	GOTO RUNDOWN
$CONTROLY:
$	SUMMARY = "Distribution kit build aborted by CTRL/Y"
$
$RUNDOWN:
$	!
$	! Do any cleanup necessary before exiting.
$	!
$	ON ERROR THEN GOTO 920$
$	IF SCRATCH .EQS. "" THEN GOTO 920$
$	IF F$GETDVI (SCRATCH, "MNT") THEN DISMOUNT /NOUNLOAD 'SCRATCH
$920$:	ON ERROR THEN GOTO 930$
$	IF TARGET .EQS. "" THEN GOTO 930$
$	IF .NOT. F$GETDVI (TARGET, "MNT") THEN GOTO 930$
$	DISMOUNT /NOUNLOAD 'TARGET
$	ERROR_COUNT = F$GETDVI (TARGET, "ERRCNT") - START_ERROR_COUNT
$	IF ERROR_COUNT .NE. 0 THEN WRITE SYS$OUTPUT -
		" There were ''ERROR_COUNT' errors on device ''TARGET'"
$930$:
$	set noon
$	close/nolog kitcreate
$	close/nolog files
$	close/nolog ask
$	set on
$	SET UIC 'DEFUIC'
$	SET DEFAULT 'DEFDIR'
$	SET PROTECTION=('DEFPROT')/DEFAULT
$	PREV_PRIV = F$SETPRV(PREV_PRIV)
$	WRITE SYS$OUTPUT SUMMARY
$	EXIT
$!
$! new_kit
$!
$! Inputs:
$!	kit_name 
$ new_kit:
$	DEF TOP 'SCRATCH'['KIT_NAME']
$	DEF ROOT 'SCRATCH'['KIT_NAME'.]
$	open/write kitcreate TOP:ASKQ.COM
$	close kitcreate
$	open/write kitcreate TOP:RESTORE.COM
$	close kitcreate
$	copy 'command'uvinstal.com top:kitinstal.com
$	OPEN/WRITE kitcreate top:'kit_name'backup.com
$	tmp = kit_name + vrsn
$	WRITE KITCREATE -
"$ @''command'UVKITBLD ''tmp' ''target' ''scratch'[''KIT_NAME'.A]*.* ''scratch'[''kit_name']kitsave.dat"
$	close kitcreate
$	open/write kitcreate top:kitsave.dat
$
$ GOTO NEW_KIT_DONE
$ !
$ !new_saveset
$ !
$ !inputs:
$ !	SAVESET_NAME
$ !	SAVESET_TEXT
$ !	kit_name
$ !
$ NEW_SAVESET:
$	SAVESET_SIZE=0
$	CREATE/DIR ROOT:['SAVESET_NAME']
$	OPEN/WRITE FILES TOP:TEMP.TMP
$	OPEN/WRITE ASK TOP:PRE.TMP
$	SAVESET_SIZE=0
$	WRITE ASK -
"$ SAVESET_NAME:= ''SAVESET_NAME'"
$	write files -
	    "$ if .not. restore_''saveset_name' then goto end_''saveset_name'"
$	write files "$ save = saveset_name"
$	if saveset_name .eqs. "A" then goto new_saveset_done
$	WRITE KITCREATE "''scratch'[''KIT_NAME'.''SAVESET_NAME']*.*"
$	write files "$ vmi$callback restore_saveset ''saveset_name'"
$ GOTO NEW_SAVESET_DONE
$ !
$ ! rename_file
$ !	THIS CALL ASSUMES THAT THE FILE TYPE IS ".UV" AND THE FILE
$ ! WAS ALREADY COPIED BY A NEW_FILE CALL
$ !
$ ! Inputs:
$ !	FILE_NAME
$ !	DEST_DIR
$ !	DEST_NAME
$RENAME_FILE:
$ 	IF F$LOCATE(".UV",FILE_NAME).EQ.F$LEN(FILE_NAME) THEN GOTO -
		BAD_RENAME
$	WRITE FILES "$ VMI$CALLBACK PROVIDE_IMAGE NEWFILE$ ''DEST_NAME' VMI$ROOT:[''DEST_DIR']"
$	RENAME	ROOT:['SAVESET_NAME']'FILE_NAME' -
		ROOT:['SAVESET_NAME']'DEST_NAME'
$	GOTO RENAME_FILE_DONE
$BAD_RENAME:
$	WRITE SYS$OUTPUT "file ''file_name' is in valid on a rename call"
$	Write sys$Output "Renamed files must have a .UV file type"
$	goto rundown
$ !
$ ! new_file
$ !	THIS routine has specail knowlege of the .UV extension.  It asumes
$ !  there will be a rename for the given file
$ ! Inputs:
$ !	FILE_NAME
$ !	FILE_SIZE
$ !	DEST_DIR
$ !
$ NEW_FILE:
$	SAVESET_SIZE=SAVESET_SIZE+FILE_SIZE
$	LOGNAM=KIT_NAME+"$"+FILE_NAME-"."
$	IF F$LOGICAL(LOGNAM).NES."" THEN GOTO MOVE_TO_A
$ 	IF F$LOCATE(".UV",FILE_NAME).NE.F$LEN(FILE_NAME) THEN GOTO NOPROVIDE
$	WRITE FILES "$ VMI$CALLBACK PROVIDE_IMAGE NEWFILE$ ''FILE_NAME' VMI$ROOT:[''DEST_DIR']"
$   noprovide:
$	DEF 'LOGNAM 'SAVESET_NAME'
$	COPY 'SOURCE'['SOURCE_TOPSYS_DOT''DEST_DIR']'FILE_NAME' -
		ROOT:['SAVESET_NAME']
$	GOTO NEW_FILE_DONE
$ MOVE_TO_A:
$	TRANS=F$LOGICAL(LOGNAM)
$ 	IF F$LOCATE(".UV",FILE_NAME).NE.F$LEN(FILE_NAME) THEN -
			GOTO NOPROVIDE2
$	WRITE FILES -
"$ IF .NOT. RESTORE_''TRANS' THEN -"
$	WRITE FILES "$ VMI$CALLBACK PROVIDE_IMAGE NEWFILE$ ''FILE_NAME' VMI$ROOT:[''DEST_DIR']"
$   noprovide2:
$	IF TRANS.EQS."A" THEN GOTO MOVE_TO_DONE
$	DEF/NOLOG 'LOGNAM A
$	RENAME ROOT:['TRANS']'FILE_NAME' ROOT:[A]
$ MOVE_TO_DONE:
$	GOTO NEW_FILE_DONE
$ !
$ ! end_saveset
$ !
$ END_SAVESET:
$	write ASK "$ saveset_size=''saveset_size'"
$	write ask "$ restore_''saveset_name'==true"
$	if saveset_name .eqs."A" then goto restore_always
$	WRITE ASK "$ IF RESTORE_ALL THEN GOTO ALL_''SAVESET_NAME'"
$	write ask -
"$ VMI$CALLBACK ASK RESTORE_''saveset_name' ""Do you want to install the ''saveset_text'"""
$	write ask -
	"$ IF .NOT. RESTORE_''saveset_name' THEN GOTO NOcheck_''SAVESET_NAME'"
$	WRITE ASK "$ALL_''SAVESET_NAME':"
$	WRITE ASK "$ TOTAL_BLOCKS = TOTAL_BLOCKS + saveset_size"
$	write ask -
	"$ VMI$CALLBACK CHECK_NET_UTILIZATION ENOUGH_BLOCKS total_blocks"
$	WRITE ASK -
	"$ IF ENOUGH_BLOCKS THEN GOTO NOCHECK_''saveset_name'"
$	WRITE ASK "$ VMI$CALLBACK MESSAGE E NOSPACE -"
$	WRITE ASK -
"""System disk does not contain enough free blocks to install the ''SAVESET_TEXT'"""
$	WRITE ASK -
"$ VMI$CALLBACK MESSAGE E NOSPACE ""''SAVESET_SIZE' free blocks required."""
$	write ask "$ EXIT VMI$_FAILURE"
$restore_always:
$	write ask "$nocheck_''saveset_name':"
$	CLOSE ASK
$	WRITE FILES "$END_''SAVESET_NAME':"
$	CLOSE FILES
$	APPEND TOP:PRE.TMP top:askq.com
$	append TOP:TEMP.TMP TOP:restore.com
$	DELete TOP:PRE.TMP;,TOP:TEMP.TMP;
$ GOTO END_SAVESET_DONE
$ !
$ ! create_isam_check
$ !
$ CREATE_ISAM_CHECK:
$	OPEN/WRITE FILES TOP:TEMP.TMP
$	write files "$version_check:"
$	write files "$ numbers = ""0123456789""
$	write files "$ temp = vmi$product"
$	write files "$k5:"
$	write files "$ tmp = f$ext(0,1,temp)"
$	write files "$ if f$loc(tmp,numbers) .ne. f$len(numbers) then goto k7
$	write files "$ temp = f$ext(1,999,temp)"
$	write files "$ goto k5"
$	write files "$k7:"
$	write files "$ prod_version = f$ext(0,3,temp)"
$	write files "$ sys_version = f$getsyi(""version"")"
$	write files "$ sys_version = f$edit(sys_version,""TRIM"")"
$	write files "$ if f$locate(""."",sys_version) .ne. f$length(sys_version) then goto k8"
$	write files "$ sys_version = sys_version - f$extract(0,1,sys_version)"
$	write files "$ goto k9"
$	write files "$k8:"
$	write files "$ sys_version = sys_version - ""."""
$	write files "$ sys_version = f$ext(1,999,sys_version)"
$	write files "$ sys_version = ""0"" + sys_version"
$	write files "$k9:"
$	write files "$ if prod_version .eqs. sys_version then goto provide"
$       write files "$isam_check:"
$	write files "$ say """""
$	write files "$ defvol = """""
$	write files "$ tmp = ""UPDKIT"" + sys_version + "".TXT"""
$	write files "$ open/share/read/write isamfile sys$update:'tmp'"
$	write files "$ letters = ""ABCDEFGHIJLMNOQRSTUVWXYZ""
$	write files "$ on controly then goto no_finish"
$	write files "$ set def vmi$kwd"
$	write files "$ create/directory [.src]"
$	write files "$loop:"
$	write files "$ on error then goto k10"
$	write files "$ letter = f$extract(0,1,letters)"
$	write files "$ file = f$extract(0,f$length(vmi$product) - 3,vmi$product)
$	write files "$ opt = file"
$	write files "$ file = file + sys_version + letter"
$       write files "$ read/key='file'/end_of_file=loop isamfile rcd"
$	write files "$ goto continue"
$	write files "$k10:"
$	write files "$ if letter .eqs. save then goto provide"
$	write files "$ letters = f$extract(1,999,letters)"
$	write files "$ goto loop"
$	write files "$continue:"
$	write files "$ volnumber = f$extract(f$length(rcd) - 1,1,rcd)"
$	write files "$ if defvol .eqs. volnumber then goto k19
$	write files "$ if f$getdvi(vmi$device,""MNT"") then dismount/nounload 'vmi$device"
$	write files "$ say ""To complete the installation of "",opt,"" -""
$	write files "$ say ""Please ready volume "",volnumber,"" of the maintenance update kit""
$	write files "$ defvol = volnumber"
$	write files "$ vmi$callback PLACE_VOLUME"
$	write files "$ mount/over=id 'vmi$device"
$	write files "$k19:"
$	write files "$ on error then goto restore_error"
$	write files "$ tmp = vmi$place + file
$	write files "$ backup/verify 'tmp'.Z/save [.src]"
$	write files "$ copy [.src]*.* vmi$kwd:"
$	write files "$ delete [.src]*.*;*"
$	write files "$ goto k10
$	write files "$provide:
$	write files "$ set default vmi$kwd"
$	write files "$ if f$search(""vmi$kwd:*.vu*"") .eqs. """" then goto all_done"
$	write files "$ save_a = 0"
$	write files "$instal:"
$	write files "$ set default [.src]"
$	write files "$ if save_a .eqs. 0 then goto restore_a"
$	write files "$ @kitinstal ""VMI$_INSTALL"" """" """" ""NOBACKUP""
$	write files "$ if .not. $status then goto no_finish"
$	write files "$all_done:"
$	write files "$ set default vmi$kwd
$	write files "$ close/nolog text"
$	write files "$ goto end_instal"
$	write files "$restore_a:"
$	write files "$ set default vmi$kwd"
$	write files "$ if defvol .eqs. "1" then goto k35
$	write files "$ if f$getdvi(vmi$device,""MNT"") then dismount/nounload 'vmi$device"
$	write files "$ say """""
$	write files "$ say ""To complete the installation of "",opt,"" -""
$	write files "$ say ""Please ready volume 1 of the maintenance update kit""
$	write files "$ vmi$callback PLACE_VOLUME"
$	write files "$ mount/over=id 'vmi$device"
$	write files "$k35:"
$	write files "$ set default 'vmi$place
$	write files "$ tmp = f$search(""*.a"")"
$	write files "$ set default vmi$kwd
$	write files "$ backup/verify 'tmp'/save [.src]"
$	write files "$ copy [.src]*.* vmi$kwd:"
$	write files "$ delete [.src]*.*;*"
$	write files "$ copy vmi$kwd:kitinstal.com [.src]"
$	write files "$ save_a = 1"
$	write files "$ goto instal"
$	write files "$restore_error:"
$	write files "$ say ""Unable to restore saveset ""'tmp"
$	write files "$ goto delete_dir"
$	write files "$no_finish:"
$	write files "$ say """""
$	write files "$ say ""Unexpected halt to installation.""
$	write files "$ say OPTION,"" will now be removed.""
$	write files "$ say """""
$	write files "$ @SYS$UPDATE:REMOVE ""SYS$UPDATE:VMSKITBLD.DAT"" 'OPTION' ""Y"""
$	write files "$delete_dir:"
$	write files "$ close/nolog isamfile"
$	write files "$ set default vmi$kwd"
$	write files "$ delete [.src]*.*;*"
$	write files "$ exit vmi$_failure"
$	CLOSE FILES
$	APPEND TOP:TEMP.TMP TOP:restore.com
$	delete TOP:TEMP.TMP;*
$ !
$ ! end_kit
$ !
$ END_KIT:
$	CLOSE KITCREATE
$	open/write kitcreate top:temp.tmp
$	write kitcreate "$end_instal:"
$	write kitcreate "$ if f$verify() then set noverify"
$	write kitcreate "$ close/nolog isamfile"
$	write kitcreate "$ if f$search(""src.dir"") .nes. """" then delete [.src]*.*;*
$	write kitcreate "$ exit vmi$_success"
$	close kitcreate
$	append top:askq.com,top:restore.com,top:temp.tmp top:kitinstal.com
$	rename top:kitinstal.com root:[a]
$	delete top:askq.com;,top:restore.com;,top:temp.tmp;
$ goto end_kit_done
