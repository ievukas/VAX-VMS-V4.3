$ !
$ !	[MSCP.COM]MSCPBLD.COM
$ !
$ ! Command file to build the MSCP Server.
$ !
$ ! Assumes [MSCP] and definitions for system build.
$ !
$ GOTO 'PHASE'
$
$INIT:
$ !
$ !	CREATE THE DIRECTORIES
$ !
$ @SYSBLDCOM$:CREATEDIR
$ EXIT
$
$UPDATE:
$ !
$ !	Create updated library file source.
$ !
$ DELETE SRC$:*.*;*
$ SRCUPDATE MSCPDEF.MAR
$ EXIT
$
$SRCLIB:
$ !
$ !	Create library
$ !
$ DELETE LIB$:MSCPDEF.MLB;*
$ LIBRARY/MACRO/CREATE LIB$:MSCPDEF SRC$:MSCPDEF
$ EXIT
$
$ASSEM:
$ !
$ !	PURGE AND RE-CREATE THE MACRO LANGUAGE OBJECTS AND LISTINGS
$ !
$ PURGE OBJ$:*.OBJ,LIS$:*.LIS
$ @SYSBLDCOM$:FASM 'FACNAM "" NOLIB 'UPDATES'
$ EXIT
$
$OBJLIB:
$ !
$ !	Create object library from object modules.
$ !
$ @SYSBLDCOM$:OBJLIB MSCP
$ EXIT
$
$LNKLIB:
$ !
$ ! Null LNKLIB stage
$ !
$ EXIT
$
$LINK:
$ !
$ !	Link MSCP image
$ !
$ @COM$:MSCPLNK
$ EXIT
$
$RESULT:
$ !
$ !	COPY THE EXE AND MAP TO A SYSTEM AREA
$ !
$ CPYRESEXE EXE$:*.EXE
$ CPYRESMAP MAP$:*.MAP
$ CPYRESLIS LIS$:*.LIS MSCP.LSS
