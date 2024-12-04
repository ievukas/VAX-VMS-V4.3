$ !++
$ !
$ ! FORRTLBLD.COM  -	build the component FORRTL.
$ !			assumes definitions for: LIB$, LIS$, SRC$, EXE$, MAP$,
$ !						 OBJ$ and SYSBLDCOM$.
$ !			assumes existence of:	 SYSBLDCOM$:CREATEDIR.COM
$ !						 SYSBLDCOM$:FASM.COM
$ !						 SYSBLDCOM$:VECTORTST.COM
$ !
$ ! 1-001 adapted from RTLBLD.COM.  MDL 15-Aug-1983
$ ! 1-002 need .BLF's and RTLLIB.L32 from LIBRTL; GET/REMSHRLIB them.  
$ !	  MDL 16-Aug-1983
$ ! 1-003 need more stuff from LIBRTL & MTHRTL.  Get it.  MDL 16-Aug-1983
$ ! 1-004 delete checkpoint file from old builds.  MDL 24-Aug-1983
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
$ DELSHRLIB LIB$:FORMSG.MAR
$ DELETE OBJ$:*.*;*,LIS$:*.*;*,LIB$:*.*;*
$ !
$ ! create new updated files not updated in ASSEM phase.
$ !
$ SRCUPDATE COMEST.REQ
$ SRCUPDATE FORDEF.FOR
$ SRCUPDATE FORERR.SDL
$ SRCUPDATE FORFMT.REQ
$ SRCUPDATE FORIOSDEF.SDL
$ SRCUPDATE FORLIB.REQ
$ SRCUPDATE FORMACROS.REQ
$ SRCUPDATE FORMSG.MSG
$ SRCUPDATE FORNML.REQ
$ SRCUPDATE FOROPN.REQ
$ SRCUPDATE FORPAR.SDL
$ SRCUPDATE FORPROLOG.REQ
$ SRCUPDATE FORRCE.SDL
$ !
$ ! create SDL source files from MESSAGE source files.
$ !
$ MESSAGE/SDL=LIB$:/NOOBJECT/NOLIST SRC$:FORMSG
$ !
$ ! run SDL conversions for VMSLIB component to use in SRCLIB (next) phase.
$ !
$ SDL/NOLIST/LANG=(BLISS=LIB$:,MACRO=LIB$:)	SRC$:FORERR
$ SDL/NOLIST/LANG=(FORTRAN=LIB$:)		SRC$:FORIOSDEF
$ SDL/NOLIST/LANG=(MACRO=LIB$:)			SRC$:FORPAR
$ SDL/VMS/NOLIST/LANG=(BLISS=LIB$:)		SRC$:FORPAR
$ SDL/NOLIST/LANG=(BLISSF=LIB$:)		SRC$:FORRCE
$ SDL/VMS/NOLIST/LANG=(BLISS=LIB$:,MACRO=LIB$:,FORTRAN=LIB$:) LIB$:FORMSG
$ !
$ ! share message source files w/other component(s) that use them.
$ !
$ PUTSYSMSG SRC$:FORMSG.MSG		! share file with SYSMSG component
$ !
$ ! share require files w/other component(s) that use them.
$ !
$ CPYSHRLIB LIB$:FORMSG.MAR		! share file with VMSLIB component
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
$ ! copy FORTRAN INCLUDE files to SYS$LIBRARY
$ !
$ CPYSYSLIB SRC$:FORDEF.FOR
$ CPYSYSLIB LIB$:FORIOSDEF.FOR
$ !
$ ! delete the files we are about to create (from previous builds).
$ !
$ DELETE LIB$:FORRTL.MLB;*
$ DELETE LIB$:FORRTL.OLB;*,FORMSGPTR.OLB;*,FORVECTRS.OLB;*
$ REMSHRLIB OTSISB.MAR
$ REMSHRLIB OTSLUB.MAR
$ REMSHRLIB OTSISB.BLF
$ REMSHRLIB OTSLUB.BLF
$ REMSHRLIB OTSMAC.REQ
$ REMSHRLIB OTSLNK.REQ
$ REMSHRLIB OTSISB.R32
$ REMSHRLIB OTSLUB.R32
$ REMSHRLIB OTSMSG.R32
$ REMSHRLIB MTHMSG.R32
$ REMSHRLIB MTHERR.R32
$ REMSHRLIB RTLODBG.REQ
$ REMSHRLIB RTLPSECT.REQ
$ REMSHRLIB OTSCCBREQ.REQ
$ !
$ ! get library/require files from other components as needed.
$ !
$ GETSHRLIB OTSISB.MAR		! get file from LIBRTL component
$ GETSHRLIB OTSLUB.MAR		! get file from LIBRTL component
$ GETSHRLIB OTSISB.BLF		! get file from LIBRTL component
$ GETSHRLIB OTSLUB.BLF		! get file from LIBRTL component
$ GETSHRLIB OTSMAC.REQ		! get file from LIBRTL component
$ GETSHRLIB OTSLNK.REQ		! get file from LIBRTL component
$ GETSHRLIB OTSISB.R32		! get file from LIBRTL component
$ GETSHRLIB OTSLUB.R32		! get file from LIBRTL component
$ GETSHRLIB OTSMSG.R32		! get file from LIBRTL component
$ GETSHRLIB MTHMSG.R32		! get file from MTHRTL component
$ GETSHRLIB MTHERR.R32		! get file from MTHRTL component
$ GETSHRLIB RTLODBG.REQ		! get file from LIBRTL component
$ GETSHRLIB RTLPSECT.REQ	! get file from LIBRTL component
$ GETSHRLIB OTSCCBREQ.REQ	! get file from LIBRTL component
$ !
$ ! move files just obtained into other subdirectories as needed.
$ !
$ RENAME LIB$:OTSMAC.REQ	SRC$:
$ RENAME LIB$:OTSLNK.REQ	SRC$:
$ RENAME LIB$:RTLODBG.REQ	SRC$:
$ RENAME LIB$:RTLPSECT.REQ	SRC$:
$ RENAME LIB$:OTSCCBREQ.REQ	SRC$:
$ !
$ ! create macro source libraries.  insert modules as appropriate.
$ !
$ LIBRARY/CREATE/MACRO LIB$:FORRTL.MLB
$ LIBRARY/MACRO LIB$:FORRTL LIB$:FORERR.MAR
$ LIBRARY/MACRO LIB$:FORRTL LIB$:FORPAR.MAR
$ LIBRARY/MACRO LIB$:FORRTL LIB$:FORMSG.MAR
$ LIBRARY/MACRO LIB$:FORRTL LIB$:OTSISB.MAR
$ LIBRARY/MACRO LIB$:FORRTL LIB$:OTSLUB.MAR
$ !
$ ! create object libraries.  these will be filled in during the ASSEM phase.
$ !
$ LIBRARY/CREATE/OBJECT LIB$:FORRTL
$ LIBRARY/CREATE/OBJECT LIB$:FORMSGPTR
$ LIBRARY/CREATE/OBJECT LIB$:FORVECTRS
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
$ DELETE LIS$:FORLIB.L32;*,LIS$:FORLIB.LIS;*
$ BLISS/LIBRARY=LIB$:/LIST=LIS$:/SOURCE=REQUIRE SRC$:FORLIB
$ !
$ ! delete the files we are about to create (from previous builds); cannot use
$ ! wildcard delete because library listings and object libraries were just 
$ ! created.  So just PURGE.
$ !
$ REMSHRLIB RTLLIB.L32
$ PURGE LIS$:
$ PURGE OBJ$:
$ !
$ ! get bliss source libraries from other facilities as needed.
$ !
$ GETSHRLIB RTLLIB.L32		! get file from LIBRTL component
$ !
$ ! invoke system build assembly procedure to perform assemblies.  This will 
$ ! compile all modules as specified in FORRTLASM.DAT.  Objects will be placed
$ ! in libraries according to FORRTLASM.DAT specifications as well.
$ !
$ @SYSBLDCOM$:FASM FORRTL "" Y 'UPDATES N Y
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
$ ! image was placed in the object library FORRTL.OLB during the ASSEM phase, so
$ ! any remaining OBJ's can be deleted.
$ !
$ DELETE OBJ$:*.OBJ;*
$ !
$ ! extract message pointer object files from message object library and insert
$ ! them into facility object library.
$ !
$ LIBRARY/EXTRACT=*/OUT=OBJ$:FORMSGPTR.OBJ LIB$:FORMSGPTR
$ LIBRARY LIB$:FORRTL OBJ$:FORMSGPTR.OBJ
$ DELETE OBJ$:FORMSGPTR.OBJ;
$ !
$ ! extract individual vector object files from vector object library, to be
$ ! used in next phase to link the shareable image(s).
$ !
$ LIBRARY/EXTRACT=FOR$VECTOR/OUT=OBJ$:FORVECTOR.OBJ LIB$:FORVECTRS
$ !
$ ! share the object library for this facility with other facilities that may
$ ! need it.
$ !
$ CPYRESOBJ LIB$:FORRTL.OLB
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
$ DELETE EXE$:FORRTL.EXE;*,MAP$:FORRTL.MAP;*
$ !
$ ! link the Run-Time Library Shareable Image FORRTL.
$ !
$ LINK/NOSYSLIB/SHARE=EXE$:FORRTL/MAP=MAP$:FORRTL/FULL/CROSS -
  COM$:FORRTLLNK/OPTIONS
$ !
$ ! copy it into it's destination on the result disk, and insert it into the 
$ ! shareable image library there.
$ !
$ CPYSYSLIB EXE$:FORRTL.EXE
$ CPYSYSLIB OBJ$:FORVECTOR.OBJ
$ INSHARLIB EXE$:FORRTL
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
$ @SYSBLDCOM$:VECTORTST EXE$:FORRTL
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
$ ! end of file FORRTLBLD.COM
$ !--
