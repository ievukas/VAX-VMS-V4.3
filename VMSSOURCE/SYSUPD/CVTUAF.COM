$ ON ERROR THEN GOTO CVT_ERROR
$ !
$ ! [ SYSUPD ] C V T U A F . C O M
$ !
$ ! This command procedure converts a Release 3 formatted SYSUAF.DAT to
$ ! Release 4 format.  To effect the conversion:
$ !
$ !	$ @[SYSUPD]CVTUAF [UAF-filename]
$ !
$ ! The necessary privilege is read access to the old SYSUAF.DAT and write
$ ! access to its directory.
$ !
$ UAFNAME = P1
$ IF UAFNAME .EQS. "" THEN INQUIRE UAFNAME "Enter the file name of the UAF to be converted"
$ IF UAFNAME .EQS. "" THEN UAFNAME = "SYS$SYSTEM:SYSUAF.DAT"
$ IF F$SEARCH (UAFNAME) .EQS. "" THEN GOTO NO_UAF
$ ASSIGN 'UAFNAME' NEWUAF
$ ASSIGN 'UAFNAME' OLDUAF
$ RUN SYS$SYSTEM:CVTUAF
$ DEASSIGN OLDUAF
$ DEASSIGN NEWUAF
$EXIT
$NO_UAF:
$ WRITE SYS$OUTPUT "Authorization file ", UAFNAME, " does not exist"
$ EXIT
$CVT_ERROR:
$ WRITE SYS$OUTPUT "Conversion did not complete successfully"
