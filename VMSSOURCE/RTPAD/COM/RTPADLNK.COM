$ !
$ ! LINK COMMAND FILE FOR RTPAD
$ !
$ QUAL := DEBUG
$ IF P1 .EQS. "" THEN QUAL := NOTRACE
$ DELETE EXE$:RTPAD.EXE;*, MAP$:RTPAD.MAP;*
$ LINK /EXE=EXE$:RTPAD /MAP=MAP$:RTPAD/FULL/CROSS /'QUAL' -
	LIB$:RTPAD/INCLUDE=(RTPAD,VMSRT,RSXRT,RSTSRT,CTERMRT,-
		RTVMSPEC,CTSENSERT,CTSETRT,RTMSG,RTLOGIO,RTDTE)/LIBRARY,-
	SYS$INPUT/OPTION
PSECT=$PLIT$,EXE
PSECT=$RMSNAM,NOEXE
PSECT=_RSTSRT,NOEXE
PSECT=_RTPAD,NOEXE
