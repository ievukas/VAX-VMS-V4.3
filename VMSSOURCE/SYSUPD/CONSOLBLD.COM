$ !++
$ ! CONSOLBLD.COM	- Build a VMS console medium. Update history at end
$ !				of file.
$ !
$ ! ABSTRACT:	This command procedure will build a VAX family console
$ !		medium on the target device.  This command procedure is
$ !		driven from a data file which specifies which files are
$ !		to be copied to the console medium.
$ !
$ !
$ ! INPUTS:	P1	- Kit type.  Legal types are: 780, 750, 730.
$ !		P2	- Target device. (assumed on line w/ no medium mounted)
$ !		P3	- Source device and directory where console boot
$ !			  command files, microcode files, and diagnostic files
$ !			  (if any) can be found. (DDCU:[DIRECTORY])
$ !		P4	- Source device and directory where VMB.EXE can be
$ !			  found.  (DDCU:[DIRECTORY])  Optional.  Defaults to
$ !			  SYS$SYSROOT:[SYSEXE].
$ !		P5	- Data file spec.  Optional.  Defaults to
$ !			  SYS$UPDATE:'P1'CNSL.DAT
$ !		P6	- Null string to build console media.  "COMPARE" to
$ !			  compare contents of console media with specified
$ !			  console files.
$ !		P7	- If P6 = "COMPARE", then P7 must be the directory
$ !			  spec of a scratch directory.  ALL FILES WILL BE
$ !			  DELETED, but if files are found, you'll be given
$ !			  a chance to back out.
$ !
$ !		SETPRV privilege required.
$ !
$ !
$ ! DATA FILE FORMAT:
$ !
$ !		- Records beginning with "!" are treated as comments.
$ !
$ !		- Records beginning with "$" are executed as DCL commands.
$ !
$ !		- All other records are file names.
$ !
$ !		The data file is responsible for setting the record format
$ !		AND the default directory from which the files are to be
$ !		copied.  This is done by having the appropriate DCL commands
$ !		in the data file.
$ !
$ !
$ ! NOTE:	The console medium for the 11/780, 11/750 and 11/730 must
$ !		have a valid boot block.  This command procedure uses
$ !		WRITEBOOT to write a boot block to the 11/750 medium, and
$ !		RTB to write a boot block to the 11/780 and 11/730 media.
$ !
$ !--
$
$ !
$ ! If this is running as a batch job, make sure all the parameters are
$ ! specified.
$ !
$ IF F$MODE() .NES. "BATCH" THEN GOTO START
$ IF P1 .NES. "" .AND. P2 .NES. "" .AND. P3 .NES. "" THEN GOTO START
$ WRITE SYS$OUTPUT "*** error *** P1 through P3 must be specified"
$ EXIT
$
$START:
$ F_CMP = 0
$ IF P6 .EQS. "COMPARE" THEN F_CMP = 1
$ WRITE SYS$OUTPUT ""
$ IF F_CMP THEN WRITE SYS$OUTPUT "Compare console medium against master files."
$ IF .NOT. F_CMP THEN WRITE SYS$OUTPUT "Create a VMS console medium."
$ WRITE SYS$OUTPUT ""
$ KIT_DONE = 0
$ ON ERROR THEN GOTO CLEAN_UP
$ ON CONTROL_Y THEN GOTO CLEAN_UP
$ KIT = P1
$ TARGET = P2
$ CMDSRC = P3
$ VMBSRC = P4
$ IF .NOT. F_CMP THEN GOTO KIT
$ !For compare purposes, P7 must be specified on command line.  The directory
$ !specified must be empty
$ IF P7 .NES. "" THEN GOTO CHECK_SCRATCH_DIR
$ WRITE SYS$OUTPUT "% For compare purposes, P7 must be specified on command line"
$ GOTO CLEAN_UP
$CHECK_SCRATCH_DIR:
$ SCRATCH_DIR = F$PARSE(P7,"SYS$DISK:")
$ SCRATCH_DIR = F$EXT(0,F$LOC("]",SCRATCH_DIR)+1,SCRATCH_DIR)
$ IF F$SEARCH("''SCRATCH_DIR'*.*") .EQS. "" THEN GOTO KIT
$ WRITE SYS$OUTPUT "% WARNING - ''SCRATCH_DIR' is not empty."
$ DIRECTORY 'SCRATCH_DIR'
$ INQUIRE YN "Do you want to continue (All files in ''SCRATCH_DIR' will be deleted) "
$ IF .NOT. YN THEN GOTO CLEAN_UP
$ DELETE /LOG 'SCRATCH_DIR'*.*;*
$KIT:
$ REQUIRED_PRIVS = "CMKRNL,CMEXEC,LOG_IO,SYSNAM,VOLPRO"
$ SAVED_PRIVS = F$SETPRV(REQUIRED_PRIVS)
$ SAVED_UIC = F$USER()
$ SAVED_DIR = F$TRNLNM("SYS$DISK") + F$DIR()
$ IF .NOT. F_CMP THEN SET UIC [1,4]
$GET_KIT:
$ !
$ ! If P1 was not specified, then prompt for a kit type.
$ !
$ IF KIT .EQS. "" THEN -
  INQUIRE KIT "Which kit do you wish to build (780!750!730)"
