$ !
$ !	[ F 1 1 X . C O M ] F 1 1 X B L D . C O M
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
$ @COM$:F11XUPD
$ EXIT
$
$SRCLIB:
$ !
$ !	No source library
$ !
$ EXIT
$
$ASSEM:
$ PURGE OBJ$:*.OBJ, LIS$:*.LIS
$ @SYSBLDCOM$:FASM 'FACNAM "" N 'UPDATES
$ EXIT
$
$OBJLIB:
$ !
$ !	Concatenate the objects, delete and re-create the object
$ !		library LIB$:F11BXQP.OLB then delete the
$ !		concatenated objects file.
$ !
$ @SYSBLDCOM$:OBJLIB F11BXQP 200 500 250
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
$ !	Delete images and maps. Then re-create F11BXQP and FILESERV
$ !		EXE and MAP.
$ !
$ DELETE EXE$:F11BXQP.EXE;*,FILESERV.EXE;*, MAP$:F11BXQP.MAP;*,FILESERV.MAP;*
$ @COM$:F11XLNK
$ @COM$:FILSRVLNK
$ EXIT
$
$RESULT:
$ !
$ !	Copy the EXE and MAP to a System area
$ !
$ CPYRESEXE EXE$:F11BXQP.EXE,EXE$:FILESERV.EXE
$ CPYRESMAP MAP$:F11BXQP.MAP,MAP$:FILESERV.MAP
$ !
$ !	Build the concatenated listing RESLIS$:F11BXQP.LSS
$ !
$ CPYRESLIS SRC$:XQPDEF.B32,LIS$:*.LIS F11BXQP.LSS
