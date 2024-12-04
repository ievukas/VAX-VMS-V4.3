$ !++
$ !
$ ! LIBRTLBLD.COM  -	build the component LIBRTL.
$ !			assumes definitions for: LIB$, LIS$, SRC$, EXE$, MAP$,
$ !						 OBJ$ and SYSBLDCOM$.
$ !			assumes existence of:	 SYSBLDCOM$:CREATEDIR.COM
$ !						 SYSBLDCOM$:FASM.COM
$ !						 SYSBLDCOM$:VECTORTST.COM
$ !
$ ! 1-001 - adapted from RTLBLD.  MDL 25-Jul-1983
$ ! 1-002 - bugfixes.  MDL 3-Aug-1983
$ ! 1-003 - share files needed by BASRTL, FORRTL.  MDL 4-Aug-1983
$ ! 1-004 - CPYRESOBJ the .OLB produced by this facility.  MDL 11-Aug-1983
$ ! 1-005 - share RTLLIB.L32 with FORRTL.  MDL 16-Aug-1983
$ ! 1-006 - share STRMACROS.REQ with COBRTL.  MDL 18-Aug-1983
$ ! 1-007 - delete checkpoint file from old builds.  MDL 24-Aug-1983
$ ! 1-008 - build RTLLIB.L32 in the SRCLIB phase.  MDL 13-Sep-1983
$ ! 1-009 - DELSHRLIB & CPYSHRLIB RTLLIB in the SRCLIB phase also.  Fix
$ !	    file-specs for DEL/CPYSHRLIBs.  MDL 16-Sep-1983
$ ! 1-010 - fix one more DELSHRLIB.  MDL 16-Sep-1983
$ ! 1-011 - add a CPYSYSLIB of SIGDEF.FOR.  MDL 22-Sep-1983
$ ! 1-012 - add a SRCUPDATE of SIGDEF.FOR.  CW Hobbs 24-Sep-1983
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
$ DELSHRLIB LIB$:LIBMSG.MAR
$ DELSHRLIB SRC$:OTSCCBREQ.REQ
$ DELSHRLIB LIB$:OTSISB.MAR
$ DELSHRLIB LIB$:OTSISB.R32
$ DELSHRLIB LIB$:OTSISB.BLF
$ DELSHRLIB SRC$:OTSLNK.REQ
$ DELSHRLIB LIB$:OTSLUB.MAR
$ DELSHRLIB LIB$:OTSLUB.R32
$ DELSHRLIB LIB$:OTSLUB.BLF
$ DELSHRLIB SRC$:OTSMAC.REQ
$ DELSHRLIB LIB$:OTSMSG.MAR
$ DELSHRLIB LIB$:OTSMSG.R32
$ DELSHRLIB LIB$:STRMSG.MAR
$ DELSHRLIB SRC$:STRMACROS.REQ
$ DELSHRLIB LIB$:LIBCLIDEF.MAR
$ DELSHRLIB LIB$:LIBCLIDEF.REQ
$ DELSHRLIB LIB$:LIBDCFDEF.MAR
$ DELSHRLIB LIB$:LIBDCFDEF.REQ
$ DELSHRLIB LIB$:LIBFMTDEF.MAR
$ DELSHRLIB LIB$:LIBFMTDEF.REQ
$ DELSHRLIB SRC$:RTLMACMAR.MAR
$ DELSHRLIB SRC$:RTLMACB32.REQ
$ DELSHRLIB SRC$:RTLODBG.REQ
$ DELSHRLIB SRC$:RTLPSECT.REQ
$ IF F$SEARCH("LIS$:LIBCLICAL.LIS") .NES. "" THEN -
  SET FILE LIS$:LIBCLICAL.LIS;* /REMOVE
$ IF F$SEARCH("LIS$:LIBCVTATB.LIS") .NES. "" THEN -
  SET FILE LIS$:LIBCVTATB.LIS;* /REMOVE
$ IF F$SEARCH("LIS$:LIBSCRPKG.LIS") .NES. "" THEN -
  SET FILE LIS$:LIBSCRPKG.LIS;* /REMOVE
