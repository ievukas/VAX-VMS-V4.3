$ !
$ !	[ D I S M O U . C O M ] D I S M O U B L D . C O M
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
$ !	Create updated require file sources  (NONE)
$ !
$ EXIT
$
$SRCLIB:
$ PREVDIR:='F$LOG("SYS$DISK")''F$DIR()'
$ SET DEF [VMSLIB]
$ MESSAGE/MDL=SRC$:DISMOUMSG/NOOBJ SRC$:DISMOUMSG
$ MCR MDL LIB$:DISMOUMSG=SRC$:DISMOUMSG
$ COPY LIB$:DISMOUMSG.B32 LIB$:DISMOUMSG.REQ
$ SET DEF 'PREVDIR'
$ EXIT
$
$ASSEM:
$ REMSHRLIB MOUDEF.B32
$ GETSHRLIB MOUDEF.B32
$ @SYSBLDCOM$:FASM 'FACNAM "" N 'UPDATES
$ EXIT
$
$OBJLIB:
$ !
$ !	Create object library from object modules.
$ !
$ @SYSBLDCOM$:OBJLIB DISMOUNT
$ EXIT
$
$LNKLIB:
$ !
$ !	Delete shareable dismount map and image then re-create it.
$ !
$ DELETE EXE$:DISMNTSHR.EXE;*,	MAP$:DISMNTSHR.MAP;*
$ @COM$:DMTSHRLNK		! Link the shareable image
$ CPYSYSLIB EXE$:DISMNTSHR.EXE	! Copy to library area
$ INSHARLIB EXE$:DISMNTSHR	! Insert into IMAGELIB
$ EXIT
$
$LINK:
$ !
$ !	Delete DISMOUNT map and image then re-create EXE$:DISMOUNT.EXE
$ !			and MAP$:DISMOUNT.MAP
$ !
$ DELETE EXE$:DISMOUNT.EXE;*, MAP$:.MAP;*
$ @COM$:DISMOULNK
$ EXIT
$
$RESULT:
$ !
$ !	Copy the EXE and MAP to a System area
$ !
$ CPYRESEXE EXE$:DISMOUNT.EXE
$ CPYRESMAP MAP$:DISMOUNT.MAP
$ !
$ !	Build the concatenated listing RESLIS$:DISMOUNT.LSS
$ !
$ CPYRESLIS LIS$:*.LIS DISMOUNT.LSS
