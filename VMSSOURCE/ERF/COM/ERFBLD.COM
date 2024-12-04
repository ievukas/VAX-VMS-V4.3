$ !
$ !	[ E R F . C O M ] E R F B L D . C O M
$ !
$ !	This command file builds the Error Report Formatter, ERF.
$ !
$ GOTO 'PHASE'
$
$INIT:
$ !
$ !	CREATE THE DIRECTORIES
$ !
$ @SYSBLDCOM$:CREATEDIR
$ EXIT
$
$UPDATE:
$ !
$ !	Create updated sources.
$ !
$ srcupdate parserdat.sdl
$ srcupdate erfmsg.msg
$ srcupdate recseldef.req
$ srcupdate erfdef.req
$ srcupdate embetdef.req
$ srcupdate deverrdef.req
$ srcupdate dev_class.for
$ srcupdate deverr.for
$ srcupdate dr32com.for
$ srcupdate emblmdef.for
$ srcupdate embspdef.for
$ srcupdate modes.for
$ srcupdate msghdr.for
$ srcupdate opcodes.for
$ srcupdate qiocommon.for
$ srcupdate ssmessage.for
$ srcupdate syecom.for
$ srcupdate volmount.for
$ EXIT
$
$SRCLIB:
$ !
$ !	NO MACRO LIBRARY.
$ !
$ sdl/lan=(fortv3=src$,bliss=lib$:) src$:parserdat
$ EXIT
$
$ASSEM:
$ !
$ !	DELETE PURGE-CREATE THE SYE OBJECTS AND LISTINGS
$ !
$ PURGE OBJ$:*.OBJ, LIS$:*.LIS, *.LSS
$ !
$ !
$ @SYSBLDCOM$:FASM 'FACNAM "" N 'UPDATES
$ EXIT
$
$OBJLIB:
$ !
$ !	Create object library from object modules.
$ !
$ @SYSBLDCOM$:OBJLIB ERF
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
$ !	DELETE MAP AND IMAGE FILES, THEN RE-CREATE 
$ !
$ DELETE EXE$:ERF.EXE;*, MAP$:.MAP;*
$ @COM$:ERFLNK
$ EXIT
$
$RESULT:
$ !
$ !	COPY THE IMAGE AND MAP FILES TO A SYSTEM AREA
$ !
$ CPYRESEXE EXE$:ERF.EXE
$ CPYRESEXE EXE$:ERFPROC1.EXE
$ CPYRESEXE EXE$:ERFPROC2.EXE
$ CPYRESEXE EXE$:ERFPROC3.EXE
$ CPYRESEXE EXE$:ERFPROC4.EXE
$ CPYRESEXE EXE$:ERFPROC5.EXE
$ CPYRESEXE EXE$:ERFBRIEF.EXE
$ CPYRESEXE EXE$:ERFDISK.EXE
$ CPYRESEXE EXE$:ERFTAPE.EXE
$ CPYRESEXE EXE$:ERFBUS.EXE
$ CPYRESEXE EXE$:ERFRLTIM.EXE
$ CPYRESEXE EXE$:ERFSUMM.EXE
$ CPYRESEXE EXE$:ERFINICOM.EXE
$ CPYSYSLIB EXE$:ERFSHR.EXE
$ CPYSYSLIB EXE$:ERFCOMMON.EXE
$ CPYSYSLIB PRMOBJ$:ERFLIB.TLB
$ CPYRESMAP MAP$:ERF.MAP
$ !
$ !
$ !	BUILD THE CONCATENATED LISTING LS:[10,50]SYE.LSS
$ !
$ CPYRESLIS LIS$:*.LIS ERF.LSS
