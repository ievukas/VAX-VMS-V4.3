$ !
$ ! VMS040 - Apply VAX/VMS upgrade distribution kit for Release 4.
$ ! 
$ ! This procedure requires SETPRV privilege.
$ !
$ ! This command file upgrades the system disk to release 4
$ !
$ ! This procedure is invoked by VMSINSTAL, with the following conditions:
$ !
$ !	- All privileges except BYPASS enabled
$ !	- UIC set to [1,4]
$ !	- VMI$KWD logical name defined as SYS$SYSROOT:[SYSUPD.product],
$ !			where 'product' is VMS040
$ !	- VMI$DEVICE is a local symbol defined in VMSINSTAL which contains
$ !		the kit device.
$ !	- VMI$PLACE is a local symbol in VMSINSTAL which defines the
$ !		location (node, dev, dir of the kit)
$ !
$	SAY = "WRITE SYS$OUTPUT"
$	TYPE SYS$INPUT

			VAX/VMS V4.0 Upgrade Procedure

This procedure will convert a VAX/VMS V3.4, V3.5, V3.6, or V3.7 system disk into
a VAX/VMS V4.0 system disk.  To accomplish this, the system must  be rebooted
several times.  The upgrade will continue automatically after each reboot via a
specially created system startup command procedure. 



			       IMPORTANT

The distribution kit may not be placed in any directory except [000000].  If you
have moved the required savesets to a different directory please exit from the
upgrade and move them to a [000000] directory. 

The pagefile, swapfile, dump file, and user authorization file will all be
purged to one version.  All accounting and operator logs will be deleted.
Everything in [SYSERR] will also be deleted. All *.JNL files in the system
directory tree will be deleted. 

If you wish to preserve any of these files, please exit from the upgrade and
move them to a user directory. 

RESTAR.CMD must match the memory interleaving of your system configuration.
If this is incorrect and there is a power failure, the upgrade will not
recover correctly.  If you are unsure of the setting of RESTAR.CMD, contact
your Field Service representative.

AUTOGEN may attempt to re-size your primary pagefile or swapfile. You can
control this via entries in the parameter file SYS$SYSTEM:MODPARAMS.DAT. See
the Guide to VAX/VMS System Management and Daily Operations for detailed
information. 

$	IF F$SEARCH("SYS$SYSTEM:NETNODE.DAT") .EQS. "" THEN GOTO 5
$	TYPE SYS$INPUT
This system has DECnet/VAX installed.  The DECnet/VAX license is contained on a
separate binary distribution kit. Ensure that you have the version 4.0 kit
before continuing the upgrade. 

$5:	IF (F$GETSYI("CPU") .NE. 1) .OR. -
	   ((F$GETSYI("SID") .AND. %X800000) .EQ. 0) THEN GOTO 6	! Not 785
$	TYPE SYS$INPUT
This is a VAX-11/785 system.  The DEFBOO.CMD file on the console floppy must be
already set up to automatically boot from the system device.  If it is not, do
not continue the upgrade until you have set it up to do so. 

$6:	INQUIRE YN "Do you want to continue? (Y/N)"
$	IF (YN .EQS. "") THEN GOTO 6
$	IF .NOT. YN THEN EXIT VMI$_FAILURE
$	SAY ""
$	SAY "		Upgrade Phase 1		''F$TIME()'"
$	DEFDIR = "SYSUPD.VMS040"
$	SET MESSAGE /FACILITY/SEVERITY/TEXT/IDENTIFICATION
$	SET CONTROL=T
$	SET ON
$	ON ERROR THEN GOTO 7000
$	ON CONTROL_Y THEN GOTO 7000
$	PREV_PRIV = F$SETPRV("BYPASS")
$	SET PROTECTION=(S:RWED,G:RWED,O:RWED,W:RE)/DEFAULT
$	UPGRADE$SHUTDOWN = 1			!Set to 0 to not shutdown at
$						! end of phase 1
$	COPY == "COPY"
$	MOUNT == "MOUNT"
$	EXCHANGE == "EXCHANGE /NOMESSAGE"
$	ANAL_BAD == "$BAD"
$	FLX == "$FLX"
$	KIT = "''VMI$DEVICE'"
$	IF KIT .EQS. "" THEN GOTO 8210
$	IF F$FILE("SYS$SYSTEM:PAGEFILE.SYS","ALQ") .LT. 4600 THEN GOTO 8220
$	KIT = F$GETDVI(KIT,"DEVNAM")
$	IF (F$EXT(0,1,KIT) .EQS. "_") THEN KIT = F$EXT(1,F$LENGTH(KIT),KIT)
$	IF (F$EXT(0,1,KIT) .EQS. "_") THEN KIT = F$EXT(1,F$LENGTH(KIT),KIT)
$	T1 = F$PARSE(VMI$PLACE,"[0,0]",,"DIRECTORY")
$	IF (T1 .NES. "[0,0]") .AND. (T1 .NES. "[000000]") THEN GOTO 8160
$	IF (F$PARSE(VMI$PLACE,,,"NODE") - "::") .NES. "" THEN GOTO 8180
$	KIT_RC25 = 0
$	KIT_RL02 = 0
$	KIT_DOTLR = 0		! Turn into tailored system
$	KIT_ISTLR = 0		! System already tailored
$	KIT_CROOT = 0		! True if already has syscommon
$	KIT_DOCROOT = 0		! True to create syscommon disk
$	LIB_DISK = ""		! No library disk
$	T1 = F$GETDVI("SYS$SYSDEVICE","DEVTYPE")
$	IF (T1 .EQ. 10) .OR. (T1 .EQ. 18) THEN GOTO 8120 !RL02, RB02 illegal
$	T1 = F$GETDVI(KIT,"DEVTYPE")
$	T2 = F$GETDVI(KIT,"DEVCLASS")
$	IF (T2 .EQ. 1) .AND. ((T1 .EQ. 10) .OR. (T1 .EQ. 18)) THEN KIT_RL02 = 1
$	IF (T2 .EQ. 1) .AND. ((T1 .EQ. 23) .OR. (T1 .EQ. 24)) THEN KIT_RC25 = 1
$GET_SYSVER:
$	SYSVER = F$GETSYI("VERSION")
$	SYSVER :='SYSVER'
$	V4_SYS = 0
$	IF F$LOCATE("3.",SYSVER) .EQ. F$LENGTH(SYSVER) THEN V4_SYS = 1
$	IF .NOT. V4_SYS THEN GOTO 40
$	IF (F$EXT(1,3,SYSVER) .GES. "2M9") THEN GOTO 30
$	SAY "Unrecognized system version ''sysver'.  Upgrade aborted."
$	GOTO 7000
$30:
$	IF .NOT. V4_SYS THEN GOTO 40
$	IF F$GETSYI("ALLOCLASS") .NE. 0 THEN GOTO 8230
$	IF F$EDIT("''F$GETSYI("SCSNODE")'","TRIM") .EQS. "" THEN GOTO 35
$	TYPE SYS$INPUT

This SYSGEN parameter SCSNODE is non-blank. It must be reset to all blanks
before the upgrade can procede.  Please reset the SYSGEN parameter SCSNODE to
all blanks, reboot, and procede with the upgrade.  Also, remember that the
SYSGEN parameter VAXCLUSTER must be set to 0.  Upgrade aborted. 
$	GOTO 7000
$35:
$	IF .NOT. F$GETSYI("CLUSTER_MEMBER") THEN GOTO 40
$	TYPE SYS$INPUT

