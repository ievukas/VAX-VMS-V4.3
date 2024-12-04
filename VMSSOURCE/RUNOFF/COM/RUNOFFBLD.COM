$ !
$ !	[ R U N O F F . C O M ] R U N O F F B L D . C O M
$ !
$ !	Assume default directory is [RUNOFF] and logical names
$ !	BUG$, COM$, ENH$, EXE$, LIB$, LIS$, MAP$, OBJ$, and SRC$
$ !	are defined.
$ !
$ ON ERROR THEN GOTO FINISH
$ @COM$:ASSIGNREQ			  ! Define REQUIRE logical names
$ GOTO 'PHASE'

$INIT:
$ !
$ !	Create the Directories
$ !
$ @SYSBLDCOM$:CREATEDIR
$ GOTO FINISH

$UPDATE:
$ !
$ !	Create updated sources.
$ !
$ @COM$:DSRUPD
$ GOTO FINISH

$SRCLIB:
$ !
$ !	Delete and re-create the Bliss libraries
$ !
$ BLISS/LIBRARY=SRC$:rnodefdsr /LIST=LIS$:  SRC$:rnodef.REQ
$ BLISS/LIBRARY=SRC$:/LIST=LIS$:  SRC$:DSRLIB.REQ
$ DELETE OBJ$:*.OBJ;*,*.OBI;*,*.OBT;*
$ DELETE LIB$:*.OLB;*
$ PURGE SRC$:, OBJ$:, LIS$:
$ DELETE FASMCHECK.CHK;*
$ GOTO FINISH

$ASSEM:
!
!	Do BLISS compiles of RUNOFF modules
!
$ @SYSBLDCOM$:FASM RUNOFF "" N 'UPDATES' N Y
$ PURGE OBJ$:,LIS$:
$ GOTO FINISH

$OBJLIB:
$ !
$ !	Create object library from object modules.
$ !
$ !	Call to OBJLIB:
$ !	    @SYSBLDCOM$:OBJLIB <Facility name> <blocks> <globals> <modules>
$ !				    <NO for /noglobals on LIBRARY verb>
$ !
$ !	Values coded below are based on Version 2.6-01 of RUNOFF.
$ !
$ @com$:dsrutlsr SAVE			   ! Save modules specific to utilities
$ @SYSBLDCOM$:OBJLIB RUNOFF   400 400 115  ! Generate RUNOFF.OLB
$ @com$:dsrutlsr RESTORE DSRINDEX	   ! Restore DSRINDEX specific modules
$ @SYSBLDCOM$:OBJLIB DSRINDEX 140 200  16  ! Generate DSRINDEX.OLB
$ @com$:dsrutlsr RESTORE DSRTOC		   ! Restore DSRTOC specific modules
$ @SYSBLDCOM$:OBJLIB DSRTOC   110 120   7  ! Generate DSRTOC.OLB
$ GOTO FINISH

$LNKLIB:
$ !
$ ! Null LNKLIB phase
$ !
$ GOTO FINISH

$LINK:
$ !
$ !	Delete linker map and image then re-create EXE$:RUNOFF.EXE
$ !			and MAP$:RUNOFF.MAP
$ !
$ DELETE EXE$:DSRTOC.EXE;*, MAP$:DSRTOC.MAP;*	! Dump old maps and images
$ DELETE EXE$:DSRINDEX.EXE;*, MAP$:DSRINDEX.MAP;*
$ @COM$:RUNOFFLNK				! generate new map and image
$ @COM$:DSRUTLLNK				! generate TOC and TCX
$ GOTO FINISH
$
$RESULT:
$ !
$ !	Copy the EXE and MAP to a System area
$ !
$ CPYRESEXE EXE$:RUNOFF.EXE,EXE$:DSRTOC.EXE,EXE$:DSRINDEX.EXE
$ CPYRESMAP MAP$:RUNOFF.MAP	RUNOFF.MAP
$ CPYRESMAP MAP$:DSRTOC.MAP	DSRTOC.MAP
$ CPYRESMAP MAP$:DSRINDEX.MAP	DSRINDEX.MAP
$ !
$ !	Build the concatenated listing RUNOFF.LSS
$ !
$ CPYRESLIS SRC$:*.REQ,*.MSG,LIS$:*.LIS RUNOFF.LSS
$
$FINISH:
$ IF (.NOT. $STATUS) .AND. ($SEVERITY .NE. 0) THEN -
  WRITE SYS$OUTPUT "%BLD-F-FAIL, ********* RUNOFF BUILD FAILED **********"
$ @COM$:DEASREQ				  ! Dispose of special logical names
