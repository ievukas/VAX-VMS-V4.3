$ !
$ !	Link NETSERVER image
$ !
$ qual = "notrace"
$ if p1 .nes. "" then qual = "debug"
$ delete exe$:netserver.exe;*, map$:netserver.map;*
$ link/exe=exe$:netserver /map=map$:netserver/full/cross /'qual' -
	lib$:netacp/include=network_server
