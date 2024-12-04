$ !
$ !	[SYSBLDCOM] B O O T U P D . C O M - Update bootstrap on console device
$ !
$ ! This command file will update the VMS bootstrap file "VMB.EXE" on the
$ ! console storage device.  The new VMB will be copied from the build
$ ! result disk BLD$$.
$ !
$ WRITE SYS$OUTPUT "		 Command file to update bootstrap image"
$ WRITE SYS$OUTPUT "		 VMB.EXE on the console storage device with"
$ WRITE SYS$OUTPUT "		 the image from the new build."
$ WRITE SYS$OUTPUT " "
$ ON ERROR THEN GOTO 20
$ PRIVS = F$SETPRV("CMKRNL,SYSNAM,SYSPRV")
$ WRITE SYS$OUTPUT "Please place the system console medium in the console drive"
$ INQUIRE CONFIRM "and type <ret> when ready"
$ RUN SYSGEN
CONNECT CONSOLE
$ IF F$GETDVI ("CSA1:","MNT") THEN DISMOUNT CSA1:
$ WRITE SYS$OUTPUT " "
$ MOUNT/SYSTEM/FOR/DATA=WRITE CSA1: "VAX console"
$ WRITE SYS$OUTPUT " "
$ EXCHANGE
RENAME /NOPROTECT CSA1:VMB.EXE CSA1:
COPY /REPLACE /PROTECT /LOG BLD$$:<SYSEXE>VMB.EXE /TRANSFER=BLOCK CSA1:
$ IF .NOT. $STATUS THEN GOTO 18
$
$ WRITE SYS$OUTPUT " "
$ WRITE SYS$OUTPUT "Bootstrap updated from new build."
$ WRITE SYS$OUTPUT " "
$
$ 18:
$ DISMOUNT CSA1:
$ MOUNT/SYSTEM/FOR/NOWRITE CSA1: "VAX console"	! Protect from users
$
$ 20:
$ PRIVS = F$SETPRV (PRIVS)
