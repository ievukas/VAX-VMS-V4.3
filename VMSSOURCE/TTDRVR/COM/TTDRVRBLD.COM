$ !
$ !	[ TTDRVR.COM ] T T D R V R B L D . C O M
$ !
$ !	Assumes [TTDRVR] and definitions for  EXE$:,OBJ$:,LIS$:,
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
$ !	Create updated sources shared by other components
$ !
$ DELSHRLIB OBJ$:TTYDEF.MAR
$ SRCUPDATE TTYDEF.SDL			! To become part of LIB.MLB
$ SRCUPDATE TTYMACS.MAR			! To become part of LIB.MLB
$ SDL/VMS SRC$:TTYDEF.SDL /LIS=LIS$ /LANG=(BLISS=OBJ$,MACRO=OBJ$)
$ APPEND SRC$:TTYMACS.MAR OBJ$:TTYDEF.MAR
$ CPYSHRLIB OBJ$:TTYDEF.MAR
$ EXIT
$
$SRCLIB:
$ !
$ !	Create terminal service macro library
$ !
$ EXIT
$
$ASSEM:
$ !
$ !	Delete and re-create the assembly language objects and listings
$ !
$ DELETE OBJ$:*.OBJ;*,LIS$:*.LSS;*,*.LIS;*
$ @SYSBLDCOM$:FASM 'FACNAM "" N 'UPDATES
$ EXIT
$
$OBJLIB:
$ !
$ !	Concatenate the objects, delete and re-create the object
$ !		library LIB$:TTDRVR.OLB then delete the
$ !		concatenated objects file.
$ !
$ DELETE LIB$:TTDRVR.OLB;*
$ LIB/CREATE=(BLOCKS=100,MODULES=20)/NOGLOBALS -
	LIB$:TTDRVR OBJ$:*.OBJ
$ DELETE OBJ$:*.OBJ;*
$ !
$ !	Conditionally copy TTDRVR.OLB for other's use.
$ !
$ IF CPYOLB .EQS. "Y" THEN CPYRESOBJ LIB$:TTDRVR.OLB
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
$ !	Delete then re-create EXE$:*.EXE, OBJ$:*.STB, and LIS$:*.MAP.
$ !
$ DELETE EXE$:TTDRIVER.EXE;*,MAP$:TTDRIVER.MAP;*
$ DELETE EXE$:DZDRIVER.EXE;*,MAP$:DZDRIVER.MAP;*
$ DELETE EXE$:DZVDRIVER.EXE;*,MAP$:DZVDRIVER.MAP;*
$ DELETE EXE$:YCDRIVER.EXE;*,MAP$:YCDRIVER.MAP;*
$ DELETE EXE$:YFDRIVER.EXE;*,MAP$:YFDRIVER.MAP;*
$ @COM$:TTDRVRLNK
$ EXIT
$
$RESULT:
$ !
$ !	Copy the EXE and MAP to a System area
$ !
$ CPYRESEXE EXE$:TTDRIVER.EXE
$ CPYRESEXE EXE$:DZDRIVER.EXE
$ CPYRESEXE EXE$:DZVDRIVER.EXE
$ CPYRESEXE EXE$:YCDRIVER.EXE
$ CPYRESEXE EXE$:YFDRIVER.EXE
$ CPYRESMAP MAP$:*.MAP
$ !
$ !	Build the concatenated listing LIS$:TTDRVR.LSS
$ !
$ CPYRESLIS LIS$:*.LIS TTDRVR.LSS
$ 
