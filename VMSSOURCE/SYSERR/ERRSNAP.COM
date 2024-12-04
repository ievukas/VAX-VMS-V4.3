$!
$! This procedure is NOT meant to be run interactively.  It is SPAWNed by the
$! program ERRFMT.EXE if ERRFMT is notified that a valid VENUS error snapshot
$! file exists on the VENUS console disk.  This command procedure copies the
$! file into the SYS$ERRORLOG directory.
$!
$! Inputs:
$!	FILENAME - a DCL symbol defined to be the name of the error snapshot
$!		   file on the console disk
$!
$! Outputs:
$!	The file is copied from the console disk to SYS$ERRORLOG:ERRSNAP.LOG
$!	The symbol $STATUS indicates whether the copy operation was successful.
$!
$ IF F$MODE() .NES. "OTHER" THEN EXIT
$
$ SYSOUT := WRITE SYS$OUTPUT
$ SYSOUT ""
$ SYSOUT "%ERRFMT-I-ERRORSNAP, The ERRFMT process has been notified that a"
$ SYSOUT "snapshot of the hardware state was stored in a file on the console
$ SYSOUT "disk at the time of the last processor error.  This file will be"
$ SYSOUT "copied to SYS$ERRORLOG:ERRSNAP.LOG.  The console disk will now be"
$ SYSOUT "mounted so that this error snapshot file can be accessed."
$ SYSOUT ""
$ IF F$GETDVI("CSA1:","EXISTS") THEN GOTO CONSOLE_EXISTS
$ RUN SYS$SYSTEM:SYSGEN
CONNECT CONSOLE
$ !
$CONSOLE_EXISTS:
$ IF .NOT. F$GETDVI("CSA1:","MNT") THEN GOTO CONSOLE_MOUNT
$ IF F$GETDVI("CSA1:","FOR") THEN GOTO CONSOLE_DISMOUNT
$ SYSOUT "%ERRFMT-E-FIL11_DEV, console device is already mounted as FILES-11"
$ STATUS = 4
$ GOTO ABORT
$ !
$CONSOLE_DISMOUNT:
$ ON ERROR THEN CONTINUE
$ DISMOUNT CSA1:
$ STATUS = $STATUS
$ IF .NOT. STATUS THEN GOTO ABORT
$ !
$CONSOLE_MOUNT:
$ MOUNT/NOASSIST/FOREIGN/NOWRITE CSA1: "VAX console"
$ STATUS = $STATUS
$ IF .NOT. STATUS THEN GOTO ABORT
$
$ DEFINE/USER FILE CSA1:'FILENAME'
$ EXCHANGE COPY FILE /TRANSFER_MODE=BLOCK SYS$ERRORLOG:ERRSNAP.LOG
$ STATUS = $STATUS
$ IF .NOT. STATUS THEN GOTO ABORT
$ SYSOUT "%ERRFMT-I-COPIED, file SYS$ERRORLOG:ERRSNAP.LOG copied successfully."
$
$CLEAN_UP:
$ IF F$GETDVI("CSA1:","MNT") THEN DISMOUNT CSA1:
$ MOUNT/NOASSIST/FOREIGN/SYSTEM/NOWRITE CSA1:
$ EXIT STATUS
$
$ABORT:
$ ON ERROR THEN CONTINUE
$ SYSOUT "%ERRFMT-F-ABORT, procedure to copy error snapshot file aborted."
$ GOTO CLEAN_UP
