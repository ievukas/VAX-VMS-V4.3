$ !
$ !	[ S O R T 3 2 . C O M ] S O R T 3 2 L N K . C O M
$ !
$ !	Command file to link SORTMERGE.EXE
$ !
$ DELETE EXE$:SORTMERGE.EXE;*,MAP$:SORTMERGE.MAP;*
$ LINK/NOTRACE	-
/EXE=EXE$:SORTMERGE	-	! Executable image
/MAP=MAP$:SORTMERGE/FULL/CROSS	-	! Link map
LIB$:SORTMERGE/INCL=(-
SOR$ENTRY,-	! Main entry point
SOR$COMMAND,-	! Command line processing
UTIL$CHK_CLI,-	! CLI interface for checkpointing
SOR$OUTPUT,-	! Terminal output
LIB$FIXUP_DEC),-! Repair decimal reserved operands
SYS$INPUT/OPTIONS
EXE$:SORTSHR/SHARE
PSECT=$PLIT$,PIC,SHR,EXE
PSECT=$CODE$,PIC,SHR
COLLECT=CODE,$CODE$,$PLIT$,SOR$RO_CODE,_LIB$CODE
$ EXIT
