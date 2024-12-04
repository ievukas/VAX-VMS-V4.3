$ !
$ !	[ D C X . C O M ] D C X A S N R E Q . C O M
$ !
$ !	Commmand procedure to define require file logical names to compile
$ !	 the data compression / expansion procedures.
$ !
$ DEFINE PREFIX SRC$:PREFIX.REQ
$ DEFINE DCXDEF LIB$:DCXDEF.B32
$ DEFINE DCXPRVDEF LIB$:DCXPRVDEF.B32
$ DEFINE DCXMSG LIB$:DCXMSG.B32
