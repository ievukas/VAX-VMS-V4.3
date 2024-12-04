$ !
$ !	[B A D . C O M] B A D L N K . C O M
$ !
$
$ ! Link BAD for the ANALYZE/MEDIA command.
$
$ delete exe$:analyzbad.exe;*, map$:analyzbad.map;*
$ debug := "/notraceback"
$ if p1 .nes. "" then debug := "/debug"
$ link 'debug' -
	/executable=exe$:analyzbad -
	/map=map$:analyzbad/full/cross_reference -
	sys$input:/options
	lib$:analyzbad/include=(badblocks, baddata, badinit, badio,-
				badmain, badmsg, badreport),-
	resobj$:vmount/include=chksm2
	psect=$plit$,exe
