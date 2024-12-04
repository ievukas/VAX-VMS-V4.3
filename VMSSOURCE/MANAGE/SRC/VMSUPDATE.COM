$ !
$ ! Modified by:
$ !
$ !		BLS0320		Benn Schreiber		18-MAY-1984
$ !		Do not use /PROCESS=UNIQUE, since there may not be
$ !		enough dynamic memory for the cache.
$ !
$ !		BLS0302		Benn Schreiber		11-APR-1984
$ !		Do not allow use on tailored or cluster multi-system disk
$ !		configurations, as it will only fail.
$ !
$ !		MCN0001		Maria del C. Nasr	20-Oct-1983
$ !		Comment out check for console device because it is no
$ !		longer needed, plus it will not work in a cluster
$ !		environment.
$ !
$ ON CONTROL_Y THEN GOTO DONE
$ DELETE/SYMBOL/GLOBAL/ALL
$ SAY = "WRITE SYS$OUTPUT"
$ SET PROT=(S:RWED,G:RWED,O:RWED,W:RE)/DEFAULT
$ SYSDISK = F$LOGICAL("SYS$DISK")
$ SAVE_DEFULT = F$ENVIRONMENT("DEFAULT")
$ DEFUIC:='F$USER()
$ DEFINE DXA1 CSA1:
$ DEFINE DX1 CSA1:
$ DEFINE SYS$KIT CSA1:
$ DEFINE VMS$STARLET SYS$DISK:[SYSLIB] 
$ DEFINE VMS$HELPLIB SYS$DISK:[SYSHLP] 
$ CPU_TYPE = F$GETSYI("CPU")
$ EXIT_MESSAGE = " Update sequence abnormally terminated."
$ SET NOON
$ SAY " "
$ SAY "                  VMS Update Procedure"
$ SAY " "
$ SAY " This command procedure performs VAX/VMS software updates and"
$ SAY " optional  software  installations  for  VAX/VMS  Release  4."
$ SAY " During this sequence, the standard  console  medium will not"
$ SAY " be present in the console  drive. Therefore,  the system may"
$ SAY " be vulnerable to a power  failure or other fatal crash. If a"
$ SAY " system  crash  should  occur  during  this period the update"
$ SAY " sequence  can  be  restarted  at  the beginning of the first"
$ SAY " incomplete update."
$ SAY " "
$ SAY " Dismount the current console medium."
$
$ IF F$GETSYI("TAILORED") THEN GOTO BAD_CONFIGURATION
$ IF F$SEARCH("SYS$SPECIFIC:[000000]SYSCOMMON.DIR") .NES. "" -
			THEN GOTO BAD_CONFIGURATION
$CONNECT_CONSOLE:
$ RUN SYS$SYSTEM:SYSGEN
CONNECT CONSOLE
$ IF F$GETDVI("CSA1:","MNT") THEN DISMOUNT CSA1:
$ SAY " "
$ SAY " Please place the first volume in the console drive"
$ SAY " "
$ 20:
$ INQUIRE READY "Are you ready to continue?"
$ IF .NOT. READY THEN GOTO 20
$ GOTO 30
$
$ 25:
$ SAY " "
$ SAY " Please place the next volume in the console drive"
$ SAY " "
$ INQUIRE READY "Are you ready to continue?"
$ IF .NOT. READY THEN GOTO 25
$
$ 30:
$ SET UIC [001,004]
$ SET DEFAULT SYS$DISK:[SYSUPD]
$ MOUNT/NOWRITE/OVER=ID CSA1: 
$ IF .NOT. $STATUS THEN GOTO DONE
$ IF .NOT. F$GETDVI("CSA1","MNT") THEN GOTO LBL_ERROR
$ FILE := 'F$GETDVI("CSA1","VOLNAM")'.COM
$ GOTO EXECUTE_PROCEDURE
$
$ LBL_ERROR:
$ SAY " "
$ SAY " Unable to determine volume label"
$ GOTO DONE
$
$ EXECUTE_PROCEDURE:
$ COPY CSA1:'FILE SYS$DISK:
$ @'FILE
$ SET UIC 'DEFUIC'
$ SET DEFAULT 'SYSDISK'[SYSUPD]
$ DELETE 'FILE;*
$
$DISMOUNT_KIT:
$ DISMOUNT CSA1:
$ SAY " "
$ INQUIRE READY "Are there more kits to process?"
$ IF READY THEN GOTO 25
$ EXIT_MESSAGE = " Requested update sequence is complete."
$
$DONE:
$ ON CONTROL_Y THEN GOTO CLEAN_UP
$ SET NOON
$
$ IF .NOT. F$GETDVI("CSA1:", "EXISTS") THEN GOTO CLEAN_UP
$ IF F$GETDVI("CSA1:", "MNT") THEN DISMOUNT CSA1:
$ IF CPU_TYPE .EQ. 3 THEN GOTO 730_CONSOLE
$ SAY " "
$ SAY " Please place the system console medium in the console drive."
$ SAY " "
$ INQUIRE READY "Are you ready to continue?"
$ IF READY THEN -
	MOUNT/FOREIGN/SYSTEM/PROTECTION=S:RWLP/NOWRITE/NOASSIST CSA1: CONSOLE
$ GOTO CLEAN_UP
$
$730_CONSOLE:
$ IF .NOT. F$GETDVI("CSA2:","MNT") THEN -
	MOUNT/FOREIGN/SYSTEM/PROTECTION=S:RWLP/NOWRITE/NOASSIST CSA2: CONSOLE
$
$CLEAN_UP:
$ IF F$TRNLNM ("SYS$KIT") .NES. "" THEN DEASSIGN SYS$KIT
$ IF F$TRNLNM ("DX1") .NES. "" THEN DEASSIGN DX1
$ IF F$TRNLNM ("DXA1") .NES. "" THEN DEASSIGN DXA1
$ IF F$TRNLNM ("VMS$STARLET") .NES. "" THEN DEASSIGN VMS$STARLET
$ IF F$TRNLNM ("VMS$HELPLIB") .NES. "" THEN DEASSIGN VMS$HELPLIB
$ IF "''DEFUIC'" .NES. "" THEN SET UIC 'DEFUIC'
$ IF "''SAVE_DEFAULT'" .NES. "" THEN SET DEFAULT 'SAVE_DEFAULT
$ SAY EXIT_MESSAGE
$ SET ON
$ EXIT
$BAD_CONFIGURATION:
$ SAY ""
$ SAY "This product may not be installed on this software configuration."
$ SAY "Consult your local Digital office for assistance."
$ SAY ""
$ GOTO CLEAN_UP