$ IF F$SEARCH("LIS$:LIBTPARSE.LIS") .NES. "" THEN -
  SET FILE LIS$:LIBTPARSE.LIS;* /REMOVE
$ DELETE OBJ$:*.*;*,LIS$:*.*;*,LIB$:*.*;*
$ !
$ ! create new updated require files.
$ !
$ SRCUPDATE LIBCLIDEF.SDL
$ SRCUPDATE LIBDCFDEF.SDL
$ SRCUPDATE LIBDEF.FOR
$ SRCUPDATE LIBFMTDEF.SDL
$ SRCUPDATE LIBLNK.REQ
$ SRCUPDATE LIBMACROS.REQ
$ SRCUPDATE LIBMSG.MSG
$ SRCUPDATE LIBPROLOG.REQ
$ SRCUPDATE LIBTABMAC.MAR
$ SRCUPDATE OTSCCBREQ.REQ
$ SRCUPDATE OTSISB.SDL
$ SRCUPDATE OTSLNK.REQ
$ SRCUPDATE OTSLUB.SDL
$ SRCUPDATE OTSMAC.REQ
$ SRCUPDATE OTSMSG.MSG
$ SRCUPDATE RTLLIB.REQ
$ SRCUPDATE RTLMACB32.REQ
$ SRCUPDATE RTLMACMAR.MAR
$ SRCUPDATE RTLODBG.REQ
$ SRCUPDATE RTLPSECT.REQ
$ SRCUPDATE SIGDEF.FOR
$ SRCUPDATE STRLNK.REQ
$ SRCUPDATE STRMACROS.REQ
$ SRCUPDATE STRMSG.MSG
$ !
$ ! create SDL source files from MESSAGE source files.
$ !
$ MESSAGE/SDL=LIB$:/NOOBJECT/NOLIST SRC$:LIBMSG
$ MESSAGE/SDL=LIB$:/NOOBJECT/NOLIST SRC$:OTSMSG
$ MESSAGE/SDL=LIB$:/NOOBJECT/NOLIST SRC$:STRMSG
$ !
$ ! run SDL conversions for VMSLIB component to use in SRCLIB (next) phase.
$ !
$ SDL/NOLIST/LANG=(BLISS=LIB$:.REQ,MACRO=LIB$:) SRC$:LIBCLIDEF
$ SDL/NOLIST/LANG=(MACRO=LIB$:) 	    SRC$:LIBDCFDEF
$ SDL/VMS/NOLIST/LANG=(BLISS=LIB$:.REQ)     SRC$:LIBDCFDEF
$ SDL/NOLIST/LANG=(MACRO=LIB$:) 	    SRC$:LIBFMTDEF
$ SDL/VMS/NOLIST/LANG=(BLISS=LIB$:.REQ)     SRC$:LIBFMTDEF
$ SDL/NOLIST/LANG=(MACRO=LIB$:,BLISSF=LIB$:.BLF)     SRC$:OTSISB
$ SDL/VMS/NOLIST/LANG=(BLISS=LIB$:) 	    SRC$:OTSISB
$ SDL/NOLIST/LANG=(MACRO=LIB$:,BLISSF=LIB$:.BLF)    SRC$:OTSLUB
$ SDL/VMS/NOLIST/LANG=(BLISS=LIB$:) 	    SRC$:OTSLUB
$ SDL/VMS/NOLIST/LANG=(BLISS=LIB$:,MACRO=LIB$:,FORTRAN=LIB$:) LIB$:LIBMSG
$ SDL/VMS/NOLIST/LANG=(BLISS=LIB$:,MACRO=LIB$:) LIB$:OTSMSG
$ SDL/VMS/NOLIST/LANG=(BLISS=LIB$:,MACRO=LIB$:) LIB$:STRMSG
$ !
$ ! share message source files w/other component(s) that use them.
$ !
$ PUTSYSMSG SRC$:LIBMSG.MSG		! share file with SYSMSG component
$ PUTSYSMSG SRC$:OTSMSG.MSG		! share file with SYSMSG component
$ PUTSYSMSG SRC$:STRMSG.MSG		! share file with SYSMSG component
$ !
$ ! share require files w/other component(s) that use them.
$ !
$ CPYSHRLIB LIB$:LIBMSG.MAR		! Share file with VMSLIB component
$ CPYSHRLIB SRC$:OTSCCBREQ.REQ		! Share file with BASRTL, FORRTL components
$ CPYSHRLIB LIB$:OTSISB.R32		! Share file with BASRTL, FORRTL components
$ CPYSHRLIB LIB$:OTSISB.BLF		! Share file with FORRTL component
$ CPYSHRLIB LIB$:OTSISB.MAR		! Share file with FORRTL component
$ CPYSHRLIB SRC$:OTSLNK.REQ		! Share file with BASRTL, FORRTL components
$ CPYSHRLIB LIB$:OTSLUB.R32		! Share file with BASRTL, FORRTL components
$ CPYSHRLIB LIB$:OTSLUB.BLF		! Share file with FORRTL component
$ CPYSHRLIB LIB$:OTSLUB.MAR		! Share file with FORRTL component
$ CPYSHRLIB SRC$:OTSMAC.REQ		! Share file with BASRTL, FORRTL components
$ CPYSHRLIB LIB$:OTSMSG.MAR		! Share file with VMSLIB component
$ CPYSHRLIB LIB$:OTSMSG.R32		! Share file with VMSLIB component
$ CPYSHRLIB LIB$:STRMSG.MAR		! Share file with VMSLIB component
$ CPYSHRLIB LIB$:LIBCLIDEF.MAR		! Share file with VMSLIB component
$ CPYSHRLIB LIB$:LIBCLIDEF.REQ		! Share file with VMSLIB component
$ CPYSHRLIB LIB$:LIBDCFDEF.MAR		! Share file with VMSLIB component
$ CPYSHRLIB LIB$:LIBDCFDEF.REQ		! Share file with VMSLIB component
$ CPYSHRLIB LIB$:LIBFMTDEF.MAR		! Share file with VMSLIB component
$ CPYSHRLIB LIB$:LIBFMTDEF.REQ		! Share file with VMSLIB component
$ CPYSHRLIB SRC$:RTLMACMAR.MAR		! Share file with VMSLIB component
$ CPYSHRLIB SRC$:RTLMACB32.REQ		! Share file with VMSLIB component
$ CPYSHRLIB SRC$:RTLODBG.REQ		! Share file with FORRTL component
$ CPYSHRLIB SRC$:RTLPSECT.REQ		! Share file with BASRTL, FORRTL components
$ CPYSHRLIB SRC$:STRLNK.REQ		! Share file with VMSLIB component
$ CPYSHRLIB SRC$:STRMACROS.REQ		! Share file with COBRTL component
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
$ CPYSYSLIB SRC$:LIBDEF.FOR
$ CPYSYSLIB SRC$:SIGDEF.FOR
$ !
$ ! delete the files we are about to create (from previous builds).
$ !
$ DELETE LIB$:LIBRTL.MLB;*
$ DELETE LIB$:LIBRTL.OLB;*,LIBMSGPTR.OLB;*,LIBVECTRS.OLB;*
$ !
$ ! get library/require files from other components as needed.
$ !
$ ! NONE
$ !
$ ! create macro source libraries.  insert modules as appropriate.
$ !
$ LIBRARY/CREATE/MACRO LIB$:LIBRTL.MLB
$ LIBRARY/MACRO LIB$:LIBRTL LIB$:OTSISB.MAR
$ LIBRARY/MACRO LIB$:LIBRTL LIB$:OTSLUB.MAR
$ LIBRARY/MACRO LIB$:LIBRTL LIB$:OTSMSG.MAR
$ LIBRARY/MACRO LIB$:LIBRTL LIB$:STRMSG.MAR
$ LIBRARY/MACRO LIB$:LIBRTL LIB$:LIBMSG.MAR
$ LIBRARY/MACRO LIB$:LIBRTL LIB$:LIBFMTDEF.MAR
$ LIBRARY/MACRO LIB$:LIBRTL SRC$:LIBTABMAC.MAR
$ !
$ ! create object libraries.  these will be filled in during the ASSEM phase.
$ !
$ LIBRARY/CREATE/OBJECT LIB$:LIBRTL
$ LIBRARY/CREATE/OBJECT LIB$:LIBMSGPTR
$ LIBRARY/CREATE/OBJECT LIB$:LIBVECTRS
$ !
$ ! create the Bliss source library RTLLIB.  For this to work in the system
$ ! build, this is done after all other facilities have completed in the 
$ ! SRCLIB phase (coordinated by running this facility in SRCLIB_1).  This
$ ! has no impact for FACTSTBLDs.
$ !
$ DELSHRLIB LIB$:RTLLIB.L32
$ !
$ DELETE LIS$:RTLLIB.L32;*,LIS$:RTLLIB.LIS;*
$ BLISS/LIBRARY=LIB$:/LIST=LIS$:/SOURCE=REQUIRE SRC$:RTLLIB
$ !
$ ! share bliss libraries with other facilities
$ !
$ CPYSHRLIB LIB$:RTLLIB.L32		! Share file with FORRTL component
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
$ ! RTLLIB.L32 WAS CREATED IN THE PREVIOUS (SRCLIB) PHASE.  THIS IS A SPECIAL
$ ! CASE SO THAT ALL OF THE VARIOUS RTL FACILITIES CAN RUN CONCURRENTLY IN
$ ! THE ASSEM PHASE.  THIS IS DONE BY A SPECIAL PHASE CALLED SRCLIB_1 WHEN
$ ! RUNNING THE SYSTEM BUILD.  THERE IS NO IMPACT FOR A FACTSTBLD.
$ !
$ ! delete the files we are about to create (from previous builds); cannot use
$ ! wildcard delete because library listings and object libraries were just 
$ ! created.  So just PURGE.
$ !
$ PURGE LIS$:
$ PURGE OBJ$:
$ !
$ ! get files from other facilities that we need
$ !
$ REMSHRLIB CLIMSG.B32
$ GETSHRLIB CLIMSG.B32
$ !
$ ! invoke system build assembly procedure to perform assemblies.  This will 
$ ! compile all modules as specified in LIBRTLASM.DAT.  Objects will be placed
$ ! in libraries according to LIBRTLASM.DAT specifications as well.
$ !
$ @SYSBLDCOM$:FASM LIBRTL "" Y 'UPDATES N Y
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
$ ! image was placed in the object library LIBRTL.OLB during the ASSEM phase, so
$ ! any remaining OBJ's can be deleted.
$ !
$ DELETE OBJ$:*.OBJ;*
$ !
$ ! extract message pointer object files from message object library and insert
$ ! them into facility object library.
$ !
$ LIBRARY/EXTRACT=*/OUT=OBJ$:LIBMSGPTR.OBJ LIB$:LIBMSGPTR
$ LIBRARY LIB$:LIBRTL OBJ$:LIBMSGPTR.OBJ
$ DELETE OBJ$:LIBMSGPTR.OBJ;
$ !
$ ! extract individual vector object files from vector object library, to be
$ ! used in next phase to link the shareable image(s).
$ !
$ LIBRARY/EXTRACT=LIB$VECTOR/OUT=OBJ$:LIBVECTOR.OBJ LIB$:LIBVECTRS
$ LIBRARY/EXTRACT=LIB$VECTR2/OUT=OBJ$:LIBVECTR2.OBJ LIB$:LIBVECTRS
$ !
$ ! share the object library for this facility with other facilities that may
$ ! need it.
$ !
$ CPYRESOBJ LIB$:LIBRTL.OLB
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
$ !
$ ! Extract modules from STARLET.OLB that aren't built by RTL and insert
$ ! them into LIBRTL.OLB.
$ !
$ LIBRARIAN/EXTRACT=(LIB$CLI_CALLBACK,LIB$CVT_ATB,LIB$TPARSE)/OUTPUT=LIB$:TMP -
  SYS$LIBRARY:STARLET
