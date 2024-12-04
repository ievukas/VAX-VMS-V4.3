$ !
$ !	Create an object library from .OBJ files with the name 'P1'.
$ !
$ !	P1 - Facility name
$ !	P2 - no. of blocks
$ !	P3 - no. of globals
$ !	P4 - no. of modules
$ !	P5 - NO for /NOGLOBALS
$ !
$ IF F$SEARCH("OBJ$:*.OBJ") .EQS. "" THEN EXIT
$ IF F$SEARCH("OBJ$:LIBRIS.AOK") .NES. "" THEN GOTO L1
$ BLOX = P2
$ GLOBS = P3
$ MODS = P4
$ GLOB_QUAL = ""
$ IF BLOX .EQS. "" THEN BLOX = 100
$ IF GLOBS .EQS. "" THEN GLOBS = 275
$ IF MODS .EQS. "" THEN MODS = 75
$ IF P5 .EQS. "" THEN P5 = "YES"
$ IF .NOT. P5 THEN GLOB_QUAL = "/NOGLOBALS"
$ LIB/CREATE=(BLOCKS='BLOX,GLOBALS='GLOBS,MODULES='MODS) 'GLOB_QUAL' -
	 LIB$:'P1' OBJ$:*.OBJ
$ PURGE LIB$:'P1'.OLB
$ IF CPYOLB THEN CPYRESOBJ LIB$:'P1'.OLB
$ CREATE OBJ$:LIBRIS.AOK
$L1:
$ DELETE OBJ$:*.OBJ;*
$ DELETE OBJ$:LIBRIS.AOK;*