This node is currently part of a VAXcluster.  The upgrade cannot procede within
a VAXcluster environment.  Please remove this node from the cluster and reboot
with the SYSGEN parameter VAXCLUSTER equal to 0.  Upgrade aborted. 
$	GOTO 7000
$40:
$	IF V4_SYS THEN ANAL_BAD == "ANALYZE /MEDIA /EXERCISE /LOG"
$	VALID_SAVESETS = "REQ,LIB,OPT,ALL"
$	VALID_UPGRADES = "IGNORE,KEEP,UNDER,OVER"
$	TARGET = F$LOGICAL("SYS$SYSDEVICE") - "__"
$	IF V4_SYS THEN OLD_ROOT_DOT = F$TRNLNM("SYS$TOPSYS") + "."
$	IF V4_SYS THEN GOTO NO_TOPSYS
$	T1 = F$LOGICAL("SYS$SYSROOT")
$	L = F$LOCATE("[",T1)
$	M = F$LOCATE(".",T1)
$	OLD_ROOT_DOT = ""
$	IF M .EQ. F$LENGTH(T1) THEN GOTO NO_TOPSYS
$	N = M - L
$	L = L + 1
$	OLD_ROOT_DOT = F$EXT(L,N,T1)
$NO_TOPSYS:
$	IF OLD_ROOT_DOT .EQS. "" THEN GOTO 8200
$	OLD_ROOT = OLD_ROOT_DOT - "."
$	CPUTYPE = F$GETSYI("CPU")
$	IF (CPUTYPE .EQ. 0) .OR. (CPUTYPE .GT. 3) THEN GOTO 8000
$	IF F$SEARCH("''TARGET'[''OLD_ROOT']SYSCOMMON.DIR;1") .NES. "" -
		THEN GOTO REDO_CROOT
$	IF F$GETDVI("PA","EXISTS") THEN GOTO ASK_CROOT
$	T1 = F$GETDVI("SYS$SYSDEVICE","MAXBLOCK")
$	IF "''TLR$MAXBLOCK'" .EQS. "" THEN TLR$MAXBLOCK = 70000
$	IF T1 .GE. TLR$MAXBLOCK THEN GOTO CHECK_NETDB
$	TYPE SYS$INPUT

Tailoring lets you  remove VAX/VMS files you do not need in your normal
operations. While tailoring your system disk, you need a disk drive for 
the system disk and a disk drive for the library disk. The library disk 
only has to be mounted for tailoring operations, for installing VAX/VMS 
optional products or for doing maintenance updates. The library disk must 
be 20,000 blocks (RL02) or larger. 

If you intend to  install optional  products from distribution media that 
conflicts with  your use of the library disk, do not select the tailoring 
option. For example, with a dual-RK07  system you cannot install optional 
products from an RK07 distribution disk.

The upgrade procedure will not restore the OPTIONAL saveset if the 
library disk is less than 25,000 blocks.