$ LIBRARIAN LIB$:LIBRTL LIB$:TMP
$ DELETE LIB$:TMP.OBJ;*
$ !
$ ! delete the files we are about to create (from previous builds).
$ !
$ DELETE EXE$:LIBRTL.EXE;*,MAP$:LIBRTL.MAP;*
$ !
$ ! link the Run-Time Library Shareable Image LIBRTL.
$ !
$ LINK/NOSYSLIB/SHARE=EXE$:LIBRTL/MAP=MAP$:LIBRTL/FULL/CROSS -
  COM$:LIBRTLLNK/OPTIONS
$ !
$ ! copy it into it's destination on the result disk, and insert it into the 
$ ! shareable image library there.
$ !
$ CPYSYSLIB EXE$:LIBRTL.EXE
$ CPYSYSLIB OBJ$:LIBVECTOR.OBJ
$ INSHARLIB EXE$:LIBRTL
$ !
$ ! delete the files we are about to create (from previous builds).
$ !
$ DELETE EXE$:LIBRTL2.EXE;*,MAP$:LIBRTL2.MAP;*
$ !
$ ! link the Run-Time Library Shareable Image LIBRTL2.
$ !
$ LINK/NOSYSLIB/SHARE=EXE$:LIBRTL2/MAP=MAP$:LIBRTL2/FULL/CROSS -
  COM$:LIBRTLNK2/OPTIONS
