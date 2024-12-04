$ !
$ ! CONSCOPY -- Save or Restore a console medium
$ !
$ ! Inputs:
$ !	P1 - Kit type: 780 or 750 or 730
$ !	P2 - Function: SAVE or RESTORE
$ !	P3 - Files-11 virtual disk name
$ !	P4 - Console device drive
$ !	P5 - File to be written on the bootblock of the console medium.
$ !	     Optional.  The defaults are:
$ !		780 - CONSOL.SYS
$ !		750 - BOOT58.EXE
$ !		730 - BOOT.EXE
$ !
$ ! This program saves or restores a console medium.  It uses the native
$ ! mode utility EXCHANGE to copy and re-format files between a user medium
$ ! (Files-11 format) and a console medium (RT-11 format).
$ !
$ IF F$MODE() .EQS. "BATCH" THEN SET NOVERIFY
$  
$ !**********************************************************************
$ !*	If this is running as a batch job, make sure all		*
$ !*	parameters are specified.					*
$ !**********************************************************************
$
$ IF F$MODE() .NES. "BATCH" THEN GOTO START
$ IF P1 .NES. "" .AND. P2 .NES. "" .AND. P3 .NES. "" .AND. P4 .NES. "" -
	THEN GOTO START
$ WRITE SYS$OUTPUT "%CONSCOPY-E-MISSING_PARMS, P1 through P4 must be specified."
$ EXIT 4
$
$ !**********************************************************************
$ !*	Write a greeting mssage, then initialize symbols used by this	*
$ !*	command procedure.						*
$ !**********************************************************************
$
$START:
$ TYPE SYS$INPUT

    S Y S $ U P D A T E : C O N S C O P Y . C O M

	Save or restore a VMS console medium.

$ SAVED_PRIVS = F$SETPRV("CMEXEC,CMKRNL,LOG_IO,SYSNAM,VOLPRO")
$ SAVED_DIR := 'F$LOG("SYS$DISK")''F$DIR()'
$ KIT_DONE := FALSE
$
$ KIT := 'P1
$ FUNCTION := 'P2
$ VIRTUAL_DISK := 'P3
$ CONSOLE_DEVICE := 'P4
$ BOOTFILE := 'P5
$
$ !**********************************************************************
$ !*	Get CPU type, and derive information about the console		*
$ !*	device from it.							*
$ !**********************************************************************
$
$KIT:
$ !
$ ! If P1 not specified, prompt for kit type.
$ !
$ IF KIT .NES. "" THEN GOTO KIT_CHECK
$
$KIT_GET:
$ CPU_NUM = F$GETSYI ("CPU")
$ IF CPU_NUM .EQ. 1 THEN KIT = "780"
$ IF CPU_NUM .EQ. 2 THEN KIT = "750"
$ IF CPU_NUM .EQ. 3 THEN KIT = "730"
$ WRITE SYS$OUTPUT ""
$ INQUIRE KIT_Q "Which kit do you want to build [780, 750 or 730, default ''KIT']"
$ IF KIT_Q .NES. "" THEN KIT = KIT_Q
$
$KIT_CHECK:
$ IF KIT .EQS. "780" THEN GOTO SET_780_PARMS
$ IF KIT .EQS. "750" THEN GOTO SET_750_PARMS
$ IF KIT .EQS. "730" THEN GOTO SET_730_PARMS
$ WRITE SYS$OUTPUT "%CONSCOPY-E-BAD_CPU_TYPE, must be one of ""780"", ""750"", or ""730"""
$ IF F$MODE() .EQS. "BATCH" THEN EXIT 4	! Exit batch mode with serious error
$ GOTO KIT_GET
$
$SET_780_PARMS:
$ MEDIUM := "floppy"
$ IF BOOTFILE .EQS. "" THEN BOOTFILE := CONSOL.SYS
$ GOTO END_SET_PARMS
$
$SET_750_PARMS:
$ MEDIUM := "TU58"
$ IF BOOTFILE .EQS. "" THEN BOOTFILE := BOOT58.EXE
$ GOTO END_SET_PARMS
$
$SET_730_PARMS:
$ MEDIUM := "TU58"
$ IF BOOTFILE .EQS. "" THEN BOOTFILE := BOOT.EXE
$
$END_SET_PARMS:
$
$ !**********************************************************************
$ ! 	Get the remainder of the input parameters.			*
$ !**********************************************************************
$
$FUNCTION:
$ !
$ ! If P2 not specified, prompt for function.
$ !
$ IF FUNCTION .NES. "" THEN GOTO FUNCTION_CHECK
$ TYPE SYS$INPUT:

	A SAVE operation involves copying the  console medium to
	an RT-11  virtual volume, which  is a Files-11 file that
	is an image of the RT-11 console volume.

	A RESTORE operation involves copying the entire contents
	of a virtual volume to a console medium.