$	INQUIRE YN "Do you want this upgrade to produce a tailored system [N]"
$	IF YN .EQS. "" THEN YN = "N"
$	IF .NOT. YN THEN GOTO CHECK_NETDB
$GET_LIB_DISK:
$	INQUIRE LIB_DISK "In which drive will you mount the library disk"
$	IF LIB_DISK .EQS. "" THEN GOTO GET_LIB_DISK
$	IF .NOT. F$GETDVI(LIB_DISK,"EXISTS") THEN GOTO 8140
$	LIB_DISK = F$GETDVI(LIB_DISK,"DEVNAM") - "_" - "_"
$	IF (F$GETDVI(LIB_DISK,"MAXBLOCK") .LT. 20000) THEN GOTO 8140
$	KIT_DOTLR = 1
$	IF V4_SYS THEN KIT_ISTLR = F$GETSYI("TAILORED")
$	IF .NOT. KIT_ISTLR THEN GOTO CHECK_NETDB
$!Already-tailored system...ft2 at least.
$flist = "SYS$SYSTEM:EXCHANGE.EXE\AUTHORIZE\DISKQUOTA\ANALYZBAD\RTB\WRITEBOOT\BOOTBLOCK\"
$rlf = ""
$errors = 0
$open /write f1 sys$update:v4upgrade.tlr
$ckf_loop:
$f = f$elem(0,"\",flist)
$if f .eqs. "" then goto ckf_done
$f1 = f
$tf = f$search(f$parse(f1,,rlf,,"SYNTAX_ONLY"))
$if tf .eqs. "" then goto ckf_fnf
$ckf_next:
$if tf .eqs. "" then goto ckf_next80
$if rlf .eqs. "" then rlf = f1
$if f$parse(f1,,,"TYPE","SYNTAX_ONLY") .eqs. "." then goto ckf_next20
$rlf = rlf - f$parse(rlf,,,"TYPE","SYNTAX_ONLY")
$rlf = rlf + f$parse(f1,,,"TYPE","SYNTAX_ONLY")
$ckf_next20:
$i = f$loc(":",f1)
$if i .eq. f$len(f1) then goto ckf_next40
$j = f$loc(":",rlf)
$rlf = rlf - f$ext(0,j,rlf)
$rlf = f$ext(0,i,f1) + rlf
$ckf_next40:
$ckf_next80:
$flist = flist - "''f'\"
$goto ckf_loop
$ckf_fnf:
$ write f1 "[sysexe]",f$parse(f1,,,"name","syntax_only"),".EXE"
$errors = errors + 1
$goto ckf_next
$ckf_done:
$ close f1
$ if errors .eq. 0 then delete sys$update:v4upgrade.tlr;*
$ IF ERRORS .eq. 0 THEN GOTO CHECK_NETDB
$	TYPE SYS$INPUT

VMS files required for the upgrade are not on your system disk.

We will tailor them from your current library disk.
$ if kit .nes. lib_disk then goto ckf_mntlibdisk
$ dismount /nounload 'kit'
$ckf_getlibdisk:
$ say ""
$ say "Put your current library disk in ''lib_disk'."
$ say ""
$ inquire yn "Are you ready to continue (Y/N): "
$ if .not. yn then goto ckf_getlibdisk
$ckf_mntlibdisk:
$ if .not. f$getdvi(lib_disk,"MNT") then goto ckf_mntlib10
$ if f$trnlnm("lib$sysdevice") .nes. "" then goto ckf_mntlib20
$ dismount 'lib_disk' /nounload
$ckf_mntlib10:
$ @sys$update:vmstailor mount 'lib_disk'
$ckf_mntlib20:
$ @sys$update:vmstailor copy /log v4upgrade
$ @sys$update:vmstailor dismount 'lib_disk'
$ if kit .nes. lib_disk then goto ckf_remountkit
$ say ""
$ say "Place the first volume of your distribution kit back in ''kit'."
$ckf_getkitback:
$ say ""
$ inquire yn "Are you ready to continue (Y/N) "
$ if .not. yn then goto ckf_getkitback
$ckf_remountkit:
$ mount /over=id 'kit'
$ goto check_netdb
$REDO_CROOT:
$	TYPE SYS$INPUT

Your system disk is already configured as a cluster system disk.
It will be upgraded to a cluster system disk.

$	KIT_DOCROOT = 1
$	KIT_CROOT = 1
$	GOTO CHECK_NETDB
$ASK_CROOT:
$	TYPE SYS$INPUT

If this node is part of a VAXcluster, you may want to set up
your system disk to run multiple cluster nodes from a single disk.

$	INQUIRE YN "Do you want to know more about cluster system disks [N]"
$	IF YN .EQS. "" THEN YN = "N"
$	IF .NOT. YN THEN GOTO ASK_CR2
$	TYPE SYS$INPUT:

If you have an HSC-based system disk, it can be made to run
multiple systems with up to 14 nodes sharing all files except
PAGEFILE.SYS, SWAPFILE.SYS, SYSDUMP.DMP and VAXVMSSYS.PAR.

$	IF V4_SYS THEN GOTO FT2_CR
$	TYPE SYS$INPUT:

All files in the current system directory tree will be moved into
[V4COMMON...].  See the VAXCluster documentation for details on
converting stand-alone systems into VAXCluster systems.

$	GOTO ASK_CR2
$FT2_CR:
$	TYPE SYS$INPUT:

If your system is already set up with multiple systems on the system
disk, the upgrade will convert only the directory tree on which this
system is running.  You must execute SYS$UPDATE:MAKEROOT.COM to create
the directory trees for other nodes on this disk.

$ASK_CR2:
$	INQUIRE YN "Do you want to generate a cluster common system disk [N]"
$	IF YN .EQS. "" THEN YN = "N"
$	IF .NOT. YN THEN GOTO CHECK_NETDB
$	KIT_DOCROOT = 1
$CHECK_NETDB:
$	NET$AREA_NUM == 0
$	IF F$SEARCH("SYS$SYSTEM:NETNODE.DAT") .EQS. "" THEN GOTO CHANGE_PWDS
$	TYPE SYS$INPUT:

By default your DECnet node will be set up in area 1.  You may specify a
different area but you will be able to communicate with other nodes in your
area only if they too convert to the new area number.

$	NET$AREA_NUM == 1
$	INQUIRE YN "Specify the area number for your DECnet node [1]"
$	SET NOON
$	IF YN .NES. "" THEN NET$AREA_NUM == F$INTEGER(YN)
$	IF (NET$AREA_NUM .GE. 1) .AND. (NET$AREA_NUM .LE. 63) THEN GOTO CHANGE_PWDS
$	SAY ""
$	SAY "% ''NET$AREA_NUM' is an invalid area number."
$	GOTO CHECK_NETDB
$CHANGE_PWDS:
$	SET NOON
$	SET DEFAULT SYS$SYSTEM:
$	UAF = "$AUTHORIZE"
$	SAY ""
$	SAY "Now we will ask you for new passwords for the following accounts:"
$	SAY "	SYSTEM, SYSTEST, FIELD"
$	SAY ""
$	SET TERM /NOECHO
$	T1 = "SYSTEM"
$	T2 = "MANAGER"
$	T3 = "CPWD_10"
$	GOTO CPWD_100
$CPWD_10:
$	T1 = "SYSTEST"
$	T2 = "UETP"
$	T3 = "CPWD_20"
$	GOTO CPWD_100
$CPWD_20:
$	T1 = "FIELD"
$	T2 = "SERVICE"
$	T3 = "CPWD_30"
$	GOTO CPWD_100
$CPWD_30:
$	GOTO CPWD_DONE
$CPWD_100:
$	SAY ""
$	INQUIRE /NOPUNC T4 "Enter new password for account ''T1': "
$	T4:='T4'
$	IF (T4 .NES. T2) .AND. (T4 .NES. T1) .AND. -
			(F$LENGTH(T4) .GE. 6) THEN GOTO CPWD_120
$	SAY "''T4' is an invalid password for the ''T1' account."
$	SAY "The password for ''T1' must be at least 6 characters,"
$	SAY "and ''T2' and ''T1' are illegal passwords."
$	GOTO CPWD_100
$CPWD_120:
$	INQUIRE /NOPUNC T5 "Re-enter the password for account ''T1' for verification: "
$	SAY ""
$	T5:='T5'
$	IF T5 .EQS. T4 THEN GOTO CPWD_140
$	SAY "Password verification error."
$	GOTO CPWD_100
$CPWD_140:
$	UAF MODIFY 'T1' /PASSWORD='T4'
$	GOTO 'T3'
$CPWD_DONE:
$	SET TERM /ECHO
$	SAY ""
$	SAY "Turning off disk quotas on system disk."
$	SET NOON
$	RUN SYS$SYSTEM:DISKQUOTA
USE SYS$SYSDEVICE
DISABLE
$50:
$	CLROOT = OLD_ROOT_DOT
$	IF KIT_CROOT THEN CLROOT = "V4COMMON."
$	NEW_ROOT = "SYSF"
$	SET ON
$	SET DEFAULT 'TARGET'['CLROOT''DEFDIR']
$	SET NOON
$	STOP JOB_CONTROL
$	STOP OPCOM
$	STOP ERRFMT
$	SET ON
$	GOTO COPY_CONS
$ !
$ ! Restart the console media copy here.
$ !
$RESTART_CONSOLE:
$	ON ERROR THEN CONTINUE
$	IF F$GETDVI(FLX_DEVICE,"MNT") THEN DISMOUNT 'FLX_DEVICE'
$	SAY ""
$	SAY "ERROR.  Restarting the part of the upgrade procedure"
$	SAY "that copies the old console ''MEDIUM'."
$	SAY ""
$ !
$ ! Copy the console files to system disk
$ !
$COPY_CONS:
$	BOOT_CS = "YES"
$	ON ERROR THEN GOTO RESTART_CONSOLE
$	CREATE/DIR/PROT=(S:RWED,O:RWE,G:RE,W:RE) -
		'TARGET'['CLROOT''DEFDIR'.CONSOLE]
$	SET DEFAULT 'TARGET'['CLROOT''DEFDIR'.CONSOLE]
$	FLX_DEVICE = "CS1:"
$	IF V4_SYS THEN FLX_DEVICE = "CSA1:"
$	IF F$SEARCH("*.*") .NES. "" THEN DELETE *.*;*
$	FILES11_FLX_SWITCH = "/RS/IM"
$	RT_FLX_SWITCH = "/RT"
$	GOTO SET_CONS_'CPUTYPE'
$SET_CONS_1:			!780
$	MEDIUM = "floppy"
$	BOOTFILE = "CONSOL.SYS"
$	GOTO END_SET_PARMS
$
$SET_CONS_2:			!750
$	MEDIUM = "TU58"
$	BOOTFILE = "BOOT58.EXE"
$SET_CONS_2A:
$	INQUIRE BOOT_CS "Do you want to boot from the TU58? (Y/N)"
$	IF BOOT_CS .EQS. "" THEN GOTO SET_CONS_2A
$	IF .NOT. BOOT_CS THEN GOTO START_CLEAN
$	GOTO END_SET_PARMS
$
$SET_CONS_3:			!730
$	MEDIUM = "TU58"
$	FLX_DEVICE = "CS2:"
$	IF V4_SYS THEN FLX_DEVICE = "CSA2:"
$	RT_FLX_SWITCH = "/RT/IM"
$	BOOTFILE = "BOOT.EXE"
$
$END_SET_PARMS:
$	SYSGEN = "$SYSGEN"
$	SYSGEN CONNECT CONSOLE
$	IF F$GETDVI(FLX_DEVICE,"MNT") THEN DISMOUNT 'FLX_DEVICE'
$	ON ERROR THEN GOTO RESTART_CONSOLE
$MOUNT_CONSOLE:
$	SAY ""
$ 	SAY "Now a new site-specific ''MEDIUM' must be created to allow"
$	SAY "reboot of a kernel VAX/VMS V4.0 system."
$	SAY ""
$	SAY "Your old console ''MEDIUM' should be in drive ''FLX_DEVICE'."
$	SAY "Your old console will not be modified during the upgrade."
$AGAIN1:
$	INQUIRE YN -
	"Is the old console ''MEDIUM, ''FLX_DEVICE', ready to be mounted? (Y/N)"
$	IF .NOT. YN THEN GOTO AGAIN1
$	MOUNT/FOREIGN 'FLX_DEVICE'
$	SAY ""
$	SAY "The old console ''MEDIUM' will be copied to a scratch"
$	SAY "directory now.  Afterwards you will be asked to insert"
$	YN = "5"
$	IF MEDIUM .EQS. "TU58" THEN YN = "10-15"
$	SAY "a scratch ''MEDIUM'.  This copy takes about ''YN' minutes."
$	IF .NOT. V4_SYS THEN FLX 'FILES11_FLX_SWITCH'='FLX_DEVICE'*.*'RT_FLX_SWITCH'
$	IF V4_SYS THEN EXCHANGE COPY 'FLX_DEVICE'*.*/TRANSFER=BLOCK *
$	SET DEFAULT 'TARGET'['CLROOT''DEFDIR']
$	IF (CPUTYPE .NE. 1) THEN GOTO ENOUGH_ROOM
$	IF F$SEARCH("PCS.PAT") .NES. "" THEN DELETE PCS.PAT;*
$ENOUGH_ROOM:
$	SET DEFAULT 'TARGET'['CLROOT''DEFDIR'.CONSOLE]
$	DEFBOO_NAM = "DEFBOO.CMD"
$AGAIN4:
$	SAY ""
$	SAY "If you have not done so previously, you must now set DEFBOO.CMD"
$	SAY "to boot the system from your current system disk."
$	INQUIRE YN "Do you need to set up your DEFBOO.CMD? (Y/N)"
$	IF (YN .EQS. "") .OR. (YN .EQS. "?") THEN GOTO AGAIN4
$	IF .NOT. YN THEN GOTO DEFBOO_SET
$SETDEFBOO_0:
$	SAY ""
$	INQUIRE NAME "Enter the name of the default boot command file"
$	IF F$SEARCH (NAME) .NES. "" THEN GOTO SETDEFBOO_1
$	SAY ""
$	SAY "Unable to find boot command file ''NAME'."
$	SAY ""
$SDFBOO_0:
$	INQUIRE YN "Do you wish to select another file? (Y/N)"
$	IF (YN .EQS. "") .OR. (YN .EQS. "?") THEN GOTO SDFBOO_0
$	IF YN THEN GOTO SETDEFBOO_0
$	SAY "ERROR setting the default boot command file."
$	GOTO RESTART_CONSOLE
$SETDEFBOO_1:
$	DEFBOO_NAM = NAME
$DEFBOO_SET:
$	SET DEFAULT 'TARGET'['CLROOT''DEFDIR']
$	IF .NOT. V4_SYS THEN FLX /RS='FLX_DEVICE''DEFBOO_NAM'/RT
$	IF V4_SYS THEN EXCHANGE COPY 'FLX_DEVICE''DEFBOO_NAM' *
$	RENAME 'DEFBOO_NAM' DEFBOO.SIT
$	DISMOUNT 'FLX_DEVICE'
$	SET DEFAULT 'TARGET'['CLROOT''DEFDIR'.CONSOLE]
$ !
$ ! Modify DEFBOO to boot from SYSF
$ !
$	SAY "Modifying DEFBOO.CMD to boot V4 from [SYSF.SYSEXE]."
$	OPEN/WRITE DATA2 DEFBOO.CMD
$	OPEN/WRITE DATA3 UPGGEN.CMD	!Also write copy that stops in SYSBOOT.
$	OPEN/READ DATAF$ 'TARGET'['CLROOT''DEFDIR']DEFBOO.SIT
$	R5_CHANGED = 0
$GET_DEFBOO_REC:
$	READ/END_OF_FILE=DEFBOO_EOF DATAF$ RECORD
$	RECORD := 'RECORD
$	L = F$LOCATE("D/G 5",RECORD)
$	IF (L .EQ. F$LEN(RECORD)) THEN L = F$LOCATE("D/G/L 5",RECORD)
$	IF (CPUTYPE .EQ. 1) THEN L = F$LOCATE("R5",RECORD)
$	IF (L .EQ. F$LENGTH(RECORD)) THEN GOTO WRITE_DEFBOO_REC
$	IF .NOT. R5_CHANGED THEN GOTO FOUND_R5
$	SAY "Edit of DEFBOO.CMD found two R5 lines."
$	GOTO 7000
$FOUND_R5:
$	IF (CPUTYPE .NE. 1) THEN -
		RECORD = "D/G 5 F0000000        ! Boot from SYSF"
$	IF (CPUTYPE .NE. 1) THEN GOTO FLAG_R5_CHANGED
$	L = F$LOCATE("8",RECORD)
$	K = F$LENGTH(RECORD)
$	IF (L .EQ. K) THEN RECORD = "DEPOSIT R5 F0004000    ! UPGRADE - Boot from SYSF"
$	IF (L .NE. K) THEN RECORD = "DEPOSIT R5 F0000800    ! UPGRADE - Boot MP from SYSF"
$FLAG_R5_CHANGED:
$	R5_CHANGED = 1
$WRITE_DEFBOO_REC:
$530:
$	WRITE DATA2 RECORD
$	IF F$LOCATE("DEPOSIT R5 F000",RECORD) .NE. F$LENGTH(RECORD) THEN -
	RECORD = F$EXTRACT(0,18,RECORD) + "1	! UPGRADE - Interactive boot from SYSF"
$	IF F$LOCATE("D/G 5",RECORD) .NE. F$LENGTH(RECORD) THEN -
	RECORD = "D/G 5 F0000001        ! UPGRADE - Interactive Boot from SYSF"
$	WRITE DATA3 RECORD
$	GOTO GET_DEFBOO_REC
$DEFBOO_EOF:
$	IF R5_CHANGED THEN GOTO DEFBOO_EDIT_DONE
$	SAY "Edit of DEFBOO.CMD failed to find R5."
$	GOTO 7000
$DEFBOO_EDIT_DONE:
$	CLOSE DATAF$
$	CLOSE DATA2
$	CLOSE DATA3
$	PURGE DEFBOO.CMD
$	GOTO CHECK_NEW_CONSOLE
$RESTART_CONSOLE_2:
$	ON ERROR THEN CONTINUE
$	DISMOUNT 'FLX_DEVICE'
$	SAY ""
$	SAY "Error initializing the console ''MEDIUM'."
$	SAY "If the console ''MEDIUM' had bad blocks, please replace it"
$	SAY "with a different ''MEDIUM'."
$	SAY ""
$	SAY "Restarting the part of the upgrade procedure that initializes"
$	SAY "the scratch console ''MEDIUM'."
$CHECK_NEW_CONSOLE:
$	ON ERROR THEN GOTO RESTART_CONSOLE_2
$	SAY ""
$	SAY "Put a scratch console ''MEDIUM' into drive ''FLX_DEVICE'."
$	SAY "This will be initialized now to verify that the media is"
$	SAY "usable and written just before the system is rebooted, in"
$	SAY "order to boot from the V4.0 kernel."
$	SAY ""
$	IF MEDIUM .NES. "TU58" THEN GOTO CHECK_NEW10
$	SAY "Make sure that you have pushed the RECORD switch on the"
$	SAY "scratch TU58 cartridge to allow writing on the cartridge."
$	SAY ""
$check_new10:
$	SAY "DO NOT put your normal console media back in the console drive"
$	SAY "during the remainder of the upgrade procedure."
$	SAY ""
$AGAIN3:
$	INQUIRE YN -
"Is a scratch console ''MEDIUM, now in ''FLX_DEVICE'? (Y/N)"
$	IF .NOT. YN THEN GOTO AGAIN3
$	ON ERROR THEN GOTO RESTART_CONSOLE_2
$	MOUNT/FOREIGN 'FLX_DEVICE'
$	INQUIRE YN "Do you want to run BAD on the new console ''MEDIUM' [Y]"
$	IF YN .EQS. "" THEN YN = "Y"
$	IF .NOT. YN THEN GOTO AGAIN3A
$	SAY ""
$	SAY "Running BAD on new console ''MEDIUM'."
$	ANAL_BAD 'FLX_DEVICE'
$	IF .NOT. $STATUS THEN GOTO RESTART_CONSOLE_2
$AGAIN3A:
$	SAY ""
$	SAY "Initializing the scratch console ''MEDIUM."
$	SAY ""
$	IF .NOT. V4_SYS THEN FLX 'FLX_DEVICE'/RT/ZE
$	IF V4_SYS THEN EXCHANGE INIT 'FLX_DEVICE'/VOLUME_FORMAT=RT11/SEG=2
$	IF .NOT. $STATUS THEN GOTO RESTART_CONSOLE_2
$START_CLEAN:
$	GOTO INFORM_CLEAN_'CPUTYPE'
$INFORM_CLEAN_1:		!780
$	TYPE SYS$INPUT
The upgrade procedure will continue automatically for the next two hours.
It reboots automatically with no operator intervention needed from here on. 
$	GOTO INFORM_CLEAN_X
$INFORM_CLEAN_2:		!750
$	SAY "The upgrade procedure will continue for the next 20 minutes."
$	SAY "After that it will reboot."
$	IF BOOT_CS THEN SAY "Enter B to the BOOT58> prompt to reboot."
$	IF .NOT. BOOT_CS THEN SAY "Enter CTRL/P when the shutdown is complete"
$	IF .NOT. BOOT_CS THEN SAY "and then enter B/F0000000 ddcu to reboot."
$	SAY ""
$	SAY "The upgrade procedure will continue automatically"
$	SAY "after the reboot."
$	GOTO INFORM_CLEAN_X
$INFORM_CLEAN_3:		!730
$	SAY "The upgrade procedure will continue automatically for the next"
$	SAY "2 hours. It reboots automatically."
$	IF .NOT. KIT_RL02 THEN GOTO INFORM_CLEAN_X
$	SAY "You will be needed to remove the first RL02 cartridge"
$	SAY "and insert the library cartridge in approximately 45 minutes."
$INFORM_CLEAN_X:
$	IF .NOT. KIT_DOTLR THEN GOTO INFORM_CLEAN_Y
$	TYPE SYS$INPUT

Because you are building a tailored system, you will be needed
during phase 2 of the upgrade to ready the library disk.
$INFORM_CLEAN_Y:
$	SAY ""
$	@['CLROOT''DEFDIR']DIRCLENUP 'TARGET' 'V4_SYS'
$	SET ON
$ !
$ ! Delete known files and associated global sections.
$ !
$	SAY ""
$	SAY "Removing installed images."
$ IF V4_SYS THEN GOTO DEL_KNOWN_V4
$ INSTALL = "$INSTALL"
$ DEFINE /USER SYS$OUTPUT INSLIST.TMP
$ INSTALL /LIST
$ open /read /error=8040 DATA$ inslist.tmp
$ open /write /error=8060 DATA1$ inscmd.tmp
$del_known_20:
$	read /end=del_known_eof data$ record
$	record:='record'
$	record = f$extract(0,f$loc(" ",record),record)
$	t1 = f$length(record)
$	if f$locate("VMSRTL.EXE",record) .ne. t1 then goto del_known_20
$	if f$locate("DISMNTSHR.EXE",record) .ne. t1 then goto del_known_20
$	if f$locate("MOUNTSHR.EXE",record) .ne. t1 then goto del_known_20
$	write /error=8080 data1$ record,"/DELETE"
$	goto del_known_20
$
$DEL_KNOWN_V4:
$	INSTALL = "$INSTALL /COMMAND"
$	INSTALL PURGE
$	IF .NOT. F$FILE("SYS$SHARE:DISMNTSHR.EXE","KNOWN") -
		THEN INSTALL ADD SYS$SHARE:DISMNTSHR/OPEN/SHARE/PROTECT/NOPURGE
$	IF .NOT. F$FILE("SYS$SHARE:MOUNTSHR.EXE","KNOWN") -
		THEN INSTALL ADD SYS$SHARE:MOUNTSHR/OPEN/SHARE/PROTECT/HEADER
$	IF .NOT. F$FILE("SYS$SHARE:SECURESHR.EXE","KNOWN") -
		THEN INSTALL ADD SYS$SHARE:SECURESHR/OPEN/SHARE/PROTECT/HEAD
$DEL_KV4_20:
$	GOTO DEL_KNOWN_END
$del_known_eof:
$ close data$
$ close data1$
$ SET NOON
$ define /user sys$input inscmd.tmp
$ install
$ delete inslist.tmp.*
$ delete inscmd.tmp.*
$DEL_KNOWN_END:
$	IF F$SEARCH("SYS$SYSTEM:UPGRADE.KIT") .NES. "" THEN -
		DELETE SYS$SYSTEM:UPGRADE.KIT;*
$	IF F$SEARCH("SYS$UPDATE:VMIMARKER.OLD") .NES. "" THEN -
		DELETE SYS$UPDATE:VMIMARKER.OLD;*
$	IF F$SEARCH("SYS$UPDATE:VMIMARKER.DAT") .NES. "" THEN -
		RENAME SYS$UPDATE:VMIMARKER.DAT;* *.OLD;*
$	ON ERROR THEN GOTO 7000
$
$ !
$ ! Now clean off all the VAX/VMS V3 files, so that the maximum free space
$ ! is available on the system disk.  All files required to reboot and execute
$ ! this procedure will not be deleted, so that the upgrade can recover from
$ ! any error and the procedure restarted.
$ !
$ ! This is the main cleanup loop that is executed for each record
$ ! in the data file.
$ !
$	SAY ""
$	SAY "Now removing all VAX/VMS ''SYSVER' files not needed"
$	SAY "to complete the upgrade."
$	SAY ""
$	SAY "Purging old accounting data files, operator logs, and [SYSERR]."
$	PURGE 'TARGET'['OLD_ROOT_DOT'SYSMGR]ACCOUNTNG.DAT,OPERATOR.LOG
$	PURGE 'TARGET'['OLD_ROOT_DOT'SYSERR]*.*
$	CREATE/DIRECTORY/OWNER=[1,4]/PROT=(S:RWE,O:RWE,G:RE,W:RE) -
		 'TARGET'['NEW_ROOT']
$
$	FILENAME :='TARGET'['CLROOT''DEFDIR']VMSKITBLD.V3N
$	SAY ""
$	SAY "Deleting [''CLROOT'..]*.JNL;*"
$	DELETE 'TARGET'['CLROOT'..]*.JNL;*
$	SAY ""
$	SAY "Now creating the new directory tree in [''NEW_ROOT'...] and deleting"
$	SAY "all files in [''CLROOT'..] not needed to boot the system."
$	OPEN/READ/ERROR=8020 DATAF$ 'FILENAME'
$	CONDIT = 1+8+64+256	! Use UETP, HELP, DECnet, and Coding Examples
$	PREV_NAME = ""
$	LEGAL_UPGRADES = "IGNORE,KEEP,OVER,UNDER,"
$ !
$ ! Now read the data file.  Create directories in the new directory
$ ! tree, and delete all files in the old tree that are not marked
$ ! with UPG=.
$ !
$RECORD_LOOP:
$	READ/END_OF_FILE=3000 DATAF$ RECORD
$	IF F$EXTRACT(0,1,RECORD) .EQS. "$" THEN GOTO RECORD_LOOP
$	IF F$EXTRACT(0,1,RECORD) .EQS. "!" THEN GOTO RECORD_LOOP
$ !
$ ! Get the upgrade field from the current record.
$ !
$GET_UPGRADE:
$	L = F$LOCATE("UPG=",RECORD) + 4
$	UPGRADE = F$EXTRACT(L,132,RECORD)
$	L = F$LOCATE(",",UPGRADE)
$	UPGRADE = F$EXTRACT(0,L,UPGRADE)
$	IF UPGRADE .EQS. "" THEN GOTO GET_SAVESET
$	IF F$LOCATE(UPGRADE,VALID_UPGRADES) .NE. F$LENGTH(VALID_UPGRADES) -
	THEN GOTO RECORD_LOOP
$	SAY "Bad upgrade field specified in record *''RECORD'*"
$	GOTO 7000
$ !
$ ! Get the saveset field from the current record.
$ !
$GET_SAVESET:
$	L = F$LOCATE("SET=",RECORD) + 4
$	SAVESET = F$EXTRACT(L,132,RECORD)
$	L = F$LOCATE(",",SAVESET)
$	SAVESET = F$EXTRACT(0,L,SAVESET)
$	IF SAVESET .EQS. "" THEN SAVESET = "LIB"
$	IF F$LOCATE(SAVESET,VALID_SAVESETS) .NE. F$LENGTH(VALID_SAVESETS) -
	THEN GOTO GET_CONDITIONAL
$	SAY "Bad saveset field specified in record *''RECORD'*"
$	GOTO 7000
$ !
$ ! Get the CONDITIONAL field from the current record.
$ !
$GET_CONDITIONAL:
$	CONDITIONAL = ""
$	L = F$LOCATE("COND=",RECORD) + 5
$	IF L .GE. F$LENGTH(RECORD) THEN GOTO GET_NAME
$	CONDITIONAL = F$EXTRACT(L,132,RECORD)
$	IF CONDITIONAL .EQS. "" THEN GOTO GET_NAME
$	L = F$LOCATE(",",CONDITIONAL)
$	CONDITIONAL = F$EXTRACT(0,L,CONDITIONAL)
$	IF (CONDITIONAL .AND. CONDIT) .EQ. 0 THEN GOTO RECORD_LOOP
$ !
$ ! Get the name from the current record.  (The name is always the first field
$ ! in the record, and doesn't have a keyword associated with it.)
$ !
$GET_NAME:
$	L = F$LOCATE(",",RECORD)
$	NAME = F$EXTRACT(0,L,RECORD)
$ !
$ ! Get the operation specified by the current record.
$ !
$GET_OPERATION:
$	L = F$LOCATE("OP=",RECORD) + 3
$	OPERATION = F$EXTRACT(L,132,RECORD)
$	IF OPERATION .EQS. "" THEN GOTO NORMAL
$	L = 'F$LOCATE(",",OPERATION)
$	OPERATION = F$EXTRACT(0,L,OPERATION)
$	IF (OPERATION .EQS. "BUILD") .OR. (OPERATION .EQS. "COPY") .OR. -
	   (OPERATION .EQS. "CONTIG") THEN GOTO NORMAL
$	IF (OPERATION .EQS. "CREATE") THEN GOTO CREATE
$	IF (OPERATION .EQS. "SET") THEN GOTO SET
$	GOTO RECORD_LOOP
$
$NORMAL:
$	IF (F$LOC("_",NAME) .NE. F$LEN(NAME)) .AND. .NOT. V4_SYS -
		THEN GOTO RECORD_LOOP		! No _'s on V3.n
$	IF (F$LOC(".",NAME) .GT. 9) .AND. .NOT. V4_SYS -
		THEN GOTO RECORD_LOOP		!No _'s or long names on V3.n
$	IF F$SEARCH(NAME) .NES. "" THEN DELETE 'TARGET''NAME';*
$	GOTO RECORD_LOOP
$	
$SET:
$	SET DEFAULT ['CLROOT''NAME']
$	SETDIR = NAME
$	IF NAME .NES. PREV_NAME THEN -
		SAY "Now working on files in [''CLROOT'''NAME']."
$	PREV_NAME = NAME
$	GOTO RECORD_LOOP
$
$CREATE:
$	CREATE/DIRECTORY/OWNER=[1,4]/PROT=(S:RWE,O:RWE,G:RE,W:RE) -
		'TARGET'['NEW_ROOT'.'NAME']
$	L = F$LOCATE("SYNONYM=",RECORD) + 8
$	SYNONYM = F$EXTRACT(L,132,RECORD)
$	L = F$LOCATE(",",SYNONYM)
$	SYNONYM = F$EXTRACT(0,L,SYNONYM)
$	IF SYNONYM .EQS. "" THEN GOTO RECORD_LOOP
$	SET FILE /ENTER='TARGET'['NEW_ROOT']'SYNONYM'.DIR;1 -
			'TARGET'['NEW_ROOT']'NAME'.DIR;1
$	GOTO RECORD_LOOP
$
$3000:
$	SET DEFAULT 'TARGET'['CLROOT''DEFDIR']
$	CLOSE DATAF$
$	SAY ""
$ 	SAY "Now copying over the V4.0 required saveset."
$	BACKUP/VERIFY/REPLACE -
		'KIT'[0,0]REQUIRED/SAVE_SET -
		'TARGET'['NEW_ROOT'...] -
		/SELECT=[SYS0...] -
		/EXCLUDE=([SYS0.SYSEXE]PAGEFILE.SYS,SYSDUMP.DMP, -
			SWAPFILE.SYS,NOTICE.TXT,-
			SYSUAF.DAT,STARTUP.INS,[SYSEXE]*.*;*)
$	SAY ""
$	SAY "Purging pagefile, swapfile, dump file, and authorization"
$	SAY "files back to one version."
$	SAY "(Please ignore possible file not found messages.)"
$	SET NOON
$	OLD_SYSEXE = "''TARGET'[''OLD_ROOT_DOT'SYSEXE]"
$	NEW_SYSEXE = "''TARGET'[''NEW_ROOT'.SYSEXE]"
$	OLD_SYSUAF = OLD_SYSEXE
$	IF KIT_CROOT THEN OLD_SYSUAF = TARGET + "[V4COMMON.SYSEXE]"
$	IF F$SEARCH("''OLD_SYSEXE'PAGEFILE.SYS") .NES. "" -
		THEN PURGE 'OLD_SYSEXE'PAGEFILE.SYS
$	IF F$SEARCH("''OLD_SYSEXE'SYSDUMP.DMP") .NES. "" -
		THEN PURGE 'OLD_SYSEXE'SYSDUMP.DMP
$	IF F$SEARCH("''OLD_SYSEXE'SWAPFILE.SYS") .NES. "" -
		THEN PURGE 'OLD_SYSEXE'SWAPFILE.SYS
$	IF F$SEARCH("''NEW_SYSEXE'PAGEFILE.SYS;*") .NES. "" -
		THEN SET FILE /REMOVE 'NEW_SYSEXE'PAGEFILE.SYS;*
$	IF F$SEARCH("''NEW_SYSEXE'SYSDUMP.DMP;*") .NES. "" -
		THEN SET FILE /REMOVE 'NEW_SYSEXE'SYSDUMP.DMP;*
$	IF F$SEARCH("''NEW_SYSEXE'SWAPFILE.SYS;*") .NES. "" -
		THEN SET FILE /REMOVE 'NEW_SYSEXE'SWAPFILE.SYS;*
$	IF F$SEARCH("''OLD_SYSUAF'SYSUAF.DAT") .NES. "" -
		THEN PURGE 'OLD_SYSUAF'SYSUAF.DAT
$	IF F$SEARCH("''NEW_SYSEXE'SYSUAF.DAT;*") .NES. "" -
		THEN SET FILE /REMOVE 'NEW_SYSEXE'SYSUAF.DAT;*
$	IF F$SEARCH("''OLD_SYSUAF'NETUAF.DAT") .NES. "" -
		THEN PURGE 'OLD_SYSUAF'NETUAF.DAT
$	IF F$SEARCH("''NEW_SYSEXE'NETUAF.DAT;*") .NES. "" -
		THEN SET FILE /REMOVE 'NEW_SYSEXE'NETUAF.DAT;*
$	IF .NOT. V4_SYS THEN GOTO NORIGHTSLIST
$	IF F$SEARCH("''OLD_SYSUAF'RIGHTSLIST.DAT") .NES. "" -
		THEN PURGE 'OLD_SYSUAF'RIGHTSLIST.DAT
$	IF F$SEARCH("''NEW_SYSEXE'RIGHTSLIST.DAT;*") .NES. "" -
		THEN SET FILE /REMOVE 'NEW_SYSEXE'RIGHTSLIST.DAT;*
$NORIGHTSLIST:
$	SAY ""
$	SAY "Entering old page, swap, dump,and authorization files in new directory tree."
$	IF F$SEARCH("''OLD_SYSEXE'PAGEFILE.SYS") .NES. "" -
		THEN SET FILE /ENTER='NEW_SYSEXE'PAGEFILE.SYS -
		'OLD_SYSEXE'PAGEFILE.SYS
$	IF F$SEARCH("''OLD_SYSEXE'SYSDUMP.DMP") .NES. "" -
		THEN SET FILE /ENTER='NEW_SYSEXE'SYSDUMP.DMP -
		'OLD_SYSEXE'SYSDUMP.DMP
$	IF F$SEARCH("''OLD_SYSEXE'SWAPFILE.SYS;*") .NES. "" -
		THEN SET FILE /ENTER='NEW_SYSEXE'SWAPFILE.SYS -
		'OLD_SYSEXE'SWAPFILE.SYS
$	IF F$SEARCH("''OLD_SYSUAF'SYSUAF.DAT;*") .NES. "" -
		THEN SET FILE /ENTER='NEW_SYSEXE'SYSUAF.DAT -
		'OLD_SYSUAF'SYSUAF.DAT
$	IF F$SEARCH("''OLD_SYSUAF'NETUAF.DAT;*") .NES. "" -
		THEN SET FILE /ENTER='NEW_SYSEXE'NETUAF.DAT -
		'OLD_SYSUAF'NETUAF.DAT
$	IF .NOT. V4_SYS THEN GOTO NORIGHTS_10
$	IF F$SEARCH("''OLD_SYSUAF'RIGHTSLIST.DAT;*") .NES. "" -
		THEN SET FILE /ENTER='NEW_SYSEXE'RIGHTSLIST.DAT -
		'OLD_SYSUAF'RIGHTSLIST.DAT
$NORIGHTS_10:
$ !
$ ! Create data files that will be used to create a new site-specific
$ ! sysgen parameter file.  NOTE: Uses AUTOGEN from the VMS040 saveset,
$ ! not the one for the running system.  The files will be written to
$ ! the current SYS$SYSTEM and renamed to the new system directory in a
$ ! later phase of the upgrade.
$ !
$	SET DEFAULT 'NEW_SYSEXE'
$	SAY ""
$	SAY "Invoke V4 AUTOGEN to save current SYSGEN parameters."
$	SAY ""
$	TEMP = "V3UPGRADE"
$	IF V4_SYS THEN TEMP = "V4UPGRADE"
$	@'TARGET'['CLROOT''DEFDIR']AUTOGEN SAVPARAMS SAVPARAMS 'TEMP'
$ !
$ ! Set up the default startup command file for the next phase
$ ! of the upgrade procedure, after reboot.
$ !
$	SAY ""
$	SAY "Setting the startup command file for the next phase of the upgrade."
$	IF F$SEARCH("''OLD_SYSEXE'STARTUP.INS") .NES. "" -
		THEN DELETE 'OLD_SYSEXE'STARTUP.INS;*
$	IF KIT_CROOT .AND. -
	   (F$SEARCH("''TARGET'[''CLROOT'SYSEXE]STARTUP.INS") .NES. "") -
		THEN DELETE 'TARGET'['CLROOT'SYSEXE]STARTUP.INS;*
$	IF F$SEARCH("''OLD_SYSEXE'STARTUP.UP*") .NES. "" -
		THEN DELETE 'OLD_SYSEXE'STARTUP.UP*;*
$	IF KIT_CROOT .AND. -
	   (F$SEARCH("''TARGET'[''CLROOT'SYSEXE]STARTUP.UP*") .NES. "") -
		THEN DELETE 'TARGET'['CLROOT'SYSEXE]STARTUP.UP*;*
$	COPY 'TARGET'['CLROOT''DEFDIR']STARTUP.UP* 'NEW_SYSEXE'
$	COPY 'NEW_SYSEXE'STARTUP.UP2 'NEW_SYSEXE'STARTUP.INS
$
$	IF .NOT. BOOT_CS THEN GOTO DISK_BOOT_BLOCK
$	SET DEFAULT ['CLROOT''DEFDIR'.CONSOLE]
$	GOTO 490
$RESTART_CONS_WRT:
$	ON ERROR THEN CONTINUE
$	IF F$GETDVI(FLX_DEVICE,"MNT") THEN DISMOUNT 'FLX_DEVICE'
$	SAY ""
$	SAY "Error initializing the console ''MEDIUM'."
$	SAY "If the console ''MEDIUM' was unwritable, please replace it"
$	SAY "with a different ''MEDIUM'."
$	SAY ""
$	SAY "Restarting the part of the upgrade procedure that writes"
$	SAY "a new console ''MEDIUM'."
$	SAY ""
$AGAIN7:
$	INQUIRE READY -
"Is a scratch console ''MEDIUM, now in ''FLX_DEVICE'? (Y/N)"
$	IF .NOT. READY THEN GOTO AGAIN7
$	ON ERROR THEN GOTO RESTART_CONS_WRT
$	MOUNT/FOREIGN 'FLX_DEVICE'
$	SAY ""
$	SAY "Running BAD on new console ''MEDIUM'."
$	ANAL_BAD 'FLX_DEVICE'
$	IF .NOT. $STATUS THEN GOTO RESTART_CONS_WRT
$	SAY ""
$	SAY "Initializing the scratch console ''MEDIUM."
$	IF .NOT. V4_SYS THEN FLX 'FLX_DEVICE'/RT/ZE
$	IF V4_SYS THEN EXCHANGE INIT 'FLX_DEVICE'/VOLUME_FORMAT=RT11/SEG=2
$	IF .NOT. $STATUS THEN GOTO RESTART_CONS_WRT
$490:
$	ON ERROR THEN GOTO RESTART_CONS_WRT
$	SAY ""
$	SAY "Copying console files to new console ''MEDIUM'."
$	COPY 'TARGET'['NEW_ROOT'.SYSEXE]VMB.EXE *
$	GOTO MAKE_NEW_CONS_'CPUTYPE'
$MAKE_NEW_CONS_2:			!750
$	COPY 'TARGET'['CLROOT''DEFDIR']BOOT58.EXE *
$	GOTO MAKE_NEW_CONS_X
$MAKE_NEW_CONS_1:			!780
$MAKE_NEW_CONS_3:			!730
$MAKE_NEW_CONS_X:
$	PURGE *.*
$	IF .NOT. V4_SYS THEN -
		FLX 'FLX_DEVICE''RT_FLX_SWITCH'=*.*'FILES11_FLX_SWITCH'
$	IF V4_SYS THEN EXCHANGE COPY *.*/TRANSFER=BLOCK 'FLX_DEVICE'
$	IF .NOT. V4_SYS THEN FLX 'FLX_DEVICE'/RT=DEFBOO.CMD/RS
$	IF .NOT. V4_SYS THEN FLX 'FLX_DEVICE'/RT=UPGGEN.CMD/RS
$	IF V4_SYS THEN EXCHANGE COPY DEFBOO.CMD,UPGGEN.CMD 'FLX_DEVICE'
$	IF .NOT. $STATUS THEN GOTO RESTART_CONS_WRT
$
$WRITEBOOT:
$	SAY ""
$	SAY "Writing a boot block on the console media."
$	GOTO WRITEBOOT_'CPUTYPE'
$WRITEBOOT_1:
$WRITEBOOT_3:
$	!
$	! Use RTB utility to write a bootblock on 780 and 730 media.
$	!
$	ON ERROR THEN CONTINUE
$	DEFINE/USER RTB$INPUT 'BOOTFILE'
$	DEFINE/USER RTB$OUTPUT 'FLX_DEVICE'
$	RUN SYS$SYSTEM:RTB
$	GOTO 3099
$
$WRITEBOOT_2:
$	ASSIGN/USER 'FLX_DEVICE''BOOTFILE' BOOT 
$	RUN SYS$SYSTEM:WRITEBOOT
BOOT
1
C000
$ !
$ ! Clean up from writing console media.
$ !
$3099:
$	DELETE 'TARGET'['CLROOT''DEFDIR'.CONSOLE]*.*;*
$	IF F$GETDVI(FLX_DEVICE,"MNT") THEN DISMOUNT 'FLX_DEVICE'
$ !
$ ! Write boot block onto disk so that it can be booted on an 11/750,
$ ! even if it is being upgraded on another type of cpu.
$ !
$DISK_BOOT_BLOCK:
$	ASSIGN/USER 'TARGET'['NEW_ROOT'.SYSEXE]VMB.EXE BOOT 
$	RUN SYS$SYSTEM:WRITEBOOT
BOOT
1
200
$	ON ERROR THEN GOTO 7000
$	DELETE 'TARGET'['CLROOT''DEFDIR']CONSOLE.DIR;1
$PASS_SCS:
$	RUN SYS$SYSTEM:SYSGEN
USE CURRENT
WRITE SYS$UPDATE:ZZZTEMP.PAR
EXIT
$	DEFINE CHGSCS$V3_PARFILE SYS$UPDATE:ZZZTEMP.PAR
$	DEFINE CHGSCS$V4_PARFILE 'NEW_SYSEXE'VAXVMSSYS.PAR
$	RUN 'TARGET'['CLROOT''DEFDIR']CHGSYSPAR
$	DELETE SYS$UPDATE:ZZZTEMP.PAR;
$	SAY ""
$	SAY "System shutting down to boot a kernel V4.0 system."
$	SAY "(Please ignore any error messages during the SHUTDOWN procedure)"
$	SAY ""
$	IF BOOT_CS THEN -
	SAY "Leave the newly created site-specific console ''MEDIUM'"
$	IF BOOT_CS THEN -
	SAY "in the console drive for the remainder of the upgrade procedure."
$	SAY ""
$	SAY "The upgrade procedure will continue automatically after the"
$	SAY "reboot.  If for any reason you should have to restart"
$ 	SAY "the upgrade procedure by rebooting by hand, from now on"
$	SAY "type only:"
$	SAY ""
$	IF (CPUTYPE .EQ. 1) .OR. (CPUTYPE .EQ. 3) THEN -
	SAY "		B"
$	IF (CPUTYPE .EQ. 2) .AND. .NOT. BOOT_CS THEN -
	SAY "		B/F0000000 ddcu"
$	IF (CPUTYPE .EQ. 2) .AND. BOOT_CS THEN -
	SAY "		B/800 DDA0"
$	IF (CPUTYPE .EQ. 2) .AND. BOOT_CS THEN -
	SAY "		@DEFBOO.CMD"
$	SAY ""
$	SAY "The distribution kit must remain on ''KIT' and the system disk"
$	SAY "must remain on ''TARGET' in order to proceed to the next phase"
$	SAY "of the upgrade."
$	SAY ""
$	SAY "The sysgen parameters are set to boot any system. Do not"
$	SAY "change them during the reboot or the upgrade may fail"
$	SAY "to execute properly!"
$	SAY ""
$	SAY "On occasion, this shutdown fails to complete. If the system fails"
$	SAY "to shut down within 5 minutes, enter CTRL/P, H, and reboot"
$	SAY "as described above to continue the upgrade procedure."
$	SAY ""
$	IF CPUTYPE .NE. 3 THEN GOTO ENDX_730
$	SAY "Because we have changed console TU58 cartridges, the system"
$	SAY "may reload the microcode.  This operation takes approximately"
$	SAY "10 minutes."
$ENDX_730:
$	SAY ""
$	SAY "If, for some reason, the kernel V4 system should fail to boot,"
$	SAY "you can boot into SYSBOOT by entering"
$	SAY ""
$	IF (CPUTYPE .EQ. 1) .OR. (CPUTYPE .EQ. 3) THEN -
$		SAY "		@UPGGEN.CMD"
$	IF CPUTYPE .EQ. 2 THEN SAY "		B/F0000001 ddcu"
$	SAY ""
$ !
$ ! Create a data file that will be used to find the distribution
$ ! kit after reboot.
$ !
$	SET DEFAULT 'NEW_SYSEXE'
$	IF F$SEARCH("UPGRADE.KIT") .NES. "" THEN DELETE UPGRADE.KIT;*
$	IF F$GETDVI(KIT,"MNT") THEN DISMOUNT /NOUNLOAD 'KIT'
$	IF V4_SYS THEN GOTO WRT_UKIT
$	T1 = F$GETDVI(KIT,"DEVTYPE")
$	IF (T1 .EQ. 23) .OR. (T1 .EQ. 24) THEN KIT = "DA" + F$EXTRACT(2,999,KIT)
$	IF LIB_DISK .EQS. "" THEN GOTO WRT_UKIT
$	T1 = F$GETDVI(LIB_DISK,"DEVTYPE")
$	IF (T1 .EQ. 23) .OR. (T1 .EQ. 24) THEN -
			LIB_DISK = "DA" + F$EXTRACT(2,999,LIB_DISK)
$WRT_UKIT:
$	OPEN/WRITE DATAF$ UPGRADE.KIT
$	WRITE DATAF$ KIT
$	WRITE DATAF$ OLD_ROOT_DOT
$	WRITE DATAF$ NEW_ROOT
$	WRITE DATAF$ "''F$TIME()'"
$	TEMP = "V3UPGRADE"
$	IF V4_SYS THEN TEMP = "V4UPGRADE"
$	WRITE DATAF$ TEMP
$	T1 = ""
$	IF KIT_RL02 THEN T1 = T1 + "A"
$	IF KIT_RC25 THEN T1 = T1 + "B"
$	IF KIT_DOTLR THEN T1 = T1 + "C"
$	IF KIT_ISTLR THEN T1 = T1 + "D"
$	IF KIT_DOCROOT THEN T1 = T1 + "E"
$	IF KIT_CROOT THEN T1 = T1 + "F"
$	IF NET$AREA_NUM .EQ. 0 THEN GOTO WRT_FLAGS
$	T1 = T1 + "G=" + F$FAO("!2ZL",NET$AREA_NUM)
$WRT_FLAGS:	
$	WRITE DATAF$ T1
$	WRITE DATAF$ SYSVER
$	WRITE DATAF$ LIB_DISK
$	CLOSE DATAF$
$	!
$	! Now shut down the system.
$	!
$	YN = "Y"
$	IF .NOT. BOOT_CS THEN YN = "N"
$	SET DEFAULT 'TARGET'['CLROOT''DEFDIR']
$	IF .NOT. UPGRADE$SHUTDOWN THEN GOTO UPGRADE_P1_DONE
$	@SYS$SYSTEM:SHUTDOWN -
		0 "Reboot during upgrade procedure" N N "later" 'YN' NONE
$
$UPGRADE_P1_DONE:
$	SAY "Upgrade phase 1 complete. Your first command MUST be a SET NOON."
$	@SYS$SYSTEM:STARTUP JOBCTL
$	@OPA0:
$	STOP /ID=0
$	!
$	! On error, exit from the upgrade procedure here.
$	!
$7000:
$	ON ERROR THEN EXIT 0
$	SAY ""
$	SAY "Upgrade to VAX/VMS Version 4.0 incomplete."
$	SAY ""
$	SAY "Error exit from upgrade procedure."
$	SAY "Restart upgrade from last boot of system."
$	SAY ""
$	IF F$LOGICAL("DATAF$") .NES. "" THEN  CLOSE DATAF$
$	IF F$LOGICAL("DATA2") .NES. "" THEN CLOSE DATA2
$	IF F$LOGICAL("DATA3")  .NES. "" THEN CLOSE DATA3
$	IF ("''CLROOT'" .EQS. "") .OR. ("''DEFDIR'" .EQS. "") .OR. -
	   ("''TARGET'" .EQS. "") THEN GOTO 7100
$	IF F$SEARCH("''TARGET'[''CLROOT'''DEFDIR']CONSOLE.DIR") .EQS. "" -
							THEN GOTO 7100
$	IF F$SEARCH("''TARGET'[''CLROOT'''DEFDIR'.CONSOLE]*.*;*") .NES. "" -
		THEN DELETE 'TARGET'['CLROOT''DEFDIR'.CONSOLE]*.*;*
$	SET FILE /NODIRECTORY 'TARGET'['CLROOT''DEFDIR']CONSOLE.DIR
$	DELETE 'TARGET'['CLROOT''DEFDIR']CONSOLE.DIR;
$7100:
$	EXIT	VMI$_FAILURE
$ !
$ ! Error conditions
$ !
$8000:
$	SAY "Unknown or unsupported cpu type (''CPUTYPE').
$	GOTO 7000
$8020:
$	SAY "Unable to open data parameter file ''FILENAME'.
$	GOTO 7000
$8040:
$	SAY "Error opening input file INSLIST.TMP."
$	GOTO 8100
$8060:
$	SAY "Error opening output file INSCMD.TMP."
$	GOTO 8100
$8080:
$	SAY "Error writing output file INSCMD.TMP."
$8100:
$	IF F$LOGICAL("DATA$") .NES. "" THEN CLOSE DATA$
$	IF F$LOGICAL("DATA1$") .NES. "" THEN CLOSE DATA1$
$	GOTO 7000
$8120:
$	SAY "This system disk cannot be upgraded."
$	GOTO 7000
$8140:
$	SAY "Invalid device for library disk."
$	INQUIRE YN "Do you want to try again"
$	IF YN THEN GOTO GET_LIB_DISK
$	GOTO 7000
$8160:
$	SAY "Distribution kit is not located in directory [000000]."
$	GOTO 7000
$8180:
$	SAY "Distribution kit must be located on the local system."
$	GOTO 7000
$8200:
$	SAY ""
$	SAY "This system disk does not have a top level directory,"
$	SAY " and cannot be upgraded."
$	SAY ""
$	GOTO 7000
$8210:
$	SAY "No device specified for distribution kit."
$	GOTO 7000
$8220:
$	SAY "PAGEFILE is too small for the upgrade to successfully complete."
$	SAY "Please resize it to at least 4600 blocks and restart the upgrade."
$	GOTO 7000
$8230:
$	SAY "The SYSGEN parameter ALLOCLASS must be set to zero.  Please reset"
$	SAY "it, reboot, and restart the upgrade."
$	GOTO 7000
