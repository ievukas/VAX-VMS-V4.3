$ !
$ ! Link DCLDIET
$ !
$ qual := notrace
$ if p1 .nes. "" then qual := debug
$ delete exe$:dcldiet.exe;*, map$:dcldiet.map;*
$ link /exe=exe$:dcldiet /map=map$:dcldiet/full/cross  /'qual' -
	lib$:util32/include=dcldiet
