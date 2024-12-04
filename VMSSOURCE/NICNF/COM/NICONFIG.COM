$ SET NOON
$ IF "''NICONFIG$COMMAND'" .NES. "" THEN NICONFIG$COMMAND
$ RUN SYS$SYSTEM:NICONFIG.EXE
$!
$! NICONFIG provides support for the DECnet CONFIGURATOR MODULE
$!
$! Copyright (C) 1982
$! Digital Equipment Corporation, Maynard, Massachusetts 01754
