$ SET NOON
$ DEFDIR:='F$DIRECTORY()
$ ON CONTROLY THEN GOTO ABORT_1
$ TYPE SYS$INPUT:
 
  TRIALKIT.COM - Create a trial system kit.

$ ! There are several parameters which control the kit copy procedure.
$ ! Some or all of these parameters may be specified as input to the proceedure.
$ !  
$ ! The parameters are:
$ !  
$ ! P1 - SOURCE -This parameter specifies the name of the main device/directory
$ !	that contains the [.OBJ] subdirectory containing the new images.
$ ! 	If omitted, the answer is solicited from the user.  If the device is
$ !	not specified, the default is WORK$.  If the directory is not
$ !	specified it is [username].
$ !  
$ ! P2 - TARGET - This parameter specifies the target disk.
$ ! 	 If omitted, the answer is solicited from the user.
$ !  
$ ! P3 - TOPSYS - The top level system directory to use, e.g. SYS0
$ !	 P3 may be explicitly specified as "NONE" to get a "flat" system.
$ !	 If omitted and P2 is specified then TOPSYS is defaulted.
$ !	 If omitted and P2 is solicited, then TOPSYS is solicited as well.
$ !	 When TOPSYS is defaulted, the value "NONE" or "SYS0" is used
$ !	 based on whether the target disk was a "flat" system or had
$ !	 a TOPSYS of SYS0.
$ !
$ ! P4 - CLASSES - The classes of components that are to be moved.
$ !	 This corresponds to those specified to TRIALSYS.COM.
$ !	 Defaults to ALL.
$ !
$ ! P5 - RESD - The result disk corresponding to RESOBJ$.
$ !	 Defaults to RESD$:.
$ !
$ !
$ ! This command procedure creates  a bootblock on the target disk.
$ ! This allows the user to boot the target disk on COMET.  This is
$ ! done by WRITEBOOT, and requires LOG_IO privilege.  Note that this
$ ! is done just before exiting TRIALKIT, so if WRITEBOOT fails, the
$ ! target disk is unharmed and complete.
$ !
$ OLD_PRIVS = F$SETPRV("SYSPRV,LOG_IO")
$ ON CONTROLY THEN GOTO ABORT_2
$ SOURCE=P1
$ TARGET=P2
$ TOPSYS=P3
$ CLASSES=P4
$ RESD=P5
$ IF SOURCE .NES. "" THEN GOTO 15
$ INQUIRE SOURCE -
"Device/directory containing [.OBJ]? (D = WORK$:[username])"
$15:
$ TEMP = F$PARSE(SOURCE,,,"NAME")
$ IF TEMP .NES. "" .AND. TEMP .EQS. SOURCE THEN SOURCE = "[''SOURCE']"
$ TEMP = F$GETJPI("","USERNAME")
$ DEF_INPUT = "WORK$:[''TEMP']"
$ INPDEV = F$PARSE(SOURCE,DEF_INPUT,,"DEVICE")
$ INPDIR = F$PARSE(SOURCE,DEF_INPUT,,"DIRECTORY") - "[" - "<" - "]" - ">"
$ EXE := 'INPDEV'['INPDIR'.OBJ]
$ LIS := 'INPDEV'['INPDIR'.LIS]
$20:
$ IF TARGET .NES. "" THEN GOTO 25
$ TYPE SYS$INPUT:

! This command file assumes that the target disk contains
! a valid VAX/VMS Release 3 binary kit.

$ INQUIRE TARGET - 
"What is the target disk name? (DDCU:)"
$ GOTO 20
$25:
$ TARGET = TARGET - ":" + ":"
$ ALLOCATE 'TARGET
$ MOUNT/DATA_CHECK=(READ,WRITE)/OVERRIDE=ID 'TARGET'
$ ON CONTROLY THEN GOTO ABORT_3
$ !
$ ! Now get the desired top level system directory
$ !
$ DEFAULT_TOPSYS = "NONE"
$ TEMP = F$SEARCH("''TARGET'[0,0]SYS0.DIR;1")
$ IF TEMP .NES. "" THEN DEFAULT_TOPSYS = "SYS0"
$ IF TOPSYS .NES. "" .OR. P2 .NES. "" THEN GOTO 30
$ TYPE SYS$INPUT:

! The default top level system directory is either "NONE" or "SYS0"
! depending on whether the target device has a "flat" system or a
! top level system directory of SYS0.

$ IF F$MODE() .EQS. "BATCH" THEN GOTO 30
$ INQUIRE TOPSYS -
"What is the top level system directory? [default = ''DEFAULT_TOPSYS']"
$30:
$ IF TOPSYS .EQS. "" THEN TOPSYS = DEFAULT_TOPSYS
$ IF TOPSYS .EQS. "NONE" THEN TOPSYS = ""
$ FRONT = "["
$ IF TOPSYS .NES. "" THEN FRONT = "[" + TOPSYS + "."
$ IF F$MODE() .NES. "INTERACTIVE" THEN GOTO 32
$ IF CLASSES .EQS. "" THEN INQUIRE CLASSES -
"What classes do you want? [default = ALL]"
$32:
$ IF CLASSES .EQS. "" THEN CLASSES = "ALL"
$35:
$ IF RESD .NES. "" THEN GOTO 40
$ IF F$MODE() .NES. "INTERACTIVE" THEN GOTO 36
$ INQUIRE RESD -
"What is the result disk? [default = RESD$:]"
$36:
$ IF RESD .EQS. "" THEN RESD = "RESD$:"
$ IF F$LOCATE(":",RESD) .EQS. F$LENGTH(RESD) THEN RESD = RESD + ":"
$40:
$ COPY := "COPY/PROT=(SY:RWED,OW:RWED,GR:RWED,WO:RE)"
$ !
$ ! Files needing special handling
$ !
$ DELETE 'TARGET''FRONT'SYSEXE]SYSBOOT.EXE;*
$ COPY/CONTIG/TRUNC 'EXE'SYSBOOT.EXE 'TARGET''FRONT'SYSEXE]
$ !
$ ! Write a boot block on the target disk.
$ !
$ SET DEFAULT 'FRONT'SYSEXE]
$ COPY/CONTIG/TRUNC 'EXE'VMB.EXE 'TARGET'
$ PURGE 'TARGET'VMB.EXE
$ ASSIGN/USER 'TARGET''FRONT'SYSEXE] TARGET_DISK
$ RUN SYS$SYSTEM:WRITEBOOT
TARGET_DISK:VMB.EXE
1
200
$ !
$ !  Now get the files to be moved.
$ !
$ OPEN/READ/SHARE FACILITIES RESOBJ$:VMSNEWBLD.DAT
$ READ/KEY="AAINFO "/INDEX=1 FACILITIES RECORD
$ GOTO 70
$ANOTHER_FACILITY:
$ READ/END=END_OF_FILE FACILITIES RECORD
$70:
$ TEMP = F$EXTRACT(16,16,RECORD)
$ TEMP = F$EXTRACT(0,F$LOCATE(" ",TEMP),TEMP)
$ IF TEMP .NES. "AAINFO" THEN  GOTO END_OF_FILE
$ IF F$LOCATE("/EXEC=",RECORD) .EQ. F$LENGTH(RECORD) THEN GOTO SKIP_FACILITY
$ FACILITY = F$EXTRACT(0,(F$LOCATE(" ",RECORD)),RECORD)
$ CLASS = F$EXTRACT((F$LOCATE("/EXEC=",RECORD)+6),F$LENGTH(RECORD),RECORD)
$ CLASS = F$EXTRACT(0,F$LOCATE(" ",CLASS),CLASS)
$ DIRECTORY/OUTPUT=SYS$LOGIN:FACILITY.TMP/COL=1 -
	'RESD'['FACILITY'.OBJ]*.EXE;,'RESD'['FACILITY'.OBJ]*.STB
