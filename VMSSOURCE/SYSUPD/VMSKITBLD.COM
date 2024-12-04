$	VERIFY = F$VERIFY(0)
$	IF P3 .NES. "" .AND. P4 .NES. "" THEN GOTO START
$	TYPE SYS$INPUT:

 VMSKITBLD - Build or Copy VAX/VMS binary distribution kit for Release 4.

$ !*****************************************************************************
$ !
$ ! This command file allows the invoker to create a system disk or copy a
$ ! system disk.  The transfer can  occur between any  of the disk types sup-
$ ! ported in Release 4.  For small disks (e.g. RL02) the saveset select
$ ! feature allows distribution over several volumes.
$ !
$ ! This command file will also create a bootblock on the target disk.  This
$ ! This is done by WRITEBOOT, and requires LOG_IO privilege.
$ !
$ ! There are  eight parameters which  control the kit build procedure.  Some
$ ! or all of these parameters may be specified as input.
$ !
$ ! The parameters are:
$ !
$ ! P1 = FILESPEC   The file name of the data file to use for the procedure.
$ !	Default = SYS$UPDATE:VMSKITBLD.DAT
$ ! 
$ ! P2 = MASK  The mask to use for determining whether to transfer each
$ !	individual file.
$ ! 
$ ! P3 = SOURCE:[SOURCE_TOPSYS] This specifies the source disk from which the
$ !	kit will be built, and the associated top level system directory if any.
$ !	If SOURCE_TOPSYS is defaulted, then the source device is checked
$ !	to see if it has a SYS0 topsys.  If it does, then SYS0 is the
$ !	the default, if not then NONE is the default.  To do a VMSKITBLD
$ !	from a cluster common system disk, specify SYS$SYSROOT as the
$ !	source device.
$ !
$ ! P4 = TARGET:LABEL[TARGET_TOPSYS] The target disk, its associated top
$ !	level system directory, and the target disk label to which the
$ !	kit will be built.  If TARGET_TOPSYS is defaulted, then it is
$ !	assumed to be SYS0.  An explicit "NONE" is required to produce
$ !	a "flat" system.
$ !
$ ! P5 = SELECT  Savesets to be output.  One of: REQ, LIB, OPT, ALL.
$ !	By default ALL files are transferred to the output device
$ !
$ ! P6 = MicroVMS	This parameter is set to one of the following if a
$ !			MicroVMS kit is being built:
$ !	BASE - base system
$ !	UTIL - common utilities option
$ !	USER - secure user environment option
$ !	NET  - network option
$ !	PROG - program development tools option
$ !	SYSP - system programming option
$ !	INTE - checkpointing and journaling integrity option
$ !
$ ! P7 = COPY     This parameter specifies whether to BUILD, ADD, or COPY.
$ !	BUILD -	Initializes a new volume or volume set and creates all
$ !		the necessary directories from scratch.
$ !	COMMON -The same as BUILD, except that a cluster common system
$ !		disk will be built.
$ !	ADD   - Puts a new system in a new set of directories on an 
$ !		existing volume which presumably contains other 
$ !		systems on it.  The TARGET_TOPSYS should
$ !		be a new top level system directory.
$ !	COPY  -	Copies the kit files to an already existing set of
$ !		system directories.  It will not create the directories.
$ !
$ ! P8 = OPTIONS  This parameter is a comma separated list of options.
$ !	NOPROMPT - Indicates that the user should not be prompted with
$ !		   "device ready" questions.  Command procedures which
$ !		   invoke VMSKITBLD with known device status set this switch.
$ !
$ ! This command procedure uses as input a data file (specified in P1 or
$ ! defaulted to [SYSUPD]VMSKITBLD.DAT on the system disk).  The data file is
$ ! read as input commands to be executed by the procedure.  The format of each
$ ! record in the data file is as follows:
$ !	1) If the record begins with a "$" (dollar sign), then the record is
$ !	   submitted directly as a DCL command line.
$ !	2) The remainder of the records have the following fields defined:
$ !	   NOTE: The fields can be in any order.
$ !
$ !	NAME,OP=op,SET=set,COND=mask,UVMS=flags,CAT=tailorgroup
$ !
$ !			NAME  -  The name of the file to be copied.  Must
$ !				 include the extension but not the version.
$ !			OPERATION  =  The action to be performed on the file.
$ !				null  -  build/copy the file normally
$ !				ADD_CONDITION - OR in the specified mask bits
$ !					into the current condition bits.  New
$ !					mask bits specified in COND_ADD= parameter.
$ !				BUILD  -  transfer the file during build only
$ !				SET  -  set the default directory to NAME for
$ !					 the succeeding transfers.
$ !				CREATE  -  create a directory entry called NAME
$ !					(build only).  The "SYNONYM="  field
$ !					specifies an alternate directory name
$ !					to be entered as a synonym to NAME.
$ !				ENTER  -  make a directory entry for file NAME
$ !					(build only)
$ !				COPY  -  transfer the file during copy only
$ !				CONTIG  -  make the destination file contiguous
$ !				RENAME_B - rename a file just copied to the
$ !					target disk.  In a rename operation, the
$ !					data record also contains the field
$ !					DEST=new_file_name.  Only used for
$ !					BUILD and ADD operations.
$ !				RENAME_C - same as RENAME_B except used for
$ !					COPY operations.
$ !				SYSGEN  -  create the sysgen files (build
$ !					only).  If NAME is null, use default
$ !					sysgen file sizes depending on target
$ !					disk type.  If 	NAME is not null, create
$ !					the sysgen file specified in NAME, and
$ !					use the FILESIZE= field of the record
$ !					to specify the file size.
$ !				WRITEBOOT - write a bootblock on the target
$ !					device
$ !			SAVESET	- Chooses a subset of files to copy to the
$ !					target device.  This parameter is used
$ !					for building Release 4 distribution kits
$ !				REQ - required saveset
$ !				LIB - library saveset
$ !				OPT - optional saveset
$ !				ALL - all savesets
$ !			CONDITIONAL  -  The value to be ANDed to determine
$ !				whether or not to copy/build this file.
$ !
$ !				a)  1  -  UETP
$ !				b)  2  -  Regression Tests
$ !				c)  4  -  Regression Test Tools
$ !				d)  8  -  HELP files
$ !				e) 16  -  F4P, FORTRAN
$ !				f) 32  -  BASIC +2
$ !				g) 64  -  DECnet
$ !				h) 128 -  BLISS32 .L32 files (NO BLISS32.EXE!)
$ !				i) 256 -  coding examples
$ !				j) 512,1024  -  VMS development only, not
$ !					for REL 4 kits
$ !				k) 2048 - files needed to build VMS
$ !					distribution kits
$ !				l) 4096 - MicroVMS only, not part of VMS
$ !				m) 8192 - Journaling related files (**JNL)
$ !				n) all others undefined
$ !
$ !			CATEGORY - The tailoring group(s) to which this
$ !				   file belongs.  This field is used by
$ !				   [SYSBLDCOM]TAILORBLD.COM to create the
$ !				   tailoring group files.
$ !
$ ! If the logical name VMSKITBLD$LOCAL is defined VMSKITBLD will
$ ! process the contents of the named file after processing the primary
$ ! kit data file.
$
$START:
$	DEFDIR = F$ENVIRONMENT("DEFAULT")
$	DEFUIC = F$USER()
$	SYSGEN = "$SYSGEN"
$	SAY = "WRITE SYS$OUTPUT"
$	ON ERROR THEN GOTO 3020
$	ON CONTROL_Y THEN GOTO 3020
$	DOING_LOCAL = 0
$	REQ_PRIVS = "CMKRNL,SYSPRV,LOG_IO,VOLPRO"
$	SAVED_PRIVS = F$SETPRV(REQ_PRIVS)
$	NOPRIV = 0
$	IF .NOT. F$PRIVILEGE(REQ_PRIVS) THEN NOPRIV = 1
$
$	P1 = F$PARSE(P1,"SYS$UPDATE:VMSKITBLD.DAT",,,"SYNTAX_ONLY")
$	FILENAME = P1
$	IF F$SEARCH(P1) .NES. "" THEN GOTO GET_LOCAL
$	SAY "Error opening data file ''P1'"
$	GOTO 3020
$GET_LOCAL:
$	VMSKITBLD$LOCAL_FILE = F$TRNLNM("VMSKITBLD$LOCAL")
$	IF VMSKITBLD$LOCAL_FILE .EQS. "" THEN GOTO PARSE_OPTIONS
$	VMSKITBLD$LOCAL_FILE = F$PARSE(VMSKITBLD$LOCAL_FILE,"SYS$UPDATE:.DAT",,,"SYNTAX_ONLY")
$	IF F$SEARCH(VMSKITBLD$LOCAL_FILE) .NES. "" THEN GOTO LOCAL_OK
$	SAY "Error opening local data file ''VMSKITBLD$LOCAL_FILE' ."
$	GOTO PARSE_OPTIONS
$LOCAL_OK:
$	 SAY "Local data file ''VMSKITBLD$LOCAL_FILE' will also be processed."
$PARSE_OPTIONS:
$	SAY ""
$ !
$ ! Parse OPTIONS
$ !
$	PROMPT = "TRUE"
$	IF F$LOCATE ("NOPROMPT", P8) .NE. F$LENGTH (P8) -
	  .AND. P8 .NES. "" THEN PROMPT = "FALSE"
