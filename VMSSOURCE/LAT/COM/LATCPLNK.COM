$ !
$ !	Link LATCP
$ !
$ DELETE EXE$:LATCP.EXE;*, MAP$:LATCP.MAP;*
$ LINK /EXE=EXE$:LATCP -
	/MAP=MAP$:LATCP/FULL/CROSS/NOTRACE -
	LIB$:LAT/INCLUDE=(LATCP,LCP_COMMANDS,LATCPMSG), -
	EXSM:SYS.STB/SELECTIVE
