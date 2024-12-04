$ !
$ ! Link Disk I/O Monitor
$ !
$ delete exe$:diskmon.exe;*,map$:diskmon.map;*
$ link /exe=exe$:diskmon /map=map$:diskmon/full/cross /notrace -
	lib$:util32/include=(diskmon,iocollect,get_device_info),-
	exsm:sys.stb/selective
