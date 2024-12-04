$	GOTO BEGIN
$ !++
$ ! BOOTBLDR.COM  - Command file to create 11/782 console floppies
$ !
$ ! AUTHOR:	Paul DeStefano		11-Jul-1984
$ !
$ ! ABSTRACT:	This command procedure creates a new console floppy for a
$ !		multiprocessor system by modifying the command procedures from
$ !		an existing 11/780 console floppy to use MA780 multi-port
$ !		memory.  The original console floppy will not be changed in any
$ !		way.  A list of files to be modified will be made by selecting
$ !		the command procedures with the following naming conventions:
$ !
$ !					D%%BOO.CMD
$ !					D%%GEN.;
$ !					D%%XDT.;
$ !					CIBOO.CMD
$ !					CIGEN.;
$ !					CIXDT.;
$ !					RESTAR.CMD
$ !					CS1BOO.CMD
$ !					CS1GEN.;
$ !
$ !		Diagnostic Supervisor bootstrap files and Interleaved memory
$ !		bootstrap files will not be reproduced on the new floppy.  This
$ !		includes any files with the following naming conventions:
$ !
$ !					SM%BOO.%%%
$ !					SB%BOO.%%%
$ !					SR%BOO.%%%
$ !					%%%%%%.ILV
$ !
$ !		All other files are copied without modification.
$ !		A new DEFBOO.CMD will be created for the system device.
$ !		RMEM.;1 will be created so that the system can be reset to run
$ !		without the MA780 memory.
$ !
$ !
$ ! INPUTS:	P1	- Specifies the operation to perform.  Optional.
$ !
$ !			  BUILD for building VAX 11/782 floppies from a
$ !			  previously created memory configuration file.
$ !
$ !			  CONFIGURE for building a memory configuration
$ !			  data file.
$ !
$ !			  Defaults to building VAX 11/782 floppies by
$ !			  prompting the user for all necessary information.
$ !
$ !			  When using both the BUILD mode and the default mode,
$ !			  the user should be familiar with the memory
$ !			  configuration of the system, and should know the TR
$ !			  numbers and the amount of memory on each of the
$ !			  memory controllers.  The user should also know the
$ !			  TR number of the UBA controller for the unibus boot
$ !			  devices.
$ !
$ !			  See the VAX - 11/782 users guide for a description
$ !			  of the question asked by BOOTBLDR.
$ !
$ !		P2	- Memory configuration data file spec.
$ !
$ !			  If the operation is BUILD, P2 specifies the name of
$ !			  the memory configuration data file to be used by
$ !			  BOOTBLDR.  
$ !
$ !			  If the operation is CONFIGURE, P2 specifies the name
$ !			  of a memory configuration data file to be created by
$ !			  BOOTBLDR.  The user will be prompted for the memory
$ !			  configuration as described above.
$ !
$ !		P3	- Floppy disk drive to use.  (Format is DDU:)
$ !			  If not specified during a BUILD operation, BOOTBLDR
$ !			  will prompt for the device to use.
$ !
$ ! MEMORY CONFIGURATION DATA FILE FORMAT:
$ !
$ !		- Records beginning with "!" are treated as comments.
$ !
$ !		- All other records are used to describe the memory
$ !		  configuration.  These records become inputs to BOOTBLDR's
$ !		  inquiries regarding the memory configuration.
$ !
$ ! NOTE:	This procedure requires interaction from the user and can not
$ !		be run as a BATCH job.
$ !
$ !		MS780E memory must be addressed on megabyte boundaries.
$ !		Because of this, it is possible to have gaps between memory.
$ !		For example, if the System has:
$ !
$ !			1.5 megabytes of MA780 memory
$ !			1 megabyte MS780E memory
$ !
$ !		Boot command files will be built with the MA780 memory starting
$ !		at address 0 and the MS780E memory starting at 2 MEG leaving a
$ !		.5 megabyte gap between the memory.  BOOTBLDR will try to
$ !		resolve these gaps whenever possible.
$ !
$ !		This procedure will create a temporary subdirectory
$ !		[.TEMPBOOT].  It is assumed that this directory does not
$ !		already exist.
$ !
$ !--
$BEGIN:
$	WRITE SYS$OUTPUT ""
$	WRITE SYS$OUTPUT-
 "    VAX 11/782 Multiprocessor Bootstrap Command Procedure Builder"
$	WRITE SYS$OUTPUT ""
$
$	IF F$MODE() .EQS. "BATCH" THEN GOTO NO_BATCH
$
$	DIRECTORY	:= DIRECTORY
$	SET		:= SET
$	RUN		:= RUN
$	MOUNT		:= MOUNT
$	DISMOUNT	:= DISMOUNT
$	CREATE		:= CREATE
$	DELETE		:= DELETE
$	PURGE		:= PURGE
$	COPY		:= COPY
$	INIT		:= INIT
$	DEFINE		:= DEFINE
$	ANALYZE		:= ANALYZE
$	EXCHANGE	:= EXCHANGE
$
$	PRIMARY		:= TRUE
$	ATTACHED	:= FALSE
$	DIR_CREATED	:= FALSE
$	CONSOLE_MOUNTED	:= FALSE
$	DIR_FILE_OPEN	:= FALSE
$	EXCH_FILE_OPEN	:= FALSE
$	NOMOD_DIR_OPEN	:= FALSE
$	MOD_DIR_OPEN	:= FALSE
$	OLD_FILE_OPEN	:= FALSE
$	NEW_FILE_OPEN	:= FALSE
$	DATA_FILE_OPEN	:= FALSE
$	CONFIG_NOT_DONE	:= FALSE
$	USE_LOCAL	:= FALSE
$	TOLD		:= FALSE
$
$ !
$ ! Mode 1 = Build floppies by prompting user.
$ ! Mode 2 = Build floppies from data file.
$ ! Mode 3 = Create data file.
$ !
$	MODE = 3
$
$	ON CONTROL_Y THEN GOTO BOTH_DONE
$	ON CONTROL_C THEN GOTO BOTH_DONE
$
$	IF F$EXTRACT(0,1,P1) .NES. "C" THEN GOTO BUILD
$	MODE = 3
$	IF P2 .EQS. "" THEN INQUIRE P2-
	"Enter output filespec for memory configuration data file"
$	ON ERROR THEN GOTO BOTH_DONE
$	IF F$LOCATE(".",P2) .EQ. F$LEN(P2) THEN P2 = P2 + ".DAT"
$	OPEN/WRITE DATA_FILE 'P2
$	ON ERROR THEN CONTINUE
$	CONFIG_NOT_DONE	:= TRUE
$	WRITE DATA_FILE "!			Memory Configuration Data File"
$	WRITE DATA_FILE "!"
$	WRITE DATA_FILE "!			  for use with BOOTBLDR.COM"
$	WRITE DATA_FILE "!"
$	WRITE DATA_FILE "!"
$	WRITE DATA_FILE "! Primary processor memory configuration:"
$	WRITE DATA_FILE "!"
$	GOTO BUILD1
$
$BUILD:					! Determine if input from user or file.
$
$	MODE = 1
$
$	SAVEDEF		:= 'F$DIRECTORY()'
$	SAVED_PRIVS = F$SETPRV("CMKRNL,LOG_IO,VOLPRO")
$	SAVED_UIC = F$USER()
$	SET UIC [1,4]
$
$	IF F$EXTRACT(0,1,P1) .NES. "B" THEN GOTO START
$	MODE = 2
$	IF P2 .EQS. "" THEN INQUIRE P2-
	"Enter input filespec for memory configuration data file"
