$ !
$ !	Update require file sources with SLP changes
$ !
$ DELETE SRC$:*.*;*
$ SRCUPDATE FCPDEF.B32
$ CPYSHRLIB SRC$:FCPDEF.B32