$ !
$ ! Parse SELECT parameter.
$ !
$	SELECT = P5
$	VALID_SAVESETS = "REQ,LIB,OPT,ALL"
$	IF SELECT .EQS. "" THEN SELECT = "ALL"
$	IF F$LOCATE(SELECT,VALID_SAVESETS) .NE. F$LENGTH(VALID_SAVESETS) -
	THEN GOTO GET_OPERATION
$	SAY -
"P5 must be one of: REQ, LIB, OPT, ALL, or null"
$	EXIT
$ !
$ ! Determine which operation was requested.
$ !
$GET_OPERATION:
$	BUILD = P7
$	P7 = ""
$	F_COMMON = 0
$	OKOPS = "/BUILD/ADD/COPY/COMMON/"
$60:	IF BUILD .NES. "" .AND. F$LOC("/"+BUILD,OKOPS) .NE. F$LEN(OKOPS) -
			THEN GOTO 61
$	INQUIRE /NOPUNCT BUILD "Operation [BUILD,ADD,COPY,COMMON]? "
$	GOTO 60
$61:
$	IF BUILD .EQS. "CO" THEN GOTO GET_OPERATION !Ambiguous
$	OKOPS = F$EXTRACT(F$LOC("/"+BUILD,OKOPS)+1,999,OKOPS)
$	BUILD = F$ELEMENT(0,"/",OKOPS)
$	IF BUILD .NES. "COMMON" THEN GOTO GET_SOURCE
$	F_COMMON = 1
$	BUILD = "BUILD"
$ !
$ ! Get source device and TOPSYS directory.
$ !
$GET_SOURCE:
$	DEFAULT_SOURCE_TOPSYS = "NONE"
$	SOURCE = P3
$	IF SOURCE .EQS. "" THEN GOTO SRC_PROMPT
$	COLON_POS = F$LOCATE(":",SOURCE)+1
$	SOURCE_TOPSYS = F$EXTRACT(COLON_POS,132,SOURCE)
$	SOURCE = F$EXTRACT(0,COLON_POS,SOURCE)
$	SOURCE = SOURCE - ":" + ":"		! Make sure : is at the end.
$	TEMP = F$SEARCH("''SOURCE'[0,0]SYS0.DIR;1")
$	IF TEMP .NES. "" THEN DEFAULT_SOURCE_TOPSYS = "SYS0"
$	GOTO FORM_SRC_SYMBOLS
$
$NOSUCH_SOURCE:
$	WRITE SYS$OUTPUT "No such device as ''SOURCE'."
$SRC_PROMPT:
$	INQUIRE SOURCE "Enter mounted SOURCE disk name (DDCU:)"
$	IF SOURCE .EQS. "" THEN GOTO SRC_PROMPT
$	IF .NOT. F$GETDVI(SOURCE,"EXISTS") THEN GOTO NOSUCH_SOURCE
$	SOURCE = SOURCE - ":" + ":"		! Make sure : is at the end.
$	TEMP = F$SEARCH("''SOURCE'[0,0]SYS0.DIR;1")
$	IF TEMP .NES. "" THEN DEFAULT_SOURCE_TOPSYS = "SYS0"
$	INQUIRE SOURCE_TOPSYS -
"Enter SOURCE disk top level system directory [default = ''DEFAULT_SOURCE_TOPSYS']"
$
$FORM_SRC_SYMBOLS:
$	IF .NOT. F$GETDVI(SOURCE,"EXISTS") THEN GOTO NOSUCH_SOURCE
$	IF .NOT. F$TRNLNM(SOURCE-":",,,,,"CONCEALED") THEN -
		SOURCE = F$GETDVI(SOURCE,"FULLDEVNAM")
