$ !++
$ !
$ ! PLIRTLBLD.COM  -	build the component PLIRTL.
$ !			assumes definitions for: LIB$, LIS$, SRC$, EXE$, MAP$,
$ !						 OBJ$ and SYSBLDCOM$.
$ !			assumes existence of:	 SYSBLDCOM$:CREATEDIR.COM
$ !						 SYSBLDCOM$:FASM.COM
$ !						 SYSBLDCOM$:VECTORTST.COM
$ !
$ ! 1-001 - adapted from RTLBLD.  MDL 22-Aug-1983
$ ! 1-002 - add DATDEF.SDL.  MDL 22-Aug-1983
$ ! 1-003 - delete checkpoint file from old builds.  MDL 24-Aug-1983
$ !
$ !--
$ ON SEVERE_ERROR THEN GOTO FAIL
$ ON ERROR THEN CONTINUE
$ !
$ ! assign RTL-specific logical names.
$ !
$ DEFINE 	RTLIN		SRC$:
$ DEFINE 	RTLML		LIB$:
$ DEFINE 	RTLSTARLE	SYS$LIBRARY:STARLET.L32
$ DEFINE	RTLTPAMAC	SYS$LIBRARY:TPAMAC.L32
$ DEFINE	RTLLIB		SYS$LIBRARY:LIB.L32
$ !
$ ! branch to phase to be run.
$ !
$ STATUS = 1
$ GOTO 'PHASE'
$ !
$ !
$ !
$INIT:
$ !+
$ ! INIT phase 
$ !-
$ !
$ ! create directories on the target disk.
$ !
$ @SYSBLDCOM$:CREATEDIR
$ !
$ GOTO EXIT
$ !+
$ ! end of INIT phase
$ !-
$UPDATE:
$ !+
$ ! UPDATE phase
$ !-
$ !
$ SET NOON
$ !
$ ! delete the files we are about to create (from previous builds).
$ !
$ DELETE OBJ$:*.*;*,LIS$:*.*;*,LIB$:*.*;*
$ !
$ ! create new updated files not updated in ASSEM phase.
$ !
$ SRCUPDATE DATDEF.SDL
$ SRCUPDATE ENVCODES.IN
$ SRCUPDATE FILEDEF.IN
$ SRCUPDATE PLIFILDSP.IN
$ SRCUPDATE PLIRTDEF.MAR
$ !
$ ! create SDL source files from MESSAGE source files.
$ !
$ ! NONE
$ !
$ ! run SDL conversions for VMSLIB component to use in SRCLIB (next) phase.
$ !
$ SDL/NOLIST/LANG=(MACRO=LIB$:)		SRC$:DATDEF
$ !
$ ! share message source files w/other component(s) that use them.
$ !
$ ! NONE
$ !
$ ! share require files w/other component(s) that use them.
$ !
$ SET ON
$ !
$ ! get rid of old versions of files just updated.
$ !
$ PURGE SRC$:
$ GOTO EXIT
$ !+
$ ! end of UPDATE phase
$ !-
$SRCLIB:
$ !+
$ ! SRCLIB phase 
$ !-
$ !
$ ! delete assembly checkpoint file (from previous builds).
$ !
$ DELETE FASMCHECK.CHK;*
$ !
$ ! delete the files we are about to create (from previous builds).
$ !
$ DELETE LIB$:PLIRTL.MLB;*
$ DELETE LIB$:PLIRTL.OLB;*,PLIMSGPTR.OLB;*,PLIMSGTXT.OLB;*,PLIVECTRS.OLB;*
$ !
$ ! get library/require files from other components as needed.
$ !
$ ! NONE
$ !
$ ! move files just obtained into other subdirectories as needed.
$ !
$ ! NONE
$ !
$ ! create macro source libraries.  insert modules as appropriate.
$ !
$ LIBRARY/CREATE/MACRO LIB$:PLIRTMAC.MLB SRC$:PLIRTDEF,-
					 LIB$:DATDEF
$ LIBRARY/CREATE/TEXT  LIB$:PL1RTSRC.TLB SRC$:ENVCODES.IN,-
					      FILEDEF.IN,-
					      PLIFILDSP.IN