$ !
$ ! copy it into it's destination on the result disk, and insert it into the 
$ ! shareable image library there.
$ !
$ CPYSYSLIB EXE$:LIBRTL2.EXE
$ CPYSYSLIB OBJ$:LIBVECTR2.OBJ
$ INSHARLIB EXE$:LIBRTL2
$ !
$ GOTO EXIT
$ !+
$ ! end of LNKLIB phase
$ !-
$LINK:
$ !+
$ ! LINK phase 
$ !-
$ GOTO EXIT
$ !+
$ ! end of LINK phase
$ !
$RESULT:
$ !+
$ ! RESULT phase
$ !-
$ !
$ !
$ !	Enter synonyms in our LIS$ for modules built by VMSLIB so
$ !	that they can be found easier.  
$ !
$ IF F$SEARCH("LIS$:LIBCLICAL.LIS") .NES. "" THEN -
  SET FILE LIS$:LIBCLICAL.LIS;* /REMOVE
$ IF F$SEARCH("LIS$:LIBCVTATB.LIS") .NES. "" THEN -
  SET FILE LIS$:LIBCVTATB.LIS;* /REMOVE
$ IF F$SEARCH("LIS$:LIBSCRPKG.LIS") .NES. "" THEN -
  SET FILE LIS$:LIBSCRPKG.LIS;* /REMOVE
