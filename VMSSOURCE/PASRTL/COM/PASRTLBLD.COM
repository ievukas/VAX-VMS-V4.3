$ !++
$ !
$ ! PASRTLBLD.COM  -	build the component PASRTL.
$ !			assumes definitions for: LIB$, LIS$, SRC$, EXE$, MAP$,
$ !						 OBJ$ and SYSBLDCOM$.
$ !			assumes existence of:	 SYSBLDCOM$:CREATEDIR.COM
$ !						 SYSBLDCOM$:FASM.COM
$ !						 SYSBLDCOM$:VECTORTST.COM
$ !
$ ! 1-001 adapted from RTLBLD.  MDL 18-Aug-1983
$ ! 1-002 delete checkpoint file from old builds.  MDL 24-Aug-1983
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
$ SRCUPDATE PASBUGCOD.REQ
$ SRCUPDATE PASEXTERN.REQ
$ SRCUPDATE PASFCB.SDL
$ SRCUPDATE PASKDB.REQ
$ SRCUPDATE PASLIB.REQ
$ SRCUPDATE PASMACROS.REQ
$ SRCUPDATE PASOPEDEF.REQ
$ SRCUPDATE PASPFD.REQ
$ SRCUPDATE PASPFV.REQ
$ SRCUPDATE PASPROLOG.REQ
$ !
$ ! create SDL source files from MESSAGE source files.
$ !
$ ! NONE
$ !
$ ! run SDL conversions for VMSLIB component to use in SRCLIB (next) phase.
$ !
$ SDL/NOLIST/LANG=(BLISSF=LIB$:)	SRC$:PASFCB
$ !
$ ! share message source files w/other component(s) that use them.
$ !
$ ! NONE
$ !
$ ! share require files w/other component(s) that use them.
$ !
$ ! NONE
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
$ DELETE LIB$:PASRTL.MLB;*
$ DELETE LIB$:PASRTL.OLB;*,PASMSGPTR.OLB;*,PASMSGTXT.OLB;*,PASVECTRS.OLB;*
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
$ LIBRARY/CREATE/OBJECT LIB$:PASRTL
$ LIBRARY/CREATE/OBJECT LIB$:PASMSGPTR
$ LIBRARY/CREATE/OBJECT LIB$:PASMSGTXT
$ LIBRARY/CREATE/OBJECT LIB$:PASVECTRS
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
$ DELETE LIS$:PASLIB.L32;*,LIS$:PASLIB.LIS;*
$ BLISS/LIBRARY=LIB$:/LIST=LIS$:/SOURCE=REQUIRE SRC$:PASLIB
$ !
$ ! delete the files we are about to create (from previous builds); cannot use
$ ! wildcard delete because library listings and object libraries were just 
$ ! created.  So just PURGE.
$ !
$ PURGE LIS$:
$ PURGE OBJ$:
$ !
$ ! invoke system build assembly procedure to perform assemblies.  This will 
$ ! compile all modules as specified in PASRTLASM.DAT.  Objects will be placed
$ ! in libraries according to PASRTLASM.DAT specifications as well.
$ !
$ @SYSBLDCOM$:FASM PASRTL "" Y 'UPDATES N Y
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
$ ! image was placed in the object library PASRTL.OLB during the ASSEM phase, so
$ ! any remaining OBJ's can be deleted.
$ !
$ DELETE OBJ$:*.OBJ;*
$ !
$ ! extract message pointer object files from message object library and insert
$ ! them into facility object library.
$ !
$ LIBRARY/EXTRACT=*/OUT=OBJ$:PASMSGPTR.OBJ LIB$:PASMSGPTR
$ LIBRARY LIB$:PASRTL OBJ$:PASMSGPTR.OBJ
$ DELETE OBJ$:PASMSGPTR.OBJ;
$ !
$ ! extract individual vector object files from vector object library, to be
$ ! used in next phase to link the shareable image(s).
$ !
$ LIBRARY/EXTRACT=PAS$VECTOR/OUT=OBJ$:PASVECTOR.OBJ LIB$:PASVECTRS
$ !
$ ! share the object library for this facility with other facilities that may
$ ! need it.
$ !
$ CPYRESOBJ LIB$:PASRTL.OLB
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
$ DELETE EXE$:PASRTL.EXE;*,MAP$:PASRTL.MAP;*
$ !
$ ! link the Run-Time Library Shareable Image PASRTL.
$ !
$ LINK/NOSYSLIB/SHARE=EXE$:PASRTL/MAP=MAP$:PASRTL/FULL/CROSS -
  COM$:PASRTLLNK/OPTIONS
$ !
$ ! copy it into it's destination on the result disk, and insert it into the 
$ ! shareable image library there.
$ !
$ CPYSYSLIB EXE$:PASRTL.EXE
$ CPYSYSLIB OBJ$:PASVECTOR.OBJ
$ INSHARLIB EXE$:PASRTL
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
$ DELETE EXE$:PASMSG.EXE;*
$ !
$ ! link the Run-Time Library Message Image PASMSG.
$ !
$ LINK/MAP=NL:/SHARE=EXE$:PASMSG LIB$:PASMSGTXT/INCLUDE=PAS$MSGDEF
$ !
$ ! copy it into it's destination on the result disk.
$ !
$ CPYSYSMSG EXE$:PASMSG.EXE
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
$ @SYSBLDCOM$:VECTORTST EXE$:PASRTL
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
$ ! end of file PASRTLBLD.COM
$ !--