$FUNCTION_GET:
$ WRITE SYS$OUTPUT ""
$ INQUIRE FUNCTION "Do you want to SAVE or RESTORE your console ''MEDIUM'?"
$
$FUNCTION_CHECK:
$ IF (FUNCTION .EQS. "SAVE") .OR. (FUNCTION .EQS. "RESTORE") -
	THEN GOTO VIRTUAL_DEVICE
$ WRITE SYS$OUTPUT "%CONSCOPY-E-BAD_FUNCTION, must be either ""SAVE"" or ""RESTORE"""
$ IF F$MODE() .EQS. "BATCH" THEN EXIT 4	! Exit batch mode with serious error
$ GOTO FUNCTION_GET
$
$VIRTUAL_DEVICE:
$ !
$ ! If P3 not specified, prompt for Files-11 virtual device name
$ !
$ IF VIRTUAL_DISK .NES. "" THEN GOTO VIRTUAL_CHECK
$ !
$VIRTUAL_INQUIRE:
$ WRITE SYS$OUTPUT ""
$ INQUIRE VIRTUAL_DISK "Enter file name of virtual disk [default SYS$DISK:CONSOLE.DSK]"
$ IF VIRTUAL_DISK .EQS. "" THEN VIRTUAL_DISK = "CONSOLE.DSK"
$ !
$VIRTUAL_CHECK:
$ F11_DEV = F$PARSE(VIRTUAL_DISK,,,"DEVICE")
$ F11_DIR = F$PARSE(VIRTUAL_DISK,,,"DIRECTORY")
$ FILES11_DEVICE = F11_DEV + F11_DIR
$ !
$ ! Check that the directory exists and is writable.
$ !
$ IF F$PARSE("''FILES11_DEVICE'TEST") .EQS. "" THEN CREATE /DIRE /LOG 'FILES11_DEVICE'
$ OPEN /WRITE FILE 'FILES11_DEVICE'CHECK_WRITE.ACCESS
$ CLOSE FILE
$ DELETE /NOLOG 'FILES11_DEVICE'CHECK_WRITE.ACCESS;*
$ LOG = "/LOG"
$ IF F$MODE() .EQS. "BATCH" THEN GOTO NOLOG_CHECK
$ WRITE SYS$OUTPUT ""
$ INQUIRE TEMP "Do you want log messages as files are copied? [Y/N, default Yes]"
$ IF ((TEMP .NES. "") .AND. (.NOT. TEMP)) THEN LOG = ""
$ !
$ ! If P4 not specified, prompt for console device drive.
$ !
$NOLOG_CHECK:
$ IF CONSOLE_DEVICE .NES. "" THEN GOTO CONSOLE_TRNLOG
$ !
$CONSOLE_INQUIRE:
$ WRITE SYS$OUTPUT ""
$ INQUIRE CONSOLE_DEVICE "Enter console device drive (DDCU:)"
$ IF CONSOLE_DEVICE .EQS. "" THEN GOTO CONSOLE_INQUIRE
$ !
$CONSOLE_TRNLOG:
$ CD = F$LOGICAL(CONSOLE_DEVICE)
$ IF CD .EQS. "" THEN GOTO CONSOLE_CHECK
$ CONSOLE_DEVICE = CD
$ GOTO CONSOLE_TRNLOG
$ !
$CONSOLE_CHECK:
$ IF F$GETDVI(CONSOLE_DEVICE,"EXISTS") THEN GOTO CONSOLE_EXISTS
$ IF F$LOCATE("CS",CONSOLE_DEVICE) .EQ. F$LENGTH(CONSOLE_DEVICE) THEN GOTO CONSOLE_NOTEXIST
$ ON ERROR THEN GOTO CLEAN_UP
$ ON CONTROL_Y THEN GOTO CLEAN_UP
$ RUN SYS$SYSTEM:SYSGEN
CONNECT CONSOLE
$ IF F$GETDVI(CONSOLE_DEVICE,"EXISTS") THEN GOTO CONSOLE_EXISTS
$ !
$CONSOLE_NOTEXIST:
$ WRITE SYS$OUTPUT "%CONSCOPY-E-NOSUCHDEV, console device does not exist"
$ IF F$MODE() .EQS. "BATCH" THEN EXIT 4
$ GOTO CONSOLE_INQUIRE
$ !
$CONSOLE_EXISTS:
$ CONSOLE_DEVICE = F$GETDVI(CONSOLE_DEVICE,"DEVNAM")	! get std format name
$ IF CONSOLE_DEVICE .EQS. "" THEN GOTO CONSOLE_NOTEXIST
$ RTB_DEVICE:= 'F$EXTRACT(1,2,CONSOLE_DEVICE)''F$EXTRACT(4,1,CONSOLE_DEVICE)':
$ IF .NOT. F$GETDVI(CONSOLE_DEVICE,"MNT") THEN GOTO CONSOLE_MOUNT
$ IF F$GETDVI(CONSOLE_DEVICE,"FOR") THEN GOTO CONSOLE_DISMOUNT
$ WRITE SYS$OUTPUT "%CONSCOPY-E-FIL11_DEV, console device is mounted as FILES-11, must be /FOREIGN"
$ IF F$MODE() .EQS. "BATCH" THEN EXIT 4
$ EXIT
$ !
$CONSOLE_DISMOUNT:
$ DISMOUNT 'CONSOLE_DEVICE'
$ !
$CONSOLE_MOUNT:
$ WRITE SYS$OUTPUT ""
$ WRITE SYS$OUTPUT "Put your console ''MEDIUM' into drive ''CONSOLE_DEVICE',"
$ INQUIRE TEMP "and type <RETURN> when ready"
$ MOUNT/NOASSIST/FOREIGN/DATA=WRITE 'CONSOLE_DEVICE' "VAX console"
$
$ !**********************************************************************
$ !*	Save or restore the console medium.				*
$ !**********************************************************************
$
$ SET DEFAULT 'FILES11_DEVICE'
$ IF FUNCTION .EQS. "RESTORE" THEN GOTO RESTORE
$
$SAVE:
$ WRITE SYS$OUTPUT ""
$ !
$ ! Copy the contents of the console medium to a files-11 virtual device,
$ ! using the EXCHANGE utility.
$ !
$ OPEN /WRITE COMFILE SYS$SCRATCH:CONSCOPY_TEMP.COM
$ WRITE COMFILE "$ EXCHANGE"
$ WRITE COMFILE "INITIALIZE /CREATE /SEGMENTS=2 /ALLOCATION=512 ''VIRTUAL_DISK' ""''KIT' console"""
$ WRITE COMFILE "MOUNT /VIRTUAL CONSOLE_SAVE: ''VIRTUAL_DISK'"
$ WRITE COMFILE "COPY ''LOG' ''CONSOLE_DEVICE'*.* CONSOLE_SAVE:"
$ WRITE COMFILE "DIRECTORY /OWNER CONSOLE_SAVE:"
$ WRITE COMFILE "EXIT"
$ CLOSE COMFILE
$ !
$ @SYS$SCRATCH:CONSCOPY_TEMP.COM
$ !
$ KIT_DONE := TRUE
$ GOTO CLEAN_UP
$
$RESTORE:
$ WRITE SYS$OUTPUT ""
$ !
$ ! Rebuild the console medium.  EXCHANGE will be used to copy the files to the
$ ! console medium in RT-11 format.  Also, write a bootblock on the medium.
$ !
$ OPEN /WRITE COMFILE SYS$SCRATCH:CONSCOPY_TEMP.COM
$ WRITE COMFILE "$ EXCHANGE"
$ WRITE COMFILE "INITIALIZE /SEGMENTS=2 ''CONSOLE_DEVICE' ""''KIT' console"""
$ WRITE COMFILE "MOUNT /VIRTUAL CONSOLE_RESTORE: ''VIRTUAL_DISK'"
$ WRITE COMFILE "MOUNT /DATA_CHECK=WRITE ''CONSOLE_DEVICE'"
$ WRITE COMFILE "COPY ''LOG' CONSOLE_RESTORE:*.* ''CONSOLE_DEVICE'"
$ IF ((KIT .EQS. "780") .OR. (KIT .EQS. "730")) THEN -
	WRITE COMFILE "COPY /BOOT ''LOG' ''CONSOLE_DEVICE'''BOOTFILE'"
