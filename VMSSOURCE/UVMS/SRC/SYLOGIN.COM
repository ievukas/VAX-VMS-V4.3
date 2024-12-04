$! Enable control-T for interactive processes.
$
$	IF F$MODE() .EQS. "INTERACTIVE" THEN SET CONTROL=T
$
$! For the system manager's account, define some special symbols.
$
$	ACNT_NAME = F$GETJPI(0,"USERNAME")
$	ACNT_NAME = F$EDIT(ACNT_NAME,"COLLAPSE")
$	IF ACNT_NAME .NES. "SYSTEM" THEN GOTO ALL_ACNTS
$
$	! Define shutdown commands
$
$	SHUTDOWN  == "@SYS$SYSTEM:SHUTDOWN 0 SHUTDOWN YES NO LATER NO NONE"
$	SHUTDOWN1 == "@SYS$SYSTEM:SHUTDOWN"
$
$	! Define command for removing a MicroVMS option from the
$	! system disk.
$
$	REMOVE == "@SYS$UPDATE:REMOVE SYS$UPDATE:VMSKITBLD.DAT"
$
$ALL_ACNTS:
$
$	INSTALL :== $INSTALL/COMMAND
$	INI*ITIALIZE :== INITIALIZE/NOHIGHWATER
$	MOU*NT :== MOUNT/NOASSIST
$	IF F$MODE() .EQS. "INTERACTIVE" THEN SET TERMINAL/INQUIRE
$DONE:
$	EXIT
