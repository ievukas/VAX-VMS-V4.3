$ !			D S R U T L L N K . C O M
$ !
$ QUAL:=DEBUG
$ IF "''P1'" .EQS. "" THEN QUAL := NOTRACE
$ !
$ ! Link command for DSRTOC, the table of contents utility
$ !
$ LINK  /NOTRACE /EXE=EXE$:dsrtoc /MAP=MAP$:dsrtoc /CROSS /FULL /'QUAL' -
	LIB$:dsrtoc/LIBRARY/INCLUDE=cntvrs, -
	LIB$:runoff/LIBRARY, -
	SYS$LIBRARY:xport/LIBRARY/INCLUDE=xportmsg,-
	SYS$INPUT/OPT
PSECT=$PLIT$,EXE
$ !
$ ! Link command for DSRINDEX, the two-column index utility
$ !
$ LINK  /NOTRACE /EXE=EXE$:dsrindex /MAP=MAP$:dsrindex /CROSS /FULL /'QUAL' -
	LIB$:dsrindex/LIBRARY/INCLUDE=ndxvrs, -
	LIB$:runoff/LIBRARY, -
	SYS$LIBRARY:xport/LIBRARY/INCLUDE=xportmsg,-
	SYS$INPUT/OPT
PSECT=$PLIT$,EXE
