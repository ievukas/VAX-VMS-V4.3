$ !
$ !	[ N I C N F . C O M ] N I C N F B L D . C O M
$ !
$ !	THIS COMMAND FILE BUILDS THE NICONFIG IMAGE.
$ !
$ GOTO 'PHASE'
$
$INIT:
$ !
$ !	Create the Directories
$ !
$ @SYSBLDCOM$:CREATEDIR
$ EXIT
$
$UPDATE:
$ !
$ !	Create updated sources.
$ !
$ SRCUPDATE CNFMSG.MSG
$ SRCUPDATE CNFDEF.SDL
$ SRCUPDATE CNFWQDEF.SDL
$ SRCUPDATE CNFPREFIX.REQ
$ EXIT
$
$SRCLIB:
$ !
$ ! Build error message codes and severity levels.
$ !
$ ON ERROR THEN CONTINUE
$ SDL /LANGUAGE=BLISS=LIB$ /LIS=LIS$ SRC$:CNFDEF
$ SDL /LANGUAGE=BLISS=LIB$ /LIS=LIS$ SRC$:CNFWQDEF
$ EXIT
$
$ASSEM:
$ !
$ !	PURGE and re-create the NICONFIG objects and listings
$ !
$ PURGE OBJ$:*.OBJ,*.LIS
$ @SYSBLDCOM$:FASM 'FACNAM "" N 'UPDATES
$ EXIT
$
$OBJLIB:
$ !
$ !	Create object library from object modules.
$ !
$ @SYSBLDCOM$:OBJLIB NICONFIG
$ EXIT
$
$LNKLIB:
$ !
$ ! Null LNKLIB phase
$ !
$ EXIT
$
$LINK:
$ !
$ !	Delete NICONFIG map and image then re-create EXE$:NICONFIG.EXE
$ !			and MAP$:NICONFIG.MAP
$ !
$ DELETE EXE$:NICONFIG.EXE;*, MAP$:.MAP;*
$ @COM$:NICNFLNK
$ EXIT
$
$RESULT:
$ !
$ !	Copy the EXE and MAP to a System area
$ !
$ CPYRESEXE  EXE$:NICONFIG.EXE
$ CPYRESEXE  COM$:NICONFIG.COM
$ CPYRESMAP  MAP$:NICONFIG.MAP
$ !
$ !	Build the concatenated listing RESLIS$:NICONFIG.LSS
$ !
$ CPYRESLIS  LIS$:*.LIS  NICONFIG.LSS
$ EXIT
