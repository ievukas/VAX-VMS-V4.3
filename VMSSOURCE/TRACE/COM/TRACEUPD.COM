!	[ T R A C E . C O M ]  T R A C E U P D . C O M
!
!	This file is used to apply the updates to the master copy of the
!	require files during the system build procedure, UPDATE phase.
!
$ DELETE SRC$:*.*;*
$ SRCUPDATE STRUCDEF.REQ
$ SRCUPDATE TBKDST.REQ
$ SRCUPDATE TBKLIB.REQ
$ SRCUPDATE TBKPROLOG.REQ
$ SRCUPDATE TRACEMSG.MDL