$ OPEN/READ FILES SYS$LOGIN:FACILITY.TMP
$ANOTHER_IMAGEFILE:
$ READ/END=1000 FILES RECORD
$ IF F$LOCATE(".EXE;",RECORD) .NE. F$LENGTH(RECORD) THEN GOTO 80
$ IF F$LOCATE(".STB;",RECORD) .EQ. F$LENGTH(RECORD) THEN GOTO ANOTHER_IMAGEFILE
$80:
$ IMAGEFILE = F$EXTRACT(0,(F$LOCATE(";",RECORD)),RECORD)
$ IF (IMAGEFILE .EQS. "VMB.EXE") .OR. (IMAGEFILE .EQS. "SYSBOOT.EXE") THEN -
	GOTO ANOTHER_IMAGEFILE
$ TARGET_DIR = "SYSEXE"
$ IF F$SEARCH("''RESD'[SYSEXE]''IMAGEFILE'") .NES. "" THEN GOTO 90
$ TARGET_DIR = "SYSLIB"
$ IF F$SEARCH("''RESD'[SYSLIB]''IMAGEFILE'") .NES. "" THEN GOTO 90
$ TARGET_DIR = "SYSTEST"
$ IF F$SEARCH("''RESD'[SYSTEST]''IMAGEFILE'") .NES. "" THEN GOTO 90
$ WRITE SYS$OUTPUT "%TRIALKIT-W-FNF, unable to find ", IMAGEFILE, " on ", RESD
$ WRITE SYS$OUTPUT "%TRIALKIT-W-ASSUME,	assumption made that it goes in [.SYSEXE]"
$ TARGET_DIR = "SYSEXE"
$90:
$ SET DEFAULT 'FRONT''TARGET_DIR']
$ DELETE 'TARGET''IMAGEFILE';*
$ IF CLASSES .EQS. "ALL" THEN GOTO 100
$ IF F$LOCATE(CLASS,CLASSES) .EQ. F$LENGTH(CLASSES) THEN GOTO ANOTHER_IMAGEFILE
$100:
$ COPY 'EXE''IMAGEFILE' 'TARGET'
$ GOTO ANOTHER_IMAGEFILE
$1000:
$ CLOSE FILES
$ DELETE SYS$LOGIN:FACILITY.TMP;*
$SKIP_FACILITY:
$ GOTO ANOTHER_FACILITY
$END_OF_FILE:
$ CLOSE FACILITIES
$ !
$ !  Now copy the maps.
$ !
$ SET DEFAULT 'FRONT'SYSEXE]
$ DELETE 'TARGET'SYS.MAP;*,RMS.MAP;*
$ COPY 'LIS'SYS.MAP 'TARGET'
$ COPY 'LIS'RMS.MAP 'TARGET'
$ DELETE 'TARGET'SYSLOA750.MAP;*,SYSLOA780.MAP;*,SYSLOA730.MAP;*
$ COPY 'LIS'SYSLOA730.MAP 'TARGET'
$ COPY 'LIS'SYSLOA750.MAP 'TARGET'
$ COPY 'LIS'SYSLOA780.MAP 'TARGET'
$ DELETE 'TARGET'TTDRIVER.MAP;*
$ COPY 'LIS'TTDRIVER.MAP 'TARGET'
$ !
$ALL_DONE:
$ SET NOON
$ WRITE SYS$OUTPUT "Kit is complete."
$ABORT_3:
$ DISMOUNT/NOUNLOAD 'TARGET'
$ CLOSE FILES
$ CLOSE FACILITIES
$ABORT_2:
$ OLD_PRIVS = F$SETPRV(OLD_PRIVS)
$ABORT_1:
$ SET DEFAULT 'DEFDIR'
