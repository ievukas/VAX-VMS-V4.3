$ !
$ ! This links the instruction emulation images for microVAX.  The psects
$ ! are collected into clusters to force the loadable code to be placed
$ ! together and be based at virtual address 0.  This makes debugging
$ ! much easier as symbols in VAXEMUL.STB can be used when looking at the
$ ! emulation code in a dump.
$ !
$ DELETE EXE$:VAXEMUL.EXE;*,EXE$:VAXEMUL.STB;*,MAP$:VAXEMUL.MAP;*
$ LINK /NOSYSSHR /NOTRACEBACK -
	/SHARE=EXE$:VAXEMUL -
	/MAP=MAP$:VAXEMUL /FULL /CROSS -
	/SYMBOL=EXE$:VAXEMUL -
	OBJ$:EMULAT.OLB /INCLUDE=(-
		VAX$LOAD,-
		VAX$EMULATE,-
		VAX$HANDLER,-
		VAX$STATUS,-
		VAX$STRING,-
		VAX$DECIMAL,-
		VAX$CVTLP,-
		VAX$CVTPL,-
		VAX$ASHP,-
		VAX$DECIMAL_ARITHMETIC,-
		VAX$DECIMAL_CONVERT,-
		VAX$EDITPC),-
	EXSM:SYS.STB /SELECTIVE_SEARCH,-
	SYS$INPUT /OPTIONS
		COLLECT = LOADER_FRONT_END , $$$$$$BEGIN
		COLLECT = EMULATOR_DATA , -
			HANDLER_TABLE ,-
			PC_TABLE ,-
			RESTART_PC_TABLE ,-
			_VAX$DATA
		COLLECT = EMULATOR_CODE , -
			_VAX$$$BEGIN ,-
			_VAX$CODE ,-
			_VAX$__END
		COLLECT = LOADER_BACK_END , ____INITHK , ______END
$ !
$ ! Now link the floating point emulator.  This image is used not only by
$ ! microVAX systems bit also by other systems that do not have a particular
$ ! floating point data type implemented in hardware. 
$ !
$ DELETE EXE$:FPEMUL.EXE;*,EXE$:FPEMUL.STB;*,MAP$:FPEMUL.MAP;*
$ LINK /NOSYSSHR /NOTRACEBACK -
	/SHARE=EXE$:FPEMUL -
	/MAP=MAP$:FPEMUL /FULL /CROSS -
	/SYMBOL=EXE$:FPEMUL -
	OBJ$:EMULAT.OLB/INCLUDE=(-
		FP$LOAD,-
		VAX$EMULATE_FP),-
	EXSM:SYS.STB /SELECTIVE_SEARCH
