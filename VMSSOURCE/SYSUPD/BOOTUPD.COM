$ !
$ !	[SYSUPD] B O O T U P D . C O M - Update bootstrap image on console device
$ !
$ ! This command file will update the VMS bootstrap file "VMB.EXE" on the
$ ! console storage device.  It is assumed that the current default device is
$ ! the system device.  
$ !
$ WRITE SYS$OUTPUT "		 Command file to update bootstrap image"
$ WRITE SYS$OUTPUT "		  on console storage device."
$ WRITE SYS$OUTPUT " "
$ DIR:='F$DIRECTORY()
$ DISK:='F$LOG("SYS$DISK")
$ ON ERROR THEN GOTO 20
$ SET DEF SYS$SYSTEM
$ INQUIRE CONFIRM "Is system console medium mounted (Y/N)"
$ IF CONFIRM THEN GOTO 10
$ WRITE SYS$OUTPUT "Please place the system console medium in the console drive"
$ INQUIRE CONFIRM "and type <ret> when ready"
$ RUN SYSGEN
CONNECT CONSOLE
$ GOTO 15
$
$ 10:
$ DISMOUNT CSA1:
$
$ 15:
$ SET NOON
$ WRITE SYS$OUTPUT " "
$ MOUNT/SYSTEM/FOR/DATA=WRITE CSA1: "VAX console"
$
$ WRITE SYS$OUTPUT " "
$ EXCHANGE
RENAME /NOPROTECT /SYSTEM CSA1:*.* CSA1:
COPY /REPLACE /LOG VMB.EXE /TRANSFER=BLOCK CSA1:
$ IF .NOT. $STATUS THEN GOTO 18
$
$ WRITE SYS$OUTPUT " "
$ WRITE SYS$OUTPUT "Bootstrap updated."
$ WRITE SYS$OUTPUT " "
$
$ 18:
$ DISMOUNT CSA1:
$ MOUNT/SYSTEM/FOR/NOWRITE CSA1: "VAX console"
$
$ 20:
$ SET DEF 'DISK''DIR'