$ IF F$SEARCH("LIS$:LIBTPARSE.LIS") .NES. "" THEN -
  SET FILE LIS$:LIBTPARSE.LIS;* /REMOVE
$ IF F$SEARCH("LISD$:[VMSLIB.LIS]LIBCLICAL.LIS") .NES. "" THEN -
  SET FILE /ENTER=LIS$:LIBCLICAL.LIS LISD$:[VMSLIB.LIS]LIBCLICAL.LIS
$ IF F$SEARCH("LISD$:[VMSLIB.LIS]CVTATB.LIS") .NES. "" THEN -
  SET FILE /ENTER=LIS$:LIBCVTATB.LIS LISD$:[VMSLIB.LIS]CVTATB.LIS
$ IF F$SEARCH("LISD$:[VMSLIB.LIS]SCRPKG.LIS") .NES. "" THEN -
  SET FILE /ENTER=LIS$:LIBSCRPKG.LIS LISD$:[VMSLIB.LIS]SCRPKG.LIS
$ IF F$SEARCH("LISD$:[VMSLIB.LIS]TPARSE.LIS") .NES. "" THEN -
  SET FILE /ENTER=LIS$:LIBTPARSE.LIS LISD$:[VMSLIB.LIS]TPARSE.LIS
$ !
$ ! invoke system build vector test procedure to be sure the vectored entry
$ ! points in the shareable image(s) are correct.
$ !
$ @SYSBLDCOM$:VECTORTST EXE$:LIBRTL
$ @SYSBLDCOM$:VECTORTST EXE$:LIBRTL2
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
$ ! end of file LIBRTLBLD.COM
$ !--
