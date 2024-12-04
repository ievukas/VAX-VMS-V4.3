$ !++
$ ! STABACKIT.COM - Build a standalone kit
$ !
$ ! ABSTRACT:	This command procedure builds the standalone VMS system kit
$ !		for BACKUP and BAD.  (S/A BAD not supported for V4.0)	!*bad*
$ !
$ ! INPUT:	P1 - Target device
$ !		P2 - Target directory, defaults to <SYS0.SYSEXE>.  If target
$ !		     device is SYS$SYSDEVICE:, the directory is forced to
$ !		     <SYSE.SYSEXE> and the <SYSE> directory will be given
$ !		     a SYSCOMMON root which points to common system files
$ !		     (i.e. points to SYS$TOPSYS for normal systems and to
$ !		     existing SYSCOMMON for shared system disks).  Forced to
$ !		     <SYS0.SYSEXE> for small media.
$ !		P3 - Source device and directory, defaults to SYS$SYSTEM
$ !		P4 - Application kit type, one of [BACKUP, BAD] (Forced to
$ !		     BACKUP for V4.0)	!*bad*
$ !	
$ !		Privileges required:  SETPRV
$ !		Write access to SYS$UPDATE is also required.
$ !--
$	STA0$START_TIME = F$CVTIME (,"ABSOLUTE")
$	IF F$MODE() .NES. "INTERACTIVE" THEN GOTO STA0$ERR_NO_INT
$	!
$	! Set up a few symbols for later
$	!
$	FALSE = 0
$	TRUE  = 1
$	!
$	CONSOLE_CONNECTED 		= FALSE
$	CopyT  				= "COPY/TRUNC/LOG"
$	CopyTC 				= "COPY/TRUNC/CONTIG/LOG"
$	CopySB 				= "$STABACCOP"
$	DENS 				= ""
$	DEVICE_MOUNTED 			= FALSE
$	DEVICE_MOUNTED_1 		= FALSE
$	DEVICE_ORIGINALLY_MOUNTED 	= FALSE
$	KIT_DONE 			= FALSE
$	MICROVAX 			= FALSE
$	SAY 				= "WRITE SYS$OUTPUT"
$	SMALL_CONSOLE 			= FALSE
$	TRG_DEVICE 			= ""
$	TRGSAVE_DEVICE 			= ""
$	!
$	SET RMS/EXT=10
$	ON WARNING THEN GOTO STA0$CLEAN_UP
$	ON CONTROL_Y THEN GOTO STA0$CLEAN_UP
$	!
$	! Get necessary privileges and a system UIC
$	!
$	SAVED_PRIVS = F$SETPRV("CMKRNL,CMEXEC,LOG_IO,SYSNAM,VOLPRO,OPER")
$	SAVED_PROT  = F$ENVIRO("PROTECTION")
$	SAVED_UIC   = F$USER()
$	SET PROTECTION=(SYSTEM=RWED,OWNER=RWED,GROUP=RWED,WORLD) /DEFAULT
$	SET UIC [1,4]
$	!
$	! Find out where to find the source files.  Make sure that the source
$	! directory exists and contains SYS.EXE
$	!
$	IF P3 .EQS. "" THEN P3 = "SYS$SYSTEM:"
$	SRC_DIRECTORY = P3
$	DEFINE /NOLOG STA$SOURCE 'SRC_DIRECTORY'
$	IF F$SEARCH("STA$SOURCE:SYS.EXE") .EQS. "" THEN GOTO STA0$ERR_NO_SYS
$	!
$	! Make sure that we support the desired application
$	!
$	P4 = "BACKUP"	! For V4.0 we do not support s/a BAD	!*bad*
$	IF P4 .NES. "" THEN GOTO STA0$P4_READY
$	SAY ""
$	SAY "The STABACKIT procedure will build a standalone VMS kit for one of two"
$	SAY "standalone applications.  These applications are BACKUP, which saves"
$	SAY "and restores disk volumes, and BAD (aka ANALYZE/MEDIA), which scans"
$	SAY "disk volumes for defective blocks."
$	SAY ""
$	INQUIRE P4 "Enter the application type [BACKUP/BAD, default BACKUP]"
$	IF P4 .EQS. "" THEN P4 = "BACKUP"
$	SAY ""
$ STA0$P4_READY:
$	APPL_KIT = P4
$	IF APPL_KIT .NES. "BACKUP" .AND. APPL_KIT .NES. "BAD" THEN GOTO STA0$ERR_APPL_KIT
$	IF F$SEARCH("STA$SOURCE:STA''APPL_KIT'.EXE") .EQS. "" THEN GOTO STA0$ERR_APPL_KIT
$	!
$	! Find out where the kit should be built.  We will look at the device
$	! type specified, and use the device type to determine what to do next.
$	!
$ STA0$P1_INQUIRE:
$	IF P1 .NES. "" THEN GOTO STA0$P1_READY
$	SAY ""
$	INQUIRE P1 "Enter the name of the device on which to build the kit"
$	GOTO STA0$P1_INQUIRE
$ STA0$P1_READY:
$	TRG_DEVICE = P1
$	!
$	! If the target device is the system console make sure it is online.
$	! If the target device does not exist, and if the device name contains
$	! the string "CSA", then configure the console into the system.
$	!
$	IF F$GETDVI(TRG_DEVICE,"EXISTS") THEN GOTO STA0$DEV_EXISTS
$	IF F$LOCATE("CSA",TRG_DEVICE) .EQ. F$LENGTH(TRG_DEVICE) THEN GOTO STA0$ERR_TARGET_DEVICE
$	RUN SYS$SYSTEM:SYSGEN
		CONNECT CONSOLE
