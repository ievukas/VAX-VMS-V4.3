$ !
$ !	[ S O R T 3 2 . C O M ] S O R T 3 2 B L D . C O M
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
$ !	Update the master library source files.
$ !
$ SRCUPDATE SORLIB.REQ
$ SRCUPDATE SFKEYWRD.REQ
$ SRCUPDATE SRTSPC.REQ
$ SRCUPDATE OPCODES.REQ
$ SRCUPDATE COM.REQ
$ SRCUPDATE CDDMAC.R32
$ SRCUPDATE CDDTYPE.R32
$ SRCUPDATE RECSYM.R32
$ SRCUPDATE REQSYM.R32
$ SRCUPDATE CHKPNT.REQ
$ SRCUPDATE DKS.REQ
$ SRCUPDATE DEFS0.REQ
$ EXIT
$
$SRCLIB:
$ !
$ !	Delete and re-create the libraries
$ !
$ ! Done in ASSEM phase because of dependence on SORMSG.R32
$ EXIT
$
$ASSEM:
$ !
$ !	Delete and re-create the objects and listings
$ !
$ DELETE OBJ$:*.OBJ;*,*.OBB;*, LIS$:*.LIS;*
$ SET NOON
$ @SYSBLDCOM$:FASM 'FACNAM' "" NOLIB 'UPDATES'
$ CPYSYSMSG OBJ$:SORMSG.OBB
$ EXIT
$
$OBJLIB:
$ !
$ !	Create the object library from the object modules.
$ !
$ @SYSBLDCOM$:OBJLIB SORTMERGE		! Object library in LIB$:SORTMERGE.OLB
$ EXIT
$
$LNKLIB:
$ !
$ !	Link the shareable image
$ !
$ @COM$:SORT32SHR
$ CPYSYSLIB EXE$:SORTSHR.EXE		! Copy to library area
$ INSHARLIB EXE$:SORTSHR		! Insert into IMAGELIB
$ @SYSBLDCOM$:VECTORTST EXE$:SORTSHR COM$:VECTORTST.DAT
$ EXIT
$
$LINK:
$ !
$ !	Link the executable images
$ !
$ @COM$:SORT32LNK
$ @COM$:SRTTRNLNK
$ EXIT
$
$RESULT:
$ !
$ !	Copy the EXEs and MAPs to a System area
$ !
$ CPYRESEXE EXE$:SORTSHR.EXE
$ CPYRESEXE EXE$:SORTMERGE.EXE
$ CPYRESEXE EXE$:SRTTRN.EXE
$ CPYRESMAP MAP$:SORTSHR.MAP
$ CPYRESMAP MAP$:SORTMERGE.MAP
$ CPYRESMAP MAP$:SRTTRN.MAP
$ !
$ !	Build the concatenated listing RESLIS$:SORTMERGE.LSS
$ !
$ CPYRESLIS LIS$:*.LIS SORTMERGE.LSS
