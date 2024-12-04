$ !++
$ !
$ ! COBRTLBLD.COM  -	build the component COBRTL.
$ !			assumes definitions for: LIB$, LIS$, SRC$, EXE$, MAP$,
$ !						 OBJ$ and SYSBLDCOM$.
$ !			assumes existence of:	 SYSBLDCOM$:CREATEDIR.COM
$ !						 SYSBLDCOM$:FASM.COM
$ !						 SYSBLDCOM$:VECTORTST.COM
$ !
$ ! 1-001 - adapted from RTLBLD.COM.  MDL 17-Aug-1983
$ ! 1-002 - INTPAR.MAR needs to be in COBRTL.MLB.  GETSHRLIB files as needed
$ !	    from other facilities.  MDL 18-Aug-1983
$ ! 1-003 - delete checkpoint file from old builds.  MDL 24-Aug-1983
$ ! 1-004 - clean up CPY/DELSHRLIBs.  MDL 16-Sep-1983
$ ! 1-005 - COBPROLOG.REQ and COBLNK.REQ added.		LGB 27-Feb-1984
$ ! 1-006 - include SMGLIB.L32				LGB 27-Feb-1984
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
$ DELSHRLIB LIB$:COBMSG.MAR
$ DELETE OBJ$:*.*;*,LIS$:*.*;*,LIB$:*.*;*
$ !
$ ! create new updated files not updated in ASSEM phase.
$ !
$ SRCUPDATE COBDEF.REQ
$ SRCUPDATE COBLNK.REQ
$ SRCUPDATE COBPROLOG.REQ
$ SRCUPDATE COBMSG.MSG
$ SRCUPDATE INTPAR.SDL
$ !
$ ! create SDL source files from MESSAGE source files.
$ !
$ MESSAGE/SDL=LIB$:/NOOBJECT/NOLIST SRC$:COBMSG
$ !
$ ! run SDL conversions for VMSLIB component to use in SRCLIB (next) phase.
$ !
$ SDL/NOLIST/LANG=(MACRO=LIB$:)			SRC$:INTPAR
$ SDL/VMS/NOLIST/LANG=(BLISS=LIB$:) 	    	SRC$:INTPAR
$ SDL/VMS/NOLIST/LANG=(BLISS=LIB$:,MACRO=LIB$:) LIB$:COBMSG
$ !
$ ! share message source files w/other component(s) that use them.
$ !
$ PUTSYSMSG SRC$:COBMSG.MSG		! share file with SYSMSG component
$ !
$ ! share require files w/other component(s) that use them.
$ !
$ CPYSHRLIB LIB$:COBMSG.MAR		! share file with VMSLIB component
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
$ DELETE LIB$:COBRTL.MLB;*
$ DELETE LIB$:COBRTL.OLB;*,COBMSGPTR.OLB;*,COBVECTRS.OLB;*
$ REMSHRLIB RTLPSECT.REQ
$ REMSHRLIB STRMACROS.REQ
$ REMSHRLIB SMGLNK.REQ
$ REMSHRLIB SMGTERM.REQ
$ !
$ ! get library/require files from other components as needed.
$ !
$ GETSHRLIB RTLPSECT.REQ	! get file from LIBRTL component
$ GETSHRLIB STRMACROS.REQ	! get file from LIBRTL component
$ GETSHRLIB SMGLNK.REQ		! get file from SMGRTL component
$ GETSHRLIB SMGTERM.REQ		! get file from SMGRTL component
$ !
$ ! move files just obtained into other subdirectories as needed.
$ !
$ RENAME LIB$:RTLPSECT.REQ	SRC$:
$ RENAME LIB$:STRMACROS.REQ	SRC$:
$ RENAME LIB$:SMGLNK.REQ	SRC$:
$ RENAME LIB$:SMGTERM.REQ	SRC$:
$ !
$ ! create macro source libraries.  insert modules as appropriate.
$ !
$ LIBRARY/CREATE/MACRO LIB$:COBRTL.MLB
$ LIBRARY/MACRO LIB$:COBRTL LIB$:COBMSG.MAR
$ LIBRARY/MACRO LIB$:COBRTL LIB$:INTPAR.MAR
$ !
$ ! create object libraries.  these will be filled in during the ASSEM phase.
$ !
$ LIBRARY/CREATE/OBJECT LIB$:COBRTL
$ LIBRARY/CREATE/OBJECT LIB$:COBMSGPTR
$ LIBRARY/CREATE/OBJECT LIB$:COBVECTRS
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
$ REMSHRLIB SMGLIB.L32
$ GETSHRLIB SMGLIB.L32
$ !
$ ! delete the files we are about to create (from previous builds); cannot use
$ ! wildcard delete because library listings and object libraries were just 
$ ! created.  So just PURGE.
$ !
$ PURGE LIS$:
$ PURGE OBJ$:
$ !
$ ! invoke system build assembly procedure to perform assemblies.  This will 
$ ! compile all modules as specified in COBRTLASM.DAT.  Objects will be placed
$ ! in libraries according to COBRTLASM.DAT specifications as well.
$ !
$ @SYSBLDCOM$:FASM COBRTL "" Y 'UPDATES N Y
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
$ ! image was placed in the object library COBRTL.OLB during the ASSEM phase, so
$ ! any remaining OBJ's can be deleted.
$ !
$ DELETE OBJ$:*.OBJ;*
$ !
$ ! extract message pointer object files from message object library and insert
$ ! them into facility object library.
$ !
$ LIBRARY/EXTRACT=*/OUT=OBJ$:COBMSGPTR.OBJ LIB$:COBMSGPTR
$ LIBRARY LIB$:COBRTL OBJ$:COBMSGPTR.OBJ
$ DELETE OBJ$:COBMSGPTR.OBJ;
$ !
$ ! extract individual vector object files from vector object library, to be
$ ! used in next phase to link the shareable image(s).
$ !
$ LIBRARY/EXTRACT=COB$VECTOR/OUT=OBJ$:COBVECTOR.OBJ LIB$:COBVECTRS
$ !
$ ! share the object library for this facility with other facilities that may
$ ! need it.
$ !
$ CPYRESOBJ LIB$:COBRTL.OLB
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
$ DELETE EXE$:COBRTL.EXE;*,MAP$:COBRTL.MAP;*
$ !
$ ! link the Run-Time Library Shareable Image COBRTL.
$ !
$ LINK/NOSYSLIB/SHARE=EXE$:COBRTL/MAP=MAP$:COBRTL/FULL/CROSS -
  COM$:COBRTLLNK/OPTIONS
$ !
$ ! copy it into it's destination on the result disk, and insert it into the 
$ ! shareable image library there.
$ !
$ CPYSYSLIB EXE$:COBRTL.EXE
$ CPYSYSLIB OBJ$:COBVECTOR.OBJ
$ INSHARLIB EXE$:COBRTL
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
$ @SYSBLDCOM$:VECTORTST EXE$:COBRTL
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
$ ! end of file COBRTLBLD.COM
$ !--