$	IF F$LOCATE(".",P2) .EQ. F$LEN(P2) THEN P2 = P2 + ".DAT"
$	ON ERROR THEN GOTO BOTH_DONE
$	OPEN/READ DATA_FILE 'P2
$	ON ERROR THEN CONTINUE
$
$BUILD1:
$
$	DATA_FILE_OPEN	:= TRUE
$
$START:
$
$	MAX_CNTRLRS = 6			! Six controllers max.
$	END_MA = 0			! Starting address for first MS780%
$					!  controller.
$
$INIT_VAR:				! Start for attached processor pass.
$
$	END_MS = 0			! Starting address for first MA780.
$					!  (used for creating RMEM)
$
$	COUNT = 0
$
$INIT_VAR1:
$
$	COUNT = COUNT + 1
$	IF COUNT .GT. 6 THEN GOTO INIT_VAR3
$	IF PRIMARY THEN GOTO INIT_VAR2
$	IF MEM_TYPE'COUNT .EQS. "MA780" THEN GOTO INIT_VAR1
$
$INIT_VAR2:
$
$	MEM_TYPE'COUNT	:= ""
$	MEM_TR'COUNT = 0
$	GOTO INIT_VAR1
$
$INIT_VAR3:
$
$	CNTRLR = 1			! Controller we're currently processing.
$
$GET_MEM:				! Get the memory configuration.
$
$	IF ATTACHED .AND. MEM_TYPE'CNTRLR .EQS. "MA780" THEN GOTO GET_NEXT_MEM
$	IF MODE .NE. 2 THEN GOTO GET_MEM2
$
$GET_MEM1:				! Get memory type from data file.
$
$	READ/END_OF_FILE=DATA_FILE_ERROR DATA_FILE MEM_TYPE'CNTRLR
$	IF F$EXTRACT(0,1,MEM_TYPE'CNTRLR) .EQS. "!" THEN GOTO GET_MEM1
$	GOTO GET_MEM3
$
$GET_MEM2:				! Get memory type from user.
$
$	WRITE SYS$OUTPUT ""
$	IF PRIMARY THEN INQUIRE MEM_TYPE'CNTRLR-
	"Enter memory type (MA780, MS780A, MS780C, MS780E or <RETURN> to end)"
$	IF ATTACHED THEN INQUIRE MEM_TYPE'CNTRLR-
	"Enter memory type (MS780A, MS780C, MS780E or <RETURN> to end)"
$
$GET_MEM3:				! Make sure memory type is valid.
$
	IF MEM_TYPE'CNTRLR .EQS. "" THEN GOTO GET_MEM_END
$	IF ATTACHED THEN GOTO GET_MEM4
	IF MEM_TYPE'CNTRLR .EQS. "MA780"-
		.OR. MEM_TYPE'CNTRLR .EQS. "MS780A"-
		.OR. MEM_TYPE'CNTRLR .EQS. "MS780C"-
		.OR. MEM_TYPE'CNTRLR .EQS. "MS780E" THEN GOTO ASK_TR
$	GOTO GET_MEM7
$
$GET_MEM4:
$
$	IF MEM_TYPE'CNTRLR .EQS. "MS780A"-
		.OR. MEM_TYPE'CNTRLR .EQS. "MS780C"-
		.OR. MEM_TYPE'CNTRLR .EQS. "MS780E" THEN GOTO ASK_TR
$	IF MEM_TYPE'CNTRLR .EQS. "MA780" THEN GOTO GET_MEM5
$	GOTO GET_MEM6
$
$GET_MEM5:				! MA780 must be same on both processors.
$
$	WRITE SYS$OUTPUT-
	 "MA780 memory is assumed to be the same as the primary."
$
$GET_MEM6:
$
$	WRITE SYS$OUTPUT-
	"Illegal memory type - must be MS780A, MS780C, or MS780E"
$	GOTO GET_MEM_ERROR
$
$GET_MEM7:
$
$	WRITE SYS$OUTPUT-
	"Illegal memory type - must be MA780, MS780A, MS780C, or MS780E"
$
$GET_MEM_ERROR:
$
$	IF MODE .NE. 2 THEN GOTO GET_MEM2
$	GOTO DATA_FILE_ERROR
$
$ASK_TR:
$
$	IF MODE .EQ. 3 THEN WRITE DATA_FILE MEM_TYPE'CNTRLR
$	IF MODE .NE. 2 THEN GOTO ASK_TR2
$
$ASK_TR1:				! Get TR number from data file.
$
$	READ/END_OF_FILE=DATA_FILE_ERROR DATA_FILE MEM_TR'CNTRLR
$	IF F$EXTRACT(0,1,MEM_TR'CNTRLR) .EQS. "!" THEN GOTO ASK_TR1
$	GOTO ASK_TR3
$
$ASK_TR2:				! Get TR number from user.
$
$	INQUIRE MEM_TR'CNTRLR "Enter TR level (1 through 6)"
$
$ASK_TR3:				! Make sure TR number is 1 to 6.
$
$	IF MEM_TR'CNTRLR .GT. 0 .AND. MEM_TR'CNTRLR .LT. 7 THEN GOTO ASK_TR4
$	WRITE SYS$OUTPUT "TR number must be in the range of 1 to 6"
$	IF MODE .NE. 2 THEN GOTO ASK_TR2
$	GOTO DATA_FILE_ERROR
$
$ASK_TR4:				! Make sure TR isn't already in use.
$
$	COUNT = 0
$
$ASK_TR5:
$
$	COUNT = COUNT + 1
$	IF COUNT .EQ. CNTRLR THEN GOTO ASK_MEM_AMT
$	IF MEM_TR'CNTRLR .NE. MEM_TR'COUNT THEN GOTO ASK_TR5
$	WRITE SYS$OUTPUT-
	"Illegal memory configuration - TR numbers must be unique."
$	IF MODE .NE. 2 THEN GOTO ASK_TR2
$	GOTO DATA_FILE_ERROR
$
$ASK_MEM_AMT:
$
$	IF MODE .EQ. 3 THEN WRITE DATA_FILE MEM_TR'CNTRLR
$ !
$ ! Calculate base address of memory controller.
$ !
$	MEM_ADRS'CNTRLR = %X20000000+%X2000*MEM_TR'CNTRLR
$
$	IF MODE .NE. 2 THEN GOTO ASK_MEM_AMT2
$
$ASK_MEM_AMT1:
$
$	READ/END_OF_FILE=DATA_FILE_ERROR DATA_FILE MEM_AMOUNT'CNTRLR
$	IF F$EXTRACT(0,1,MEM_AMOUNT'CNTRLR) .EQS. "!" THEN GOTO ASK_MEM_AMT1
$	GOTO CONVERT_MEM
$
$ASK_MEM_AMT2:
$
$	IF MEM_TYPE'CNTRLR .EQS. "MS780E" THEN GOTO ASK_MEM_AMT3
$	WRITE SYS$OUTPUT-
	"Enter amount of memory for this controller in .25 megabyte"
$	INQUIRE MEM_AMOUNT'CNTRLR-
	"increments (for example, for 512 kilobytes, enter .5)"
$	GOTO CONVERT_MEM
$
$ASK_MEM_AMT3:
$
$	WRITE SYS$OUTPUT-
	"Enter amount of memory for this controller in 1 megabyte"
$	INQUIRE MEM_AMOUNT'CNTRLR-
	"increments (for example, for 4 megabytes, enter 4)"
$
$ !
$ ! Convert Megabytes to hex value
$ !
$
$CONVERT_MEM:
$
$ !
$ ! Extract integer
$ !
$	MEM_INT'CNTRLR = F$EXTRACT(0,F$LOC(".",MEM_AMOUNT'CNTRLR),-
	MEM_AMOUNT'CNTRLR)
$ !
$ ! Extract fraction
$ !
$	MEM_FRACT'CNTRLR = F$EXTRACT(F$LOCATE(".",MEM_AMOUNT'CNTRLR)+1,-
	F$LENGTH(MEM_AMOUNT'CNTRLR)-F$LOCATE(".",MEM_AMOUNT'CNTRLR)+1,-
	MEM_AMOUNT'CNTRLR)
$	IF F$LEN(MEM_FRACT'CNTRLR) .EQ. 1-
	THEN MEM_FRACT'CNTRLR = MEM_FRACT'CNTRLR*10
$ !
$ ! Make sure fraction is valid
$ !
$	IF MEM_TYPE'CNTRLR .EQS. "MS780E" THEN GOTO CONVERT_MEM2
$	IF MEM_FRACT'CNTRLR .EQS. ""-
		.OR. MEM_FRACT'CNTRLR .EQS. "0"-
		.OR. MEM_FRACT'CNTRLR .EQS. "00"-
		.OR. MEM_FRACT'CNTRLR .EQS. "25"-
		.OR. MEM_FRACT'CNTRLR .EQS. "50"-
		.OR. MEM_FRACT'CNTRLR .EQS. "75" THEN GOTO CONVERT_MEM3
$	WRITE SYS$OUTPUT "Memory amount must be in .25 megabyte increments."
$	GOTO CONVERT_MEM_ERROR
$
$CONVERT_MEM2:
$
$	IF MEM_FRACT'CNTRLR .EQS. ""-
		.OR. MEM_FRACT'CNTRLR .EQS. "0"-
		.OR. MEM_FRACT'CNTRLR .EQS. "00" THEN GOTO CONVERT_MEM3
$	WRITE SYS$OUTPUT "Memory amount must be in 1 megabyte increments."
$	GOTO CONVERT_MEM_ERROR
$
$CONVERT_MEM3:
$
$	IF MEM_TYPE'CNTRLR .EQS. "MS780C" THEN GOTO CONVERT_MEM4
$	IF MEM_TYPE'CNTRLR .EQS. "MS780E" THEN GOTO CONVERT_MEM5
$	IF MEM_TYPE'CNTRLR .EQS. "MA780" THEN GOTO CONVERT_MEM6
$	IF MEM_INT'CNTRLR .LT. 1 .OR.-
	MEM_INT'CNTRLR .EQS. "1" .AND. MEM_FRACT'CNTRLR .EQS. "" .OR.-
	MEM_INT'CNTRLR .EQS. "1" .AND. MEM_FRACT'CNTRLR .EQS. "0" .OR.-
	MEM_INT'CNTRLR .EQS. "1" .AND. MEM_FRACT'CNTRLR .EQS. "00"-
	THEN GOTO CONVERT_MEM7
$	WRITE SYS$OUTPUT "Memory amount must not exceed 1 megabytes per MS780A"
$	GOTO CONVERT_MEM_ERROR
$
$CONVERT_MEM4:
$	IF MEM_INT'CNTRLR .LT. 4 .OR.-
	MEM_INT'CNTRLR .EQS. "4" .AND. MEM_FRACT'CNTRLR .EQS. "" .OR.-
	MEM_INT'CNTRLR .EQS. "4" .AND. MEM_FRACT'CNTRLR .EQS. "0" .OR.-
	MEM_INT'CNTRLR .EQS. "4" .AND. MEM_FRACT'CNTRLR .EQS. "00"-
	THEN GOTO CONVERT_MEM7
$	WRITE SYS$OUTPUT "Memory amount must not exceed 4 megabytes per MS780C"
$	GOTO CONVERT_MEM_ERROR
$
$CONVERT_MEM5:
$
$	IF MEM_INT'CNTRLR .LT. 16 .OR.-
	MEM_INT'CNTRLR .EQS. "16" .AND. MEM_FRACT'CNTRLR .EQS. "" .OR.-
	MEM_INT'CNTRLR .EQS. "16" .AND. MEM_FRACT'CNTRLR .EQS. "0" .OR.-
	MEM_INT'CNTRLR .EQS. "16" .AND. MEM_FRACT'CNTRLR .EQS. "00"-
	THEN GOTO CONVERT_MEM7
$	WRITE SYS$OUTPUT-
	"Memory amount must not exceed 16 megabytes per MS780E"
$	GOTO CONVERT_MEM_ERROR
$
$CONVERT_MEM6:
$
$	IF MEM_INT'CNTRLR .LT. 2 .OR.-
	MEM_INT'CNTRLR .EQS. "2" .AND. MEM_FRACT'CNTRLR .EQS. "" .OR.-
	MEM_INT'CNTRLR .EQS. "2" .AND. MEM_FRACT'CNTRLR .EQS. "0" .OR.-
	MEM_INT'CNTRLR .EQS. "2" .AND. MEM_FRACT'CNTRLR .EQS. "00"-
	THEN GOTO CONVERT_MEM7
$	WRITE SYS$OUTPUT "Memory amount must not exceed 2 megabytes per MA780"
$
$CONVERT_MEM_ERROR:
$
$	IF MODE .NE. 2 THEN GOTO ASK_MEM_AMT2
$	GOTO DATA_FILE_ERROR
$
$CONVERT_MEM7:
$
$	IF MODE .EQ. 3 THEN WRITE DATA_FILE MEM_AMOUNT'CNTRLR
$ !
$ ! Convert memory amount to starting address.
$ !
$	MEM'CNTRLR = MEM_INT'CNTRLR*%X100000+MEM_FRACT'CNTRLR/25*%X40000
$ !
$ ! Calculate the address following all of the MA780 (and MS780% for RMEM) 
$ !
$	IF MEM_TYPE'CNTRLR .EQS. "MA780" THEN END_MA = END_MA+MEM'CNTRLR
$	IF MEM_TYPE'CNTRLR .EQS. "MS780A"-
		.OR. MEM_TYPE'CNTRLR .EQS. "MS780C"-
		.OR. MEM_TYPE'CNTRLR .EQS. "MS780E"-
		THEN END_MS = END_MS+MEM'CNTRLR
$
$GET_NEXT_MEM:
$
$	IF CNTRLR .EQ. MAX_CNTRLRS THEN GOTO GET_MEM_END
$	CNTRLR = CNTRLR + 1
$	GOTO GET_MEM
$
$GET_MEM_END:
$
$	IF MODE .EQ. 3 .AND. CNTRLR .NE. MAX_CNTRLRS THEN WRITE DATA_FILE ""
$	IF ATTACHED .AND. MODE .EQ. 3 THEN GOTO CONFIG_DONE
$	WRITE SYS$OUTPUT ""
$	IF ATTACHED THEN GOTO GET_NOMOD2
$ !
$ ! Determine if local memory should be used.
$ !
$
$GET_USE_LOC:
$
$	IF MODE .NE. 2 THEN GOTO GET_USE_LOC2
$
$GET_USE_LOC1:
$
$	READ/END_OF_FILE = DATA_FILE_ERROR DATA_FILE USE_LOCAL
$	IF F$EXTRACT(0,1,USE_LOCAL) .EQS. "!" THEN GOTO GET_USE_LOC1
$	GOTO GET_USE_LOC3
$
$GET_USE_LOC2:
$
$	WRITE SYS$OUTPUT-
	"Would you like the bootstrap command files to boot the system using"
$	WRITE SYS$OUTPUT-
	"local (MS780A, MS780C, or MS780E) memory as well as shared (MA780)
$	INQUIRE USE_LOCAL "memory <YES or [NO]>"
$	IF MODE .NE. 3 THEN GOTO GET_USE_LOC3
$	WRITE DATA_FILE "!"
$	WRITE DATA_FILE "! Use local memory:"
$	WRITE DATA_FILE "!"
$	WRITE DATA_FILE USE_LOCAL
$
$GET_USE_LOC3:
$
$ !
$ ! Determine the TR level of the UBA.  The UBA is assumed to be at TR level
$ ! three, or one level higher than the highest memory controller.
$ !
$	COUNT = 0
$	UBA_TR = 3
$
$GET_UBA_TR:
$
$	COUNT = COUNT + 1
$	IF COUNT .GT. CNTRLR THEN GOTO GET_UBA_TR1
$	IF MEM_TR'COUNT .GT. UBA_TR-
		.OR. MEM_TR'COUNT .EQ. UBA_TR THEN UBA_TR = MEM_TR'COUNT + 1
$	GOTO GET_UBA_TR
$
$GET_UBA_TR1:
$
$	IF MODE .NE. 2 THEN GOTO GET_UBA_TR3
$
$GET_UBA_TR2:
$
$	READ/END_OF_FILE = DATA_FILE_ERROR DATA_FILE UBATR
$	IF F$EXTRACT(0,1,UBATR) .EQS. "!" THEN GOTO GET_UBA_TR2
$	GOTO GET_UBA_TR4
$
$GET_UBA_TR3:
$
$	WRITE SYS$OUTPUT ""
$	WRITE SYS$OUTPUT-
	"The Unibus Adapter (UBA) is assumed to be at TR level ",UBA_TR
$	INQUIRE UBATR-
	"Enter the TR level of the UBA  (Enter <RETURN> to default)"
$
$GET_UBA_TR4:
$
$	IF UBATR .NES. "" THEN UBA_TR = UBATR
$	IF MODE .NE. 3 THEN GOTO GET_MBA_TR
$	WRITE DATA_FILE "!"
$	WRITE DATA_FILE "! UBA TR level:"
$	WRITE DATA_FILE "!"
$	WRITE DATA_FILE UBA_TR
$
$GET_MBA_TR:
$
$	MBA_TR = 8
$	IF MODE .NE. 2 THEN GOTO GET_MBA_TR2
$
$GET_MBA_TR1:
$
$	READ/END_OF_FILE = DATA_FILE_ERROR DATA_FILE MBATR
$	IF F$EXTRACT(0,1,MBATR) .EQS. "!" THEN GOTO GET_MBA_TR1
$	GOTO GET_MBA_TR3
$
$GET_MBA_TR2:
$
$	WRITE SYS$OUTPUT ""
$	WRITE SYS$OUTPUT-
	"The Massbus Adapter (MBA) is assumed to be at TR level ",MBA_TR
$	INQUIRE MBATR-
	"Enter the TR level of the MBA   (Enter <RETURN> to default)"
$
$GET_MBA_TR3:
$
$	IF MBATR .NES. "" THEN MBA_TR = MBATR
$	IF MODE .NE. 3 THEN GOTO GET_DEFBOO
$	WRITE DATA_FILE "!"
$	WRITE DATA_FILE "! MBA TR level:"
$	WRITE DATA_FILE "!"
$	WRITE DATA_FILE MBA_TR
$
$GET_DEFBOO:
$
$ !
$ ! Get the name of the default boot file for SET DEFBOO.CMD
$ !
$	IF MODE .NE. 2 THEN GOTO GET_DEFBOO2
$
$GET_DEFBOO1:
$
$	READ/END_OF_FILE=DATA_FILE_ERROR DATA_FILE NAME
$	IF F$EXTRACT(0,1,NAME) .EQS. "!" THEN GOTO GET_DEFBOO1
$	GOTO GET_DEFBOO3
$
$GET_DEFBOO2:
$
$	WRITE SYS$OUTPUT ""
$	WRITE SYS$OUTPUT -
	"Enter the name of the default boot command procedure (DEFBOO.CMD)"
$	INQUIRE NAME -
	"to be used when booting the system.  (Default is DB0BOO.CMD)"
$
$GET_DEFBOO3:
$
$	IF NAME .EQS. "" THEN NAME:= "DB0BOO.CMD"
$	IF MODE .NE. 3 THEN GOTO GET_DEV
$	WRITE DATA_FILE "!"
$	WRITE DATA_FILE "! Default boot command procedure:"
$	WRITE DATA_FILE "!"
$	WRITE DATA_FILE NAME
$	WRITE DATA_FILE "!"
$	WRITE DATA_FILE "! Attached processor memory configuration:"
$	WRITE DATA_FILE "!"
$	WRITE SYS$OUTPUT ""
$	WRITE SYS$OUTPUT ""
$	GOTO PRIM_MODE3_DONE
$
$GET_DEV:
$
$	IF P3 .EQS. "" THEN GOTO GET_DEV1
$	DEV := 'P3
$	GOTO GET_DEV2
$
$GET_DEV1:
$
$	WRITE SYS$OUTPUT ""
$	INQUIRE DEV "Enter the name of the floppy disk drive you want to use"
$
$GET_DEV2:
$
$	IF F$LOC(":",DEV) .EQ. F$LENGTH(DEV) THEN DEV := 'DEV':
$	IF DEV .EQS. "CS1:" .OR. DEV .EQS. "CSA1:" THEN GOTO CONNECT
$	IF F$LOC("DY",DEV) .NE. F$LENGTH(DEV) THEN GOTO CONNECT1
$	WRITE SYS$OUTPUT "Please enter drive name in the format ddu: or ddcu: ."
$	WRITE SYS$OUTPUT "For example, CS1:, CSA1:, DY0:, DYA1: ."
$	GOTO GET_DEV1
$
$CONNECT:
$
$	ON ERROR THEN GOTO BOTH_DONE
$	RUN SYS$SYSTEM:SYSGEN
CONNECT CONSOLE
$	ON ERROR THEN CONTINUE
$
$CONNECT1:
$
$	WRITE SYS$OUTPUT ""
$	WRITE SYS$OUTPUT "Insert original 11/780 console floppy in ",DEV,"."
$	INQUIRE Q  "Ready to continue? (YES or NO)"
$	IF F$EXTRACT(0,1,Q) .NES. "Y" THEN GOTO CONNECT1
$	WRITE SYS$OUTPUT ""
$	ON ERROR THEN CONTINUE
$	MOUNT 'DEV'/FOR/NOWRITE
$	CONSOLE_MOUNTED	:= TRUE
$ !
$ ! Create a temporary subdirectory and copy all files to the directory.
$ !
$
$CRE_DIR:
$
$	CREATE/DIRECTORY [.TEMPBOOT]
$	STAT = $STATUS .AND. 7
$	SET DEFAULT [.TEMPBOOT]
$	DIR_CREATED	:= TRUE
$	PRES_DIR = F$DIRECTORY()
$	IF STAT .EQ. 1 THEN GOTO CRE_DIR2
$	WRITE SYS$OUTPUT "All files in ",PRES_DIR," will be deleted."
$	INQUIRE CRE_QUES "Ready to continue? (YES or NO)"
$	IF F$EXTRACT(0,1,CRE_QUES) .EQS. "Y" THEN GOTO CRE_DIR1
$	DIR_CREATED	:= FALSE
$	GOTO BOTH_DONE
$
$CRE_DIR1:
$	DELETE *.*;*/LOG
$
$CRE_DIR2:
$
$	ON ERROR THEN GOTO BOTH_DONE
$	EXCHANGE/NOMESSAGE DIRECTORY/OUTPUT=CONDIR.TMP/COLUMNS=1 'DEV'
$	ON ERROR THEN CONTINUE
$	WRITE SYS$OUTPUT ""
$	WRITE SYS$OUTPUT "Copying console floppy to temporary directory."
$	OPEN/READ DIR_FILE CONDIR.TMP
$	DIR_FILE_OPEN	:= TRUE
$	OPEN/WRITE EXCH_FILE EXCHANGE.TMP
$	EXCH_FILE_OPEN := TRUE
$	WRITE EXCH_FILE "$ EXCHANGE/NOMESSAGE"
$
$NEXT_DIR:
$
$	READ/END_OF_FILE=DIR_END DIR_FILE DIR_RECORD
$ !
$ ! Ignore all records other than file names.
$ !
$	IF F$LOC(".",DIR_RECORD) .EQ. F$LEN(DIR_RECORD) .OR.-
	F$LOC("-",DIR_RECORD) .EQ. F$LEN(DIR_RECORD) THEN GOTO NEXT_DIR
$	FILE_NAME := 'F$EXTRACT(2,10,DIR_RECORD)
$ !
$ ! Ignore diagnostic supervisor boot files (SM%BOO.%%%, SR%BOO.%%%, or
$ ! SB%BOO.%%%) and interleave mode files (%%%%%%.ILV).  Ignore all WCS
$ ! files except WCS%%%.PAT and PAT%%%.WCS.
$ !
$	DOT = F$LOCATE (".", FILE_NAME)
$	IF F$EXTRACT(0,3,FILE_NAME) .EQS. "WCS"-
		.AND. F$EXTRACT(DOT+1,3,FILE_NAME) .NES. "PAT"-
		THEN GOTO NEXT_DIR
$	IF F$EXTRACT(DOT+1,3,FILE_NAME) .EQS. "PAT"-
		.AND. F$EXTRACT(0,3,FILE_NAME) .NES. "WCS" THEN GOTO NEXT_DIR
$	IF F$EXTRACT(DOT+1,3,FILE_NAME) .EQS. "ILV" THEN GOTO NEXT_DIR
$	IF F$EXTRACT(3,3,FILE_NAME) .NES. "BOO" THEN GOTO NEXT_DIR1
$	IF F$EXTRACT(0,2,FILE_NAME) .EQS. "SM"-
		.OR. F$EXTRACT(0,2,FILE_NAME) .EQS. "SR"-
		.OR. F$EXTRACT(0,2,FILE_NAME) .EQS. "SB" THEN GOTO NEXT_DIR

$ !
$ ! Copy all files with extentions .PAT, .BIN, .EXE, or .SYS in image mode.
$ !
$
$NEXT_DIR1:
$
$	EXCH_REC_FMT := "STREAM"
$	IF F$EXTRACT(DOT+1,3,FILE_NAME) .EQS. "PAT"-
		.OR. F$EXTRACT(DOT+1,3,FILE_NAME) .EQS. "BIN"-
		.OR. F$EXTRACT(DOT+1,3,FILE_NAME) .EQS. "EXE"-
		.OR. F$EXTRACT(DOT+1,3,FILE_NAME) .EQS. "SYS"-
		 THEN EXCH_REC_FMT := "FIXED"
$	ON ERROR THEN GOTO BOTH_DONE
$	WRITE EXCH_FILE "  COPY ",DEV,FILE_NAME,"/RECORD=",EXCH_REC_FMT," *"
$	ON ERROR THEN CONTINUE
$	GOTO NEXT_DIR
$
$DIR_END:
$
$	WRITE EXCH_FILE "  EXIT"
$	CLOSE EXCH_FILE
$	EXCH_FILE_OPEN	:= FALSE
$	CLOSE DIR_FILE
$	DIR_FILE_OPEN	:= FALSE
$	@EXCHANGE.TMP
$	DELETE CONDIR.TMP;*, EXCHANGE.TMP;*
$
$DIR_END1:
$
$	IF F$SEARCH(NAME) .NES. "" THEN GOTO DIR_END2
$
$NO_DEF:
$
$	WRITE SYS$OUTPUT "Unable to locate ",NAME
$	INQUIRE NAME-
	"What is the name of the default bootstrap command procedure"
$	GOTO DIR_END1
$
$DIR_END2:
$
$ !
$ ! Copy a V3.0 VMB.EXE (since this command procedure will only
$ ! work on a V3.0 system, SYS$SYSTEM:VMB.EXE should be V3.0 version).
$ !
$	WRITE SYS$OUTPUT ""
$	WRITE SYS$OUTPUT "Copying VMB.EXE from SYS$SYSTEM."
$	WRITE SYS$OUTPUT-
	" (11/782 requires a V3 or later VMB in order to use MA780 memory.)"
$	COPY SYS$SYSTEM:VMB.EXE *
$	PURGE VMB.EXE
$	DISMOUNT 'DEV'
$	CONSOLE_MOUNTED	:= FALSE
$	WRITE SYS$OUTPUT ""
$	WRITE SYS$OUTPUT "Please remove original floppy from ",DEV,"."
$	IF ATTACHED THEN GOTO GET_NOMOD2
$ !
$ ! Make a DEFBOO command file for the primary processor.
$ !
$	COPY 'NAME' DEFBOO.CMD
$	PURGE DEFBOO.CMD
$ !
$ ! Get a directory of the files to be copied without modification.
$ !
$
$GET_NOMOD:
$
$	DIRECTORY/OUTPUT=NOMODIR.TMP/COLUMNS=1/NOHEAD/NOTRAIL -
	/EXCLUDE=(D*GEN.*,D*XDT.*,D*BOO.CMD,CIBOO.CMD,CIGEN.,CIXDT,-
	RESTAR.CMD,DEFBOO.CMD,CS1BOO.CMD,CS1GEN.,NOMODIR.TMP)
$	GOTO MOUNT_NEW
$
$GET_NOMOD2:
$
$ !
$ ! Duplicate all files for attached.
$ !
$	DIRECTORY/OUTPUT=NOMODIR.TMP/COLUMNS=1/NOHEAD/NOTRAIL/ -
	EXCLUDE=NOMODIR.TMP
$ !
$ ! Now mount the new floppy and check for bad blocks.
$ !
$
$MOUNT_NEW:
$
$	WRITE SYS$OUTPUT ""
$	WRITE SYS$OUTPUT ""
$	IF PRIMARY THEN WRITE SYS$OUTPUT-
	"Creating floppy for primary processor."
$	IF ATTACHED THEN WRITE SYS$OUTPUT-
	"Creating floppy for attached processor."
$
$BAD_DISK:
$
$	WRITE SYS$OUTPUT ""
$	WRITE SYS$OUTPUT "Place a scratch floppy in ",DEV,"."
$
$ASK_READY:
$
$	WRITE SYS$OUTPUT "WARNING - ",DEV," will be initialized."
$	INQUIRE QUES "Ready to continue? (YES or NO)"
$	IF F$EXTRACT(0,1,QUES) .NES. "Y" THEN GOTO ASK_READY
$	WRITE SYS$OUTPUT ""
$	WRITE SYS$OUTPUT ""
$	WRITE SYS$OUTPUT "Note:  Console media must not contain any bad blocks."
$	WRITE SYS$OUTPUT ""
$	WRITE SYS$OUTPUT-
	"Analyzing ",DEV," for defective blocks, please stand by..."
$	ON ERROR THEN GOTO BOTH_DONE
$	INIT_QUAL = ""
$	IF F$GETDVI(DEV,"DEVTYPE") .EQ. %X0B THEN INIT_QUAL = "/DENSITY=SINGLE
$	INIT'INIT_QUAL 'DEV' CONSOLE
$	MOUNT/FOR 'DEV' CONSOLE
$	CONSOLE_MOUNTED	:= TRUE
$	ANALYZE/MEDIA/EXERCISE/LOG 'DEV'
$	IF $SEVERITY THEN GOTO GOOD_DISK
$	DISMOUNT 'DEV'
$	CONSOLE_MOUNTED := FALSE
$	GOTO BAD_DISK
$
$GOOD_DISK:
$
$	ON ERROR THEN GOTO BOTH_DONE
$	EXCHANGE/NOMESSAGE INITIALIZE /SEGMENTS=2 'DEV' CONSOLE
$	ON ERROR THEN CONTINUE
$	WRITE SYS$OUTPUT ""
$ !
$ ! Copy the files that will not be modified to the new console floppy
$ ! Delete them from the temporary directory as they are copied.
$ !
$	WRITE SYS$OUTPUT ""
$	WRITE SYS$OUTPUT "Copying unmodified files to ",DEV,"."
$	WRITE SYS$OUTPUT ""
$	OPEN/READ NOMOD_DIR NOMODIR.TMP
$	NOMOD_DIR_OPEN	:= TRUE
$	OPEN/WRITE EXCH_FILE EXCHANGE.TMP
$	EXCH_FILE_OPEN	:= TRUE
$	WRITE EXCH_FILE "$ EXCHANGE/NOMESSAGE/CACHE"
$	WRITE EXCH_FILE "  MOUNT ",DEV
$
$NEXT_NOMOD_FILE:
$
$	READ/END_OF_FILE=NOMOD_DONE NOMOD_DIR NOMOD_FILE
$	IF F$LOCATE ("]", NOMOD_FILE) .EQ. F$LENGTH (NOMOD_FILE)-
	THEN GOTO NEXT_NOMOD_FILE
$	FILE := 'F$EXTRACT(F$LOCATE("]",NOMOD_FILE)+1,-
	F$LENGTH(NOMOD_FILE)-F$LOCATE("]",NOMOD_FILE)+1,NOMOD_FILE)
$ !
$ ! Ignore null records.
$ !
$	IF F$LOCATE(".",FILE) .EQ. F$LENGTH(FILE) THEN GOTO NEXT_NOMOD_FILE
$ !
$ ! Determine if file should be copied image mode.
$ !
$	EXCH_REC_FMT := "STREAM"
$	IF F$LOCATE(".PAT",FILE) .NE. F$LENGTH(FILE)-
		.OR. F$LOCATE(".BIN",FILE) .NE. F$LENGTH(FILE)-
		.OR. F$LOCATE(".EXE",FILE) .NE. F$LENGTH(FILE)-
		.OR. F$LOCATE(".SYS",FILE) .NE. F$LENGTH(FILE)-
		THEN EXCH_REC_FMT := "FIXED"
$
$RESTOR_NOMOD:
$
$	ON ERROR THEN GOTO BOTH_DONE
$	WRITE EXCH_FILE "  COPY /LOG ",FILE,"/RECORD=",EXCH_REC_FMT," ",DEV
$	ON ERROR THEN CONTINUE
$	GOTO NEXT_NOMOD_FILE
$
$NOMOD_DONE:
$
$	WRITE EXCH_FILE "  DISMOUNT ",DEV
$	WRITE EXCH_FILE "  EXIT"
$	CLOSE EXCH_FILE
$	EXCH_FILE_OPEN	:= FALSE
$	CLOSE NOMOD_DIR
$	NOMOD_DIR_OPEN	:= FALSE
$	@EXCHANGE.TMP
$	DELETE NOMODIR.TMP;*, EXCHANGE.TMP;*
$ !
$ ! Get a directory of the remaining files which will be
$ ! modified for multiprocessor use.
$ !
$	WRITTEN		:= FALSE
$	IF ATTACHED THEN GOTO CREAT
$	DIRECTORY/OUTPUT=MODIR.TMP/COLUMNS=1/NOHEAD/NOTRAIL -
	D*GEN.*,D*XDT.*,D*BOO.CMD,CIBOO.CMD,CIGEN.,CIXDT.,RESTAR.CMD,-
	CS1BOO.CMD,CS1GEN.
$	GOTO MOD_FILES
$ !
$ ! If building for the attached, create dummy files to be modified.
$ !
$
$CREAT:
$
$	CREATE MODIR.TMP
[*]DEFBOO.CMD
[*]RESTAR.CMD
$	CREATE DEFBOO.CMD
			!
HALT			! HALT PROCESSOR
UNJAM			! UNJAM PROCESSOR
INIT			! INIT PROCESSOR
DEPOSIT AP 6		! INDICATOR OF HALT INSTRUCTION
EXAMINE 100		! GET STARTING ADDRESS
START 100		! AND GO THERE
$	CREATE RESTAR.CMD
			!
HALT			! HALT PROCESSOR
UNJAM			! UNJAM PROCESSOR
INIT			! INIT PROCESSOR
EXAMINE 100		! GET STARTING ADDRESS
START 100		! AND GO THERE
$
$ !
$ ! Now modify the remaining files for multiprocessor use and
$ ! copy them to the floppy.  Delete the files from the
$ ! temporary directory as they are copied.
$ !
$
$MOD_FILES:
$
$	WRITE SYS$OUTPUT ""
$	WRITE SYS$OUTPUT "Creating multiprocessor bootstrap command procedures."
$	WRITE SYS$OUTPUT ""
$	OPEN/READ MOD_DIR MODIR.TMP
$	MOD_DIR_OPEN	:= TRUE
$
$NEXT_MOD_FILE:
$
$	READ/END_OF_FILE=MOD_DIR_DONE MOD_DIR MOD_FILE
$	IF F$LOCATE ("]", MOD_FILE) .EQ. F$LENGTH (MOD_FILE)-
	THEN GOTO NEXT_MOD_FILE
$	FILE := 'F$EXTRACT(F$LOCATE("]",MOD_FILE)+1,-
	F$LENGTH(MOD_FILE)-F$LOCATE("]",MOD_FILE)+1,MOD_FILE)
