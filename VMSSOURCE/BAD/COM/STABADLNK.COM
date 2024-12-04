$ !
$ !	[ B A D . C O M ] S T A B A D L N K . C O M
$ !	Link standalone BAD (ANALYZE/MEDIA)
$ !
$ delete obj$:stabad.exe;*,map$:stabad.map;*
$ link	/exe=exe$:stabad-
	/map=map$:stabad/full/cross/nosysshr/notrace sys$input:/option
	    lib$:analyzbad/include=(analyzcmd,badstasys,badmain,badinit,-
		 badio,badblocks,badreport,baddata,badmsg),-
	    resobj$:dcl/library/include=(staclint,stastub),-
	    resobj$:cdu/include=(upgrade),-
	    resobj$:cliutl/include=(cvttime),-
	    resobj$:sysboot/include=(actimage),-
	    resobj$:vmount/include=(chksm2),-
	    resobj$:backup/include=(othermsg),-
	    exsm:sys.stb/selective
	    dzro_min=1
