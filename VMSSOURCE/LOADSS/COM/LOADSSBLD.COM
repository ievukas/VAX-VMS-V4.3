$ !
$ !	[ L O A D S S . C O M ] L O A D S S B L D . C O M
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
$ !	Update the master source files
$ !
$ EXIT
$
$SRCLIB:
$ !
$ !	Update the source libraries
$ !
$ EXIT
$
$ASSEM:
$ !
$ !	Assemble modules
$ !
$ @SYSBLDCOM$:FASM 'FACNAM "" N 'UPDATES
$ EXIT
$
$OBJLIB:
$ !
$ !	Create object library from object modules.
$ !
$ @SYSBLDCOM$:OBJLIB LOADSS
$ EXIT
$
$LNKLIB:
$ !
$ !	Delete secureshr map and image and then re-create them.
$ !
$ DELETE EXE$:SECURESHR.EXE;*,	MAP$:SECURESHR.MAP;*
$ @COM$:SECSHRLNK		! Link the shareable image
$ CPYSYSLIB EXE$:SECURESHR.EXE	! Copy to library area
$ INSHARLIB EXE$:SECURESHR	! Insert into IMAGELIB
$ EXIT
$
$LINK:
$ !
$ !	Link system processes
$ !
$ EXIT
$
$RESULT:
$ !
$ !	Copy EXE, MAP, and LIS files to a System area
$ !
$ CPYRESMAP MAP$:*.MAP
$ CPYRESLIS LIS$:*.LIS
$ EXIT
