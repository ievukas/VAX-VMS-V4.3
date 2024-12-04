$ ON ERROR THEN GOTO CVT_ERROR
$ !
$ ! [ SYSUPD ] C V T N A F . C O M
$ !
$ ! This command procedure converts a Release 3 formatted NETUAF.DAT to
$ ! Release 4 format.  To effect the conversion:
$ !
$ !	$ @[SYSUPD]CVTNAF [proxy-filename]
$ !
$ ! The necessary privilege is read access to the old NETUAF.DAT and write
$ ! access to its directory.
$ !
$ NAFNAME = P1
$ IF NAFNAME .EQS. "" THEN INQUIRE NAFNAME "Enter the file name of the proxy file to be converted"
$ IF NAFNAME .EQS. "" THEN NAFNAME = "SYS$SYSTEM:NETUAF.DAT"
$ IF F$SEARCH (NAFNAME) .EQS. "" THEN GOTO NO_NAF
$ ASSIGN 'NAFNAME' NEWNAF
$ ASSIGN 'NAFNAME' OLDNAF
$ RUN SYS$SYSTEM:CVTNAF
$ DEASSIGN OLDNAF
$ DEASSIGN NEWNAF
$EXIT
$NO_NAF:
$ WRITE SYS$OUTPUT "Network proxy file ", NAFNAME, " does not exist"
$ EXIT
$CVT_ERROR:
$ WRITE SYS$OUTPUT "Conversion did not complete successfully"
