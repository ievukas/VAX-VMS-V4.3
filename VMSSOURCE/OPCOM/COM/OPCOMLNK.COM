$ !
$ !	[OPCOM.COM]OPCOMLNK.COM
$ !
$ !	VAX/VMS OPERATOR COMMUNICATIONS IMAGES LINK COMMAND FILE
$ !		OPCOM.EXE,REPLY.EXE AND REQUEST.EXE
$ !
$LINK  /NOTRACE /NOSYSSHR -
		/EXECUTABLE=EXE$:OPCOM -
		/MAP=MAP$:OPCOM /FULL /CROSS -
		/SYMBOL=EXE$:OPCOM -
		EXSM:SYS.STB /SELECTIVE, -
		SYS$INPUT /OPTIONS
CLUSTER=OPCOM,,1,LIB$:OPCOM /INCLUDE=OPC$OPCOMMAIN /LIBRARY
$
$LINK  /NOTRACE /NOSYSSHR -
		/EXECUTABLE=EXE$:REPLY -
		/MAP=MAP$:REPLY /FULL /CROSS -
		/SYMBOL=EXE$:REPLY -
		LIB$:OPCOM /INCLUDE=OPC$REPLYMAIN /LIBR
$
$LINK  /NOTRACE /NOSYSSHR -
		/EXECUTABLE=EXE$:REQUEST -
		/MAP=MAP$:REQUEST /FULL /CROSS -
		/SYMBOL=EXE$:REQUEST -
		LIB$:OPCOM /INCLUDE=OPC$RQSTMAIN /LIBR
$
$LINK  /NOTRACE /NOSYSSHR -
		/EXECUTABLE=EXE$:OPCCRASH -
		/MAP=MAP$:OPCCRASH /FULL /CROSS -
		/SYMBOL=EXE$:OPCCRASH -
		LIB$:OPCOM /INCLUDE=OPCCRASH /LIBR, -
		EXSM:SYS.STB /SELECTIVE
