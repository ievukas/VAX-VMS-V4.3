$ !++
$ !
$ ! BASRTLBLD.COM  -	build the component BASRTL.
$ !			assumes definitions for: LIB$, LIS$, SRC$, EXE$, MAP$,
$ !						 OBJ$ and SYSBLDCOM$.
$ !			assumes existence of:	 SYSBLDCOM$:CREATEDIR.COM
$ !						 SYSBLDCOM$:FASM.COM
$ !						 SYSBLDCOM$:VECTORTST.COM
$ !
$ ! 1-001 - adapted from RTLBLD.  MDL 4-Aug-1983
$ ! 1-002 - CPYRESOBJ the .OLB produced by this facility.  MDL 11-Aug-1983
$ ! 1-003 - move .REQ files around as necessary after they're GETSHRLIB'ed.
$ !         MDL 12-Aug-1983
$ ! 1-004 - delete assembly checkpoint file from old builds.  MDL 24-Aug-1983
$ ! 1-005 - clean up CPY/DELSHRLIBs.  MDL 16-Sep-1983
$ ! 1-006 - clean up name of BASRTL2.  MDL 16-Sep-1983
$ ! 1-007 - correct a DELETE command in the RESULT phase.  MDL 20-Sep-1983
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
$ DELSHRLIB LIB$:BASMSG.MAR
$ DELETE OBJ$:*.*;*,LIS$:*.*;*,LIB$:*.*;*
$ !
$ ! create new updated files not updated in ASSEM phase.
$ !
$ SRCUPDATE BASERRMSG.REQ
$ SRCUPDATE BASFRAME.REQ
$ SRCUPDATE BASINARG.REQ
$ SRCUPDATE BASIOERR.REQ
$ SRCUPDATE BASLNK.REQ
$ SRCUPDATE BASMSG.MSG
$ SRCUPDATE BASOPN.REQ
$ SRCUPDATE BASPAR.SDL
$ SRCUPDATE BPADABDEF.REQ
$ SRCUPDATE BPAERRDEF.REQ
$ SRCUPDATE BPAFQBDEF.REQ
$ SRCUPDATE BPAFSBDEF.REQ
$ SRCUPDATE BPAFUNDEF.REQ
$ SRCUPDATE BPAMSGDEF.REQ
$ SRCUPDATE BPASTRUCT.REQ
$ SRCUPDATE BPAXRBDEF.REQ
$ SRCUPDATE MATRIX.MAR
$ !
$ ! create SDL source files from MESSAGE source files.
$ !
$ MESSAGE/SDL=LIB$:/NOOBJECT/NOLIST SRC$:BASMSG
$ !
$ ! run SDL conversions for VMSLIB component to use in SRCLIB (next) phase.
$ !
$ SDL/NOLIST/LANG=(MACRO=LIB$:) 	    SRC$:BASPAR
$ SDL/VMS/NOLIST/LANG=(BLISS=LIB$:) 	    SRC$:BASPAR
$ SDL/VMS/NOLIST/LANG=(BLISS=LIB$:,MACRO=LIB$:) LIB$:BASMSG
$ !
$ ! share message source files w/other component(s) that use them.
$ !
$ PUTSYSMSG SRC$:BASMSG.MSG		! share file with SYSMSG component
$ !
$ ! share require files w/other component(s) that use them.
$ !
$ CPYSHRLIB LIB$:BASMSG.MAR		! share file with VMSLIB component
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
$ DELETE LIB$:BASRTL.MLB;*
$ DELETE LIB$:BASRTL.OLB;*,BASVECTRS.OLB;*
$ REMSHRLIB OTSISB.R32
$ REMSHRLIB OTSLNK.REQ
$ REMSHRLIB OTSLUB.R32
$ REMSHRLIB OTSMAC.REQ
$ REMSHRLIB OTSCCBREQ.REQ
$ REMSHRLIB RTLPSECT.REQ
$ REMSHRLIB STRLNK.REQ
$ !
$ ! get library/require files from other components as needed.
$ !
$ GETSHRLIB OTSISB.R32		! get file from LIBRTL component
$ GETSHRLIB OTSLNK.REQ		! get file from LIBRTL component
$ GETSHRLIB OTSLUB.R32		! get file from LIBRTL component
$ GETSHRLIB OTSMAC.REQ		! get file from LIBRTL component
$ GETSHRLIB OTSCCBREQ.REQ	! get file from LIBRTL component
$ GETSHRLIB RTLPSECT.REQ	! get file from LIBRTL component
$ GETSHRLIB STRLNK.REQ		! get file from LIBRTL component
$ !
$ ! move files just obtained into other subdirectories as needed.
$ !
$ RENAME LIB$:OTSLNK.REQ 	SRC$:
$ RENAME LIB$:OTSMAC.REQ 	SRC$:
$ RENAME LIB$:OTSCCBREQ.REQ 	SRC$:
$ RENAME LIB$:RTLPSECT.REQ 	SRC$:
$ RENAME LIB$:STRLNK.REQ 	SRC$:
$ !
$ ! create macro source libraries.  insert modules as appropriate.
$ !
$ LIBRARY/CREATE/MACRO LIB$:BASRTL.MLB
$ LIBRARY/MACRO LIB$:BASRTL LIB$:BASMSG.MAR
$ LIBRARY/MACRO LIB$:BASRTL LIB$:BASPAR.MAR
$ LIBRARY/MACRO LIB$:BASRTL SRC$:MATRIX.MAR
$ !
$ ! create object libraries.  these will be filled in during the ASSEM phase.
$ !
$ LIBRARY/CREATE/OBJECT LIB$:BASRTL
$ LIBRARY/CREATE/OBJECT LIB$:BASVECTRS
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
$ ! compile all modules as specified in BASRTLASM.DAT.  Objects will be placed
$ ! in libraries according to BASRTLASM.DAT specifications as well.
$ !
$ @SYSBLDCOM$:FASM BASRTL "" Y 'UPDATES N Y
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
$ ! save BASMSGGEN OBJ's off to the side - they will be used later
$ !
$ IF F$SEARCH("OBJ$:BASMSGGEN.OBJ") .NES. "" -
  THEN RENAME OBJ$:BASMSGGEN.OBJ .OBB