$	IF .NOT. F$GETDVI(TRG_DEVICE,"EXISTS") THEN GOTO STA0$ERR_TARGET_DEVICE
$	SAY "SYSGEN CONNECT CONSOLE was used to make the console device available."
$	CONSOLE_CONNECTED = TRUE
$ STA0$DEV_EXISTS:
$	TRG_DEVICE = F$GETDVI(TRG_DEVICE,"FULLDEVNAM")
$	IF TRG_DEVICE .EQS. "" THEN GOTO STA0$ERR_TARGET_DEVICE
$	DEVICE_ORIGINALLY_MOUNTED = F$GETDVI(TRG_DEVICE,"MNT")
$	!
$	! Determine if the target device is a small console device
$	!
$	DEV_TYPE = F$GETDVI(TRG_DEVICE,"DEVTYPE")
$	IF DEV_TYPE .EQ. 26 THEN SMALL_CONSOLE = TRUE	! RX50 floppy
$	IF DEV_TYPE .EQ. 11 THEN SMALL_CONSOLE = TRUE	! RX02 floppy
$	IF DEV_TYPE .EQ. 16 THEN SMALL_CONSOLE = TRUE	! RX01 floppy (78x console)
$	IF DEV_TYPE .EQ. 14 THEN SMALL_CONSOLE = TRUE	! TU58 cartridge
$	!
$	! Define some symbols to differentiate between floppies and TU58s.  These
$	! symbols will be comment marks if false, and spaces if true.  The effect is
$	! to dynamically comment out those lines not applicable to the current device.
$	!
$	ifnotRX50 = "   "
$	ifRX01 = "! RX01"
$	ifRX02 = "! RX02"
$	ifRX50 = "! RX50"
$	ifRX0x = "! RX0x"
$	ifTU58 = "! TU58"
$	IF DEV_TYPE .EQ. 26 THEN ifRX50 = "  "
$	IF DEV_TYPE .EQ. 26 THEN ifnotRX50 = "! RX50 DISK"
$	IF DEV_TYPE .EQ. 11 THEN ifRX02 = "  "
$	IF DEV_TYPE .EQ. 16 THEN ifRX01 = "  "
$	IF DEV_TYPE .EQ. 14 THEN ifTU58 = "  "
$      'ifRX01' ifRX0x = "  "		
$      'ifRX02' ifRX0x = "  "
$	!
$	! Define some symbols to differentiate between MicroVAX and full
$	! VAX cpus.  Three conditions will make us decide that we are
$	! building a MicroVAX kit:
$	!	a) The target device type is one of the uVAX disks
$	!	b) The current CPU is a uVAX I or uVAX II
$	!	c) The logical name STABACKIT$MICROVAX is "YES"
$	!
$	IF DEV_TYPE .EQ. 26 THEN MICROVAX = TRUE	! RX50 floppy
$	IF DEV_TYPE .EQ. 25 THEN MICROVAX = TRUE	! RD51 disk
$	IF DEV_TYPE .EQ. 27 THEN MICROVAX = TRUE	! RD52 disk
$	IF DEV_TYPE .EQ. 28 THEN MICROVAX = TRUE	! RD53 disk
$	IF F$GETSYI("CPU") .EQ. 7 THEN MICROVAX = TRUE	! PR$_SID_TYPUV1
$	IF F$GETSYI("CPU") .EQ. 8 THEN MICROVAX = TRUE	! PR$_SID_TYPUV2
$	IF F$LOGICAL ("STABACKIT$MICROVAX") .EQS. "YES" THEN MICROVAX = TRUE
$	!
$	ifuvax =    "! MicroVAX cpu"
$	ifnotuvax = "  "
$	IF MICROVAX THEN ifuVAX    = "  "
$	IF MICROVAX THEN ifnotuVAX = "! Not MicroVAX cpu"
$	!
$	! If we are building to a large disk, go to that section of code
$	!
$	IF .NOT. SMALL_CONSOLE THEN GOTO STA0$LARGE_DISK_CHECK
$	!
$	! Perform checks for small devices, floppies and TU58s
$	!
$	IF F$GETDVI(TRG_DEVICE,"MNT") THEN DISMOUNT /NOUNLOAD 'TRG_DEVICE'
$	P2 = "<SYS0.SYSEXE>"				! Use SYS0 root for small consoles
$	MEDIA_NAME = "floppy diskette"
$	IF DEV_TYPE .EQ. 14 THEN MEDIA_NAME = "TU58 cartridge"
$	!
$	! The RX50 kit requires two pieces of media and must be ANALYZEd, other kits require
$	! three pieces and ANALYZE is optional.
$	!
$     'ifnotRX50' GOTO STA0$TU_RX_KIT
$	SAY ""
$ 	SAY "The standalone kit requires two ''MEDIA_NAME's.  The first"
$ 	SAY "''MEDIA_NAME' contains the standalone VMS system files, the second"
$	SAY "''MEDIA_NAME' contains the ''APPL_KIT' application image."
$ 	SAY ""
$ 	SAY "NOTE: Both ''MEDIA_NAME's will be checked for bad blocks. If any bad"
$	SAY "blocks are found, this procedure will ask for another blank ''MEDIA_NAME'"
$	SAY "and retry the operation."
$	SAY ""
$	BUILD_SYSTEM = TRUE
$	BUILD_APPL = TRUE
$	ANAL_MED = "1"
$	GOTO STA0$DO_SYSGEN
$	!
$	! TU58 and RX01 kits need three pieces, ask whether the user wants to run
$	! BAD on the media.
$	!
$ STA0$TU_RX_KIT:
$	SAY "The standalone kit requires three ''MEDIA_NAME's.  The first two"
$	SAY "''MEDIA_NAME's contain the standalone VMS system files, the third"
$	SAY "''MEDIA_NAME' contains the ''APPL_KIT' application image."
$	SAY ""
$	SAY "The system kit and the application kit can be built separately."
$!	SAY "since the same system kit can be used with any application kit." !*bad* 
$	SAY ""
$	INQUIRE TEMP "Do you want to build the system kit?       [Yes/No, default Yes]"
$	IF TEMP .EQS. "" THEN TEMP = TRUE
$	BUILD_SYSTEM = FALSE
$	IF TEMP THEN BUILD_SYSTEM = TRUE
$	INQUIRE TEMP "Do you want to build the application kit?  [Yes/No, default Yes]"
$	IF TEMP .EQS. "" THEN TEMP = TRUE
$	BUILD_APPL = FALSE
$	IF TEMP THEN BUILD_APPL = TRUE
$	SAY ""
$ STA0$BUILD_BOTH:
$	ADDED_TIME = "15 minutes"
$	IF DEV_TYPE .EQ. 14 THEN ADDED_TIME = "2 hours"
$	SAY "If desired, STABACKIT will use the ANALYZE /MEDIA utility to check the"
$	SAY "''MEDIA_NAME'(s) for defective blocks.  This can prevent failure to boot"
$	SAY "if the media is bad, but it adds about ''ADDED_TIME' to the time needed"
$	SAY "to create the full kit."
$	SAY ""
$	INQUIRE TEMP "Do you want to scan for bad blocks?  [Yes/No, default No]"
$	IF TEMP .EQS. "" THEN TEMP = FALSE
$	ANAL_MED = "0"
$	IF TEMP THEN ANAL_MED = "1"
$	SAY ""
$	GOTO STA0$DO_SYSGEN
$	!
$	! Perform checks for large disks
$	!
$ STA0$LARGE_DISK_CHECK:
$	IF TRG_DEVICE .EQS. F$GETDVI("SYS$SYSDEVICE","FULLDEVNAM") THEN GOTO STA0$ADD_TO_SYSTEM
$	CMN_SYS_DIR := ""
$	SAY ""
$	SAY "Do you want to initialize ''TRG_DEVICE'?  Note that this will erase all"
$	SAY "files currently on the volume."
$	SAY ""
$	SAY "It is not necessary to initialize the disk, and you would not want to"
$	SAY "initialize if you want to add a kit to an existing Files-11 disk.  The"
$	SAY "disk must be a valid Files-11 disk if you wish to skip initializing,"
$	SAY "however."
$	SAY ""
$	INQUIRE TEMP "Do you want to initialize [Yes/No, default No]"
$	IF TEMP .EQS. "" THEN TEMP = FALSE
$	IF .NOT. TEMP THEN GOTO STA0$NOT_INITIALIZE
$	IF F$GETDVI(TRG_DEVICE,"MNT") THEN DISMOUNT /NOUNLOAD 'TRG_DEVICE'
$	INQUIRE TEMP "Enter the new volume label [default STAND''APPL_KIT']"
$	IF TEMP .EQS. "" THEN TEMP = "STAND''APPL_KIT'"
$	INITIALIZE 'TRG_DEVICE' 'TEMP'
$ STA0$NOT_INITIALIZE:
$	SAY ""
$	IF .NOT. F$GETDVI(TRG_DEVICE,"MNT") THEN MOUNT /OVERRIDE=IDENT 'TRG_DEVICE'
$	DEVICE_MOUNTED = TRUE
$	GOTO STA0$LARGE_DISK_COMMON
$	!
$	! Put the s/a kit on the "E" directory of the current system
$	!
$ STA0$ADD_TO_SYSTEM:
$	P2 = F$EDIT(P2,"UPCASE")
$	IF P2 .NES. "" .AND. F$LOCATE("SYSE.SYSEXE",P2) .EQ. F$LENGTH(P2) THEN -
		SAY "Using <SYSE.SYSEXE> as target directory on system device."