$	SOURCE_TOPSYS = SOURCE_TOPSYS - "[" - "<" - "]" - ">"
$	IF SOURCE_TOPSYS .EQS. "" THEN SOURCE_TOPSYS = DEFAULT_SOURCE_TOPSYS
$	IF SOURCE_TOPSYS .EQS. "NONE" THEN SOURCE_TOPSYS = ""
$	SOURCE_TOPSYS_DOT = ""
$	IF SOURCE_TOPSYS .NES. "" THEN SOURCE_TOPSYS_DOT = SOURCE_TOPSYS + "."
$ !
$ ! Get target device, label, and TOPSYS directory.
$ !
$GET_TARGET:
$	TARGET = P4
$	IF TARGET .EQS. "" THEN GOTO TARGET_PROMPT
$	COLON_POS = F$LOCATE(":",TARGET)+1
$	LB_POS = F$LOCATE("[",TARGET)
$	LABEL = F$EXTRACT(COLON_POS,LB_POS-COLON_POS,TARGET)
$	IF LABEL .EQS. "" THEN INQUIRE LABEL -
"Enter the TARGET disk's label [default = VAXVMSRL4]"
$	TARGET_TOPSYS = F$EXTRACT(LB_POS,132,TARGET) - "[" - "<" - "]" - ">"
$	TARGET = F$EXTRACT(0,COLON_POS,TARGET)
$	GOTO FORM_TARGET_SYMBOLS
$NOSUCH_TARGET:
$	SAY "No such device as ''TARGET'."
$	TARGET = ""
$TARGET_PROMPT:
$	INQUIRE TARGET "Enter TARGET disk name (DDCU:)"
$	IF TARGET .EQS. "" THEN GOTO TARGET_PROMPT
$	IF .NOT. F$GETDVI(TARGET,"EXISTS") THEN GOTO NOSUCH_TARGET
$	TARGET = TARGET - ":" + ":"
$	INQUIRE LABEL -
"Enter the TARGET disk's label [default = VAXVMSRL4]"
$GET_TARGET_TOPSYS:
$	INQUIRE TARGET_TOPSYS -
"Enter TARGET disk top level system directory [default = SYS0]"
$
$FORM_TARGET_SYMBOLS:
$	IF .NOT. F$GETDVI(TARGET,"EXISTS") THEN GOTO NOSUCH_TARGET
$	TARGET = F$GETDVI(TARGET,"FULLDEVNAM")
$	IF LABEL .EQS. "" THEN LABEL = "VAXVMSRL4"
$	IF TARGET_TOPSYS .EQS. "" THEN TARGET_TOPSYS = "SYS0"
$	IF TARGET_TOPSYS .NES. "NONE" THEN GOTO NOT_FLAT
$	IF .NOT. F_COMMON THEN GOTO FLAT_TARGET
$	TYPE SYS$INPUT

