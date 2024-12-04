$ !
$ !	[ E X C H N G . C O M ] E X C H N G B L D . C O M
$ !
$ !
$ !	Assumes [EXCHNG] and definitions for  EXE$:,OBJ$:,LIS$:,MAP$:,COM$:
$ !
$ !
$ GOTO 'PHASE'
$
$INIT:
$ !
$ !	Create the Directories
$ !
$ @SYSBLDCOM$:CREATEDIR
$ !
$ EXIT
$
$UPDATE:
$ !
$ !	Create updated sources for those not done in FASM
$ !
$ DELETE SRC$:*.*;*
$ SRCUPDATE EXCHNGHLP.HLP
$ SRCUPDATE EXCLIB.B32
$ SRCUPDATE EXCREQ.R32
$ SRCUPDATE EXCDEFS.SDL
$ !
$ EXIT
$
$SRCLIB:
$ !
$ !	Delete and re-create the SDL definition outputs
$ !
$ DELETE LIS$:EXCDEFS.LIS;*, LIB$:EXCDEFS.R32;*,EXCDEFS.MAR;*
$ SDL /VMS_DEVELOPMENT /COPYRIGHT /LIST=LIS$: /LANGUAGES=(BLISS=LIB$:,MACRO=LIB$:) SRC$:EXCDEFS 
$ !
$ EXIT
$
$ASSEM:
$ !
$ !	Re-create the libraries and their listings
$ !
$ DELETE LIB$:EXCLIB.L32;*, LIS$:EXCLIB.LIS;*
$ BLISS /LIBRARY=LIB$: /LIST=LIS$: SRC$:EXCLIB
$ !
$ DELETE OBJ$:EXCHNGHLP.HLB;*
$ LIBR /CREATE=(BLOCKS=225,MODULES=24,GLOBALS=0) /HELP OBJ$:EXCHNGHLP.HLB SRC$:EXCHNGHLP
$ !
$ !	Re-create the objects and listings
$ !
$ PURGE OBJ$:*.OBJ,*.OBB, LIS$:*.LSS,*.LIS
$ @SYSBLDCOM$:FASM 'FACNAM "" N 'UPDATES
$ PURGE OBJ$:*.OBJ,*.OBB, LIS$:*.LSS,*.LIS
$ !
$ !	Put the message object where it can be included in the shared message section
$ !
$ CPYSYSMSG OBJ$:EXCMSG.OBB
$ !
$ EXIT
$
$OBJLIB:
$ !
$ !	Create object library from object modules.
$ !
$ @SYSBLDCOM$:OBJLIB EXCHNG 276 350 32	! facility, blocks, globals, modules
$ !
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
$ !	LINK phase handled by another procedure
$ !
$ @COM$:EXCHNGLNK
$ !
$ EXIT
$
$RESULT:
$ !
$ !	Copy the EXE and MAP to a System area
$ !
$ CPYRESEXE EXE$:EXCHANGE.EXE
$ CPYRESMAP MAP$:EXCHANGE.MAP
$ !
$ !	Build the concatenated listing LIS$:EXCHANGE.LSS
$ !
$ CPYRESLIS LIS$:*.LIS EXCHANGE.LSS
$ !
$ !	Copy the help library to a system area
$ !
$ CPYSYSHLP OBJ$:EXCHNGHLP.HLB
$ !
$ EXIT