$	P2 = "<SYSE.SYSEXE>"			! Put on "E" root of current sys
$ 	CMN_SYS_DIR := 'f$trnlnm("SYS$SYSDEVICE")'[000000]'f$trnlnm("SYS$TOPSYS")'.dir
$	IF F$SEARCH("SYS$SYSDEVICE:[''F$TRNLNM("SYS$TOPSYS")']SYSCOMMON.DIR") .NES. "" THEN -
		CMN_SYS_DIR := 'F$TRNLNM("SYS$SYSDEVICE")'['F$TRNLNM("SYS$TOPSYS")']SYSCOMMON.DIR
$	!
$	! Rejoin common code
$	!
$ STA0$LARGE_DISK_COMMON:
$	IF P2 .EQS. "" THEN P2 = "<SYS0.SYSEXE>"
$	IF F$SEARCH("''TRG_DEVICE'''P2'*.*") .EQS. "" THEN GOTO STA0$DO_SYSGEN
$	SAY ""
$	SAY "WARNING, there are already files in ''TRG_DEVICE'''P2'.  These files"
$	SAY "will be deleted before adding the kit files.  Are you sure that you want to"
$	SAY "continue and delete these files?"
$ STA0$LARGE_DISK_REALLY:
$	SAY ""
$	INQUIRE TEMP "Do you want to continue [Yes/No, no default]"
$	IF TEMP .EQS. "" THEN GOTO STA0$LARGE_DISK_REALLY
$	IF .NOT. TEMP THEN GOTO STA0$ERR_REQUEST_ABORT
$	!
$	! If SYSE root already has a SYSCOMMON.DIR then remove it.
$	!
$	IF CMN_SYS_DIR .NES. "" THEN IF F$SEARCH("''TRG_DEVICE'[SYSE]SYSCOMMON.DIR;1") .NES. "" THEN -
		SET FILE/REMOVE/LOG 'TRG_DEVICE'[SYSE]SYSCOMMON.DIR;1
$	ON WARNING THEN CONTINUE
$	DELETE /LOG 'TRG_DEVICE''P2'*.*;*
$	ON WARNING THEN GOTO STA0$CLEAN_UP
$	IF F$SEARCH("''TRG_DEVICE'''P2'*.*") .EQS. "" THEN GOTO STA0$DO_SYSGEN
$	SAY ""
$	SAY "Unable to delete all the files in ''TRG_DEVICE'''P2',"
$	SAY "please delete the remaining files yourself and restart the kit build."
$	SAY ""
$	GOTO STA0$CLEAN_UP
$ STA0$DO_SYSGEN:
$	DEFINE /NOLOG STA$TARGET 'TRG_DEVICE''P2'
$	!
$	! Build a parameter file for the standalone environment.  The
$	! parameters are chosen to allow running on the minimum 512 kb system,
$	! while also allowing enough expansion space so that CI/HSC systems
$	! will run with the same parameters.  
$	!
$	RUN SYS$SYSROOT:[SYSEXE]SYSGEN
		USE DEFAULT
		SET BALSETCNT		4
		SET BUGREBOOT		0
		SET CJFLOAD		0
		SET DUMPBUG		1
		SET FREELIM		16
		SET GBLPAGES		512
		SET GBLPAGFIL		128
		SET GBLSECTIONS		20
		SET IRPCOUNT		64
		SET IRPCOUNTV		512
		SET KFILSTCNT		2
		SET LNMPHASHTBL		1
		SET LNMSHASHTBL		1
		SET LOCKIDTBL		40
		SET LOCKIDTBL_MAX	200
		SET LRPCOUNT		10
		SET LRPCOUNTV		32
		SET MAXPROCESSCNT	12
		SET MPW_HILIM		8192
		SET MPW_LOLIMIT		0
		SET MPW_WAITLIM		8192
		SET NPAGEDYN		150000
		SET NPAGEVIR		512000
		SET PAGFILCNT		1
		SET PAGEDYN		10240
		SET PFCDEFAULT		2
		SET PHYSICALPAGES	8192
		SET POOLPAGING		0
		SET PQL_DASTLM		12
		SET PQL_DDIOLM		12
		SET PQL_DPGFLQUOTA	4096
		SET PQL_DWSDEFAULT	2048
		SET PQL_DWSEXTENT	2048
		SET PQL_DWSQUOTA	2048
		SET RESHASHTBL		10
		SET SCSNODE		"SABKUP"
		SET SCSSYSTEMID		65535
		SET SRPCOUNT		24
		SET SRPCOUNTV		512
		SET SRPSIZE		128
		SET SWPFILCNT		0
		SET SYSPAGING		0
		SET VAXCLUSTER		0
		SET VIRTUALPAGECNT	4096
		SET WSMAX		2048
		WRITE SYS$UPDATE:VAXVMSSYS.PAR
$	!
$	! If MicroVAX, then set maximum physical pages to 1MB so that this
$	! will work when there is a QVSS on the configuration.  Adjust
$	! a couple of other parms to match 1 MB
$	!
$	IF .NOT. MICROVAX THEN GOTO STA0$NO_UVAX_SYSGEN
$	RUN SYS$SYSROOT:[SYSEXE]SYSGEN
		USE SYS$UPDATE:VAXVMSSYS.PAR
		SET PHYSICALPAGES 2048
		SET SYSPAGING 1
		SET VIRTUALPAGECNT 4096
		SET WSMAX 1024
		WRITE SYS$UPDATE:VAXVMSSYS.PAR
