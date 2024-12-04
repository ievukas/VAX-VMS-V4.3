$ !
$ ! Command procedure to invoke an editor for MAIL.
$ !
$ ! Inputs:
$ !
$ !	P1 = Input file name.
$ !	P2 = Output file name.
$ !
$ ! If MAIL$EDIT is undefined, MAIL will invoke callable EDT.
$ ! If MAIL$EDITis defined to be a command procedure,
$ ! MAIL will create a subprocess to edit the mail.
$ !
$ ! Note that this procedure is run in the context of a subprocess.
$ ! LOGIN.COM is not executed.  However, all process logical names
$ ! and DCL global symbols are copied.
$ !
$ ! The default directory is the same as the parent process
$ !
$ DEFINE /USER SYS$INPUT 'F$TRNLNM("SYS$OUTPUT")'
$ IF P1 .EQS. "" THEN GOTO NOINPUT
$ EDIT /OUTPUT='P2' 'P1'
$ EXIT
$NOINPUT:
$ EDIT 'P2'
$ EXIT
