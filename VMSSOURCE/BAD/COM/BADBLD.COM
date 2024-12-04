$ !
$ !	[B A D . C O M] B A D B L D . C O M
$ !
$ GOTO 'PHASE'
$
$INIT:
$ !
$ !	Create the Directories
$ !
$ @SYSBLDCOM$:CREATEDIR
$ EXIT

$UPDATE:
$ !
$ !	Update the structure definition and command line definition files.
$ !
$ SRCUPDATE BADDEF.SDL
$ SRCUPDATE ANALYZCMD.CLD
$ EXIT
$
$SRCLIB:
$ !
$ !	Create the new require files.
$ !
$ SDL/VMS/COPYRIGHT SRC$:BADDEF	/LANGUAGE=BLISS=LIB$
$ EXIT
$
$ASSEM:
$ !
$ !	Purge and recreate the object files and listings
$ !
$ PURGE OBJ$:*.OBJ,*.OBB, LIS$:*.LIS
$ @SYSBLDCOM$:FASM BAD "" N 'UPDATES'
$ CPYSYSMSG OBJ$:BADMSG.OBB
$ EXIT
$
$OBJLIB:
$ !
$ !	Create object libraries
$ !
$ @SYSBLDCOM$:OBJLIB ANALYZBAD 250 750 50
$ EXIT
$
$LNKLIB:
$ !
$ !	Null LNKLIB phase
$ !
$ EXIT
$
$LINK:
$ !
$ !	Delete images and maps and then recreate
$ !
$ @COM$:BADLNK
$ @COM$:STABADLNK
$ EXIT
$
$RESULT:
$ !
$ !	Copy the images and maps to the system area
$ !
$ CPYRESEXE EXE$:ANALYZBAD.EXE
$ CPYRESMAP COM$:BADLNK.COM,MAP$:ANALYZBAD.MAP
$ CPYRESEXE EXE$:STABAD.EXE
$ CPYRESMAP COM$:STABADLNK.COM,MAP$:STABAD.MAP
$ !
$ !	Build the concatenated listings
$ !
$ CPYRESLIS SRC$:*.REQ,SRC$:*.MSG,LIS$:*.LIS ANALYZBAD.LSS
