$ !
$ !	[UAF.COM] U A F B L D . C O M
$ !
$ !	Command file to build AUTHORIZE program
$ !
$ ! 	Assumes [UAF] and definitions for EXE$: , OBJ$: , LIS$: ,
$ !		MAP$: , COM$:
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
$ !	Update cld file, help file
$ !
$ SRCUPDATE AUTHORIZE.CLD
$ SRCUPDATE OAFDEF.SDL
$ SRCUPDATE ONFDEF.SDL
$ SRCUPDATE UAFHELP.HLP
$ SRCUPDATE UAFREQ.SDL
$ SRCUPDATE UAFMSG.MSG
$ EXIT
$
$SRCLIB:
$ !
$ !	AUTHORIZE has no macro libraries, but it has a help library
$ !
$ LIBRAR/HELP/CREATE=(MODULES:9) OBJ$:UAFHELP SRC$:UAFHELP
$ SDL/VMS/COPYRIGHT SRC$:OAFDEF /LANGUAGE=(BLISS=LIB$)
$ SDL/VMS/COPYRIGHT SRC$:ONFDEF /LANGUAGE=(BLISS=LIB$)
$ SDL/VMS/COPYRIGHT SRC$:UAFREQ /LANGUAGE=(BLISS=LIB$)
$ EXIT
$
$ASSEM:
$ !
$ !	HPWD is assembled by login and SETPRIV comes out of STARLET.OLB
$ !	PURGE and re-create the objects and listings
$ !
$ PURGE OBJ$:*.OBJ,LIS$:*.LSS,*.LIS
$ @SYSBLDCOM$:FASM 'FACNAM' "" NOLIB 'UPDATES'
$ SET COMMAND/OBJ=OBJ$: SRC$:AUTHORIZE
$ CPYSYSMSG OBJ$:UAFMSG.OBB
$ EXIT
$
$OBJLIB:
$ !
$ !	Create object library from object modules.
$ !
$ @SYSBLDCOM$:OBJLIB UAF
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
$ !	Delete authorize map and image then re-create EXE$:AUTHORIZE.EXE
$ !			and MAP$:AUTHORIZE.MAP
$ !
$ DELETE EXE$:*.EXE;*,MAP$:*.MAP;*
$ @COM$:CVTUAFLNK
$ @COM$:CVTNAFLNK
$ @COM$:UAFLNK
$ EXIT
$
$RESULT:
$ !
$ !	Copy the EXE, MAP, and HLB  to a System area
$ !
$ CPYRESEXE EXE$:CVTUAF.EXE
$ CPYRESMAP MAP$:CVTUAF.MAP
$ CPYRESEXE EXE$:CVTNAF.EXE
$ CPYRESMAP MAP$:CVTNAF.MAP
$ CPYRESEXE EXE$:AUTHORIZE.EXE
$ CPYRESMAP MAP$:AUTHORIZE.MAP
$ CPYSYSHLP OBJ$:UAFHELP.HLB
$ !
$ !	Build the concatenated listing
$ !
$ CPYRESLIS LIS$:*.LIS AUTHORIZE.LSS