$ IF (KIT .EQS. "780") .OR. (KIT .EQS. "750") .OR. (KIT .EQS. "730") THEN -
	GOTO TARGET
$ KIT = ""
$ GOTO GET_KIT
$
$TARGET:
$ !
$ ! If P2 was not specified, then prompt for a target device.
$ !
$ IF TARGET .EQS. "" THEN -
  INQUIRE TARGET "Specify target device (DDCU:)"
$ TARGET = TARGET - ":" + ":"
$
$CMDSRC:
$ !
$ ! If P3 was not specified, then prompt for a source device and directory
$ ! for boot command files, microcode and diagnostic console files.
$ !
$ IF CMDSRC .NES. "" THEN GOTO VMBSRC
$ WRITE SYS$OUTPUT -
"    All boot command files, microcode files, and diagnostic files listed in"
$ WRITE SYS$OUTPUT -
"    data file ''KIT'CNSL.DAT are expected to be in the directory you specify."
$ INQUIRE CMDSRC -
"Directory containing console files (DDCU:[DIRECTORY])"
$
$VMBSRC:
$ !
$ ! If P4 was not specified, use SYS$SYSROOT:[SYSEXE] as the device and
$ ! directory where VMB.EXE, the primary bootstrap file, can be found.
$ !
$ IF VMBSRC .NES. "" THEN GOTO OPEN
$ TOPSYS = F$TRNLNM("SYS$TOPSYS")
$ IF TOPSYS .NES. "" THEN TOPSYS = TOPSYS + "."
$ VMBTEMP = F$TRNLNM("SYS$SYSDEVICE") + "[" + TOPSYS + "SYSEXE" + "]"
$ IF F$MODE() .NES. "INTERACTIVE" THEN GOTO VMBSRC_DEFAULT
$ WRITE SYS$OUTPUT -
"    VMB.EXE, the primary bootstrap image, is expected to be in the"
$ WRITE SYS$OUTPUT -
"    directory you specify next.  The default is ''VMBTEMP'."
$ WRITE SYS$OUTPUT -
"    Just type <RETURN> to select default device and directory."
$ INQUIRE VMBSRC -
"Specify device and directory containing VMB.EXE"
$VMBSRC_DEFAULT:
$ IF VMBSRC .EQS. "" THEN VMBSRC = VMBTEMP
$
$OPEN:
$ !
$ ! Open the data files.
$ !
$ ON CONTROL_Y THEN GOTO CLEAN_UP
$ T1 = CMDSRC
$ IF F_CMP THEN T1 = SCRATCH_DIR
$ SET DEFAULT 'T1'
$ IF P5 .EQS. "" THEN P5 := SYS$UPDATE:'KIT'CNSL.DAT
$ OPEN DATA_FILE 'P5
$ OPEN/WRITE EXCH_FILE SYS$SCRATCH:EXCHANGE.TMP
$
$MOUNT:
$ !
$ ! Mount the TARGET device.  The device is assumed to be on line
$ ! with no medium currently mounted.  The medium is first INITed
$ ! to give it the volume name of "CONSOLE".
$ !
$ ! If the target device is the system console, some
$ ! extra steps must be taken to be sure the console
$ ! is on line and unmounted.  (This is not necessary for
$ ! 11/730 kits, though, since the console TU58 is in a
$ ! different drive than the "user" tu58).
$ !
$ IF F$EXTRACT(0,2,TARGET) .NES. "CS" THEN GOTO CHK_CNSL_DEV
$ RUN SYS$SYSTEM:SYSGEN
CONNECT CONSOLE
$
$CHK_CNSL_DEV:
$ IF .NOT. F$GETDVI(TARGET,"MNT") THEN GOTO FINISH_MOUNT
$ DISMOUNT 'TARGET
$
$FINISH_MOUNT:
$ IF KIT .EQS. "780" THEN CNSL_MEDIUM = "floppy"
$ IF KIT .EQS. "750" .OR. KIT .EQS."730" THEN CNSL_MEDIUM = "TU58 cartridge"
$ WRITE SYS$OUTPUT "Put the ''CNSL_MEDIUM' in the target device, ''TARGET'."
$ INQUIRE NULL "Type <cr> when you are ready to continue"
$ MOUNT/FOR 'TARGET "''KIT' console"
$ IF .NOT. F_CMP THEN -
	EXCHANGE/NOMESSAGE INITIALIZE /SEGMENTS=2 'TARGET "''KIT' console"