$ STA0$NO_UVAX_SYSGEN:
$	!
$	SYS_PAR_FILE = F$SEARCH("SYS$UPDATE:VAXVMSSYS.PAR")
$	SAY "Sysgen parameters for standalone VMS have been placed in file"
$	SAY "		''SYS_PAR_FILE'"
$	IF SMALL_CONSOLE THEN GOTO STA1$BUILD_CONSOLE_VOLUME
$	GOTO STA2$BUILD_LARGE_DISK
$	!
$	! Above procedures will "return" to STA0$CLEAN_UP
$	!
$	!
$	! Do any cleanup necessary before exiting.
$	! If the target device was the system console,
$	! the original console medium must be remounted.
$	!
$ STA0$CLEAN_UP:
$	ON ERROR THEN CONTINUE
$	ON CONTROL_Y THEN CONTINUE
$	IF TRGSAVE_DEVICE .EQS. "" THEN GOTO STA0$CLEAN_UP_A
$	IF .NOT. F$GETDVI(TRGSAVE_DEVICE, "EXISTS") THEN GOTO STA0$CLEAN_UP_A
$	IF F$GETDVI(TRGSAVE_DEVICE, "MNT") .AND. DEVICE_MOUNTED_1 THEN DISMOUNT /NOUNLOAD 'TRGSAVE_DEVICE'
$ STA0$CLEAN_UP_A:
$	IF TRG_DEVICE .EQS. "" THEN GOTO STA0$FINISH_CLEAN_UP
$	IF .NOT. F$GETDVI(TRG_DEVICE, "EXISTS") THEN GOTO STA0$FINISH_CLEAN_UP
$	IF F$GETDVI(TRG_DEVICE, "MNT") .AND. DEVICE_MOUNTED .AND. (.NOT. DEVICE_ORIGINALLY_MOUNTED) THEN -
		DISMOUNT /NOUNLOAD 'TRG_DEVICE'
$	IF F$LOCATE("CSA",TRG_DEVICE) .EQ. F$LENGTH(TRG_DEVICE) THEN GOTO STA0$FINISH_CLEAN_UP
$	IF F$GETSYI("CPU") .EQ. 3 THEN GOTO STA0$730_CONSOLE
$	CONSOLE_DRIVE := CSA1
$	GOTO STA0$REMOUNT_CONSOLE
$
$ STA0$730_CONSOLE:
$	IF F$GETDVI("CSA2:","MNT") THEN GOTO STA0$FINISH_CLEAN_UP
$	CONSOLE_DRIVE := CSA2
$
$ STA0$REMOUNT_CONSOLE:
$	SAY ""
$	SAY "The console volume will be mounted /NOWRITE for protection."
$	SAY "Please replace the original console ''MEDIA_NAME'."
$	SAY ""
$	INQUIRE TEMP "Enter ""YES"" when ready"
$	IF F$LENGTH(TEMP) .EQ. 0 THEN GOTO STA0$REMOUNT_CONSOLE
$	IF F$EXTRACT(0,1,TEMP) .NES. "Y" THEN GOTO STA0$REMOUNT_CONSOLE
$	SAY ""
$	MOUNT/FOREIGN/SYSTEM/NOWRITE 'CONSOLE_DRIVE' CONSOLE
$
$ STA0$FINISH_CLEAN_UP:
$	IF F$LOGICAL("STA$SOURCE") .NES. "" THEN DEASSIGN STA$SOURCE
$	IF F$LOGICAL("STA$TARGET") .NES. "" THEN DEASSIGN STA$TARGET
$	IF F$SEARCH("SYS$UPDATE:VAXVMSSYS.PAR") .NES. "" THEN DELETE /LOG SYS$UPDATE:VAXVMSSYS.PAR;*
$	SET RMS/EXT=0
$	SET UIC 'SAVED_UIC'
$	SET PROTECTION=('SAVED_PROT') /DEFAULT
$	SET PROCESS/PRIV=('SAVED_PRIVS')
$	SAY ""
$	STA0$END_TIME   = F$CVTIME (,"ABSOLUTE")
$	SAY "Ending time   ''STA0$END_TIME'"
$	SAY "Starting time ''STA0$START_TIME'"
$	SAY ""
$	IF .NOT. KIT_DONE THEN SAY "An error or abort occurred, the kit is incomplete."
$	IF KIT_DONE THEN SAY "The kit is complete."
$	EXIT
$!+
$! Error routines
$!-
$ STA0$ERR_NO_INT:
$	SAY ""
$	SAY "Procedure must be run interactively, sorry."
$	SAY ""
$	EXIT 4	! Severe error, no message
$
$ STA0$ERR_TARGET_DEVICE:
$	SAY ""
$	SAY "Output kit device not accessible."
$	GOTO STA0$ERR_COMMON
$
$ STA0$ERR_REQUEST_ABORT:
$	SAY ""
$	SAY "Aborting kit build due to user's request."
$	GOTO STA0$ERR_COMMON
$
$ STA0$ERR_NO_SYS:
$	SAY ""
$	SAY "SYS.EXE not found in source directory ''SRC_DIRECTORY'."
$	GOTO STA0$ERR_COMMON
$
$ STA0$ERR_APPL_KIT:
$	SAY ""
$	SAY "Application kit not supported or ''SRC_DIRECTORY'STA''APPL_KIT'.EXE not found."
$	GOTO STA0$ERR_COMMON
$
$ STA0$ERR_COMMON:
$	SAY ""
$	GOTO STA0$CLEAN_UP
$!+
$! Routine to handle the condition of a media defect during an ANAL /MED operation.
$! The user is requested to insert a new piece of media, then the operation will be
$! retried.
$!-
$ STA0$BAD_MEDIUM:
$	DISMOUNT /NOUNLOAD 'TRG_DEVICE'
$	SAY ""
$	SAY "ANALYZE /MEDIA detected one or more bad blocks on the"
$	SAY "''MEDIA_NAME' in ''TRG_DEVICE'."
$ STA0$BAD_MEDIUM_A:
$	SAY ""
$	SAY "Please replace the defective ''MEDIA_NAME' in ''TRG_DEVICE' with"
$	SAY "another blank ''MEDIA_NAME'."
$	SAY ""
$	INQUIRE TEMP "Enter ""YES"" when ready"
$	IF F$LENGTH(TEMP) .EQ. 0 THEN GOTO STA0$BAD_MEDIUM_A
$	IF F$EXTRACT(0,1,TEMP) .NES. "Y" THEN GOTO STA0$BAD_MEDIUM_A
$	SAY ""
$	GOTO 'STA0$BAD_MEDIUM_RETURN'		! Return to try the analyze again