A cluster common system disk may not be built without a top level
system directory.

$	P4 = ""
$	GOTO GET_TARGET
$FLAT_TARGET:
$	TARGET_TOPSYS = ""
$	TYPE SYS$INPUT

Warning -- system disks built without a top level system directory are
           not supported by Digital and cannot be upgraded nor updated.

$
$NOT_FLAT:
$	TARGET_TOPSYS_DOT = ""
$	ROOT = "[0,0]"
$	IF TARGET_TOPSYS .NES. "" THEN GOTO 10$
$	IF BUILD .NES. "ADD" THEN GOTO GET_DATAFILE
$	SAY -
"The ADD function requires a top level system directory for the TARGET disk."
$	GOTO GET_TARGET_TOPSYS
$10$:
$	TARGET_TOPSYS = TARGET_TOPSYS - "[" - "<" - "]" - ">"
$	IF 'F$LENGTH(TARGET_TOPSYS) .EQ. 0 THEN GOTO 20$
$	IF 'F$LENGTH(TARGET_TOPSYS) .EQ. 4 -
	.AND. ((TARGET_TOPSYS .GES. "SYS0" .AND. TARGET_TOPSYS .LES. "SYS9") -
	.OR. (TARGET_TOPSYS .GES. "SYSA" .AND. TARGET_TOPSYS .LES. "SYSF")) -
	THEN GOTO 20$
$	SAY -
"The TARGET top level system directory must be SYS0 - SYSF, or NONE."
$	GOTO GET_TARGET_TOPSYS
$20$:
$	TARGET_TOPSYS_DOT = TARGET_TOPSYS + "."
$	TRGROOT_TOPSYS = TARGET_TOPSYS
$	TRGROOT_TOPSYS_DOT = TARGET_TOPSYS_DOT
$	IF F_COMMON THEN TARGET_TOPSYS_DOT = "V4COMMON."
$	IF F_COMMON THEN TARGET_TOPSYS = "V4COMMON"
$	ROOT = "[" + TARGET_TOPSYS + "]"
$ !
$ ! Get data file name.
$ !
$GET_DATAFILE:
$	ON ERROR THEN GOTO 3010
$	ON CONTROL_Y THEN GOTO 3010
$	OPEN/READ DATAF 'FILENAME
$	IF $STATUS THEN GOTO GET_MICROVMS
$	SAY " Unable to open data parameter file."
$	EXIT
$
$GET_MICROVMS:
$	MICROVMS = P6
$	IF MICROVMS .EQS. "" THEN GOTO GET_CONDIT
$	VALID_MICROVMS = "BASE/UTIL/USER/NET/PROG/SYSP/INTE/"
$	IF F$LOCATE("''MICROVMS/",VALID_MICROVMS).EQ.F$LENGTH(VALID_MICROVMS) -
	 THEN GOTO ERR_P6