$
$
$ ! While the data file is not empty:
$ !	- read a record.
$ !	- if the record is a comment, ignore it.
$ !	- if the record is a DCL command, execute it.
$ !	- if the record is a file name, generate a copy command
$ !	  to copy it to the target device.
$ !
$ ! Write the initial exchange commands now, the copy commands will follow.
$ ! Note:  The $ EXCHANGE "MOUNT" and "DISMOUNT" commands will not affect the
$ !	TARGET device's status as seen by DCL.  They are here for $ EXCHANGE's
$ !	caching scheme only.
$ !
$ WRITE EXCH_FILE "$ EXCHANGE/NOMESSAGE/CACHE"
$ WRITE EXCH_FILE "  MOUNT ",TARGET
$NEXT_RECORD:
$ READ/END_OF_FILE=FINISH_TRANSFER DATA_FILE DATA_RECORD
$ IF "''F$EXTRACT(0,1,DATA_RECORD)'" .EQS. "!" THEN GOTO NEXT_RECORD
$ IF "''F$EXTRACT(0,1,DATA_RECORD)'" .EQS. "$" THEN GOTO EXECUTE_COMMAND
$ FILE_SPEC := 'DATA_RECORD'
$ IF F_CMP THEN GOTO CMP_COPY
$ WRITE EXCH_FILE "  COPY /LOG ",FILE_SPEC,"/RECORD=",EXCH_REC_FMT," ",TARGET
$ GOTO NEXT_RECORD
$
$CMP_COPY:
$ FILE_SPEC = F$PARSE(FILE_SPEC,,,"NAME") + F$PARSE(FILE_SPEC,,,"TYPE")
$ WRITE EXCH_FILE -
    "  COPY /LOG ",TARGET,FILE_SPEC,"/RECORD=",EXCH_REC_FMT," ",SCRATCH_DIR
$ GOTO NEXT_RECORD
$
$EXECUTE_COMMAND:
$ !
$ ! Execute a DCL command record and return to the read loop.
$ !
'DATA_RECORD
$ GOTO NEXT_RECORD
$
$FINISH_TRANSFER:
$ !
$ ! Conclude the exchange commands with an exit, close the file and execute
$ ! the transfers.  Upon completion, delete the temporary command file.
$ !
$ WRITE EXCH_FILE "  DISMOUNT ",TARGET
$ WRITE EXCH_FILE "  EXIT"
$ CLOSE EXCH_FILE
$ @SYS$SCRATCH:EXCHANGE.TMP
$ DELETE SYS$SCRATCH:EXCHANGE.TMP;*
$
$WRITE_BOOTBLK:
$ IF F_CMP THEN GOTO DO_COMPARE
$ !
$ ! Write a bootblock on the medium.  Select the appropriate CPU console image.
$ !
$ IF (KIT .NES. "730") .AND. (KIT .NES. "780") THEN GOTO KIT_750
$ IF KIT .EQS. "730" THEN IMAGE_NAME = "BOOT.EXE"
$ IF KIT .EQS. "780" THEN IMAGE_NAME = "CONSOL.SYS"
$ EXCHANGE/NOMESSAGE COPY /BOOT 'TARGET''IMAGE_NAME'
$ GOTO BOOT_WRTTN
$
$KIT_750:
$ ASSIGN/USER 'TARGET' TARGET_DEVICE
$ MCR WRITEBOOT
TARGET_DEVICE:BOOT58.EXE
1
C000
$
$BOOT_WRTTN:
$ WRITE SYS$OUTPUT "Boot block written."
$ KIT_DONE = 1
$ GOTO CLEAN_UP
$DO_COMPARE:
$ DIF_FOUND = 0
$CMP_LOOP:
$ SET NOON
$ FILE_SPEC = F$SEARCH("''SCRATCH_DIR'*.*")
$ IF FILE_SPEC .EQS. "" THEN GOTO CMP_DONE
$ IF F$LOC("VMB.EXE",FILE_SPEC) .EQ. F$LEN(FILE_SPEC) THEN -
		DIFF /MODE=HEX 'FILE_SPEC' 'CMDSRC'