$ WRITE COMFILE "DIRECTORY /OWNER ''CONSOLE_DEVICE'"
$ WRITE COMFILE "EXIT"
$ CLOSE COMFILE
$ !
$ @SYS$SCRATCH:CONSCOPY_TEMP.COM
$ !
$ IF KIT .NES. "750" THEN GOTO ALL_DONE
$ !
$ ! USE THE WRITEBOOT PROGRAM TO WRITE THE 750 BOOT
$ !
$ ASSIGN/USER 'CONSOLE_DEVICE''BOOTFILE' BOOT 
$ RUN SYS$SYSTEM:WRITEBOOT
BOOT
1
C000
$ !
$ALL_DONE:
$ !
$ KIT_DONE := TRUE
$ !
$ !**********************
$ !*	Clean up.	*
$ !**********************
$
$CLEAN_UP:
$ SET NOON
$ WRITE SYS$OUTPUT ""
$ IF F$SEARCH ("SYS$SCRATCH:CONSCOPY_TEMP.COM") .NES. "" THEN -
		 DELETE /NOLOG SYS$SCRATCH:CONSCOPY_TEMP.COM;*
$ SET DEFAULT 'SAVED_DIR'
$ IF KIT_DONE THEN WRITE SYS$OUTPUT -
	"	The ''FUNCTION' of your console ''MEDIUM' is complete."