$
$REOPEN:
$
$	OPEN/READ OLD_FILE 'FILE
$	OLD_FILE_OPEN	:= TRUE
$	OPEN/WRITE NEW_FILE NEWCMD.TMP
$	NEW_FILE_OPEN	:= TRUE
$ !
$ ! Add comments describing floppy and memory configuration.
$ !
$	WRITE NEW_FILE "!"
$	IF PRIMARY THEN GOTO PRIM_COMMENTS
$	WRITE NEW_FILE-
	"!	11/782 ATTACHED PROCESSOR BOOT COMMAND FILE - ",FILE
$	WRITE NEW_FILE "!"
$	WRITE NEW_FILE-
	"!	COMMAND FILES RESTAR.CMD AND DEFBOO.CMD ARE ESSENTIALY "
$	WRITE NEW_FILE-
	"!	THE SAME.  THIS FILE CAN BE INVOKED MANUALLY WITH THE COMMAND:"
$	WRITE NEW_FILE "!			@",FILE
$	WRITE NEW_FILE "!"
$	WRITE NEW_FILE-
	"!	THIS COMMAND FILE CAN ONLY BE USED FOR THE ATTACHED PROCESSOR"
$	WRITE NEW_FILE "!	ON A TIGHTLY-COUPLED MULTI-PROCESSING SYSTEM"
$	GOTO COMMENTS
$
$PRIM_COMMENTS:
$
$	WRITE NEW_FILE-
	"!	11/782 PRIMARY PROCESSOR BOOT COMMAND FILE - ",FILE
