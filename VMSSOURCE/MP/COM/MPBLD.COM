$ !
$ !	[ M P . C O M ] M P B L D . C O M
$ !
$ !	THIS COMMAND FILE BUILDS THE MULTI-PROCESSOR PRIVILEGED PROGRAM.
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
$ SRCUPDATE MP.MDL
$ SRCUPDATE MPMACROS.MAR
$ EXIT
$
$SRCLIB:
$ !
$ ! Build library containing macros, error message codes, and severity levels.
$ !
$ DELETE LIB$:MP.MAR;*,MP.B32;*,MP.MLB;*
$ MCR MDL LIB$:MP=SRC$:MP
$ LIBR/MAC/CREATE/CREATE LIB$:MP.MLB LIB$:MP.MAR,SRC$:MPMACROS.MAR
$ EXIT
$
$ASSEM:
$ !
$ !	PURGE and re-create the MP objects and listings
$ !
$ PURGE OBJ$:*.OBJ,LIS$:*.LIS
$ @SYSBLDCOM$:FASM 'FACNAM "" N 'UPDATES
$ EXIT
$
$OBJLIB:
$ !
$ !	Create object library from object modules.
$ !
$ ! If there are no object files, then don't do anything.  Otherwise, check
$ ! to see if the marker file exists. If it does, then the finish cleaning
$ ! up OBJ$:.  If the marker file does not exist, then create the object
$ ! library.
$ !
$ IF F$SEARCH("OBJ$:*.OBJ") .EQS. "" THEN EXIT
$ IF F$SEARCH("OBJ$:LIBRIS.AOK") .NES. "" THEN GOTO L1
$ LIB/CREATE=(BLOCKS=100,MODULES=20)/GLOBALS LIB$:MP.OLB OBJ$:*.OBJ
$ IF .NOT. $STATUS THEN EXIT
$ PURGE LIB$:MP.OLB
$ !
$ !	Conditionally copy MP.OLB for other's use.
$ !
$ IF CPYOLB .EQS. "Y" THEN CPYRESOBJ LIB$:MP.OLB
$ !
$ !	Clean up for OBJLIB phase.
$ !
$ CREATE OBJ$:LIBRIS.AOK
$ L1:
$ DELETE OBJ$:*.OBJ;*
$ DELETE OBJ$:LIBRIS.AOK;*
$ EXIT
$
$LNKLIB:
$ !
$ !	Delete MP map and image then re-create EXE$:MP.EXE
$ !	and MAP$:MP.MAP.
$ !
$ DELETE EXE$:MP.EXE;*, MAP$:.MAP;*, EXE$:MP.STB;*
$!DELETE EXE$:MPCLRPFM.EXE;*, MAP$:.MAP;*
$!DELETE EXE$:MPSHWPFM.EXE;*, MAP$:.MAP;*
$ @COM$:MPLNK
$ IF CPYOLB THEN CPYRESOBJ EXE$:MP.STB
$ EXIT
$
$LINK:
$ !
$ !	Null LINK phase.  Links done in LNKLIB phase
$ !
$ EXIT
$
$RESULT:
$ !
$ !	Copy the EXE and MAP to a System area
$ !
$ CPYRESEXE EXE$:MP.EXE
$ CPYRESEXE EXE$:MP.STB
$!CPYRESEXE EXE$:MPCLRPFM.EXE
$!CPYRESEXE EXE$:MPSHWPFM.EXE
$ CPYRESEXE MAP$:MP.MAP
$ CPYRESMAP MAP$:MP.MAP
$ !
$ !	Build the concatenated listing RESLIS$:MP.LSS
$ !
$ CPYRESLIS  LIS$:*.LIS  MP.LSS
$ EXIT
