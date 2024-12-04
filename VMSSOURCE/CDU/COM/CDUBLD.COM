$ !
$ !	BUILD THE COMMAND DEFINITION UTILITY
$ !
$ GOTO 'PHASE'
$
$INIT:
$ !
$ ! Create the directories
$ !
$ @SYSBLDCOM$:CREATEDIR
$ EXIT
$
$UPDATE:
$ !
$ !	Create updated sources.
$ !
$ DELETE SRC$:*.*;*
$ SRCUPDATE CDUREQ.R32
$ SRCUPDATE CLI5DEF.R32			! Should never change.
$ SRCUPDATE GENRALREQ.R32
$ EXIT
$
$SRCLIB:
$ EXIT
$
$ASSEM:
$ !
$ ! Do the compilations
$ !
$ PURGE OBJ$:*.OBJ,*.OBB,LIS$:*.LIS
$ @SYSBLDCOM$:FASM 'FACNAM' "" NOLIB 'UPDATES'
$ CPYSYSMSG OBJ$:CDUMSGS.OBB
$ EXIT
$
$OBJLIB:
$ !
$ ! Create the object library
$ !
$ @SYSBLDCOM$:OBJLIB CDU
$ EXIT
$
$LNKLIB:
$ EXIT
$
$LINK:
$ !
$ ! Create the linked image and map
$ !
$ @COM$:CDULNK
$ EXIT
$
$RESULT:
$ !
$ ! Copy everything to the result area.
$ !
$ CPYRESEXE EXE$:CDU.EXE
$ CPYRESMAP MAP$:CDU.MAP
$ CPYRESLIS LIS$:*.LIS CDU.LSS
