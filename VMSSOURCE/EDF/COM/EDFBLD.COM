$ !
$ !	[ EDF.COM ] E D F B L D . C O M
$ !
$ !
$ !	Assumes [EDF] and definitions for  EXE$:,OBJ$:,LIS$:,
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
$ SRCUPDATE EDFHLP.HLP
$ SRCUPDATE EDFMSG.MSG
$ SRCUPDATE EDFSTRUCT.SDL
$ SRCUPDATE EDFVALUE.PAS
$ EXIT
$
$SRCLIB:
$ !
$ !	Re-create the Help library
$ !
$ LIBRARY/CREATE=(BLOCKS=35,MODULES=20,GLOBALS=0)/HELP OBJ$:EDFHLP SRC$:EDFHLP
$ SDL-
/VMS-
/COPYRIGHT-
/LIST=LIS$:/LANGUAGE=(BLISS=LIB$:,PASCAL=LIB$:)-
 SRC$:EDFSTRUCT
$ PASCAL/NOOBJ/ENV=LIB$: LIB$:EDFSTRUCT
$ DELETE LIB$:EDFSTRUCT.PAS;*
$ MESSAGE/SDL=LIB$:EDFSDLMSG SRC$:EDFMSG
$ SDL-
/VMS-
/COPYRIGHT-
/LIST=LIS$:/LANGUAGE=PASCAL=LIB$:-
 LIB$:EDFSDLMSG
$ PASCAL/NOOBJ/ENV=LIB$: LIB$:EDFSDLMSG
$ DELETE LIB$:EDFSDLMSG.PAS;*,LIB$:EDFSDLMSG.SDL;*
$ EXIT
$
$ASSEM:
$ !
$ !	Purge and re-create the objects, listings, and environment files
$ !
$ PURGE OBJ$:*.OBJ,*.OBB,LIS$:*.LSS,*.LIS,LIB$:*.PEN
$ @SYSBLDCOM$:FASM 'FACNAM "" N 'UPDATES
$ CPYSYSMSG OBJ$:EDFMSG.OBB
$ EXIT
$
$OBJLIB:
$ !
$ !	Create object library from object modules.
$ !
$ @SYSBLDCOM$:OBJLIB EDF
$ EXIT
$
$LNKLIB:
$ !
$ !	Null lnklib phase
$ !
$ EXIT
$
$LINK:
$ !
$ !	Delete EDF map and image then re-create EXE$:EDF.EXE
$ !			and MAP$:EDF.MAP
$ !
$ DELETE EXE$:EDF.EXE;*,MAP$:EDF.MAP;*
$ @COM$:EDFLNK
$ EXIT
$
$RESULT:
$ !
$ !	Copy the EXEs and MAPs to a System area
$ !
$ CPYRESEXE EXE$:EDF.EXE
$ CPYRESMAP MAP$:EDF.MAP
$ CPYSYSHLP OBJ$:EDFHLP.HLB
$ !
$ !	Build the concatenated listing LIS$:EDF.LSS
$ !
$ CPYRESLIS LIS$:*.LIS EDF.LSS
