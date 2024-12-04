$ !++
$ !
$ ! SMGRTLBLD.COM  -	build the component SMGRTL (SMGSHR.EXE).
$ !			assumes definitions for: LIB$, LIS$, SRC$, EXE$, MAP$,
$ !						 OBJ$ and SYSBLDCOM$.
$ !			assumes existence of:	 SYSBLDCOM$:CREATEDIR.COM
$ !						 SYSBLDCOM$:FASM.COM
$ !						 SYSBLDCOM$:VECTORTST.COM
$ !
$ ! 1-001 - adapted from RTLBLD.  MDL 22-Aug-1983
$ ! 1-002 - delete checkpoint file from old builds.  MDL 24-Aug-1983
$ ! 1-003 - clean up CPY/DELSHRLIBs.  MDL 16-Sep-1983
$ ! 1-004 - build SMGLIB.L32 in special SRCLIB_1 phase, similar to LIBRTL.
$ !	    COBRTL references it.  MDL 27-Feb-1984
$ ! 1-005 - Add in new SDL files, REQ files for integration of SMG output
$ !	    routines.  Also build TERMTABLE related images in this facility.
$ !	    LEB 6-Mar-1984
$ ! 1-006 - Add in SRCUPDATE of SMGDATSTR.REQ.  LEB 7-Mar-84
$ ! 1-007 - Add in REMSHRLIB, GETSHRLIB and RENAME of file STRLNK.REQ.
$ !	    TH/LEB 13-Mar-1984
$ ! 1-008 - Fix LINK and RESULT phases to build TERMTABLE properly and get
$ !		the .TXT files from the master disk. TH
$ ! 1-009 - Use logical name TERMTABLE to get TERMTABLE.EXE built in RESEXE$
$ !	    and then copy it to EXE$. STAN 21-Mar-1984.
$ ! 1-010 - Define logical for where to get SMGTERMS.TXT. STAN 21-Mar-1984.
$ ! 1-011 - Add a LIB/EXTRACT from SMGVECTRS.OLB to get SMGVECTOR.OBJ
$ !	    LEB 26-Mar-1984
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
$ DELSHRLIB LIB$:SMGDEF.MAR
$ DELSHRLIB LIB$:SMGDEF.R32
$ DELSHRLIB SRC$:SMGLNK.REQ
$ DELSHRLIB SRC$:SMGTERM.REQ
$ DELETE OBJ$:*.*;*,LIS$:*.*;*,LIB$:*.*;*
$ !
$ ! create new updated files not updated in ASSEM phase.
$ !
$ SRCUPDATE SMGDEF.SDL
$ SRCUPDATE SMGKCB.SDL
$ SRCUPDATE SMGKDE.SDL
$ SRCUPDATE SMGKQB.SDL
$ SRCUPDATE SMGKTH.SDL
$ SRCUPDATE SMGTRMPTR.SDL
$ SRCUPDATE SMGDATSTR.REQ
$ SRCUPDATE SMGLIB.REQ
$ SRCUPDATE SMGLNK.REQ
$ SRCUPDATE SMGMACROS.REQ
$ SRCUPDATE SMGPROLOG.REQ
$ SRCUPDATE SMGSCRMAC.REQ
$ SRCUPDATE SMGSCRTCB.REQ
$ SRCUPDATE SMGTABDEF.REQ
$ SRCUPDATE SMGTERM.REQ
$ SRCUPDATE SMGTPALIB.REQ
$ SRCUPDATE SMGTPACTL.REQ
$ SRCUPDATE SMGTRMMAC.REQ
$ SRCUPDATE SMGTRMSTR.R32
$ !
$ ! create SDL source files from MESSAGE source files.
$ !
$ ! NONE
$ !
$ ! run SDL conversions for VMSLIB component to use in SRCLIB (next) phase.
$ !
$ SDL/VMS/NOLIST/LANG=(BLISS=LIB$:,MACRO=LIB$:)	SRC$:SMGDEF
$ SDL/VMS/NOLIST/LANG=(BLISS=LIB$:,MACRO=LIB$:)	SRC$:SMGTRMPTR
$ SDL/NOLIST/LANG=(BLISSF=LIB$:)		SRC$:SMGKCB
$ SDL/NOLIST/LANG=(BLISSF=LIB$:)		SRC$:SMGKDE
$ SDL/NOLIST/LANG=(BLISSF=LIB$:)		SRC$:SMGKQB
$ SDL/NOLIST/LANG=(BLISSF=LIB$:)		SRC$:SMGKTH
$ !
$ ! share message source files w/other component(s) that use them.
$ !
$ ! NONE
$ !
$ ! share require files w/other component(s) that use them.
$ !
$ CPYSHRLIB LIB$:SMGDEF.MAR		! share file with VMSLIB component
$ CPYSHRLIB LIB$:SMGDEF.R32		! share file with VMSLIB component
$ CPYSHRLIB LIB$:SMGTRMPTR.MAR		! share file with VMSLIB component
$ CPYSHRLIB LIB$:SMGTRMPTR.R32		! share file with VMSLIB component
$ CPYSHRLIB SRC$:SMGLNK.REQ		! share file with COBRTL component
$ CPYSHRLIB SRC$:SMGTERM.REQ		! share file with COBRTL component
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
$ DELETE LIB$:SMGRTL.MLB;*
$ DELETE LIB$:SMGRTL.OLB;*,SMGMSGPTR.OLB;*,SMGMSGTXT.OLB;*,SMGVECTRS.OLB;*
$ !
$ REMSHRLIB STRLNK.REQ
$ !
$ ! get library/require files from other components as needed.
$ !
$ GETSHRLIB STRLNK.REQ
$ !
$ ! move files just obtained into other subdirectories as needed.
$ !
$ RENAME LIB$:STRLNK.REQ	SRC$:
$ !
$ ! create macro source libraries.  insert modules as appropriate.
$ !
$ LIBRARY/CREATE/MACRO LIB$:SMGRTL.MLB
$ LIBRARY/MACRO LIB$:SMGRTL LIB$:SMGDEF.MAR
$ !
$ ! create object libraries.  these will be filled in during the ASSEM phase.
$ !
$ LIBRARY/CREATE/OBJECT LIB$:SMGRTL
$ LIBRARY/CREATE/OBJECT LIB$:SMGMSGPTR
$ LIBRARY/CREATE/OBJECT LIB$:SMGMSGTXT
$ LIBRARY/CREATE/OBJECT LIB$:SMGVECTRS
$ !
$ ! create the Bliss source library SMGLIB.  For this to work in the system
$ ! build, this is done after all other facilities have completed in the 
$ ! SRCLIB phase (coordinated by running this facility in SRCLIB_1).  This
$ ! has no impact for FACTSTBLDs.
$ !
$ DELSHRLIB LIB$:SMGLIB.L32
$ !
$ DELETE LIS$:SMGLIB.L32;*,LIS$:SMGLIB.LIS;*
$ BLISS/LIBRARY=LIB$:/LIST=LIS$:/SOURCE=REQUIRE SRC$:SMGLIB
$ !
$ ! Create a BLISS source library specific to TERMTABLE support.
$ DELETE LIS$:SMGTPALIB.L32;*,LIS$:SMGTPALIB.LIS;*
$ BLISS/LIBRARY=LIB$:SMGTPALIB/LIST=LIS$:SMGTPALIB/SOURCE=REQUIRE -
	SRC$:SMGTPALIB
