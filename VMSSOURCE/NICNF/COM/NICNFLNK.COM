$ !
$ !	[NICNF.COM]NICNFLNK.COM	- Link NICONFIG
$ !
$ DELETE EXE$:NICONFIG.EXE;*, MAP$:NICONFIG.MAP;*
$ LINK /EXE=EXE$:NICONFIG -
	/MAP=MAP$:NICONFIG /FULL /CROSS -
	/NOSYSSHR /NOTRACE -
	LIB$:NICONFIG/LIBRARY/INCLUDE=( CNFMAIN )
