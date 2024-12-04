$ !++
$ !
$ ! RPGRTLBLD.COM  -	build the component RPGRTL.
$ !			assumes definitions for: LIB$, LIS$, SRC$, EXE$, MAP$,
$ !						 OBJ$ and SYSBLDCOM$.
$ !			assumes existence of:	 SYSBLDCOM$:CREATEDIR.COM
$ !						 SYSBLDCOM$:FASM.COM
$ !						 SYSBLDCOM$:VECTORTST.COM
$ !
$ ! 
$ ! 1-001 - adapted from RTLBLD.  MDL 22-Aug-1983
$ ! 1-002 - delete checkpoint file from old builds.  MDL 24-Aug-1983
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
$ SRCUPDATE RPGDEF.REQ
$ SRCUPDATE RPGPROLOG.REQ
$ SRCUPDATE RPGLIB.REQ
$ !
$ ! create SDL source files from MESSAGE source files.
$ !
$ ! NONE
$ !
$ ! run SDL conversions for VMSLIB component to use in SRCLIB (next) phase.
$ !
$ ! NONE
$ !
$ ! share message source files w/other component(s) that use them.
$ !
$ ! NONE
$ !
$ ! share require files w/other component(s) that use them.
$ !
$ ! NONE
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
$ DELETE LIB$:RPGRTL.MLB;*
$ DELETE LIB$:RPGRTL.OLB;*,RPGMSGPTR.OLB;*,RPGMSGTXT.OLB;*,RPGVECTRS.OLB;*
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
$ ! NONE
$ !
$ ! create object libraries.  these will be filled in during the ASSEM phase.
$ !
$ LIBRARY/CREATE/OBJECT LIB$:RPGRTL
$ LIBRARY/CREATE/OBJECT LIB$:RPGMSGPTR
$ LIBRARY/CREATE/OBJECT LIB$:RPGMSGTXT
$ LIBRARY/CREATE/OBJECT LIB$:RPGVECTRS
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
$ DELETE LIS$:RPGLIB.L32;*,LIS$:RPGLIB.LIS;*
$ BLISS/LIBRARY=LIB$:/LIST=LIS$:/SOURCE=REQUIRE SRC$:RPGLIB
$ !
$ ! delete the files we are about to create (from previous builds); cannot use
$ ! wildcard delete because library listings and object libraries were just 
$ ! created.  So just PURGE.
$ !
$ PURGE LIS$:
$ PURGE OBJ$:
$ !
$ ! invoke system build assembly procedure to perform assemblies.  This will 
$ ! compile all modules as specified in RPGRTLASM.DAT.  Objects will be placed
$ ! in libraries according to RPGRTLASM.DAT specifications as well.
$ !
$ @SYSBLDCOM$:FASM RPGRTL "" Y 'UPDATES N Y
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
$ ! image was placed in the object library RPGRTL.OLB during the ASSEM phase, so
$ ! any remaining OBJ's can be deleted.
$ !
$ DELETE OBJ$:*.OBJ;*
$ !
$ ! extract message pointer object files from message object library and insert
$ ! them into facility object library.
$ !
$ LIBRARY/EXTRACT=*/OUT=OBJ$:RPGMSGPTR.OBJ LIB$:RPGMSGPTR
$ LIBRARY LIB$:RPGRTL OBJ$:RPGMSGPTR.OBJ
$ DELETE OBJ$:RPGMSGPTR.OBJ;
$ !
$ ! extract individual vector object files from vector object library, to be
$ ! used in next phase to link the shareable image(s).
$ !
$ LIBRARY/EXTRACT=RPG$VECTOR/OUT=OBJ$:RPGVECTOR.OBJ LIB$:RPGVECTRS
$ !
$ ! share the object library for this facility with other facilities that may
$ ! need it.
$ !
$ CPYRESOBJ LIB$:RPGRTL.OLB
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
$ DELETE EXE$:RPGRTL.EXE;*,MAP$:RPGRTL.MAP;*
$ !
$ ! link the Run-Time Library Shareable Image RPGRTL.
$ !
$ LINK/NOSYSLIB/SHARE=EXE$:RPGRTL/MAP=MAP$:RPGRTL/FULL/CROSS -
  COM$:RPGRTLLNK/OPTIONS
$ !
$ ! copy it into it's destination on the result disk, and insert it into the 
$ ! shareable image library there.
$ !
$ CPYSYSLIB EXE$:RPGRTL.EXE
$ CPYSYSLIB OBJ$:RPGVECTOR.OBJ
$ INSHARLIB EXE$:RPGRTL
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
$ DELETE EXE$:RPGMSG.EXE;*
$ !
$ ! link the Run-Time Library Message Image RPGMSG.
$ !
$ LINK/MAP=NL:/SHARE=EXE$:RPGMSG LIB$:RPGMSGTXT/INCLUDE=RPG$MSGDEF
$ !
$ ! copy it into it's destination on the result disk.
$ !
$ CPYSYSMSG EXE$:RPGMSG.EXE
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
$ @SYSBLDCOM$:VECTORTST EXE$:RPGRTL
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
$ ! end of file RPGRTLBLD.COM
$ !--