$ !
$ ! share bliss libraries with other facilities
$ !
$ CPYSHRLIB LIB$:SMGLIB.L32		! Share file with COBRTL component
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
$ ! SMGLIB.L32 WAS CREATED IN THE PREVIOUS (SRCLIB) PHASE.  THIS IS A SPECIAL
$ ! CASE SO THAT ALL OF THE VARIOUS RTL FACILITIES CAN RUN CONCURRENTLY IN
$ ! THE ASSEM PHASE.  THIS IS DONE BY A SPECIAL PHASE CALLED SRCLIB_1 WHEN
$ ! RUNNING THE SYSTEM BUILD.  THERE IS NO IMPACT FOR A FACTSTBLD.
$ !
$ ! get bliss source libraries from other facilities as needed.
$ !
$ REMSHRLIB RTLLIB.L32
$ GETSHRLIB RTLLIB.L32
!
$ ! delete the files we are about to create (from previous builds); cannot use
$ ! wildcard delete because library listings and object libraries were just 
$ ! created.  So just PURGE.
$ !
$ PURGE LIS$:
$ PURGE OBJ$:
$ !
$ ! invoke system build assembly procedure to perform assemblies.  This will 
$ ! compile all modules as specified in SMGRTLASM.DAT.  Objects will be placed
$ ! in libraries according to SMGRTLASM.DAT specifications as well.
$ !
$ @SYSBLDCOM$:FASM SMGRTL "" Y 'UPDATES N Y
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
$ ! image was placed in the object library SMGRTL.OLB during the ASSEM phase, so
$ ! any remaining OBJ's can be deleted.
$ !
$ DELETE OBJ$:*.OBJ;*
$ !
$ ! extract message pointer object files from message object library and insert
$ ! them into facility object library.
$ !
$ LIBRARY/EXTRACT=*/OUT=OBJ$:SMGMSGPTR.OBJ LIB$:SMGMSGPTR
$ LIBRARY LIB$:SMGRTL OBJ$:SMGMSGPTR.OBJ
$ DELETE OBJ$:SMGMSGPTR.OBJ;
$ !
$ ! extract individual vector object files from vector object library, to be
$ ! used in next phase to link the shareable image(s).
$ !
$ LIBRARY/EXTRACT=SMG$VECTOR/OUT=OBJ$:SMGVECTOR.OBJ LIB$:SMGVECTRS
$ !
$ ! share the object library for this facility with other facilities that may
$ ! need it.
$ !
$ CPYRESOBJ LIB$:SMGRTL.OLB
$ !
$ ! cause SMG messages to be built into SHRIMGMSG.EXE
$ ! 
$ LIBRARY/EXTRACT=SMG$MSGDEF/OUT=OBJ$:SMGMSG.OBB LIB$:SMGMSGTXT
$ CPYSYSMSG OBJ$:SMGMSG.OBB
$ DELETE OBJ$:SMGMSG.OBB;*
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
$ DELETE EXE$:SMGSHR.EXE;*,MAP$:SMGSHR.MAP;*
$ !
$ ! link the Run-Time Library Shareable Image SMGSHR.
$ !
$ LINK/NOSYSLIB/SHARE=EXE$:SMGSHR/MAP=MAP$:SMGSHR/FULL/CROSS -
  COM$:SMGSHRLNK/OPTIONS
