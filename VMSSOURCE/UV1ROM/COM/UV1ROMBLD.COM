$ !
$ !	[ UV1ROM.COM ] U V 1 R O M B L D . C O M
$ !
$ !	Assumes [UV1ROM] and definitions for  EXE$:,OBJ$:,LIS$:,
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
$ !	Create updated sources shared by other components, only build from
$ !	source!
$ !
$ EXIT
$
$SRCLIB:
$ !
$ !	Copy and add to VMBUV1 macro library.
$ !	Copy stripped down version of LIB.MLB for VMB building.
$ !
$ !
$ DELETE LIB$:VMBUV1.MLB;*,LIBUV1.MLB;*
$ COPY PRMOBJ$:BOOTS.MLB LIB$:VMBUV1.MLB
$ COPY PRMOBJ$:LIBUV1.MLB LIB$:LIBUV1.MLB
$ LIBRARY/MACRO LIB$:VMBUV1 -
	SRC$:VMBMACS,-
	SRC$:PRUV1DEF
$
$ EXIT
$
$ASSEM:
$ !
$ !	Purge and re-create the assembly language objects and listings
$ !
$ PURGE OBJ$:*.OBJ,LIS$:*.LIS
$ @SYSBLDCOM$:FASM 'FACNAM "" N 'UPDATES
$ EXIT
$
$OBJLIB:
$ !
$ !	Concatenate the objects, delete and re-create the object
$ !		library LIB$:VMB.OLB then delete the
$ !		concatenated objects file.
$ !
$ IF F$SEARCH("OBJ$:*.OBJ") .EQS. "" THEN EXIT
$ CPYRESOBJ PRMOBJ$:LIBCVTATB.OBJ
$ DELETE LIB$:VMBUV1.OLB;*
$ LIB/CREATE=(BLOCKS=200,MODULES=100)/NOGLOBALS -
	LIB$:VMBUV1 OBJ$:*.OBJ
$ DELETE OBJ$:*.OBJ;*
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
$ !  Define VERB EPASCAL for PASCAL source compilation
$ !
$ DEF EPASCAL PRMOBJ$:EPASCAL
$ SET COMM PRMOBJ$:EPASCAL.CLD
$ !
$ !	Delete then re-create EXE$:VMBUVAX1.EXE	and LIS$:VMBUVAX1.MAP.
$ !
$ @COM$:UV1ROMLNK
$ EXIT
$
$RESULT:
$ !
$ !
$ !	Copy the EXE and MAP to a System area
$ ! DO NOTHING!
$ !
$ !CPYRESEXE EXE$:VMBUVAX1.EXE
$ !CPYRESEXE MAP$:VMBUVAX1.MAP
$
$ EXIT
