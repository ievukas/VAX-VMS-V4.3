$ !++
$ !
$ ! VMSRTLBLD.COM  -	build the component VMSRTL.
$ !			assumes definitions for: LIB$, LIS$, SRC$, EXE$, MAP$,
$ !						 OBJ$ and SYSBLDCOM$.
$ !			assumes existence of:	 SYSBLDCOM$:CREATEDIR.COM
$ !						 SYSBLDCOM$:FASM.COM
$ !						 SYSBLDCOM$:VECTORTST.COM
$ !
$ ! 1-001 - adapted from RTLBLD.  MDL 22-Aug-1983
$ ! 1-002 - Macro library isn't needed.  MDL 22-Aug-1983
$ ! 1-003 - extract vector object in RESULT for use in VECTORTST.  
$ !	    MDL 20-Sep-1983
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
$ SET ON
$ !
$ GOTO EXIT
$ !+
$ ! end of UPDATE phase
$ !-
$SRCLIB:
$ !+
$ ! SRCLIB phase 
$ !-
$ !
$ ! delete the files we are about to create (from previous builds).
$ !
$ DELETE LIB$:VMSVECTRS.OLB;*
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
$ LIBRARY/CREATE/OBJECT LIB$:VMSVECTRS
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
$ ! delete the files we are about to create (from previous builds); cannot use
$ ! wildcard delete because library listings and object libraries were just 
$ ! created.  So just PURGE.
$ !
$ PURGE LIS$:
$ PURGE OBJ$:
$ !
$ ! invoke system build assembly procedure to perform assemblies.  This will 
$ ! compile all modules as specified in VMSRTLASM.DAT.  Objects will be placed
$ ! in libraries according to VMSRTLASM.DAT specifications as well.
$ !
$ @SYSBLDCOM$:FASM VMSRTL "" Y 'UPDATES N Y
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
$ ! image was placed in the object library VMSVECTRS.OLB during the ASSEM phase, so
$ ! any remaining OBJ's can be deleted.
$ !
$ DELETE OBJ$:*.OBJ;*
$ !
$ ! extract individual vector object files from vector object library, to be
$ ! used in next phase to link the shareable image(s).
$ !
$ ! NOT DONE HERE - LINKER OPTIONS FILE EXPLICITLY REFERENCES VMSVECTRS.OLB
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
$ DELETE EXE$:VMSRTL.EXE;*,MAP$:VMSRTL.MAP;*
$ !
$ ! link the Run-Time Library "stub" Shareable Image VMSRTL.
$ !
$ LINK/NOSYSLIB/SHARE=EXE$:VMSRTL/MAP=MAP$:VMSRTL/FULL/CROSS -
  COM$:VMSRTLLNK/OPTIONS
$ !
$ ! copy it into it's destination on the result disk, and insert it into the 
$ ! shareable image library there.
$ !
$ CPYSYSLIB EXE$:VMSRTL.EXE
$ !$ CPYSYSLIB OBJ$:VMSVECTOR.OBJ	! NOT DONE FOR VMSRTL
$ !$ INSHARLIB EXE$:VMSRTL		! NOT DONE FOR VMSRTL
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
$ ! extract vector object file from vector object library, for use in VECTORTST.
$ !
$ LIBRARY/EXTRACT=VMS$VECTOR/OUT=OBJ$:VMSVECTOR.OBJ LIB$:VMSVECTRS
$ !
$ ! invoke system build vector test procedure to be sure the vectored entry
$ ! points in the shareable image(s) are correct.
$ !
$ @SYSBLDCOM$:VECTORTST OBJ$:VMSVECTOR.OBJ COM$:VMSVECTOR.DAT
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
$ ! end of file VMSRTLBLD.COM
$ !--