$	MICROVMS = MICROVMS + "ALL"
$	GOTO GET_CONDIT
$ERR_P6:
$	SAY " ''MICROVMS' is an invalid value for the P6 parameter."
$	EXIT
$
$GET_CONDIT:
$	MASK = P2
$	CONDIT = 1+8+64+256
$	IF MASK .NES. "" THEN CONDIT = 'MASK'
$	INITIAL_ERRCNT = F$GETDVI(TARGET,"ERRCNT")
$	IF BUILD .EQS. "COPY" THEN GOTO ALLOC_TARGET
$ !
$ ! Set up for BUILD and ADD operation.
$ !
$	SET NOON
$	IF .NOT. NOPRIV THEN SET UIC [1,4]
$	SET ON
$	DELETE = "!"
$	SYS_QUAL = "/SYS"
$	IF NOPRIV THEN SYS_QUAL = ""
$	MAXFILES_QUAL = "/MAXIMUM_FILES=2500"
$	IF SELECT .EQS. "ALL" THEN MAXFILES_QUAL = ""
$	HEADERS_QUAL = ""
$	IF SELECT .EQS. "REQ" THEN HEADERS_QUAL = "/HEADERS=300"
$	INIT_VOLUME := INIT/CLUSTER=1'SYS_QUAL''MAXFILES_QUAL''HEADERS_QUAL'
$	CREATE_DIRECTORY = "CREATE/DIRECTORY/OWNER=[1,4]/PROTECTION=(SY:RWE,OW:RWE,GR:RE,WO:RE)"
$	IF NOPRIV THEN CREATE_DIRECTORY = "CREATE/DIRECTORY/PROTECTION=(SY:RWE,OW:RWE,GR:RE,WO:RE)"
$	IF BUILD .EQS. "ADD" THEN GOTO ALLOC_TARGET
$ !
$ ! This next block is only executed during a BUILD operation.
$ !
$INIT_TARGET:
$	IF F$MODE() .NES. "INTERACTIVE" THEN GOTO 63
$	SAY "  It will be necessary to initialize the target disk(s)."
$62:	IF .NOT. PROMPT THEN GOTO 63
$	INQUIRE READY -
"Is the target disk, ''TARGET, ready to be initialized? (Y/N)"
$	IF .NOT. READY THEN GOTO 62
$63:	ALLOCATE 'TARGET
$	'INIT_VOLUME' 'TARGET' 'LABEL'
$	GOTO MOUNT_TARGET
$ !
$ ! Executed during an ADD or COPY operation.
$ !
$ALLOC_TARGET:
$	SAY "  Allocate and mount the target disk(s).
$	SET DEFAULT ['TARGET_TOPSYS_DOT'SYSEXE]
$	SOURCE_DEFAULT := 'SOURCE'['SOURCE_TOPSYS_DOT'SYSEXE]
$	IF .NOT. F$GETDVI(TARGET,"MNT") THEN ALLOCATE 'TARGET
$ !
$ ! All operations converge at this point.
$ !
$MOUNT_TARGET:
$	ON CONTROL_Y THEN GOTO 3000
$	ON ERROR THEN GOTO 3000
$	IF ((BUILD .EQS. "ADD") .OR. (BUILD .EQS. "COPY")) -
		.AND. F$GETDVI(TARGET,"MNT") THEN GOTO MNT_TARG10
$	MOUNT/DATA_CHECK=(READ,WRITE) 'TARGET' 'LABEL'
$MNT_TARG10:
$	IF BUILD .EQS. "COPY" .OR. TARGET_TOPSYS .EQS. "" THEN GOTO START_BUILD
$	'CREATE_DIRECTORY'  'TARGET'['TARGET_TOPSYS']
$	IF .NOT. F_COMMON THEN GOTO START_BUILD
$	'CREATE_DIRECTORY 'TARGET'['TRGROOT_TOPSYS']
$	SET FILE /ENTER='TARGET'['TRGROOT_TOPSYS']SYSCOMMON.DIR -
		'TARGET'[0,0]'TARGET_TOPSYS'.DIR
$
$START_BUILD:
$	SET NOON
$	IF .NOT. NOPRIV THEN SET UIC [1,4]
$ !
$ ! This is the main loop that is executed for each record in the data file.
$ !
$RECORD_LOOP:
$	READ/END_OF_FILE=2000 DATAF RECORD
$	CHAR1 = F$EXTRACT(0,1,RECORD)
$	IF CHAR1 .EQS. "$" THEN GOTO EXECUTE_DCL
$	IF CHAR1 .EQS. "!" THEN GOTO RECORD_LOOP
$	IF CHAR1 .NES. "*" THEN GOTO GET_SAVESET
$	IF MICROVMS .EQS. "" THEN GOTO RECORD_LOOP
$	RECORD = F$EXTRACT(1,200,RECORD)
$	GOTO GET_SAVESET
$ !
$ ! Get the saveset field from the current record.
$ !
$GET_SAVESET:
$	IF SELECT .EQS. "ALL" THEN GOTO GET_CONDITIONAL
$	SAVESET = F$EXTRACT(F$LOCATE("SET=",RECORD)+4,132,RECORD)
$	SAVESET = F$ELEMENT(0,",",SAVESET)
$	IF SAVESET .EQS. "" THEN SAVESET = "LIB"
$	IF F$LOCATE(SAVESET,VALID_SAVESETS) .NE. F$LENGTH(VALID_SAVESETS) -
	THEN GOTO 250
$	SAY "BAD SAVESET SPECIFIED IN RECORD *''RECORD'*"
$	SAVESET = "LIB"
$250:	IF SAVESET .NES. "ALL" .AND. SELECT .NES. SAVESET -
	THEN GOTO RECORD_LOOP
$ !
$ ! Get the CONDTIONAL field from the current record.
$ !
$GET_CONDITIONAL:
$	IF CONDIT .EQ. -1 THEN GOTO GET_UVMS
$	CONDITIONAL = F$EXTRACT(F$LOCATE("COND=",RECORD)+5,132,RECORD)
$	IF CONDITIONAL .EQS. "" THEN GOTO GET_UVMS
$	CONDITIONAL = F$ELEMENT(0,",",CONDITIONAL)
$	IF (CONDITIONAL .AND. CONDIT) .EQ. 0 THEN GOTO RECORD_LOOP
$ !
$ ! Get the flagging for MICROVMS if this is a MICROVMS build.
$ !
$GET_UVMS:
$	IF MICROVMS .EQS. "" THEN GOTO GET_NAME
$	UVMS_FLAGS = F$EXTRACT(F$LOCATE("UVMS=",RECORD)+5,132,RECORD)
$	UVMS_FLAGS = F$ELEMENT(0,",",UVMS_FLAGS)
$	IF F$LOCATE(UVMS_FLAGS,MICROVMS) .EQ. F$LENGTH(MICROVMS) -
	  THEN GOTO RECORD_LOOP
