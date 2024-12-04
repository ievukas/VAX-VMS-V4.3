$ !
$ !	[ D C X . C O M ] D C X B L D . C O M
$ !
$ !	Assume default directory is [DCX] and logical names
$ !	BUG$, COM$, ENH$, EXE$, LIB$, LIS$, MAP$, OBJ$, and SRC$
$ !	are defined.
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
$ DELSHRLIB SRC$:DCXDEF.MDL
$ SRCUPDATE DCXDEF.MDL
$ SRCUPDATE DCXPRVDEF.MDL
$ CPYSHRLIB SRC$:DCXDEF.MDL		! Share file with VMSLIB component
$ SRCUPDATE DCXMSG.MSG
$!$ PUTSYSMSG SRC$:DCXMSG.MSG		! Insert in SYSMSG.TLB
$ SRCUPDATE PREFIX.REQ
$ EXIT
$
$SRCLIB:
$ !
$ !	Delete and re-create the macro library LIB$:DCXDEF.MLB
$ !
$ DELSHRLIB LIB$:DCXDEF.B32
$ DELETE LIB$:DCXDEF.MLB;*
$ MCR MDL LIB$:DCXDEF=SRC$:DCXDEF
$ CPYSHRLIB LIB$:DCXDEF.B32		! Share file with world
$ DELSHRLIB LIB$:DCXPRVDEF.B32
$ DELETE LIB$:DCXPRVDEF.MLB;*
$ MCR MDL LIB$:DCXPRVDEF=SRC$:DCXPRVDEF
$ !
$ LIBRARY/MACRO/CREATE LIB$:DCX LIB$:DCXDEF,DCXPRVDEF
$ EXIT
$
$ASSEM:
$ !
$ !	Purge and re-create the assembly language objects and listings
$ !
$ PURGE OBJ$:*.OBJ,*.OBB,LIS$:*.LIS
$ SET NOON				! In case of errors
$ @COM$:ASSIGNREQ
$ @SYSBLDCOM$:FASM DCX "" N 'UPDATES'
$ CPYSYSMSG OBJ$:DCXMSG.OBB
$ @COM$:DEASREQ
$ EXIT
$
$OBJLIB:
$ !
$ !	Create object library from object modules.
$ !
$ @SYSBLDCOM$:OBJLIB DCX
$ EXIT
$
$LNKLIB:
$ !
$ !	Delete data compression map and image then re-create EXE$:DCXSHR.EXE
$ !			and MAP$:DCXSHR.MAP
$ !
$ DELETE EXE$:DCXSHR.EXE;*,	MAP$:DCXSHR.MAP;*
$ @COM$:DCXSHRLNK
$ CPYSYSLIB EXE$:DCXSHR.EXE	! Copy to library area for MACRO/LINK
$ INSHARLIB EXE$:DCXSHR		! Insert into IMAGELIB
$ EXIT
$
$LINK:
$ !
$ ! LINK done in LNKLIB phase
$ !
$ EXIT
$
$RESULT:
$ !
$ !	Copy the EXE and MAP to a System area
$ !
$ CPYRESMAP COM$:DCXSHRLNK.COM,MAP$:DCXSHR.MAP	DCX.MAP
$ !
$ !	Build the concatenated listing DCX.LSS
$ !
$ CPYRESLIS LIS$:*.LIS DCX.LSS
