$ !
$ !	Link LATSHUT (no longer needed)
$ !
$ EXIT
$ DELETE EXE$:LATSHUT.EXE;*, MAP$:LATSHUT.MAP;*
$ LINK /EXE=EXE$:LATSHUT -
	/MAP=MAP$:LATSHUT/FULL/CROSS -
	LIB$:LAT/INCLUDE=LATSHUT, -
	EXSM:SYS.STB/SELECTIVE
