$ !
$ ! Link the CLI utility program "RUNDET"
$ !
$ qual := notrace
$ if p1 .nes. "" then qual := debug
$ delete exe$:rundet.exe;*, map$:rundet.map;*
$ link/exe=exe$:rundet/map=map$:rundet/full/cross/'qual' -
lib$:cliutl/include=(rundet,runmsg,chrsub,cnvcliatb,cnvclinum,cvttime)
$ SET NOVER
