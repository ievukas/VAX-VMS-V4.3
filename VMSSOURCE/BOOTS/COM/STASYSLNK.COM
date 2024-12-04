$ !
$ ! [BOOTS.COM]STASYSLNK.COM - Command file to link standalone SYSGEN Utility
$ !
$ ! Assumes the following definitions:
$ !
$ !	COM$:	= COMD$:[BOOTS.COM]	command and option files
$ !	EXE$:	= EXED$:[BOOTS.OBJ]	image file, experimental
$ !		= RESOBJD$:		image file, stable
$ !	LIB$:	= LIBD$:[BOOTS.OBJ]	object library, experimental
$ !		= RESOBJ$:		object library, stable
$ !	MAP$:	= MAPD$:[BOOTS.LIS]	map file, experimental
$ !		= RESOBJ$:		map file, stable
$ !	OBJ$:	= OBJD$:[BOOTS.OBJ]	symbol table file, experimental
$ !		= RESOBJ$:		symbol table file, stable
$ !	RESOBJ$:= RESD$:[SYSTEM.OBJ]	other object libraries (old [10,20])
$ !	EXSM:	= RESOBJ$:		exec symbol table, experimental
$ !		= SYS$SYSTEM:		exec symbol table, stable
$ !
$ LINK /NOSYSSHR /NOSYSLIB /EXE=EXE$:STASYSGEN /MAP=MAP$:STASYSGEN /FULL /CROSS /NOTRACE -
	LIB$:SYSBOOT.OLB/INCLUDE:(-
		ACTIMAGE,-
		AUTOCONFG,-
		LOADDRIV,-
		LOADER,-
		LOADERSUB,-
		READPRMPT,-
		SCSLOADER,-
		SHODEV,-
		STALOCK,-
		STAPUTERR,-
		STARDDRIV,-
		STASGNMSG,-
		STASYSGEN,-
		SYSGEN),-
	RESOBJ$:SYS.OLB/INCLUDE:(-
		LINKVEC,-
		PARAMETER,-
		RELOCDRV,-
		SYSPARAM),-
	SYS$LIBRARY:STARLET.OLB/INCLUDE:(-
		LIB$SIGNAL,-
		SYS$IODEF,-
		SYS$SSDEF,-
		SYS$P1_VECTOR),-
	EXSM:SYS.STB/SELECTIVE,-
	SYS$INPUT/OPTIONS
!
! Options:  minimize size of image by reducing the minimum size of demand zero
!	    sections
DZRO_MIN=1
!
! Zero out some symbols here
!
SYMBOL=NAM$B_RSL,0	! If anybody thinks they are going to use RMS, they are
SYMBOL=NAM$L_RSA,0	!  pretty badly confused.  One module in SYSGEN which we
			!  won't be needing uses these offsets.
