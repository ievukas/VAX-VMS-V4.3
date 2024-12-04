$ !
$ !	[ ACLEDT.COM ] A C L E D T B L D . C O M
$ !
$ !
$ !	Assumes [ACLEDT] and definitions for  EXE$:,OBJ$:,LIS$:,
$ !		MAP$:,COM$:
$ !
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
$ !	Create updated sources
$ !
$ DELETE SRC$:*.*;*
$ SRCUPDATE ACLEDTDEF.REQ
$ SRCUPDATE AEDLCLDEF.SDL
$ SRCUPDATE ACLEDT.HLP
$ SRCUPDATE ACLEDIT.INI
$ EXIT
$
$SRCLIB:
$ !
$ !	Create the ACL editor libraries.
$ !
$ LIBRARY/HELP/CREATE LIB$:ACLEDT SRC$:ACLEDT
$ SDL/LANGUAGE=(BLISS=LIB$,MACRO=LIB$) SRC$:AEDLCLDEF
$ LIBRARY/MACRO/CREATE LIB$:ACLEDT LIB$:AEDLCLDEF
$ EXIT
$
$ASSEM:
$ !
$ !	PURGE and re-create the bliss objects and listings
$ !
$ PURGE OBJ$:*.OBJ,*.OBB,LIS$:*.LSS,*.LIS
$ @SYSBLDCOM$:FASM 'FACNAM "" N 'UPDATES
$ CPYSYSMSG OBJ$:AEDMESSAG.OBB
$ EXIT
$
$OBJLIB:
$ !
$ !	Create object library from object modules.
$ !
$ @SYSBLDCOM$:OBJLIB ACLEDT
$ EXIT
$
$LNKLIB:
$ !
$ !	Null LNKLIB phase.
$ !
$ EXIT
$
$LINK:
$ !
$ !	Delete the map and image files, then re-create EXE$:ACLEDT.EXE
$ !	and MAP$:ACLEDT.MAP
$ !
$ DELETE EXE$:ACLEDT.EXE;*,MAP$:ACLEDT.MAP;*
$ @COM$:ACLEDTLNK
$ !
$ !	Delete the map and image files, then re-create EXE$:SETSHOACL.EXE
$ !	and MAP$:SETSHOACL.MAP
$ !
$ DELETE EXE$:SETSHOACL.EXE;*,MAP$:SETSHOACL.MAP;*
$ @COM$:SETSHOLNK
$ EXIT
$
$RESULT:
$ !
$ !	Copy the .EXE, .MAP, and help files to a System area
$ !
$ CPYRESEXE EXE$:ACLEDT.EXE
$ CPYRESMAP MAP$:ACLEDT.MAP
$ CPYSYSHLP LIB$:ACLEDT.HLB
$ CPYSYSLIB SRC$:ACLEDIT.INI
$ CPYRESEXE EXE$:SETSHOACL.EXE
$ CPYRESMAP MAP$:SETSHOACL.MAP
$ !
$ !	Build the concatenated listing LIS$:ACLEDT.LSS
$ !
$ CPYRESLIS LIS$:*.LIS ACLEDT.LSS
