$ !
$ !	[ E N C R Y P . C O M ] E N C R Y P B L D . C O M
$ !
$ GOTO 'PHASE'
$
$INIT:
$ !
$ !	Create the directories.
$ !
$ @SYSBLDCOM$:CREATEDIR
$ EXIT
$
$UPDATE:
$ !
$ !	Create updated require sources.
$ !
$ SRCUPDATE ENCSTRUCT.SDL
$ SRCUPDATE ENCFACMAC.R32
$ EXIT
$
$SRCLIB:
$ !
$ !	Compile SDL structure definitions.
$ !
$ DELETE LIB$:ENCSTRUCT.R32;*,.MAR;*
$ SDL SRC$:ENCSTRUCT/LANG=(bliss=LIB$,macro=lib$)
$ EXIT
$
$ASSEM:
$ !
$ !	Delete and re-create the objects and listings.
$ !
$ PURGE OBJ$:*.OBJ, OBJ$:*.OBB, LIS$:*.LIS
$ @SYSBLDCOM$:FASM 'FACNAM' "" NOLIB 'UPDATE'
$ EXIT
$
$OBJLIB:
$ !
$ !	Create object library from object modules.
$ !
$ @SYSBLDCOM$:OBJLIB ENCSTB
$ EXIT
$
$LNKLIB:
$ !
$ ! Create the sharable libraries
$ !
$ @COM$:ENCSTBLNK ! The stubbed sharable library
$ !
$ ! Copy the stub sharable section to the system library as the default
$ !
$ CPYSYSLIB EXE$:ENCRYPSHR.EXE
$ INSHARLIB EXE$:ENCRYPSHR.EXE
$ EXIT
$
$LINK:
$ !
$ ! Delete maps and images then re-create facility images
$ !
$ DELETE EXE$:ENCRYPFAC.EXE;*, MAP$:.MAP;*
$ @COM$:ENCFACLNK
$ EXIT
$
$RESULT:
$ !
$ !	Copy the EXE and MAP to the system area.
$ !
$ CPYRESEXE EXE$:ENCRYPFAC.EXE
$ CPYRESMAP MAP$:ENCRYPFAC.MAP
$ !
$ !	Build the concatenated listing LIS$:ENCRYP.LSS
$ !
$ CPYRESLIS SRC$:ENCFACMAC.R32,LIS$:*.LIS ENCRYP.LSS
$ EXIT
