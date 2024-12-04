$ !
$ !	Submit an ASMONE batch job to re-assemble a particular module.
$ !	This has the advantage over interactive ASMONE in that the log
$ !	file is kept around, and it makes it easy to submit multiple jobs.
$ !
$ !	P1 = Facility name
$ !	P2 = Module name
$ !
$ !	Assumes result disk = BLD$$:
$ !
$ !	Puts the log in BLD$$:[SYSBLDCOM]ASMONE_xxx.LOG
$ !
$ submit sysbldcom$:asmone -
	/notify -
	/queue=sys$build -
	/log=bld$$:[sysbldcom]asmone_'p1' /noprint -
	/param=('p1','p2',bld$$:)
