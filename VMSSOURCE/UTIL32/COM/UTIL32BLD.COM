$ !
$ !	VMS unsupported utilities
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
$ EXIT
$
$SRCLIB:
$ !
$ !	Delete and re-create the macro library
$ !
$ EXIT
$
$ASSEM:
$ !
$ !	PURGE and re-create the assembly language objects and listings
$ !
$ PURGE OBJ$:*.OBJ,*.OBB, LIS$:*.LIS
$ @SYSBLDCOM$:FASM 'FACNAM' "" NOLIB 'UPDATES'
$ CPYSYSMSG OBJ$:SEARCHMSG.OBB
$ EXIT
$
$OBJLIB:
$ @SYSBLDCOM$:OBJLIB UTIL32
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
$ !	Delete link map and image then re-create the image and maps
$ !
$ @COM$:CHKSUMLNK
$ @COM$:DIETLNK
$ @COM$:DISKQLNK
$ @COM$:RTBLNK
$ @COM$:SEARCHLNK
$ @COM$:SETUSRLNK
$ @COM$:DSKMONLNK
$ EXIT
$
$RESULT:
$ !
$ !	Copy the EXE to a System area
$ !
$ CPYRESEXE EXE$:CHECKSUM.EXE
$ CPYRESEXE EXE$:DCLDIET.EXE
$ CPYRESEXE EXE$:DISKQ.EXE
$ CPYRESEXE EXE$:RTB.EXE
$ CPYRESEXE EXE$:SEARCH.EXE
$ CPYRESEXE EXE$:SETUSER.EXE
$ CPYRESEXE EXE$:DISKMON.EXE
