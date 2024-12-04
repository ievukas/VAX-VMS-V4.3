$ !
$ !	DXCOPY.COM - Copy files between console device and current directory
$ !		     The files copied are assumed to be in standard format
$ !		     as determined by file type.
$ !
$ WRITE SYS$OUTPUT " "
$ WRITE SYS$OUTPUT "	Command file to copy files to/from the system"
$ WRITE SYS$OUTPUT "	console storage medium and the current directory."
$ WRITE SYS$OUTPUT " "
$ PRIVS = F$SETPRV ("CMKRNL,SYSNAM")
$ IF .NOT. F$PRIVILEGE ("CMKRNL,SYSNAM") THEN GOTO NOPRIVS
$ ON CONTROL THEN GOTO EXIT
$ ON WARNING THEN GOTO EXIT
$ !
$ ! Now we ask "MOUNTED", but we mean present in the drive
$ !
$ASK_MOUNT:
$ WRITE SYS$OUTPUT "Is system console storage medium mounted (is the console floppy"
$ INQUIRE ALREADY_MOUNTED "or TU58 now in _CSA1:)?  (Y/N)"
$ IF ALREADY_MOUNTED .EQS. "" THEN GOTO ASK_MOUNT
$ IF ALREADY_MOUNTED THEN GOTO MOUNTED
$ WRITE SYS$OUTPUT "Please place the system console medium in the console drive"
$ INQUIRE MOUNT "CSA1: and type <ret> when ready"
$
$MOUNTED:
$ IF F$GETDVI ("CSA1:", "EXISTS") THEN GOTO CONSOLE_EXISTS
$ WRITE SYS$OUTPUT "Running the SYSGEN utility to connect the console subsystem."
$ RUN SYS$SYSTEM:SYSGEN
CONNECT CONSOLE
$
$CONSOLE_EXISTS:
$ IF .NOT. F$GETDVI ("CSA1:", "MNT") THEN WRITE SYS$OUTPUT "Mounting CSA1:"
$ IF F$GETDVI ("CSA1:", "SWL") THEN WRITE SYS$OUTPUT "Remounting CSA1: with write access."
$ IF F$GETDVI ("CSA1:", "SWL") THEN DISMOUNT /NOUNLOAD CSA1:
$ IF .NOT. F$GETDVI ("CSA1:", "MNT") THEN MOUNT /FOREIGN CSA1: "VAX console"
$
$ASK_DIRECTION:
$ INQUIRE DIR "Copy from console medium (Y/N)?"
$ IF DIR .EQS. "" THEN GOTO ASK_DIRECTION
$ IF DIR THEN GOTO FROMCON
$
$ASK_SOURCE:
$ INQUIRE SOURCE "Enter file(s) to be copied to the console"
$ IF SOURCE .EQS. "" THEN GOTO ASK_SOURCE
$ EXCHANGE /NOMESSAGE COPY /LOG 'SOURCE' CSA1:
$ GOTO EXIT
$
$FROMCON:
$ INQUIRE SOURCE "Enter file(s) to be copied from the console"
$ IF SOURCE .EQS. "" THEN GOTO FROMCON
$ EXCHANGE /NOMESSAGE COPY /LOG CSA1:'SOURCE' *
$
$EXIT:
$ SET NOCONTROL=Y
$ SET NOON
$ IF .NOT. F$GETDVI ("CSA1:", "EXISTS") THEN RESET_PRIVS
$ IF F$GETDVI ("CSA1:", "MNT") THEN DISMOUNT CSA1:
$ WRITE SYS$OUTPUT "Remounting console /NOWRITE for protection from non-privileged users."
$ MOUNT/SYSTEM/FOR/NOWRITE CSA1: "VAX console"
$RESET_PRIVS:
$ PRIVS = F$SETPRV (PRIVS)
$ SET CONTROL=Y
$ EXIT
$
$NOPRIVS:
$ WRITE SYS$OUTPUT "%DXCOPY-F-NOPRIV, need CMRKNL and SYSNAM privs to connect and mount console"