$ !
$ ! Get the name from the current record.  (The name is always the first field
$ ! in the record, and doesn't have a keyword associated with it.)
$ !
$GET_NAME:
$	NAME = F$ELEMENT(0,",",RECORD)
$ !
$ ! Get the operation specified by the current record.
$ !
$GET_OPERATION:
$	OPERATION = F$EXTRACT(F$LOCATE("OP=",RECORD)+3,132,RECORD)
$	IF OPERATION .EQS. "" THEN GOTO NORMAL
$	OPERATION = F$ELEMENT(0,",",OPERATION)
$	GOTO 'OPERATION
$
$BUILD:
$	IF BUILD .NES. "BUILD" .AND. BUILD .NES. "ADD" THEN GOTO RECORD_LOOP
$	GOTO NORMAL
$
$COPY:
$	IF BUILD .NES. "COPY" THEN GOTO RECORD_LOOP
$	GOTO NORMAL
$
$SET:
$	SET DEFAULT ['TARGET_TOPSYS_DOT''NAME']
$	SOURCE_DEFAULT = SOURCE + "[" + SOURCE_TOPSYS_DOT + NAME + "]"
$	GOTO RECORD_LOOP
$
$CREATE:
$	IF BUILD .EQS. "COPY" THEN GOTO RECORD_LOOP
$ !
$ ! ***** Remove this logic when the diagnostic supervisor can properly
$ ! ***** handle the root directory environment.  This logic places a
$ ! ***** synonym for SYSMAINT in the MFD.
$ !
$	IF NAME .EQS. "SYSMAINT" .AND. -
		TARGET_TOPSYS .NES "" THEN GOTO CREATE_MFD_SYN
$	SYNONYM = F$EXTRACT(F$LOCATE("SYNONYM=",RECORD)+8,132,RECORD)
$	SYNONYM = F$ELEMENT(0,",",SYNONYM)
$	IF SYNONYM .EQS. "" THEN GOTO CREATE_NO_SYN
$ !
$ ! CREATE A SYNONYM DIRECTORY AND ENTER THE NORMAL ONE
$ !
$	'CREATE_DIRECTORY' 'TARGET'['TARGET_TOPSYS_DOT''SYNONYM']
$	SET FILE /ENTER='TARGET''ROOT''NAME'.DIR;1 'TARGET''ROOT''SYNONYM'.DIR;1
$	GOTO RECORD_LOOP
$CREATE_NO_SYN:
$	'CREATE_DIRECTORY' 'TARGET'['TARGET_TOPSYS_DOT''NAME']
$	IF F_COMMON THEN 'CREATE_DIRECTORY 'TARGET'['TRGROOT_TOPSYS'.'NAME']
$	GOTO RECORD_LOOP
$CREATE_MFD_SYN:
$	IF BUILD .EQS. "ADD" THEN GOTO NO_MFD_SYN
$	'CREATE_DIRECTORY' 'TARGET'['NAME']	!MAIN DIRECTORY IN MFD
$	SET FILE /ENTER='TARGET''ROOT''NAME'.DIR;1 'TARGET'[0,0]'NAME'.DIR;1
$	GOTO RECORD_LOOP
$NO_MFD_SYN:
$	WRITE SYS$OUTPUT "% MFD synonym for SYSMAINT not created for ADD operation."
$	GOTO RECORD_LOOP
$
$ENTER:
$	IF BUILD .EQS. "COPY" THEN GOTO RECORD_LOOP
$	CREATE 'TARGET''NAME'
$	GOTO RECORD_LOOP
$
$NORMAL:
$	IF BUILD .EQS. "BUILD" THEN GOTO NORMAL1
$	IF F$SEARCH("''TARGET'''NAME';") .NES. "" THEN DELETE 'TARGET''NAME';*
$NORMAL1:
$	COPY /PROTECTION=(S=RWED,O=RWED,G=RWED,W=RE) -
		'SOURCE_DEFAULT''NAME' 'TARGET''NAME'
$	GOTO RECORD_LOOP
$
$CONTIG:
$	IF F$SEARCH("''TARGET'''NAME';") .NES. "" THEN DELETE 'TARGET''NAME';*
$	COPY /PROTECTION=(S=RWED,O=RWED,G=RWED,W=RE) /CONTIG  -
		/TRUNC 'SOURCE_DEFAULT''NAME' 'TARGET''NAME'
$	GOTO RECORD_LOOP
$	
$RENAME_C:
$	IF BUILD .NES. "COPY" THEN GOTO RECORD_LOOP
$	GOTO RENAME
$RENAME_B:
$	IF BUILD .NES. "BUILD" THEN GOTO RECORD_LOOP
$RENAME:
$	DESTINATION = F$EXTRACT(F$LOCATE("DEST=",RECORD)+5,132,RECORD)
$	IF DESTINATION .EQS. "" THEN GOTO RECORD_LOOP
$	DESTINATION = F$ELEMENT(0,",",DESTINATION)
$	RENAME 'TARGET''NAME' 'TARGET''DESTINATION'
$	GOTO RECORD_LOOP
$
$EXECUTE_DCL:
	'RECORD
$	GOTO RECORD_LOOP
$
$SYSGEN:
$	IF BUILD .NES. "BUILD" THEN GOTO RECORD_LOOP
$	SET DEF ['TRGROOT_TOPSYS_DOT'SYSEXE]
$	IF MICROVMS .NES. "" THEN GOTO MICROVMSGEN
$	IF SELECT .NES. "REQ" THEN GOTO SIZE_SYSGEN_FILES
$MICROVMSGEN:
$	SAY -
	"For distribution kits, the following system file sizes are used:"
$	SAY -
	"PAGEFILE.SYS=4604, SWAPFILE.SYS=none, SYSDUMP.DMP=none"
$	NAME = "PAGEFILE.SYS"
$	FILESIZE = 4604
$	GOTO 590
$
$SIZE_SYSGEN_FILES:
$	DISKSIZE = F$GETDEV(TARGET,"MAXBLOCK")
$	IF DISKSIZE .GT. 100000 THEN GOTO 500$
$	DUMP = 1028
$	PAGE = 8192
$	SWAP = 3080
$	GOTO CREATE_SYSGEN_FILES
$500$:
$	IF DISKSIZE .GT. 300000 THEN GOTO 510$
$	DUMP = 2054
$	PAGE = 24000
$	SWAP = 26600
$	GOTO CREATE_SYSGEN_FILES
$510$:
$	DUMP = 4104
$	PAGE = 48000
$	SWAP = 36000
$
$CREATE_SYSGEN_FILES:
$	IF NAME .NES. "" THEN GOTO CREATE_SINGLE
$	SYSGEN CREATE 'TARGET'SWAPFILE/SIZE='SWAP
$	SET PROT=(S:RWED,O:RWED,G,W) 'TARGET'SWAPFILE.SYS
$	SET FILE /NOBACKUP 'TARGET'SWAPFILE.SYS
$	SYSGEN CREATE 'TARGET'PAGEFILE/SIZE='PAGE
$	SET PROT=(S:RWED,O:RWED,G,W) 'TARGET'PAGEFILE.SYS
$	SET FILE /NOBACKUP 'TARGET'PAGEFILE.SYS
$	SYSGEN CREATE 'TARGET'SYSDUMP.DMP/SIZE='DUMP
$	SET PROT=(S:RWED,O:RWED,G,W) 'TARGET'SYSDUMP.DMP
$	SET FILE /NOBACKUP 'TARGET'SYSDUMP.DMP
$	GOTO RECORD_LOOP
$
$CREATE_SINGLE:
$	FILESIZE = F$EXTRACT(F$LOCATE("FILESIZE=",RECORD)+9,132,RECORD)
$	FILESIZE = F$ELEMENT(0,",",FILESIZE)
$	IF FILESIZE .NES. "" THEN GOTO 590
$	IF NAME .EQS. "SWAPFILE" THEN GOTO SWAPFILE
$	IF NAME .EQS. "PAGEFILE" THEN GOTO PAGEFILE
$	IF NAME .EQS. "SYSDUMP.DMP" THEN GOTO SYSDUMP
$	SAY "Invalid parameter for SYSGEN, files not created."
$	SAY "Invalid record = *''RECORD'*""
$	GOTO RECORD_LOOP
$SWAPFILE:
$	FILESIZE = SWAP
$	GOTO 590
$PAGEFILE:
$	FILESIZE = PAGE
$	GOTO 590
$SYSDUMP:
$	FILESIZE = DUMP
$590:
$	SYSGEN CREATE 'TARGET''NAME'/SIZE='FILESIZE
$	SET PROT=(S:RWED,O:RWED,G,W) 'TARGET''NAME'
$	SET FILE /NOBACKUP 'TARGET''NAME'
$	GOTO RECORD_LOOP
$
$WRITEBOOT:
$	IF SELECT .NES. "REQ" .AND. SELECT .NES. "ALL" THEN GOTO RECORD_LOOP
$	IF NOPRIV THEN GOTO CANT_WRITEBOOT
$	DEFINE /USER TARGET_DISK 'TARGET'['TARGET_TOPSYS_DOT'SYSEXE]
$	RUN SYS$SYSTEM:WRITEBOOT
TARGET_DISK:VMB.EXE
1
200
$	GOTO RECORD_LOOP
$CANT_WRITEBOOT:
$	SAY "%WARNING - Unable to write boot block - no privilege."
$	SAY " It will not boot on VAX-11/750 processors."
$	SAY "To place a boot block on this disk, boot it on a VAX-11/780, and type:"
$	SAY "$ DEFINE /USER TARGET_DISK SYS$SYSROOT:[SYSEXE]"
$	SAY "$ RUN SYS$SYSTEM:WRITEBOOT"
$	SAY "TARGET_DISK:VMB.EXE"
$	SAY "1"
$	SAY "200"
$	GOTO RECORD_LOOP
$ADD_CONDITION:
$	CONDITIONAL = F$EXTRACT(F$LOCATE("COND_ADD=",RECORD)+9,132,RECORD)
$	IF CONDITIONAL .EQS. "" THEN GOTO RECORD_LOOP
$	CONDITIONAL = F$ELEMENT(0,",",CONDITIONAL)
$	CONDIT = CONDIT .OR. F$INTEGER('CONDITIONAL')
$	GOTO RECORD_LOOP
$
$2000:
$	IF DOING_LOCAL THEN GOTO 2010
$	IF VMSKITBLD$LOCAL_FILE .EQS. "" THEN GOTO 2010
$	IF F$SEARCH(VMSKITBLD$LOCAL_FILE) .EQS. "" THEN GOTO 2010
$	CLOSE DATAF
$	OPEN /READ DATAF 'VMSKITBLD$LOCAL_FILE
$	SAY "Processing data file ''VMSKITBLD$LOCAL_FILE'"
$	DOING_LOCAL = 1
$	GOTO RECORD_LOOP
$2010:
$	IF SELECT .NES. "ALL" .AND. SELECT .NES. "REQ" THEN GOTO 2100		! System disks only
$	IF TARGET_TOPSYS .EQS. "" THEN GOTO 2100				! Non-flat systems only
$	IF BUILD .EQS. "ADD" THEN GOTO 2100					! Don't change old flat sysexe
$	IF BUILD .EQS. "COPY" THEN GOTO 2020					! Directory entries not needed
$	CREATE_DIRECTORY 'TARGET'[SYSEXE]
$	GOTO 2030
$2020:
$	SET PROTECTION=(W=RWE) 'TARGET'[0,0]SYSEXE.DIR;1
$	SET FILE /REMOVE 'TARGET'[SYSEXE]SYSBOOT.EXE;
$2030:
$	SET FILE /ENTER='TARGET'[SYSEXE]SYSBOOT.EXE 'TARGET'['TARGET_TOPSYS'.SYSEXE]SYSBOOT.EXE
$	SET PROTECTION=(S:R,O:R,G,W) 'TARGET'[0,0]SYSEXE.DIR;1
$	SET FILE /REMOVE 'TARGET'['TARGET_TOPSYS'.SYSEXE]SYSBOOT.EXE;
$	SET FILE /ENTER ='TARGET'['TARGET_TOPSYS'.SYSEXE]SYSBOOT.EXE -
		'TARGET'[SYSEXE]SYSBOOT.EXE
$2100:
$	IF F$SEARCH("''TARGET'[''TARGET_TOPSYS'.SYSEXE]SYSUAF.DAT") .NES. "" -
		THEN SET PROT=(S=RWE,O=RWE,G=RWE,W) 'TARGET'['TARGET_TOPSYS'.SYSEXE]SYSUAF.DAT
$	FINAL_ERRCNT = F$GETDVI(TARGET,"ERRCNT")-INITIAL_ERRCNT
$	IF FINAL_ERRCNT .EQ. 0 THEN GOTO 3000
$	SAY ""
$	SAY F$FAO("There were !UL error!%S on !AS",FINAL_ERRCNT,TARGET)
$3000:	ON CONTROL_Y THEN CONTINUE
$	DISMOUNT/NOUNLOAD 'TARGET'
$3010:	ON CONTROL_Y THEN CONTINUE
$	CLOSE DATAF
$3020:	ON CONTROL_Y THEN CONTINUE
$	IF .NOT. NOPRIV THEN SET UIC 'DEFUIC'
$	SET DEFAULT 'DEFDIR'
$	SAVED_PRIVS = F$SETPRV(SAVED_PRIVS)
$	IF .NOT. NOPRIV THEN GOTO 3040
$	SAY "% Because you do not have privilege, you are the owner"
$	SAY "  of all files on your kit.  You may want to take the pack"
$	SAY "  to a system on which you have a privileged account and"
$	SAY "  enter the following command:"
$	SAY "$ SET FILE /OWNER=[1,4] ''TARGET'[000000...]*.*;*"
$	SAY "  you must also enter the following commands:"
$	SAY "$ DEFINE /USER TARGET_DISK ''TARGET'[SYS0.SYSEXE]	! (Or whatever drive you mount it on)"
$	SAY "$ RUN SYS$SYSTEM:WRITEBOOT"
$	SAY "TARGET_DISK:VMB.EXE"
$	SAY "1"
$	SAY "200"
$3040:
$	IF VERIFY THEN SET VERIFY		!Reset verify
$	EXIT
