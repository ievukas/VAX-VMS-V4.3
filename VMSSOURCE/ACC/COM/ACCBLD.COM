$ !
$ !	[ACC.COM] A C C B L D . C O M
$ !
$ !	Assumes [ACC] and definitions for  EXE$:,OBJ$:,LIS$:,
$ !		MAP$:,COM$:
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
$ SRCUPDATE ACCDEF.REQ
$ EXIT
$
$SRCLIB:
$ !
$ !	Null source lib phase
$ !
$ EXIT
$
$ASSEM:
$ !
$ !	Purge and re-create the assembly language objects and listings
$ !
$ PURGE OBJ$:*.OBJ,*.OBB,LIS$:*.LSS,*.LIS
$ @SYSBLDCOM$:FASM 'FACNAM "" N 'UPDATES
$ CPYSYSMSG OBJ$:ACCMSG.OBB
$ EXIT
$
$OBJLIB:
$ !
$ !	Create object library from object modules.
$ !
$ @SYSBLDCOM$:OBJLIB ACC
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
$ !	Delete ACC map and image then re-create
$ !
$ DELETE EXE$:ACC.EXE;*,MAP$:.MAP;*
$ @COM$:ACCLNK
$ EXIT
$
$RESULT:
$ !
$ !	Copy the EXE and MAP to a System area
$ !
$ CPYRESEXE EXE$:ACC.EXE
$ CPYRESMAP MAP$:ACC.MAP
$ !
$ !	Build the concatenated listing
$ !
$ CPYRESLIS LIS$:*.LIS ACC.LSS
