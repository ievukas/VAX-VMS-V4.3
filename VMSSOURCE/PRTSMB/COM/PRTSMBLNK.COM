$ !
$ ! LINK COMMAND FILE FOR PRTSMB
$ !
$ QUAL:=DEBUG
$ IF P1 .EQS. "" THEN QUAL := NOTRACE
$ DELETE EXE$:PRTSMB.EXE;*, MAP$:PRTSMB.MAP;*
$ LINK	/EXE=EXE$:PRTSMB -
	/MAP=MAP$:PRTSMB /CROSS /FULL -
	/'QUAL' -
		-
	LIB$:PRTSMB /INCLUDE=PRTSMB
