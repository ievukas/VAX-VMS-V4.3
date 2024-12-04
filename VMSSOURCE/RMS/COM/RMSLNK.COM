$ !
$ !	[ R M S . C O M ] R M S L N K . C O M
$ !
$ !	This command file links RMS as part of the System.
$ !
$ !	Assume default directory is [RMS] and logical names
$ !	COM$, EXE$, EXSM, LIB$, MAP$, OBJ$, RESD$, RESOBJ$, and SYSBLDCOM$
$ !	are defined.
$ !
$ SET NOON
$ !
$ !	Link RMS.
$ !
$ DELETE EXE$:RMS.EXE;*, MAP$:RMS.MAP;*, EXE$:RMS.STB;*
$ LINK /EXE=EXE$:RMS /SYSTEM=0 /HEADER  /NOSYSSHR -
	/MAP=MAP$:RMS/FULL/CROSS -
	/SYMBOLS=EXE$:RMS -
	RESOBJ$:SYS/INCLUDE=SYS$RMS_VECTOR,-
	LIB$:RMS/LIBR,-
	RESOBJ$:INSTAL/LIBR,-
	EXSM:SYS.STB/SELECTIVE_SEARCH