$ STA1$BUILD_CONSOLE_VOLUME:
$ !++
$ ! Build a standalone system kit for small console media
$ !
$ ! ABSTRACT:	This command subprocedure builds the standalone VMS system kit
$ !		for VAX processors which have console storage devices which
$ !		are too small to contain the kit on a single volume.  These
$ !		devices are single-density floppies (for VAX-11/78x) and TU58
$ !		cartridges (for 750 and 730).
$ !
$ !		The standalone system kit spans two volumes, named SYSTEM_1 and
$ !		SYSTEM_2.  The image SYS.EXE spans both volumes.  The first
$ !		volume contains SYSBOOT and boot images, the second contains
$ !		SYSINIT and various drivers.
$ !
$ !		The application kit is on a third volume.  After the system is
$ !		booted, it will request the third volume and activate the image
$ !		<SYSEXE>STANDALON.EXE on it.  This will be a special standalone
$ !		utility, for example standalone BACKUP or standalone BAD.
$ !
$ ! INPUTS:	(local symbols unless otherwise described)
$ !		STA$TARGET 	- logical name pointing to target device and directory
$ !		STA$SOURCE 	- logical name pointing to source directory
$ !		APPL_KIT 	- application name, e.g. "BACKUP" or "BAD"
$ !		KIT_DONE 	- symbol to set after successful completion
$ ! 		TRG_DEVICE 	- target device name, e.g. "DYA0:"
$ !		DEV_TYPE   	- device type code
$ !		BUILD_SYSTEM	- build system kit boolean
$ !		BUILD_APPL	- build application kit boolean
$ !		ANAL_MED	- analyze /media boolean
$ !--
$	!
$	! Set local warning branches
$	!
$	ON WARNING THEN GOTO STA1$CLEAN_UP
$	ON CONTROL_Y THEN GOTO STA1$CLEAN_UP
$	!
$	! If no system kit is desired, then skip to the application kit
$	!
$	IF .NOT. BUILD_SYSTEM THEN GOTO STA1$BUILD_APPL_KIT
$ STA1$MOUNT_TARGET:
$	!
$	! Initialize and mount the target device.
$	!
$	SAY ""
$	SAY "Please place the first system ''MEDIA_NAME' in drive ''TRG_DEVICE'."
$	SAY "This volume will receive the volume label SYSTEM_1."
$	SAY ""
$	INQUIRE TEMP "Enter ""YES"" when ready"
$	IF F$LENGTH(TEMP) .EQ. 0 THEN GOTO STA1$MOUNT_TARGET
$	IF F$EXTRACT(0,1,TEMP) .NES. "Y" THEN GOTO STA1$MOUNT_TARGET
$	SAY ""
$	DENS = ""
$	IF .NOT. ANAL_MED THEN GOTO STA1$NO_ANAL_1
$ STA1$ANAL_1:
$	SAY "Analyzing ''MEDIA_NAME' in ''TRG_DEVICE' for bad blocks . . ."
$	MOUNT /FOREIGN /NOMESSAGE 'TRG_DEVICE' SYSTEM_1
$	STA0$BAD_MEDIUM_RETURN = "STA1$ANAL_1"		! Set up the return address from a bad block condition
$	ON WARNING THEN GOTO STA0$BAD_MEDIUM		! On bad block/goto common routine
$	ANALYZE /MEDIA /EXERCISE /LOG 'TRG_DEVICE'
$	ON WARNING THEN GOTO STA1$CLEAN_UP
$	DISMOUNT /NOUNLOAD 'TRG_DEVICE'
$ STA1$NO_ANAL_1:
$      'ifRX02'	DENS = "/DENSITY=SINGLE"
$	INITIALIZE 'DENS' /HEADERS=28 /INDEX=BEGINNING 'TRG_DEVICE' SYSTEM_1
$	MOUNT 'TRG_DEVICE' SYSTEM_1
$	DEVICE_MOUNTED = TRUE
$	CREATE /DIRECTORY /LOG	STA$TARGET
$	!
$	! Copy the BACKUP system to the medium.  In order to conserve space, two
$	! different methods are used to copy the files.  Normal VMS images are
$	! copied with the STABACCOP program, which removes symbol table and
$	! patch text blocks.  STABACCOP creates contiguous files, except when
$	! copying the first segment of SYS.EXE (since the free space on the
$	! first volume is in at least two extents due to the placement of
$	! INDEXF.SYS).  Non-VMS load images (such as VMB and SYSBOOT) are
$	! copied with the /CONTIGUOUS and /TRUNCATE options.
$	! 
$      'ifTU58'	CopyTC	STA$SOURCE:VMB.EXE		STA$TARGET:VMB.EXE;1	! For 11/750
$		CopyTC	STA$SOURCE:SYSBOOT.EXE		STA$TARGET:SYSBOOT.EXE;1
$      'ifTU58'	CopySB	STA$SOURCE:DDDRIVER.EXE		STA$TARGET:		! Console disk drivers
$      'ifRX0x'	CopySB	STA$SOURCE:DXDRIVER.EXE		STA$TARGET:
$		CopySB	STA$SOURCE:TTDRIVER.EXE		STA$TARGET:		! Terminal class driver
$		CopySB	STA$SOURCE:SCSLOA.EXE		STA$TARGET:
$      'ifTU58'	CopySB	STA$SOURCE:SYSLOA730.EXE	STA$TARGET:		! CPU loadable code
$      'ifTU58'	CopySB	STA$SOURCE:SYSLOA750.EXE	STA$TARGET:
$      'ifRX0x'	CopySB	STA$SOURCE:SYSLOA780.EXE	STA$TARGET:
$      'ifuVAX'	CopySB	STA$SOURCE:SYSLOAUV1.EXE	STA$TARGET:
$      'ifuVAX'	CopySB	STA$SOURCE:SYSLOAWS1.EXE	STA$TARGET:
$      'ifuVAX'	CopySB	STA$SOURCE:VAXEMUL.EXE		STA$TARGET:		! String ins emulator
$		CopySB	STA$SOURCE:FPEMUL.EXE		STA$TARGET:		! Emulate G & H
$		CopyTC	SYS$UPDATE:VAXVMSSYS.PAR 	STA$TARGET:		! SYSGEN parameters
$	!
$	! Copy the first part of SYS.EXE to the volume.  We determine how much
$	! space is left on the volume, then compare against our upper and lower
$	! limits.  The lower limit is that the entire SYSPARAM parameter area must
$	! be in the first segment.  The upper limit is that the page preceding
$	! the bugcheck messages must be in the last segment.  We can have zero
$	! or more intermediate volumes, as long as the first and last volumes
$	! are within these limits.  STABACCOP could be linked against the
$	! system to automatically calculate these limits.  For now, will use values
$	! calculated by hand with significant margins.
$	!
$	SYS1_SIZE = F$GETDVI(TRG_DEVICE,"FREEBLOCKS")
$	'ifRX50' GOTO STA1$COPY_SYS_uVAX
$	!
$	! The lower limit is the address MMG$A_SYSPARAM plus the length BOO$C_SYSPARSZ.
$	! This is currently around block 30, so we will round up to 50.
$	!
$	IF SYS1_SIZE .LT. 50 THEN GOTO STA1$ERR_NO_SYS_SPACE
$	!
$	! The upper limit is the page preceding BUG$T_MESSAGES.  We calculate
$	! block 281, so round down to 275.
$	!
$	IF SYS1_SIZE .GT. 275 THEN SYS1_SIZE = 275
$	!
$	! Copy this first chunk to the volume
$	!
$	CopySB	STA$SOURCE:SYS.EXE	STA$TARGET: 1 'SYS1_SIZE'
$	!
$	! Write a boot block, only necessary for VAX-11/750 kit.
$	!
$      'ifRX0x'	GOTO STA1$NO_BOOT
$      'ifuVAX'	GOTO STA1$NO_BOOT
$	MCR WRITEBOOT
STA$TARGET:VMB.EXE
1
200
$ STA1$NO_BOOT:
$	!
$	DISMOUNT /NOUNLOAD 'TRG_DEVICE'
$	DEVICE_MOUNTED = FALSE
$ STA1$MOUNT_SECOND:
$	!
$	! Initialize and mount the second volume.
$	!
$	SAY ""
$	SAY "Please place the second system ''MEDIA_NAME' in drive ''TRG_DEVICE'."
$	SAY "This volume will receive the volume label SYSTEM_2."
$	SAY ""
$	INQUIRE TEMP "Enter ""YES"" when ready"
$	IF F$LENGTH(TEMP) .EQ. 0 THEN GOTO STA1$MOUNT_SECOND
$	IF F$EXTRACT(0,1,TEMP) .NES. "Y" THEN GOTO STA1$MOUNT_SECOND
$	SAY ""
$	DENS = ""
$	IF .NOT. ANAL_MED THEN GOTO STA1$NO_ANAL_2
$ STA1$ANAL_2:
$	SAY "Analyzing ''MEDIA_NAME' in ''TRG_DEVICE' for bad blocks . . ."
$	MOUNT /FOREIGN /NOMESSAGE 'TRG_DEVICE' SYSTEM_2
$	STA0$BAD_MEDIUM_RETURN = "STA1$ANAL_2"		! Set up the return address from a bad block condition
$	ON WARNING THEN GOTO STA0$BAD_MEDIUM		! On bad block/goto common routine
$	ANALYZE /MEDIA /EXERCISE /LOG 'TRG_DEVICE'
$	ON WARNING THEN GOTO STA1$CLEAN_UP
$	DISMOUNT /NOUNLOAD 'TRG_DEVICE'
$ STA1$NO_ANAL_2:
$      'ifRX02'	DENS = "/DENSITY=SINGLE"
$	INITIALIZE 'DENS' /HEADERS=40 /INDEX=BEGINNING 'TRG_DEVICE' SYSTEM_2
$	MOUNT 'TRG_DEVICE' SYSTEM_2
$	DEVICE_MOUNTED = TRUE
$	CREATE /DIRECTORY /LOG	STA$TARGET
$	!
$	! Build the second volume of the set.  First complete the copy of SYS.EXE
$	!
$ STA1$COPY_SYS_uVAX:
$	SYS2_START = SYS1_SIZE + 1
$	'ifRX50' SYS2_START = 1
$	CopySB	STA$SOURCE:SYS.EXE	STA$TARGET: 'SYS2_START' 9999
$	!
$	! Copy our own special SYSINIT, and a standalone configure for cluster/HSC,
$	! plus any other miscellaneous exec-type files.
$	!
$		   CopySB	STA$SOURCE:STASYSGEN.EXE	STA$TARGET:SYSINIT.EXE
$		   CopySB	STA$SOURCE:STANDCONF.EXE	STA$TARGET:
$      'ifnotuVAX' CopySB	STA$SOURCE:SCSLOA.EXE		STA$TARGET:	! Need on both volumes
$	!
$	! Copy remaining drivers, trying to filter out those which are not needed
$	!
$      'ifnotuVAX' CopySB	STA$SOURCE:DBDRIVER.EXE		STA$TARGET:	! Disk drivers
$      'ifnotuVAX' CopySB	STA$SOURCE:DDDRIVER.EXE		STA$TARGET:
$      'ifnotuVAX' CopySB	STA$SOURCE:DLDRIVER.EXE		STA$TARGET:
$      'ifnotuVAX' CopySB	STA$SOURCE:DMDRIVER.EXE		STA$TARGET:
$      'ifTU58'    CopySB	STA$SOURCE:DQDRIVER.EXE		STA$TARGET:
$      'ifnotuVAX' CopySB	STA$SOURCE:DRDRIVER.EXE		STA$TARGET:
$		   CopySB	STA$SOURCE:DUDRIVER.EXE		STA$TARGET:
$      'ifRX0x'	   CopySB	STA$SOURCE:DXDRIVER.EXE		STA$TARGET:
$      'ifnotuVAX' CopySB	STA$SOURCE:DYDRIVER.EXE		STA$TARGET:
$      'ifnotuVAX' CopySB	STA$SOURCE:LCDRIVER.EXE		STA$TARGET:	! Line printer drivers
$      'ifnotuVAX' CopySB	STA$SOURCE:LPDRIVER.EXE		STA$TARGET:
$      'ifnotuVAX' CopySB	STA$SOURCE:PADRIVER.EXE		STA$TARGET:	! Port drivers
$      		   CopySB	STA$SOURCE:PUDRIVER.EXE		STA$TARGET:
$      'ifnotuVAX' CopySB	STA$SOURCE:TFDRIVER.EXE		STA$TARGET:	! Magtape drivers
$      'ifnotuVAX' CopySB	STA$SOURCE:TMDRIVER.EXE		STA$TARGET:
$      'ifnotuVAX' CopySB	STA$SOURCE:TSDRIVER.EXE		STA$TARGET:
$      'ifnotuVAX' CopySB	STA$SOURCE:TUDRIVER.EXE		STA$TARGET:
$	!
$      'ifnotRX50' DISMOUNT /NOUNLOAD 'TRG_DEVICE'
$      'ifRX50'    DEVICE_MOUNTED_1 = DEVICE_MOUNTED
$      		   DEVICE_MOUNTED = FALSE
$      'ifRX50'    TRGSAVE_DEVICE = TRG_DEVICE
$      'ifRX50'    TRG_DEVICE = ""
$	!
$	! Do we need to do the application volume?
$	!
$ STA1$BUILD_APPL_KIT:
$	IF .NOT. BUILD_APPL THEN GOTO STA1$NO_BUILD_APPL
$ STA1$MOUNT_APPL_VOL:
$	!
$	! If an RX50, then get the name of a second RX50 drive
$	!
$      'ifnotRX50' GOTO STA1$INSERT_APPL_VOL
$	SAY ""
$	SAY "The application will be built on a second disk."
$	SAY ""
$	SAY "(The first disk must remain mounted in the first drive)."
$	SAY ""
$ STA1$ENTER_SECOND_DRIVE:
$	INQUIRE TEMP "Enter the name of the second floppy disk drive"
$	SAY ""
$	IF .NOT. F$GETDVI(TEMP,"EXISTS") THEN GOTO STA1$ENTER_SECOND_DRIVE
$	TRG_DEVICE = F$GETDVI(TEMP,"FULLDEVNAM")
$	IF TRG_DEVICE .EQS. "" THEN GOTO STA1$ENTER_SECOND_DRIVE
$	IF F$GETDVI(TRG_DEVICE,"DEVTYPE") .NE. 26 THEN GOTO STA1$ENTER_SECOND_DRIVE
$	IF TRG_DEVICE .EQS. TRGSAVE_DEVICE THEN GOTO STA1$ENTER_SECOND_DRIVE
$	!
$	! Initialize and mount the application volume.
$	!
$ STA1$INSERT_APPL_VOL:
$	SAY ""
$       SAY "Please place the application ''MEDIA_NAME' in drive ''TRG_DEVICE'."
$       SAY "This volume will receive the volume label ''APPL_KIT'."
$ STA1$INSERT_ASK:
$       SAY ""
$	INQUIRE TEMP "Enter ""YES"" when ready"
$	IF F$LENGTH(TEMP) .EQ. 0 THEN GOTO STA1$INSERT_ASK
$	IF F$EXTRACT(0,1,TEMP) .NES. "Y" THEN GOTO STA1$INSERT_ASK
$	SAY ""
$	IF .NOT. ANAL_MED THEN GOTO STA1$NO_ANAL_3
$ STA1$ANAL_3:
$	SAY "Analyzing ''MEDIA_NAME' in ''TRG_DEVICE' for bad blocks . . ."
$	MOUNT /FOREIGN /NOMESSAGE 'TRG_DEVICE' 'APPL_KIT'
$	STA0$BAD_MEDIUM_RETURN = "STA1$ANAL_3"		! Set up the return address from a bad block condition
$	ON WARNING THEN GOTO STA0$BAD_MEDIUM		! On bad block/goto common routine
$	ANALYZE /MEDIA /EXERCISE /LOG 'TRG_DEVICE'
$	ON WARNING THEN GOTO STA1$CLEAN_UP
$	DISMOUNT /NOUNLOAD 'TRG_DEVICE'
$ STA1$NO_ANAL_3:
$      'ifRX50' GOTO STA1$BACKUP_VOL
$      'ifRX02'	DENS = "/DENSITY=SINGLE"
$	INITIALIZE 'DENS' /HEADERS=20 /INDEX=BEGINNING 'TRG_DEVICE' 'APPL_KIT'
$	MOUNT 'TRG_DEVICE' 'APPL_KIT'
$	DEVICE_MOUNTED = TRUE
$	CREATE /DIRECTORY /LOG	STA$TARGET
$	!
$	! Copy the application image
$	!
$	CopySB	STA$SOURCE:STA'APPL_KIT'.EXE	STA$TARGET:STANDALON.EXE
$	!
$ STA1$NO_BUILD_APPL:
$	KIT_DONE = TRUE
$ STA1$CLEAN_UP:
$	!
$	GOTO STA0$CLEAN_UP
$!+
$! (for uVAX RX50 standalone build only)
$!
$! Do a physical backup of the target disk to a second floppy disk and
$! delete all files except sys.exe before copying the standalone application.
$! (This is to insure the same physical location of sys.exe on the 2nd disk.)
$!-
$ STA1$BACKUP_VOL:
$	MOUNT /FOREIGN /NOMESSAGE 'TRG_DEVICE'
$	BACKUP /PHYSICAL 'TRGSAVE_DEVICE' 'TRG_DEVICE'
$	DISMOUNT /NOUNLOAD 'TRG_DEVICE'
$	MOUNT /OVERRIDE=IDENTIFICATION /NOMESSAGE 'TRG_DEVICE'
$	DEVICE_MOUNTED = TRUE
$	SET VOLUME /LABEL='APPL_KIT' 'TRG_DEVICE'
$	DISMOUNT /NOUNLOAD 'TRG_DEVICE'
$	MOUNT 'TRG_DEVICE' 'APPL_KIT'
$	DEFINE /NOLOG STA$TARGET 'TRG_DEVICE''P2'
$!
$! Delete all unneccessary files from the newly created floppy (everything
$! except SYS.EXE) before copying the standalone application.
$!
$	DELETE /NOLOG STA$TARGET:*.*;* /EXCLUDE=SYS.EXE
$!
$! Now copy the standalone application package
$!
$	CopyT	STA$SOURCE:STA'APPL_KIT'.EXE 	STA$TARGET:STANDALON.EXE
$	GOTO STA1$NO_BUILD_APPL 
$!+
$! Error routines
$!-
$ STA1$ERR_TARGET_DEVICE:
$	SAY ""
$	SAY "Output kit device not accessible."
$	GOTO STA1$ERR_COMMON
$
$ STA1$ERR_NO_INT:
$	SAY ""
$	SAY "Procedure must be run interactively, sorry."
$	GOTO STA1$ERR_COMMON
$
$ STA1$ERR_NO_SYS_SPACE:
$	SAY ""
$	SAY "Not enough space for SYS.EXE on first volume.  * INTERNAL ERROR *"
$
$ STA1$ERR_COMMON:
$	SAY ""
$	GOTO STA1$CLEAN_UP