$ IF F$LOC("VMB.EXE",FILE_SPEC) .NE. F$LEN(FILE_SPEC) THEN -
		DIFF /MODE=HEX 'FILE_SPEC' 'VMBSRC'
$ IF $STATUS .NE. 1 THEN DIF_FOUND = DIF_FOUND + 1
$ GOTO CMP_LOOP
$CMP_DONE:
$ IF DIF_FOUND .EQ. 0 THEN DELETE 'SCRATCH_DIR'*.*;*
$ SET ON
$ IF DIF_FOUND .EQ. 0 THEN GOTO CLEAN_UP
$ WRITE SYS$OUTPUT "% Differences were found, console files not deleted from ''SCRATCH_DIR'"
$
$CLEAN_UP:
$ !
$ ! Do any clean up necessary before exiting.
$ ! If the target device was the system console,
$ ! the origional console medium must be mounted
$ ! to protect it from DERFS.
$ !
$ ON ERROR THEN CONTINUE
$ ON CONTROL_Y THEN CONTINUE
$ IF F$GETDVI(TARGET,"MNT") THEN DISMOUNT 'TARGET
$ IF F$EXTRACT(0,2,TARGET) .NES. "CS" THEN GOTO FINISH_CLEAN_UP
$ IF F$GETSYI("CPU") .EQ. 3 THEN GOTO 730_CONSOLE
$ CONSOLE_DRIVE = "CSA1"
$ WRITE SYS$OUTPUT -
"Please replace the original console medium in the console drive."
$ GOTO REMOUNT_CONSOLE
$
$730_CONSOLE:
$ IF F$GETDVI("CSA2:","MNT") THEN GOTO FINISH_CLEAN_UP
$ CONSOLE_DRIVE = "CSA2"
$
$REMOUNT_CONSOLE:
$ WRITE SYS$OUTPUT -
"The console medium will be mounted /NOWRITE for protection."
$ INQUIRE NULL "Type <cr> when you are ready to continue."
$ MOUNT/FOR/SYS/NOWRITE 'CONSOLE_DRIVE' "VAX console"
$
$FINISH_CLEAN_UP:
$ IF F$TRNLNM("DATA_FILE") .NES. "" THEN CLOSE DATA_FILE
$ IF F$TRNLNM("EXCH_FILE") .NES. "" THEN CLOSE EXCH_FILE
$ IF .NOT. F_CMP THEN SET UIC 'SAVED_UIC
$ SAVED_PRIVS = F$SETPRV(SAVED_PRIVS)
$ SET DEFAULT 'SAVED_DIR
$ IF KIT_DONE THEN WRITE SYS$OUTPUT "Done."
$ IF .NOT. KIT_DONE THEN -
	WRITE SYS$OUTPUT "Procedure aborted - kit is incomplete."
$ EXIT
$ !++
$ !
$ ! AUTHOR:	Steve Jeffreys		20-FEB-1980
$ !
$ ! MODIFIED BY:
$ !
$ !	V03-001	MTR0001		Mike Rhodes		11-May-1983
$ !		Convert file transfer image from c-mode FLX.EXE to native mode
$ !		$ EXCHANGE/NOMESSAGE/CACHE.  Also, optimized the copy algorithm.
$ !
$ !	V03-002	RAS0175		Ron Schaefer		 1-Aug-1983
$ !		Convert to new logical name formats.
