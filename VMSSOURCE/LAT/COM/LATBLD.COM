$ !
$ !	Local Area Terminal Facility
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
$ !	Create updated sources for macro library
$ !
$ DELETE SRC$:*.*;*
$ SRCUPDATE LATDEF.SDL
$ SRCUPDATE LATCPCLD.CLD
$ SRCUPDATE LATCPHLP.HLP
$ EXIT
$
$SRCLIB:
$ !
$ !	Create the macro library
$ !
$ DELETE LIB$:LATDEF.MAR;*, LIB$:LATDEF.R32;*
$ SDL /LANGUAGE=(BLISS=LIB$,MACRO=LIB$) /VMS SRC$:LATDEF.SDL
$ LIBRARY /CREATE /MACRO LIB$:LAT LIB$:LATDEF
$ EXIT
$
$ASSEM:
$ !
$ PURGE OBJ$:*.OBJ,LIS$:*.LIS
$ !
$ !	Delete and then re-create the CLD object tables
$ !
$ SET COMMAND/OBJ=OBJ$:LATCPCLD SRC$:LATCPCLD.CLD
$ !
$ !	Compile the sources, producing the objects and listings
$ !
$ @SYSBLDCOM$:FASM 'FACNAM' "" NOLIB 'UPDATES'
$ EXIT
$
$OBJLIB:
$ !
$ ! 	Create object library
$ !
$ DELETE LIB$:LAT.OLB;*
$ LIB/CREATE LIB$:LAT OBJ$:*.OBJ /NOGLOBALS
$ DELETE OBJ$:LAT*.OBJ;*
$ IF CPYOLB THEN CPYRESOBJ LIB$:LAT.OLB
$ !
$ !	Create the facility HELP library.
$ !
$ LIBRARY/CREATE=(MODULES=5,GLOBALS=0)/HELP OBJ$:LATCP SRC$:LATCPHLP
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
$ !	Link LTDRIVER
$ !
$ @COM$:LTDRVLNK
$ !
$ !	Link LATCP
$ !
$ @COM$:LATCPLNK
$ EXIT
$
$RESULT:
$ !
$ !	Copy the EXE, MAP and control files to a System area
$ !
$ CPYRESEXE EXE$:LTDRIVER.EXE,EXE$:LATCP.EXE
$ CPYRESMAP MAP$:LTDRIVER.MAP,MAP$:LATCP.MAP
$ CPYSYSMGR COM$:LTLOAD.COM
$ CPYSYSHLP OBJ$:LATCP.HLB