$ !
$ ! copy it into it's destination on the result disk, and insert it into the 
$ ! shareable image library there.
$ !
$ CPYSYSLIB EXE$:SMGSHR.EXE
$ CPYSYSLIB OBJ$:SMGVECTOR.OBJ 
$ INSHARLIB EXE$:SMGSHR
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
$ ! Link the termtable compiler.
$ !
$ LINK/EXE=EXE$:SMGBLDTRM/MAP=MAP$:SMGBLDTRM/FULL/CROSS -
  COM$:SMGBLDTRM/OPTIONS
$ !
$ ! Link the program that creates the global section
$ !
$ LINK/EXE=EXE$:SMGMAPTRM/MAP=MAP$:SMGMAPTRM/FULL/CROSS -
  COM$:SMGMAPTRM/OPTIONS
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
$ ! copy SMGBLDTRM.EXE to [SYSEXE]
$ !
$ CPYRESEXE EXE$:SMGBLDTRM.EXE
$ !
$ ! Copy SMGMAPTRM.EXE to [SYSEXE]
$ !
$ CPYRESEXE EXE$:SMGMAPTRM.EXE
$ !
$ ! Copy the SMGTERMS.TXT and TERMTABLE.TXT files into [SYSEXE]
$ ! as well.  These files are copied unmodified to [SYSEXE].
$ !
$ CPYRESEXE COM$:SMGTERMS.TXT
$ CPYRESEXE COM$:TERMTABLE.TXT
$ !
$ ! Now run the termtable compiler which we just created (SMGBLDTRM.EXE)
$ ! which will read in the TERMTABLE.TXT file and which will
$ ! create the TERMTABLE.EXE file which will be mapped as a global section
$ ! by program SMGMAPTRM.EXE which we also just built.
$ ! By defining logical name TERMTABLE to point to RESEXE$, this causes
$ ! the compiler to take input from TERMTABLE.TXT on RESEXE$ and produce
$ ! TERMTABLE.EXE on RESEXE$ which we then move to EXE$.
$ !
$ DEFINE/USER_MODE TERMTABLE RESEXE$:TERMTABLE
$ DEFINE/USER_MODE SMGTERMS  RESEXE$:SMGTERMS.TXT
$ RUN EXE$:SMGBLDTRM	! Gets inputs and puts outputs from/to RESEXE$:TERMTABLE
$ COPY RESEXE$:TERMTABLE.EXE EXE$:
$ !
$ ! Copy the resulting TERMTABLE.EXE to [SYSEXE]
$ !
$ CPYRESEXE EXE$:TERMTABLE.EXE
$ !
$ ! invoke system build vector test procedure to be sure the vectored entry
$ ! points in the shareable image(s) are correct.
$ !
$ @SYSBLDCOM$:VECTORTST EXE$:SMGSHR
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
$ ! end of file SMGRTLBLD.COM
$ !--