$ !
$ ! create object libraries.  these will be filled in during the ASSEM phase.
$ !
$ LIBRARY/CREATE/OBJECT LIB$:PLIRTL
$ LIBRARY/CREATE/OBJECT LIB$:PLIMSGPTR
$ LIBRARY/CREATE/OBJECT LIB$:PLIMSGTXT
$ LIBRARY/CREATE/OBJECT LIB$:PLIVECTRS
$ !
$ GOTO EXIT
$ !+
$ ! end of SRCLIB phase
$ !-
$ASSEM:
$ !+
$ ! ASSEM phase 
$ !-
$ !
$ ! create bliss source libraries.  this can't be done in the SRCLIB phase
$ ! because references are made to STARLET.L32, which didn't exist until now.
$ !
$ ! NONE
$ !
$ ! delete the files we are about to create (from previous builds); cannot use
$ ! wildcard delete because library listings and object libraries were just 
$ ! created.  So just PURGE.
$ !
$ PURGE LIS$:
$ PURGE OBJ$:
$ !
$ ! invoke system build assembly procedure to perform assemblies.  This will 
$ ! compile all modules as specified in PLIRTLASM.DAT.  Objects will be placed
$ ! in libraries according to PLIRTLASM.DAT specifications as well.
$ !
$ @SYSBLDCOM$:FASM PLIRTL "" Y 'UPDATES N Y
$ !
$ ! purge again.  this ensures minimal disk usage.
$ !
$ PURGE LIS$:
$ PURGE OBJ$:
$ !
$ GOTO EXIT
$ !+
$ ! end of ASSEM phase
$ !-
$OBJLIB:
$ !+
$ ! OBJLIB phase 
$ !-
$ !
$ ! delete unnecessary OBJ files - anything to be used in creating the shareable
$ ! image was placed in the object library PLIRTL.OLB during the ASSEM phase, so
$ ! any remaining OBJ's can be deleted.
$ !
$ DELETE OBJ$:*.OBJ;*
$ !
$ ! extract message pointer object files from message object library and insert
$ ! them into facility object library.
$ !
$ LIBRARY/EXTRACT=*/OUT=OBJ$:PLIMSGPTR.OBJ LIB$:PLIMSGPTR
$ LIBRARY LIB$:PLIRTL OBJ$:PLIMSGPTR.OBJ
$ DELETE OBJ$:PLIMSGPTR.OBJ;
$ !
$ ! extract individual vector object files from vector object library, to be
$ ! used in next phase to link the shareable image(s).
$ !
$ LIBRARY/EXTRACT=PLI$RT_TRANSFER_VECTOR/OUT=OBJ$:PLIVECTOR.OBJ LIB$:PLIVECTRS
$ !
$ ! share the object library for this facility with other facilities that may
$ ! need it.
$ !
$ CPYRESOBJ LIB$:PLIRTL.OLB
$ !
$ GOTO EXIT
$ !+
$ ! end of OBJLIB phase
$ !-
$LNKLIB:
$ !+
$ ! LNKLIB phase 
$ !-
$ !
$ ! delete the files we are about to create (from previous builds).
$ !
$ DELETE EXE$:PLIRTL.EXE;*,MAP$:PLIRTL.MAP;*
$ !
$ ! link the Run-Time Library Shareable Image PLIRTL.
$ !
$ LINK/NOSYSLIB/SHARE=EXE$:PLIRTL/MAP=MAP$:PLIRTL/FULL/CROSS -
  COM$:PLIRTLLNK/OPTIONS
$ !
$ ! copy it into it's destination on the result disk, and insert it into the 
$ ! shareable image library there.
$ !
$ CPYSYSLIB EXE$:PLIRTL.EXE
$ CPYSYSLIB OBJ$:PLIVECTOR.OBJ
$ INSHARLIB EXE$:PLIRTL
$ !
$ GOTO EXIT
$ !+
$ ! end of LNKLIB phase
$ !-
$LINK:
$ !+
$ ! LINK phase 
$ !-
$ !
$ ! delete the files we are about to create (from previous builds).
$ !
$ DELETE EXE$:PLIMSG.EXE;*
$ !
$ ! link the Run-Time Library Message Image PLIMSG.
$ !
$ LINK/MAP=NL:/SHARE=EXE$:PLIMSG LIB$:PLIMSGTXT/INCLUDE=PLI$MSGDEF
$ !
$ ! copy it into it's destination on the result disk.
$ !
$ CPYSYSMSG EXE$:PLIMSG.EXE
$ !
$ GOTO EXIT
$ !+
$ ! end of LINK phase
$ !
$RESULT:
$ !+
$ ! RESULT phase
$ !-
$ !
$ ! invoke system build vector test procedure to be sure the vectored entry
$ ! points in the shareable image(s) are correct.
$ !
$ @SYSBLDCOM$:VECTORTST EXE$:PLIRTL
$ !
$ GOTO EXIT
$ !+
$ ! end of RESULT phase
$ !-
$ !
$ ! failure exit 
$ !
$FAIL:
$ STATUS = $STATUS
$ !
$ ! common exit
$ !
$EXIT:
$ !
$ ! deassign RTL-specific logical names.
$ !
$ DEASSIGN	RTLIN
$ DEASSIGN	RTLML
$ DEASSIGN	RTLSTARLE
$ DEASSIGN	RTLTPAMAC
$ DEASSIGN	RTLLIB
$ !
$ ! exit, returning status to caller.
$ !
$ EXIT STATUS
$ !++
$ ! end of file PLIRTLBLD.COM
$ !--
