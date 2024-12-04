$ !
$ !	[ SYS.COM ] S Y S B L D . C O M
$ !
$ !	Assumes [SYS] and definitions for  EXE$:,OBJ$:,LIS$:,
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
$ DELSHRLIB SRC$:SYSDEF.SDL
$ DELSHRLIB SRC$:SYSMAR.MAR
$ DELSHRLIB SRC$:SYSPARAM.MAR
$ DELSHRLIB SRC$:CMODSSDSP.MAR
$
$ SRCUPDATE SYSDEFAE.SDL		! Part of SYSDEF.SDL
$ SRCUPDATE SYSDEFFL.SDL		! Part of SYSDEF.SDL
$ SRCUPDATE SYSDEFMP.SDL		! Part of SYSDEF.SDL
$ SRCUPDATE SYSDEFQZ.SDL		! Part of SYSDEF.SDL
$ COPY SRC$:SYSDEF%%.SDL SRC$:SYSDEF.SDL ! Used by VMSLIB SRCLIB phase
$ CPYSHRLIB SRC$:SYSDEF.SDL		! Share file with VMSLIB
$
$ SRCUPDATE SYSMAR.MAR			! Used by VMSLIB (LIB.MLB)
$ CPYSHRLIB SRC$:SYSMAR.MAR		! Share file with VMSLIB
$
$ SRCUPDATE SYSPARAM.MAR		! Used by VMSLIB (SYSBLDMLB.MLB)
$ CPYSHRLIB SRC$:SYSPARAM.MAR		! Share file with VMSLIB
$
$ SRCUPDATE CMODSSDSP.MAR		! Used by loadable pieces of code
$ CPYSHRLIB SRC$:CMODSSDSP.MAR		! Make available to them
$ !	Create updated files used by pieces of the image activator
$
$ SRCUPDATE IMGACTCTX.SDL
$ SRCUPDATE IMGMSG.MSG
$ PUTSYSMSG SRC$:IMGMSG.MSG		! Put file into SYSMSG.TLB
$ EXIT
$
$SRCLIB:
$ !
$ !	Create REQUIRE files used by image activator
$ !
$ DELSHRLIB LIB$:IMGMSGDEF.R32
$
$ DELETE LIB$:IMGACTCTX.MAR;*, LIB$:IMGACTCTX.R32;*
$ SDL /LANGUAGE=(BLISS=LIB$,MACRO=LIB$) /VMS SRC$:IMGACTCTX.SDL
$ DELETE LIB$:IMGMSGDEF.SDL;*, LIB$:IMGMSGDEF.MAR;*, LIB$:IMGMSGDEF.R32;*
$ MESSAGE /NOOBJECT /SDL=LIB$:IMGMSGDEF SRC$:IMGMSG.MSG
$ SDL /LANGUAGE=(BLISS=LIB$,MACRO=LIB$) /VMS LIB$:IMGMSGDEF
$ CPYSHRLIB LIB$:IMGMSGDEF.R32		! Share this file with INSTALL
$ DELETE LIB$:IMGACT.MLB;*
$ LIBRARY /CREATE /MACRO LIB$:IMGACT LIB$:IMGMSGDEF,LIB$:IMGACTCTX
$ EXIT
$
$ASSEM:
$ !
$ !	PURGE and re-create the assembly language objects and listings
$ !
$ PURGE OBJ$:*.OBJ,LIS$:*.LSS,*.LIS
$ @SYSBLDCOM$:FASM 'FACNAM "" N 'UPDATES
$ !
$ !	Save copies of some object modules for inclusion into STARLET.OLB
$ !	by the VMSLIB facility
$ !
$ DELETE OBJ$:SYSVECTOR.OBB;*
$ RENAME OBJ$:SYSVECTOR.OBJ OBJ$:SYSVECTOR.OBB/NEW_VERSION
$ DELETE OBJ$:P1SYSVECT.OBB;*
$ COPY OBJ$:P1SYSVECT.OBJ OBJ$:P1SYSVECT.OBB
$ DELETE OBJ$:IODEF.OBB;*,MISCDEF;*,PRDEF;*,SSDEF;*
$ COPY OBJ$:IODEF.OBJ OBJ$:IODEF.OBB
$ COPY OBJ$:MISCDEF.OBJ OBJ$:MISCDEF.OBB
$ COPY OBJ$:PRDEF.OBJ OBJ$:PRDEF.OBB
$ COPY OBJ$:SSDEF.OBJ OBJ$:SSDEF.OBB
$ DELETE OBJ$:USRVECTOR.OBB;*
$ COPY OBJ$:USRVECTOR.OBJ OBJ$:USRVECTOR.OBB
$ EXIT
$
$OBJLIB:
$ !
$ !	Concatenate the objects, delete and re-create the object
$ !		library LIB$:SYS.OLB then delete the
$ !		concatenated objects file.
$ !
$ DELETE LIB$:SYS.OLB;*
$ LIB/CREATE=(BLOCKS=500,MODULES=250)/NOGLOBALS -
	LIB$:SYS OBJ$:*.OBJ
$ DELETE OBJ$:*.OBJ;*
$ !
$ !	Conditionally Copy SYS.OLB for other's use.
$ !
$ IF CPYOLB .EQS. "Y" THEN CPYRESOBJ LIB$:SYS.OLB
$ EXIT
$
$LNKLIB:
$ !
$ !	Delete then re-create EXE$:SYS.EXE, EXE$:SYS.STB, LIS$:SYS.MAP,
$ !	and move SYS.STB to RESOBJ$ for other privileged code to link with.
$ !
$ @COM$:SYSLNK
$ IF CPYOLB THEN CPYRESOBJ EXE$:SYS.STB
$ EXIT
$
$LINK:
$ !
$ ! System is built during link lib phase now so that privileged libraries
$ ! can be linked during the lnklib phase and obtain the system symbol table.
$ !
$ ! Null LINK phase
$ !
$ EXIT
$
$RESULT:
$ !
$ !
$ !	Copy the EXE and MAP to a System area
$ !
$ CPYRESEXE EXE$:SYS.EXE
$ CPYRESMAP MAP$:SYS.MAP
$ CPYRESEXE MAP$:SYS.MAP
$ CPYRESEXE OBJ$:SYS.STB
$ !
$ !	Build the concatenated listing LIS$:SYS.LSS
$ !
$ CPYRESLIS LIS$:*.LIS SYS.LSS