$ IF .NOT. KIT_DONE THEN WRITE SYS$OUTPUT -
	"Error in command file execution -- kit is incomplete."
$ IF F$GETDVI(CONSOLE_DEVICE,"MNT") THEN DISMOUNT 'CONSOLE_DEVICE'
$ !
$ ! If this procedure used the console drive, it is now accessible.  Mount
$ ! it /NOWRITE to protect it.
$ !
$ IF F$EXTRACT(1,2,CONSOLE_DEVICE) .NES. "CS" THEN GOTO DONE
$ IF F$GETSYI("CPU") .EQ. 3 THEN GOTO 730_CONSOLE
$ CONSOLE_DRIVE := CSA1
$ GOTO RECONSOLE_MOUNT
$
$730_CONSOLE:
$ CONSOLE_DRIVE := CSA2
$
$RECONSOLE_MOUNT:
$ IF F$GETDVI(CONSOLE_DRIVE,"MNT") THEN DISMOUNT 'CONSOLE_DRIVE'
$ TYPE SYS$INPUT

	Since the console device is now accessible to users, the
	console should be remounted write-locked for protection.
	Please  place  your  console medium  back in the console
	device, and  it will be  mounted  with  /SYSTEM /NOWRITE
	protection to prevent access by unprivileged users.

$ INQUIRE READY "Type <RETURN> when ready"
$ MOUNT/NOASSIST/FOREIGN/SYSTEM/NOWRITE 'CONSOLE_DRIVE' "VAX console"
$
$DONE:
$ SET PROCESS/PRIV=('SAVED_PRIVS')
