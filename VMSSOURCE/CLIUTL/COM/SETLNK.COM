$ !
$ !	SETLNK.COM	- LINK COMMAND FILE FOR SET
$ !
$ QUAL := NOTRACE
$ IF P1 .NES. "" THEN QUAL := DEBUG
$ DELETE EXE$:SET.EXE;*, MAP$:SET.MAP;*
$ LINK /EXE=EXE$:SET /MAP=MAP$:SET/FULL/CROSS /NOSYSSHR /'QUAL' -
	LIB$:CLIUTL/INCLUDE=SETMAIN/LIBRARY,-
	RESOBJ$:LIBRTL/LIBRARY,-
	RESOBJ$:MSCP/INCL=ADDUNIT,-
	RESOBJ$:VMOUNT/INCL=(CHKSM2,CHNUCB,ERASE,LEFTONE,REBUILD),-
	RESOBJ$:F11BXQP/INCL=(CHKSUM,GETPTR),-
	EXSM:SYS.STB/SELECTIVE,-
	SYS$INPUT/OPTION
PSECT=$PLIT$,EXE
PSECT=$MSG_TEXT,EXE	! From VMOUNT\REBUILD
PSECT=$MSG_INDEX,EXE	! From VMOUNT\REBUILD
