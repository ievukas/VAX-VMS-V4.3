$ !
$ !	[ FDL.COM ] F D L B L D . C O M
$ !
$ !
$ !	Assumes [FDL] and definitions for  EXE$:,OBJ$:,LIS$:,
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
$ SRCUPDATE FDLPARDEF.SDL
$ DELSHRLIB SRC$:FDLUTIL.REQ
$ SRCUPDATE FDLUTIL.REQ
$ CPYSHRLIB SRC$:FDLUTIL.REQ		! Share file with EDF, CONV components
$ SRCUPDATE FDLMSG.MSG
$ EXIT
$
$SRCLIB:
$ !
$ !	Delete and re-create the SDL output.
$ !
$ DELSHRLIB LIB$:FDLPARDEF.R32
$ DELSHRLIB LIB$:FDLPARDEF.PEN
$ SDL-
	/VMS-
	/COPYRIGHT-
	/LIST=LIS$:-
	/LANGUAGE=(PASCAL=LIB$:,BLISS=LIB$:)-
	 SRC$:FDLPARDEF
$ PASCAL/NOOBJ/ENV=LIB$: LIB$:FDLPARDEF
$ DELETE LIB$:FDLPARDEF.PAS;*
$ @COM$:FIXSDL LIB$:FDLPARDEF.R32
$ CPYSHRLIB LIB$:FDLPARDEF.R32		! Share file with EDF, CONV components
$ CPYSHRLIB LIB$:FDLPARDEF.PEN
$ DELSHRLIB LIB$:FDLSDLMSG.PEN
$ MESSAGE/SDL=LIB$:FDLSDLMSG SRC$:FDLMSG
$ SDL-
	/VMS-
	/COPYRIGHT-
	/LIST=LIS$:-
	/LANGUAGE=PASCAL=LIB$:-
	 LIB$:FDLSDLMSG
$ PASCAL/NOOBJ/ENV=LIB$: LIB$:FDLSDLMSG
$ DELETE LIB$:FDLSDLMSG.PAS;*,LIB$:FDLSDLMSG.SDL;*
$ CPYSHRLIB LIB$:FDLSDLMSG.PEN
$ EXIT
$
$ASSEM:
$ !
$ !	PURGE and re-create the assembly and bliss objects and listings
$ !
$ PURGE OBJ$:*.OBJ,*.OBB,LIS$:*.LSS,*.LIS
$ @SYSBLDCOM$:FASM 'FACNAM "" N 'UPDATES
$ CPYSYSMSG OBJ$:FDLMSG.OBB
$ EXIT
$
$OBJLIB:
$ !
$ !	Create object library from object modules.
$ !
$ @SYSBLDCOM$:OBJLIB FDL
$ EXIT
$
$LNKLIB:
$ !
$ !	Delete FDL map and image then re-create EXE$:FDLSHR.EXE
$ !			and MAP$:FDLSHR.MAP
$ !
$ DELETE EXE$:FDLSHR.EXE;*,MAP$:.MAP;*
$ @COM$:FDLSHRLNK
$ CPYSYSLIB EXE$:FDLSHR.EXE		! Copy to library area
$ INSHARLIB EXE$:FDLSHR			! Insert into IMAGELIB
$ EXIT
$
$LINK:
$ !
$ !	Delete CREATEFDL map and image then re-create EXE$:CREATEFDL.EXE
$ !			and MAP$:CREATEFDL.MAP
$ !
$ DELETE EXE$:CREATEFDL.EXE;*,MAP$:CREATEFDL.MAP;*
$ @COM$:CREALNK
$ EXIT
$
$RESULT:
$ !
$ !	Copy the EXEs and MAPs to a System area
$ !
$ CPYRESEXE EXE$:CREATEFDL.EXE
$ CPYRESMAP MAP$:CREATEFDL.MAP
$ CPYRESMAP MAP$:FDLSHR.MAP
$ !
$ !	Build the concatenated listing LIS$:FDL.LSS
$ !
$ CPYRESLIS LIS$:*.LIS FDL.LSS