$ IF F$SEARCH("OBJ$:BASERRTXT.OBJ") .NES. "" -
  THEN RENAME OBJ$:BASERRTXT.OBJ .OBB
$ !
$ ! delete unnecessary OBJ files - anything to be used in creating the shareable
$ ! image was placed in the object library BASRTL.OLB during the ASSEM phase, so
$ ! any remaining OBJ's can be deleted.
$ !
$ DELETE OBJ$:*.OBJ;*
$ !
$ ! extract message pointer object files from message object library and insert
$ ! them into facility object library.
$ !
$ ! NOT DONE FOR THIS FACILITY
$ !
$ ! extract individual vector object files from vector object library, to be
$ ! used in next phase to link the shareable image(s).
$ !
$ LIBRARY/EXTRACT=BAS$VECTOR/OUT=OBJ$:BASVECTOR.OBJ LIB$:BASVECTRS
$ LIBRARY/EXTRACT=BAS$VECTR2/OUT=OBJ$:BASVECTR2.OBJ LIB$:BASVECTRS
$ !
$ ! share the object library for this facility with other facilities that may
$ ! need it.
$ !
$ CPYRESOBJ LIB$:BASRTL.OLB
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
$ DELETE EXE$:BASRTL.EXE;*,MAP$:BASRTL.MAP;*
$ !
$ ! link the Run-Time Library Shareable Image BASRTL.
$ !
$ LINK/NOSYSLIB/SHARE=EXE$:BASRTL/MAP=MAP$:BASRTL/FULL/CROSS -
  COM$:BASRTLLNK/OPTIONS
$ !
$ ! copy it into it's destination on the result disk, and insert it into the 
$ ! shareable image library there.
$ !
$ CPYSYSLIB EXE$:BASRTL.EXE
$ CPYSYSLIB OBJ$:BASVECTOR.OBJ
$ INSHARLIB EXE$:BASRTL
$ !
$ ! delete the files we are about to create (from previous builds).
$ !
$ DELETE EXE$:BASRTL2.EXE;*,MAP$:BASRTL2.MAP;*
$ !
$ ! link the Run-Time Library Shareable Image BASRTL2.
$ !
$ LINK/NOSYSLIB/SHARE=EXE$:BASRTL2/MAP=MAP$:BASRTL2/FULL/CROSS -
  COM$:BASRTLNK2/OPTIONS
$ !
$ ! copy it into it's destination on the result disk, and insert it into the 
$ ! shareable image library there.
$ !
$ CPYSYSLIB EXE$:BASRTL2.EXE
$ CPYSYSLIB OBJ$:BASVECTR2.OBJ
$ INSHARLIB EXE$:BASRTL2
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
$ ! Build BASMSGGEN.EXE; this image will be used in the RESULT phase.
$ ! 
$ LINK/MAP=NL:/EXE=EXE$:BASMSGGEN OBJ$:BASMSGGEN.OBB,BASERRTXT.OBB
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
$ ! run BASMSGGEN and compare its output with SRC$:MASMSG.MSG.  This ensures
$ ! that BASMSG.MSG and BASERRMSG.REQ are consistent on the master pack.
$ !
$ RUN EXE$:BASMSGGEN
$ SET NOON
$ DIFFERENCES/IGNORE=(COMMENT,BLANK_LINES)/COMMENT=EXCLAMATION SRC$:BASMSG.MSG .TMP
$ IF $SEVERITY .NE. 1 -
  THEN WRITE SYS$OUTPUT "%BUILD-E-BASMSGERR, discrepancy exists between BASMSG.MSG and BASERRMSG.REQ"
$ DELETE SRC$:BASMSG.TMP;*
$ SET ON
$ !
$ ! invoke system build vector test procedure to be sure the vectored entry
$ ! points in the shareable image(s) are correct.
$ !
$ @SYSBLDCOM$:VECTORTST EXE$:BASRTL
$ @SYSBLDCOM$:VECTORTST EXE$:BASRTL2
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
$ ! end of file BASRTLBLD.COM
$ !--