$	WRITE NEW_FILE "!"
$	WRITE NEW_FILE-
	"!	MULTI-PROCESSING BOOT, FOR MEMORY CONFIGURATION:"
$
$COMMENTS:
$
$	WRITE NEW_FILE "!"
$	WRITE NEW_FILE "!	      TR#   MEGABYTES	  MEMORY TYPE
$	WRITE NEW_FILE "!"
$	COUNT = 0
$
$COMMENTS1:
$
$	COUNT = COUNT + 1
$	IF COUNT .GT. MAX_CNTRLRS THEN GOTO END_MEM
$	IF MEM_TYPE'COUNT .EQS. "" THEN GOTO COMMENTS1
$	IF MEM_TYPE'COUNT .EQS. "MA780" THEN GOTO NOT_MS
$	WRITE NEW_FILE "!		",MEM_TR'COUNT,"	",-
	MEM_AMOUNT'COUNT,"	",MEM_TYPE'COUNT," LOCAL"
$	GOTO COMMENTS1
$
$NOT_MS:
$
$	WRITE NEW_FILE "!		",MEM_TR'COUNT,"	",-
	MEM_AMOUNT'COUNT,"	",MEM_TYPE'COUNT," MULTI-PORT"
$	GOTO COMMENTS1
$
$END_MEM:
$
$ !
$ ! Read each record of the original file and delete or add
$ ! records to make the necessary modifications.
$ !
$
$NEXT_RECORD:
$
$	READ/END_OF_FILE=EN_MOD OLD_FILE RECORD
$	CHAR = F$EXTRACT(0,1,RECORD)
$ !
$ ! Records that contain only comments are copied as is.
$ !
$	IF CHAR .EQS. "!" THEN GOTO WRITE_RECORD
$ !
$ ! All other comments are shifted right one tab for neatness.
$ !
$	RECORD=F$EXTRACT(0,F$LOCATE("!",RECORD),RECORD)-
	+"	"+F$EXTRACT(F$LOCATE("!",RECORD),-
	F$LENGTH(RECORD)-F$LOCATE("!",RECORD),RECORD)
