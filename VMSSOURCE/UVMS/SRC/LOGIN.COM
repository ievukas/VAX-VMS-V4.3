$! This command procedure is a framework for building individual
$! login command procedures
$
$! Commands you want executed no matter mode of login
$
$  IF F$MODE() .NES. "INTERACTIVE" THEN GOTO ENDINTER
$! Commands you want executed only in interactive mode
$  E*DIT :== EDIT/EDT/COMMAND=SYS$LOGIN:EDTINI.EDT
$
$ENDINTER:
$  IF F$MODE() .NES. "BATCH" THEN GOTO ENDBATCH
$! Commands you want executed only in batch mode
$ENDBATCH:
