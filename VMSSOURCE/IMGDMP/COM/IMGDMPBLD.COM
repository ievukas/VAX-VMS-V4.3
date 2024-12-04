$ !
$ !	Image Dump Build Procedure
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
$ SRCUPDATE IMGDMPDEF.SDL
$ EXIT
$
$SRCLIB:
$ !
$ !	Delete and re-create the macro library LIB$:IMGDMPLIB.*
$ !
$ DELETE LIB$:IMGDMPLIB.*;*
$ DELETE LIB$:IMGDMPDEF.*;*
$ SDL /LANGUAGE=(BLISS=LIB$:,MACRO=LIB$:) SRC$:IMGDMPDEF
$ LIB/MAC/CREATE LIB$:IMGDMPLIB LIB$:IMGDMPDEF
$ DELETE LIB$:IMGDMPDEF.MAR;*
$ EXIT
$
$ASSEM:
$ !
$ !	PURGE and re-create the assembly language objects and listings
$ !
$ PURGE OBJ$:*.OBJ,LIS$:*.LSS,*.LIS
$ @SYSBLDCOM$:FASM 'FACNAM' "" NOLIB 'UPDATES'
$ EXIT
$
$OBJLIB:
$ !
$ !	The object library is created during the assembly phase.
$ !
$ @SYSBLDCOM$:OBJLIB 'FACNAM'
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
$ !	Delete maps and images then re-create EXE$:IMGDMP.EXE,ANALIMDMP.EXE
$ !			and MAP$:IMGDMP.MAP,ANALIMDMP.MAP
$ !
$ !
$ @COM$:IMGDMPLNK
$ EXIT
$
$RESULT:
$ !
$ !	Copy the EXE and MAP to a System area
$ !
$ CPYRESEXE EXE$:ANALIMDMP.EXE
$ CPYSYSLIB EXE$:IMGDMP.EXE
$ CPYRESMAP MAP$:*.MAP
$ !
$ !	Build the concatenated listing IMGDMP.LSS
$ !
$ CPYRESLIS LIS$:*.LIS IMGDMP.LSS