$ STA2$BUILD_LARGE_DISK:
$ !++
$ ! Build a standalone system kit for disk media
$ !
$ ! ABSTRACT:	This command subprocedure builds the standalone VMS system
$ !		and application kit for large disks.
$ !
$ !		The bootable system can be placed in either the SYS0 root of a
$ !		freshly initialized disk or added to an existing disk as the
$ !		SYSE root.
$ !
$ ! INPUTS:	(local symbols unless otherwise described)
$ ! 		STA$TARGET	- logical name pointing to target device and directory
$ !		STA$SOURCE	- logical name pointing to source directory
$ !		APPL_KIT 	- application name, e.g. "BACKUP" or "BAD"
$ !		KIT_DONE 	- symbol to set after successful completion
$ !--
$	!
$	! Set up a local error path
$	!
$	ON WARNING THEN GOTO STA2$CLEAN_UP
$	ON CONTROL_Y THEN GOTO STA2$CLEAN_UP
$	!
$       'ifuVAX' GOTO STA2$UVAX_COPY
$	!
$	! Copy the system files to the target.
$	!
$	CREATE /DIRECTORY /LOG	STA$TARGET
$		   CopySB	STA$SOURCE:STASYSGEN.EXE	STA$TARGET:SYSINIT.EXE
$		   CopyTC	SYS$UPDATE:VAXVMSSYS.PAR 	STA$TARGET:	! SYSGEN parameters
$	IF CMN_SYS_DIR .EQS. "" THEN GOTO STA2$COPY_SYS_FILES
$	SET FILE/LOG/ENTER='TRG_DEVICE'[SYSE]SYSCOMMON.DIR;1 'CMN_SYS_DIR'
$	GOTO STA2$COPY_APPL_FILE
$	!
$ STA2$COPY_SYS_FILES:
$		   CopySB	STA$SOURCE:SYS.EXE		STA$TARGET:
$      		   CopyTC	STA$SOURCE:SYSBOOT.EXE		STA$TARGET:SYSBOOT.EXE;
$                  CopyTC	STA$SOURCE:VMB.EXE		STA$TARGET:VMB.EXE;
$		   CopySB	STA$SOURCE:SCSLOA.EXE		STA$TARGET:
$                  CopySB	STA$SOURCE:SYSLOA730.EXE	STA$TARGET:	! CPU-specific loadable code
$                  CopySB	STA$SOURCE:SYSLOA750.EXE	STA$TARGET:
$                  CopySB	STA$SOURCE:SYSLOA780.EXE	STA$TARGET:
$                  CopySB	STA$SOURCE:SYSLOA790.EXE	STA$TARGET:
$		   CopySB	STA$SOURCE:FPEMUL.EXE		STA$TARGET:	! For CPU's without G & H
$		   CopySB	STA$SOURCE:STANDCONF.EXE	STA$TARGET:	! Configure HSC and MSCP disks
$      		   CopySB	STA$SOURCE:CVDRIVER.EXE		STA$TARGET:	! Disk drivers
$                  CopySB	STA$SOURCE:DBDRIVER.EXE		STA$TARGET:
$                  CopySB	STA$SOURCE:DDDRIVER.EXE		STA$TARGET:
$                  CopySB	STA$SOURCE:DLDRIVER.EXE		STA$TARGET:
$                  CopySB	STA$SOURCE:DMDRIVER.EXE		STA$TARGET:
$                  CopySB	STA$SOURCE:DQDRIVER.EXE		STA$TARGET:
$                  CopySB	STA$SOURCE:DRDRIVER.EXE		STA$TARGET:
$		   CopySB	STA$SOURCE:DUDRIVER.EXE		STA$TARGET:
$                  CopySB	STA$SOURCE:DXDRIVER.EXE		STA$TARGET:
$                  CopySB	STA$SOURCE:DYDRIVER.EXE		STA$TARGET:
$                  CopySB	STA$SOURCE:LCDRIVER.EXE		STA$TARGET:	! Line printer drivers
$                  CopySB	STA$SOURCE:LPDRIVER.EXE		STA$TARGET:
$                  CopySB	STA$SOURCE:PADRIVER.EXE		STA$TARGET:	! Port drivers
$      		   CopySB	STA$SOURCE:PUDRIVER.EXE		STA$TARGET:
$                  CopySB	STA$SOURCE:TFDRIVER.EXE		STA$TARGET:	! Magtape drivers
$                  CopySB	STA$SOURCE:TMDRIVER.EXE		STA$TARGET:
$                  CopySB	STA$SOURCE:TSDRIVER.EXE		STA$TARGET:
$                  CopySB	STA$SOURCE:TUDRIVER.EXE		STA$TARGET:
$                  CopySB	STA$SOURCE:TTDRIVER.EXE		STA$TARGET:	! Terminal class driver
$	!
$	! Write a boot block, only necessary for VAX-11/750 kit.
$	!
$	MCR WRITEBOOT
STA$TARGET:VMB.EXE
1
200
$	!
$	! Finish up
$	!
$	GOTO STA2$COPY_APPL_FILE
$	!
$	! Copy the uVAX system files to the target.
$	!
$ STA2$UVAX_COPY:
$	CREATE /DIRECTORY /LOG	STA$TARGET
$		   CopySB	STA$SOURCE:STASYSGEN.EXE	STA$TARGET:SYSINIT.EXE
$		   CopyTC	STA$SOURCE:SYSBOOT.EXE		STA$TARGET:SYSBOOT.EXE;	!uVAX I needs this in root
$		   CopyTC	SYS$UPDATE:VAXVMSSYS.PAR 	STA$TARGET:	! SYSGEN parameters
$	IF CMN_SYS_DIR .EQS. "" THEN GOTO STA2$UVAX_COPY_SYS_FILES
$	SET FILE/LOG/ENTER='TRG_DEVICE'[SYSE]SYSCOMMON.DIR;1 'CMN_SYS_DIR'
$	GOTO STA2$COPY_APPL_FILE
$	!
$ STA2$UVAX_COPY_SYS_FILES:
$		   CopySB	STA$SOURCE:SYS.EXE		STA$TARGET:
$                  CopyTC	STA$SOURCE:VMB.EXE		STA$TARGET:VMB.EXE;
$		   CopySB	STA$SOURCE:SCSLOA.EXE		STA$TARGET:
$                  CopySB	STA$SOURCE:SYSLOAUV1.EXE	STA$TARGET:	! CPU-specific loadable code
$	           CopySB	STA$SOURCE:SYSLOAWS1.EXE	STA$TARGET:	! For VAXstation 200
$		   CopySB	STA$SOURCE:FPEMUL.EXE		STA$TARGET:	! For CPU's without G & H
$	           CopySB	STA$SOURCE:VAXEMUL.EXE		STA$TARGET:	! For MicroVAX cpus
$		   CopySB	STA$SOURCE:STANDCONF.EXE	STA$TARGET:	! Configure HSC and MSCP disks
$		   CopySB	STA$SOURCE:DUDRIVER.EXE		STA$TARGET:
$      		   CopySB	STA$SOURCE:PUDRIVER.EXE		STA$TARGET:
$                  CopySB	STA$SOURCE:TTDRIVER.EXE		STA$TARGET:	! Terminal class driver
$	!
$	! Copy the application image
$	!
$ STA2$COPY_APPL_FILE:
$		   CopySB	STA$SOURCE:STA'APPL_KIT'.EXE	STA$TARGET:STANDALON.EXE
$	!
$	KIT_DONE = TRUE
$	!
$ STA2$CLEAN_UP:
$	GOTO STA0$CLEAN_UP