$	IF CHAR .EQS. "D" THEN GOTO CHECK_D			! Deposit
$	IF CHAR .EQS. "S" THEN GOTO CHECK_S			! Start
$	IF CHAR .EQS. "I" .AND. ATTACHED THEN GOTO CHECK_INIT	! Init
$
$WRITE_RECORD:
$
$	WRITE NEW_FILE RECORD
$	GOTO NEXT_RECORD
$ !
$ ! Check for DEPOSIT R5 or DEPOSIT SP.
$ !
$
$CHECK_D:
$
$	IF F$LEN(RECORD) .EQ. F$LOC(" R5 ",RECORD) THEN GOTO CHECK_D2
$ !
$ ! "OR IN" the multiport software flag with the flags that are selected in the
$ ! original file.  If multiport flag is already set then abort.
$ !
$	STRING = F$EXTRACT(F$LOC(" R5 ",RECORD)+4,-
	F$LEN(RECORD)-F$LOC(" R5 ",RECORD)+4,RECORD)
$	SFLAGS = F$EXTRACT(0,F$LOC("	",STRING),STRING)
$	NEW_SFLAGS = %X'SFLAGS
$	IF .NOT. USE_LOCAL THEN NEW_SFLAGS = NEW_SFLAGS .OR. %X800
$	IF USE_LOCAL THEN NEW_SFLAGS = NEW_SFLAGS .OR. %X1000
$	NEW_SFLAGS = NEW_SFLAGS .AND. %XFFFFBFFF
$	NEW_SFLAGS = F$FAO("!XL",'NEW_SFLAGS)
$	IF NEW_SFLAGS .NE. SFLAGS THEN GOTO CHECK_D1
$	WRITE SYS$OUTPUT "BOOTBLDR has detected multiprocessor bootfile ",FILE
$	WRITE SYS$OUTPUT "on the original floppy - procedure aborted."
$	DELETE 'FILE
$	DELETE NEWCMD.TMP;
$	GOTO BOTH_DONE
$
$CHECK_D1:
$
$	WRITE NEW_FILE-
	"DEPOSIT R5 ",NEW_SFLAGS,"		! SOFTWARE BOOT FLAGS
$	GOTO NEXT_RECORD
$ !
$ ! Replace DEPOSIT R1 3 with DEPOSIT R1 'UBA_TR
$ !
$
$CHECK_D2:
$
$	IF F$LOCATE("R1 3",RECORD) .EQ. F$LEN(RECORD) THEN GOTO CHECK_D3
$	WRITE NEW_FILE "DEPOSIT R1 ",-
	F$EXTRACT(1,1,F$FAO("!XB",'UBA_TR)),-
	"			! UBA TR = ",UBA_TR
$	GOTO NEXT_RECORD
$ !
$ ! Replace DEPOSIT R1 8 with DEPOSIT R1 'MBA_TR
$ !
$
$CHECK_D3:
$
$	IF F$LOCATE("R1 8",RECORD) .EQ. F$LEN(RECORD) THEN GOTO CHECK_D4
	WRITE NEW_FILE "DEPOSIT R1 ",F$EXTRACT(1,1,F$FAO("!XB",'MBA_TR)),-
	"			! MBA TR = ",MBA_TR
$	GOTO NEXT_RECORD
$
$ !
$ ! Replace DEPOSIT R1 9 with DEPOSIT R1 'MBA_TR + 1
$ !
$
$CHECK_D4:
$
$	IF F$LOCATE("R1 9",RECORD) .EQ. F$LEN(RECORD) THEN GOTO CHECK_D5
$	IF MBA_TR .NE. %X0F THEN WRITE NEW_FILE -
	"DEPOSIT R1 ",F$EXTRACT(1,1,F$FAO("!XB",MBA_TR + 1)),-
	"			! MBA TR = ",MBA_TR + 1
$	IF MBA_TR .EQ. %X0F THEN WRITE NEW_FILE -
	"DEPOSIT R1 ",F$EXTRACT(1,1,F$FAO("!XB",'MBA_TR)),-
	"			! MBA TR = ",MBA_TR
$	GOTO NEXT_RECORD
$
$ !
$ ! Remove SP DEPOSITS to be replaced with DEPOSIT SP 200
$ !
$
$CHECK_D5:
$
$	IF F$LOCATE("SP",RECORD) .EQ. F$LEN(RECORD) THEN GOTO CHECK_FP
$	GOTO NEXT_RECORD
$ !
$ ! Add memory setup instructions after INIT for attached.
$ !
$
$CHECK_INIT:
$
$	WRITE NEW_FILE RECORD
$	GOTO WRITE_MEM
$ !
$ ! Add memory setup instructions after DEPOSIT FP for primary.
$ !
$
$CHECK_FP:
$
$	IF F$LOCATE(" FP ",RECORD) .EQ. F$LEN(RECORD) THEN GOTO DEP_MEM
$	WRITE NEW_FILE RECORD
$	IF WRITTEN THEN GOTO NEXT_RECORD
$
$ !	END_MS = 	Starting address for first MA780. (for RMEM)
$ !	END_MA = 	Starting address for first MS780% controller.
$ !	TOTAL_MS = 	Running total of MS780% memory in hex.
$ !	TOTAL_MA = 	Running total of MA780 memory in hex.
$ !	MEM_INT = 	Integer portion of memory starting address in megs.
$ !	MEM_FRAC = 	Fraction portion of memory starting address in megs.
$
$WRITE_MEM:
$
$	WRITTEN		:= TRUE
$	TOTAL_MS = 0
$	TOTAL_MA = 0
$	MEM_INT = 0
$	MEM_FRAC = 0
$	PASS = 0
$ !
$ ! Process in four passes to avoid memory gaps
$ !
$ !	First pass	- Set MA780 memory to low addresses
$ !	Second pass	- Resolve any memory gaps by setting MS780A or MS780C
$ !			  memory to follow MA780 memory until the next address
$ !			  is on a 1 meg boundary
$ !	Third pass	- Add any MS780E memory
$ !	Fourth pass	- Add any remaining MS780A or MS780C memory
$ !
$
$NEXT_PASS:
$
$	COUNT = 0
$	PASS = PASS + 1
$	IF PASS .EQ. 3 THEN SAVED_COUNT = COUNT
$	IF PASS .EQ. 4 THEN COUNT = SAVED_COUNT
$	IF PASS .EQ. 5 THEN GOTO END_FP
$
$WRITE_MEM1:
$
$	COUNT = COUNT + 1
$	IF COUNT .GT. MAX_CNTRLRS THEN GOTO NEXT_PASS
$	IF PASS .EQ. 1 .AND. MEM_TYPE'COUNT .EQS. "MA780" THEN GOTO SET_MA
$	IF PASS .EQ. 2 .AND. MEM_FRAC .EQ. 0 THEN GOTO NEXT_PASS
$	IF PASS .EQ. 2 .AND. MEM_TYPE'COUNT .EQS. "MS780A" THEN GOTO SET_MS
$	IF PASS .EQ. 2 .AND. MEM_TYPE'COUNT .EQS. "MS780C" THEN GOTO SET_MS
$	IF PASS .EQ. 3 .AND. MEM_TYPE'COUNT .EQS. "MS780E" THEN GOTO SET_MS
$	IF PASS .EQ. 4 .AND. MEM_TYPE'COUNT .EQS. "MS780A" THEN GOTO SET_MS
$	IF PASS .EQ. 4 .AND. MEM_TYPE'COUNT .EQS. "MS780C" THEN GOTO SET_MS
$	GOTO WRITE_MEM1
$
$SET_MS:
$
$ !
$ ! MSTART = first address above shared memory and any local memory we've
$ ! encountered thus far.
$ !
$	MSTART = END_MA+TOTAL_MS
$	IF MEM_TYPE'COUNT .NES. "MS780E" THEN GOTO SET_MS1
$ !
$ ! If the MS780E memory address will not start on a 1 MEG boundary then round
$ ! up to next boundary thereby leaving an unresolved memory gap.
$ !
$	IF .NOT. USE_LOCAL THEN GOTO SET_MS_TOLD
$	IF TOLD THEN GOTO SET_MS_TOLD
$	TOLD:= TRUE
$	GAP = ((MSTART + %XC0000) .AND. %XFFF00000) - MSTART
$	IF GAP .EQ. 0 THEN GOTO SET_MS_TOLD
$	GAP = GAP / %X40000 * 25
$	WRITE SYS$OUTPUT-
	"%BOOTBLDR-W-NOCONTIG, unable to configure local memory contiguously."
$	WRITE SYS$OUTPUT-
      "A gap of .",GAP," megabytes appears before the ",MEM_TYPE'COUNT," memory"
$	WRITE SYS$OUTPUT-
	"at TR ",MEM_TR'COUNT,".  Use of local memory may be inefficient."
$	WRITE SYS$OUTPUT ""
$	INQUIRE USE_LOCAL-
	"Do you still want to boot using local memory <YES or [NO]>"
$	WRITE SYS$OUTPUT ""
$	IF USE_LOCAL THEN GOTO SET_MS_TOLD
$	CLOSE OLD_FILE
$	OLD_FILE_OPEN	:= FALSE
$	CLOSE NEW_FILE
$	NEW_FILE_OPEN	:= FALSE
$	DELETE NEWCMD.TMP;
$	GOTO REOPEN
$
$SET_MS_TOLD:
$
$	TOTAL_MS = (TOTAL_MS + %XC0000) .AND. %XFFF00000
$ !
$ ! Convert MS780% starting address to a value to deposit into configuration
$ ! register B by shifting the starting address right one place, adding
$ ! in the write starting address bit, and converting the result to a formated
$ ! hex longword.
$ !
$
$SET_MS1:
$
$	MS_START = F$FAO("!XL",MSTART/%X2+%X4000)
$
$	REG = F$FAO("!XL",MEM_ADRS'COUNT)	! Configuration register A
$
$	IF MEM_TYPE'COUNT .EQS. "MS780E" THEN GOTO SET_MSE
$
$SET_MSC:					! MS780A or MS780C specific
$
$	WRITE NEW_FILE "DEPOSIT ",REG," 00400100",-
	"	! CLEAR ",MEM_TYPE'COUNT',-
	" POWER UP AND INTRLV BITS (TR #",MEM_TR'COUNT,")"
$
$	GOTO SET_MSE1
$
$SET_MSE:					! MS780E specific
$
$	WRITE NEW_FILE "DEPOSIT ",REG," 00CC0000",-
	"	! CLEAR MS780E POWER UP AND ERROR BITS (TR#",MEM_TR'COUNT,")"
$
$	REG = F$FAO("!XL",MEM_ADRS'COUNT+8)	! Configuration register C
$	WRITE NEW_FILE "DEPOSIT ",REG," 30000780","	!		"""
$
$	REG = F$FAO("!XL",MEM_ADRS'COUNT+%X0C)	! Configuration register D
$	WRITE NEW_FILE "DEPOSIT ",REG," 30000780","	!		"""
$
$SET_MSE1:					! MS780x common
$
$	REG = F$FAO("!XL",MEM_ADRS'COUNT+4)	! Configuration register B
$	WRITE NEW_FILE-
	"DEPOSIT ",REG," ",MS_START,"	! SET ",MEM_TYPE'COUNT,-
	" MEMORY TO START AT ",MEM_INT,".",MEM_FRAC,-
	" MEG (TR #",MEM_TR'COUNT,")"
$
$ !
$ ! Add this controller's memory to running total
$ !
$	TOTAL_MS = TOTAL_MS+MEM'COUNT
$	GOTO CALC_NEXT
$
$SET_MA:					! MA780 specfic
$
$	REG = F$FAO("!XL",MEM_ADRS'COUNT)	! Configuration register A
$	WRITE NEW_FILE "DEPOSIT ",REG," 00400000",-
	"	! CLEAR POWER UP AND ERROR BITS IN MA780 (TR #",MEM_TR'COUNT,")"
$
$	REG = F$FAO("!XL",MEM_ADRS'COUNT+4)	! Interface control register
$	WRITE NEW_FILE "DEPOSIT ",REG," FF000000","	!		"""
$
$	REG = F$FAO("!XL",MEM_ADRS'COUNT+8)	! Controller status register
$	WRITE NEW_FILE "DEPOSIT ",REG," D000C000","	!		"""
$
$	REG = F$FAO("!XL",MEM_ADRS'COUNT+%X10)	! Array error register
$	WRITE NEW_FILE "DEPOSIT ",REG," 80000000","	!		"""
$
$ !
$ ! Convert MA780 starting address to a value to deposit in the invalidation
$ ! control register by shifting the starting address left two places, adding
$ ! in the ID 0 bit, and converting the result to a formated hex longword,
$ !
$	MA_START = F$FAO("!XL",(TOTAL_MA*4)+1)
$	REG = F$FAO("!XL",MEM_ADRS'COUNT+%X0C)	! Invalidation control register
$	WRITE NEW_FILE-
	"DEPOSIT ",REG," ",MA_START,"	! SET MA780 TO START AT ",-
	MEM_INT,".",MEM_FRAC," MEG (TR #",MEM_TR'COUNT,")"
$ !
$ ! Calc next controller's starting address in hex.
$ !
$	TOTAL_MA = TOTAL_MA+MEM'COUNT
$ !
$ ! Calc next controller's starting address in Megs.
$ !
$
$CALC_NEXT:
$
$	MEM_INT = MEM_INT+MEM_INT'COUNT
$	MEM_FRAC = MEM_FRAC+MEM_FRACT'COUNT
$	IF MEM_FRAC .GE. 100 THEN MEM_INT = MEM_INT+1
$	IF MEM_FRAC .GE. 100 THEN MEM_FRAC = MEM_FRAC-100
$	GOTO WRITE_MEM1
$
$END_FP:					! Add deposit to SP instruction.

$
$	WRITE NEW_FILE "DEPOSIT SP 200			! SET BASE ADDRESS"
$	GOTO NEXT_RECORD
$ !
$ ! Check for Deposit to local memory address or /I 11.
$ ! If found, do not include in output file.
$ !
$
$DEP_MEM:
$
$	COUNT = 0
$
$DEP_MEM1:
$
$	COUNT = COUNT + 1
$	IF COUNT .GT. MAX_CNTRLRS THEN GOTO CHECK_I
$	IF MEM_TYPE'COUNT .EQS. "" THEN GOTO DEP_MEM1
$	IF MEM_TYPE'COUNT .EQS. "MA780" THEN GOTO DEP_MEM1
$	IF F$LOCATE(F$FAO("!XL",MEM_ADRS'COUNT),RECORD) .EQ. F$LEN(RECORD)-
	THEN GOTO DEP_MEM1
$	GOTO NEXT_RECORD
$
$CHECK_I:
$
$	IF F$LOCATE("/I 11",RECORD) .EQ. F$LEN(RECORD) THEN GOTO WRITE_RECORD
$	GOTO NEXT_RECORD
$
$CHECK_S:			! Check for START 20003000 followed by WAIT DONE
$
$	IF F$LOCATE("20003000",RECORD) .EQ. F$LENGTH(RECORD) THEN GOTO CHECK_S2
$	OLD_RECORD	:= RECORD
$	READ/END_OF_FILE=EN_MOD OLD_FILE RECORD
$	IF F$LOCATE("DONE",RECORD) .NE. F$LENGTH(RECORD) THEN GOTO NEXT_RECORD
$	WRITE NEW_FILE OLD_RECORD
$	GOTO WRITE_RECORD
$
$CHECK_S2:			! Check for START 20003004
$
$	IF F$LOCATE("20003004",RECORD) .EQ. F$LEN(RECORD) THEN GOTO WRITE_RECORD
$	WRITE NEW_FILE-
	"EXAMINE 4			! GET RESTART ADDRESS FROM RPB"
$	WRITE NEW_FILE "START @				! AND START IT"
$	GOTO NEXT_RECORD
$
$EN_MOD:			! Write the modified file out to the floppy.
$
$	CLOSE OLD_FILE
$	OLD_FILE_OPEN	:= FALSE
$	CLOSE NEW_FILE
$	NEW_FILE_OPEN	:= FALSE
$	IF F$LOCATE(";",FILE) .EQ. F$LENGTH(FILE) THEN FILE := 'FILE'";"
$	DELETE 'FILE
$	RENAME NEWCMD.TMP 'FILE
$	ON ERROR THEN GOTO BOTH_DONE
$	EXCHANGE/NOMESSAGE COPY /LOG 'FILE'/RECORD=STREAM  'DEV'
$	ON ERROR THEN CONTINUE
$	DELETE 'FILE
$	WRITTEN		:= FALSE
$	GOTO NEXT_MOD_FILE
$
$MOD_DIR_DONE:				! Finished modifying files.
$
$	CLOSE MOD_DIR
$	DELETE MODIR.TMP;*
$	MOD_DIR_OPEN	:= FALSE
$ !
$ ! Now build RMEM.
$ !
$	OPEN/WRITE NEW_FILE RMEM.
$	NEW_FILE_OPEN	:= TRUE
$	WRITE NEW_FILE "!"
$	WRITE NEW_FILE-
	"! COMMAND FILE TO RESET MEMORY CONTROLLER RESTART ADDRESSES."
$	WRITE NEW_FILE "!"
$	TOTAL_MS = 0	! Running total of MS780% memory in hex.
$	TOTAL_MA = 0	! Running total of MA780 memory in hex.
$	MEM_INT = 0
$	MEM_FRAC = 0
$	COUNT = 0
$	PASS = 1
$
$RMEM_LOOP:
$
$	COUNT = COUNT + 1
$	IF COUNT .LE. MAX_CNTRLRS THEN GOTO RMEM_LOOP1
$	IF PASS .EQ. 2 THEN GOTO END
$	PASS = 2
$	COUNT = 0
$	GOTO RMEM_LOOP
$
$RMEM_LOOP1:
$
$ !
$ ! To avoid memory gaps, process MS780E memory first.
$ !
$	IF MEM_TYPE'COUNT .EQS. "" THEN GOTO RMEM_LOOP
$	IF PASS .EQ. 1 .AND. MEM_TYPE'COUNT .NES. "MS780E" THEN GOTO RMEM_LOOP
$	IF PASS .EQ. 2 .AND. MEM_TYPE'COUNT .EQS. "MS780E" THEN GOTO RMEM_LOOP
$	IF PASS .EQ. 2 .AND. MEM_TYPE'COUNT .EQS. "MA780" THEN GOTO RMEM_LOOP2
$ !
$ !
$ ! Convert MS780% starting address to a value to deposit into configuration
$ ! register B by shifting the starting address right one place, adding
$ ! in the write starting address bit, and converting the result to a formated
$ ! hex longword.
$ !
$	MS_START = F$FAO("!XL",TOTAL_MS/%X2+%X4000)
$
$	REG = F$FAO("!XL",MEM_ADRS'COUNT+4)	! Configuration register B
$	WRITE NEW_FILE "DEPOSIT ",REG," ",MS_START,"	! SET ",-
	MEM_TYPE'COUNT," MEMORY TO START AT ",MEM_INT,".",MEM_FRAC,-
	" MEG (TR #",MEM_TR'COUNT,")"
$ !
$ ! Calc starting address for next controller in hex.
$ !
$	TOTAL_MS = TOTAL_MS+MEM'COUNT
$	GOTO CALC_NEXT1
$
$RMEM_LOOP2:
$
$	MASTART = END_MS+TOTAL_MA	! Starting address of MA780 in hex.
$ !
$ ! Convert MA780 starting address to a value to deposit in the invalidation
$ ! control register by shifting the starting address left two places, adding
$ ! in the ID 0 bit, and converting the result to a formated hex longword,
$ !
$	MA_START = F$FAO("!XL",(MASTART*4)+1)
$	REG = F$FAO("!XL",MEM_ADRS'COUNT+%X0C)	! Invalidation control register
$	WRITE NEW_FILE-
	"DEPOSIT ",REG," ",MA_START,"	! SET MA780 TO START AT ",-
	MEM_INT,".",MEM_FRAC," MEG (TR #",MEM_TR'COUNT,")"
$ !
$ ! Add memory on this controller to running total.
$ !
$	TOTAL_MA = TOTAL_MA+MEM'COUNT
$ !
$ ! Calc next controller's starting address in Megs.
$ !
$
$CALC_NEXT1:
$
$	MEM_INT = MEM_INT+MEM_INT'COUNT
$	MEM_FRAC = MEM_FRAC+MEM_FRACT'COUNT
$	IF MEM_FRAC .GE. 100 THEN MEM_INT = MEM_INT+1
$	IF MEM_FRAC .GE. 100 THEN MEM_FRAC = MEM_FRAC-100
$	GOTO RMEM_LOOP
$
$END:
$
$	CLOSE NEW_FILE
$	NEW_FILE_OPEN	:= FALSE
$	ON ERROR THEN GOTO BOTH_DONE
$	EXCHANGE/NOMESSAGE COPY /LOG RMEM.;1/RECORD=STREAM 'DEV'
$	ON ERROR THEN CONTINUE
$	DELETE RMEM.;1
$ !
$ ! Write RT-11 bootblock on floppy.
$ !
$	EXCHANGE COPY/BOOT/LOG 'DEV'CONSOL.SYS
$	DISMOUNT 'DEV'
$	CONSOLE_MOUNTED	:= FALSE
$	IF PRIMARY THEN WRITE SYS$OUTPUT-
	"Primary processor console floppy completed."
$	IF ATTACHED THEN WRITE SYS$OUTPUT-
	"Attached processor console floppy completed."
$	WRITE SYS$OUTPUT ""
$	WRITE SYS$OUTPUT ""
$	WRITE SYS$OUTPUT ""
$
$	IF ATTACHED THEN GOTO BOTH_DONE
$	IF MODE .EQ. 2 THEN GOTO PRIM_MODE2_DONE
$
$PRIM_MODE3_DONE:
$
$	WRITE SYS$OUTPUT "Enter memory configuration for attached processor."
$	WRITE SYS$OUTPUT ""
$	WRITE SYS$OUTPUT-
	"Shared (MA780) memory must be identical on both processors."
$	WRITE SYS$OUTPUT-
	"Local (MS780A, MS780C, or MS780E) memory may be different."
$	WRITE SYS$OUTPUT ""
$
$PRIM_MODE2_DONE:
$
$	PRIMARY 	:= FALSE
$	ATTACHED 	:= TRUE
$	GOTO INIT_VAR
$
$DATA_FILE_ERROR:
$
$	WRITE SYS$OUTPUT "Error in data file format."
$	GOTO BOTH_DONE
$
$NO_BOOTBLOCK:
$
$	WRITE SYS$OUTPUT "Unable to write bootblock."
$	GOTO BOTH_DONE
$
$NO_BATCH:
$
$	WRITE SYS$OUTPUT "This command procedure requires user interaction"
$	WRITE SYS$OUTPUT "and therefore cannot be run as a BATCH job.
$	GOTO EXIT1
$
$CONFIG_DONE:
$
$	CONFIG_NOT_DONE	:= FALSE
$	CLOSE DATA_FILE
$	DATA_FILE_OPEN	:= FALSE
$	P2_FILE = F$SEARCH(P2)
$	WRITE SYS$OUTPUT "" 
$	WRITE SYS$OUTPUT "%BOOTBLDR-I-CREATED, ",P2_FILE,"	created"
$
$BOTH_DONE:
$
$	ON ERROR THEN CONTINUE
$	ON CONTROL_Y THEN CONTINUE
$	IF DATA_FILE_OPEN THEN CLOSE DATA_FILE
$	IF CONFIG_NOT_DONE THEN DELETE 'P2';
$	IF DIR_FILE_OPEN THEN CLOSE DIR_FILE
$	IF EXCH_FILE_OPEN THEN CLOSE EXCH_FILE
$	IF NOMOD_DIR_OPEN THEN CLOSE NOMOD_DIR
$	IF MOD_DIR_OPEN THEN CLOSE MOD_DIR
$	IF OLD_FILE_OPEN THEN CLOSE OLD_FILE
$	IF NEW_FILE_OPEN THEN CLOSE NEW_FILE
$	IF CONSOLE_MOUNTED THEN DISMOUNT 'DEV'
$	IF MODE .EQ. 3 THEN GOTO EXIT1
$	SET DEFAULT 'SAVEDEF
$	IF .NOT. DIR_CREATED THEN GOTO EXIT
$	DELETE [.TEMPBOOT]*.*;*
$	SET PROT=(OWNER:RWED) TEMPBOOT.DIR
$	DELETE TEMPBOOT.DIR;*
$
$EXIT:
$
$	SET UIC 'SAVED_UIC
$	SET PROC/PRIV=('SAVED_PRIVS')
$	SET DEFAULT 'SAVEDEF
$
$EXIT1:
$
$	EXIT
