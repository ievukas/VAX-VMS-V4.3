$ !
$ ! STARFIX.COM
$ !
$ !	The BRDCST macro incorrectly defined offsets inside STARLET.MAR
$ !	rather than STARDEFxx.SDL.
$ !
$ !	Here we use the editor to replace the output $BRDCSTDEF macro with
$ !	the old macro before we continue.
$ !
$ !
$EDIT/NOCOMMAND LIB$:STARLET.MAR
FIND '	.MACRO	$BRDCSTDEF'
DELETE . : '	.ENDM	$BRDCSTDEF'
INSERT;;** start of area edited by STARFIX.COM
INSERT;
INSERT;	.MACRO	$BRDCSTDEF,$GBL
INSERT;		$OFFDEF	BRDCST,<MSGBUF,DEVNAM,FLAGS,CARCON>
INSERT;		$DEFINI	BRDCST,$GBL
INSERT;
INSERT;		$VIELD	BRDCST,8,<-
INSERT;			<SCREEN    ,,M>,-
INSERT;			<BOTTOM    ,,M>,-
INSERT;			<REFRSH    ,,M>>
INSERT;		$VIELD	BRDCST,8,<-
INSERT;			<ANSI      ,,M>>
INSERT;
INSERT;		$DEFEND	BRDCST,$GBL,DEF
INSERT;
INSERT;	.ENDM	$BRDCSTDEF
INSERT;
INSERT;;** end of area edited by STARFIX.COM
EXIT
$DIFF/PAR/MATCH=15 LIB$:STARLET.MAR
