$ !****************************************************************************
$ !*									      *
$ !*			 D E B U G B L D . C O M			      *
$ !*									      *
$ !*	ASSUMES DEFINITIONS FOR LIB$:, LIS$:, SRC$:,   			      *
$ !*				COM$:, EXE$:, MAP$:, OBJ$:		      *
$ !*									      *
$ !****************************************************************************
$ GOTO 'PHASE'
$ !
$INIT:
$ !
$ ! Create the directories
$ !
$ @SYSBLDCOM$:CREATEDIR
$ EXIT
$ !
$UPDATE:
$ !
$ ! Update require files
$ !
$ @COM$:DEBUGUPD
$ EXIT
$ !
$SRCLIB:
$ !
$ !	Create the common require and library files.
$ !
$ BLISS/LIBRARY=LIB$:STRUCDEF.L32/LIST=LIS$:STRUCDEF.LIS  SRC$:STRUCDEF.REQ
$ BLISS/LIBRARY=LIB$:DBGLIB.L32/LIST=LIS$:DBGLIB.LIS	SRC$:DBGLIB.REQ
$ BLISS/LIBRARY=LIB$:DSTRECRDS.L32/LIST=LIS$:DSTRECRDS.LIS  SRC$:DSTRECRDS.REQ
$ BLISS/LIBRARY=LIB$:DBGGEN.L32/LIST=LIS$:DBGGEN.LIS SRC$:DBGGEN.REQ
$ BLISS/LIBRARY=LIB$:DBGEXT.L32/LIST=LIS$:DBGEXT.LIS SRC$:DBGEXT.REQ
$ !
$ ! Create the help library
$ !
$ RUNOFF/OUTPUT=LIB$: SRC$:DEBUGHLP.RNH
$ LIBRARY/HELP/CREATE LIB$:DEBUGHLP LIB$:DEBUGHLP
$ !
$ ! Create the message file.
$ !
$ MCR MDL 		LIB$:DBGMSG=SRC$:DBGMSG
$ CREATE LIB$:DBGMSG.REQ
LIBRARY 'SYS$LIBRARY:LIB.L32';
$ CONVERT/APPEND LIB$:DBGMSG.B32 LIB$:DBGMSG.REQ
$ DELETE LIB$:DBGMSG.B32;0
$ LIB/MAC/CREATE 	LIB$:DBGMSG			LIB$:DBGMSG
$ @MASD$:[SYSEXE]CVTMSG SRC$:DBGMSG.MDL
$ MESSAGE/OBJ=OBJ$:DBGMSG.OBB DBGMSG
$ CPYSYSMSG OBJ$:DBGMSG.OBB
$ MESSAGE/FILE_NAME=DBGTBKMSG/OBJ=OBJ$:DBGMSG.OBJ DBGMSG
$ DELETE DBGMSG.MSG;0
$ !
$ EXIT
$ !
$ASSEM:
$ !
$ !	Create the objects and listings.
$ !
$ BLISS/LIBRARY=LIB$:DBGMSG.L32/LIST=LIS$:DBGMSG.LIS LIB$:DBGMSG.REQ
$ @SYSBLDCOM$:FASM 'FACNAM "" N 'UPDATES
$
$ ! Purge the .OBJ's and .LIS's so we clean up old copies that came
$ ! from previous partially completed builds. It is important that
$ ! we purge the six .OBJ's that get renamed to .SSIOBJ, so that we
$ ! do not end up with SSI modules in DEBUG.OLB.
$ !
$ PURGE OBJ$:*.OBJ
$ PURGE LIS$:*.LIS
$
$ ! Rename the six .OBJ's that came from SSI so they don't get included
$ ! in DEBUG.OLB
$ !
$ RENAME OBJ$:ISSH.OBJ OBJ$:ISSH.SSIOBJ
$ RENAME OBJ$:RESETSSI.OBJ OBJ$:RESETSSI.SSIOBJ
$ RENAME OBJ$:SSIDISP.OBJ OBJ$:SSIDISP.SSIOBJ
$ RENAME OBJ$:SSIK.OBJ OBJ$:SSIK.SSIOBJ
$ RENAME OBJ$:SSITAB.OBJ OBJ$:SSITAB.SSIOBJ
$ RENAME OBJ$:SSIU.OBJ OBJ$:SSIU.SSIOBJ
$ RENAME OBJ$:SSIUW.OBJ OBJ$:SSIUW.SSIOBJ
$ EXIT
$ !
$OBJLIB:
$ !
$ !	Create the object libraries from the object modules.
$ !
$ LIBRARY/CREATE OBJ$:DBGSSISHR.OLB OBJ$:*.SSIOBJ
$ @SYSBLDCOM$:OBJLIB DEBUG
$ EXIT
$ !
$LNKLIB:
$ !
$ ! 	Null LNKLIB phase.
$ !
$ EXIT
$ !
$LINK:
$ !
$ !	Link the debugger.
$ !
$ @COM$:DEBUGLNK
$ EXIT
$ !
$RESULT:
$ !
$ ! Copy the debug image and map to a system area
$ !
$ CPYSYSLIB EXE$:DBGSSISHR.EXE
$ CPYRESMAP MAP$:DBGSSISHR.MAP
$ CPYSYSLIB EXE$:DEBUG.EXE
$ CPYRESMAP MAP$:DEBUG.MAP
$ CPYSYSLIB EXE$:S0DEBUG.EXE
$ !
$ ! Build the concatenated listing
$ !
$ CPYRESLIS LIS$:*.LIS DEBUG.LSS
$ !
$ ! Copy the help library to sys$help and copy the message file also.
$ !
$ CPYSYSHLP LIB$:DEBUGHLP.HLB
$ CPYSYSMSG OBJ$:DBGMSG.OBB
$ EXIT
