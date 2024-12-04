$ !
$ !
$ !	This command file builds the Record Management Services (RMS32)
$ !	facility.
$ !
$ !	Assume default directory is [RMS] and logical names
$ !	BUG$, COM$, ENH$, EXE$, EXECML$, EXSM, LIB$, LIS$, MAP$, OBJ$, 
$ !	RESD$, RESOBJ$, SRC$, SRCD$, and SYSBLDCOM$ are defined.
$ !
$ GOTO 'PHASE'
$
$INIT:
$ !
$ !	Create the directories.
$ !
$ @SYSBLDCOM$:CREATEDIR
$ EXIT
$
$UPDATE:
$ !
$ !	Update the master source files.
$ !
$ DELSHRLIB SRC$:RMSCALLS.MAR
$ DELSHRLIB SRC$:RMS32MAC.MAR
$ DELSHRLIB SRC$:RMSMAC.REQ
$ @COM$:RMSUPD
$ CPYSHRLIB SRC$:RMSMAC.REQ		! Share file with VMSLIB component
$ CPYSHRLIB SRC$:RMSCALLS.MAR		! Share file with VMSLIB component
$ CPYSHRLIB SRC$:RMS32MAC.MAR		! Share file with VMSLIB component
$ PUTSYSMSG SRC$:RMSFALMSG.MSG		! Share file with MSGFIL component
$ !
$ !	MSGFIL expects to see this with a different name, so
$ !
$ RENAME SRC$:RMSDEF.MSG SRC$:RMSMSG.MSG
$ PUTSYSMSG SRC$:RMSMSG.MSG		! Share file with MSGFIL component
$ RENAME SRC$:RMSMSG.MSG SRC$:RMSDEF.MSG
$ !
$ !	Delete and re-create the macro libraries.  (This must be done in
$ !	the UPDATE phase instead of the SRCLIB phase because it shares
$ !	MDL output with VMSLIB during the SRCLIB phase and there is a
$ !	time synchronization problem.)
$ !
$ DELSHRLIB LIB$:RMSDEF.MAR
$ DELSHRLIB LIB$:RMSFALMSG.MAR
$ DELSHRLIB LIB$:RMSUSR.MAR
$ DELSHRLIB LIB$:RMSDEF.R32
$ DELSHRLIB LIB$:RMSFALMSG.B32
$ DELSHRLIB LIB$:RMSUSR.R32
$ DELSHRLIB LIB$:RMSFILSTR.R32
$ DELSHRLIB LIB$:RMSFILSTR.MAR
$ DELSHRLIB LIB$:RMSFWADEF.MAR
$ DELSHRLIB LIB$:RMSINTSTR.MAR
$ DELSHRLIB LIB$:RMSFWADEF.R32
$ DELSHRLIB LIB$:RMSINTSTR.R32
$ DELSHRLIB LIB$:RMS.MLB		! Share with SYS (BACKUP)
$ DELETE LIB$:*.B32;*,*.MAR;*,*.MLB;*,*.R32;*,-
	RMS.L32;*,RMS.LST;*,RMSINTDEF.L32;*,RMSINTDEF.LST;*
$ @COM$:RMSMLB
$ CPYSHRLIB LIB$:RMSDEF.MAR		! Share file with VMSLIB component
$ CPYSHRLIB LIB$:RMSFALMSG.MAR		! Share file with VMSLIB component
$ CPYSHRLIB LIB$:RMSUSR.MAR		! Share file with VMSLIB component
$ CPYSHRLIB LIB$:RMSDEF.R32		! Share file with VMSLIB component
$ CPYSHRLIB LIB$:RMSFALMSG.B32		! Share file with VMSLIB component
$ CPYSHRLIB LIB$:RMSUSR.R32		! Share file with VMSLIB component
$ CPYSHRLIB LIB$:RMSFILSTR.R32		! Share file with VMSLIB component
$ CPYSHRLIB LIB$:RMSFILSTR.MAR
$ CPYSHRLIB LIB$:RMSFWADEF.MAR
$ CPYSHRLIB LIB$:RMSINTSTR.MAR
$ CPYSHRLIB LIB$:RMSFWADEF.R32
$ CPYSHRLIB LIB$:RMSINTSTR.R32		! Share file with CJF	 component
$ CPYSHRLIB LIB$:RMS.MLB		! Share with SYS (BACKUP)
$ CPYSHRLIB LIB$:RMSINTDEF.L32		! Share with RMSREC component
$ EXIT
$
$SRCLIB:
$ !
$ !	Macro libraries created during UPDATE phase.
$ !
$ EXIT
$
$ASSEM:
$ !
$ !	PURGE and re-create the assembly language object and listing files.
$ !
$ PURGE OBJ$:*.OBJ,LIS$:*.LIS,*.LSS
$ @SYSBLDCOM$:FASM 'FACNAM "" N 'UPDATES
$ RENAME OBJ$:RMSGBL.OBJ OBJ$:RMSGBL.OBB/NEW_VERSION	! FOR VMSBUILD
$ EXIT
$
$OBJLIB:
$ !
$ !	Build object library.
$ !
$ RENAME OBJ$:STAPRFLNM.OBJ;* OBJ$:STAPRFLNM.OBS
$ @SYSBLDCOM$:OBJLIB RMS
$ LIBRARY/NOGLOBALS LIB$:RMS OBJ$:STAPRFLNM.OBS
$ DELETE OBJ$:STAPRFLNM.OBS;*
$ EXIT
$
$LNKLIB:
$ !
$ ! Null LNKLIB phase
$ !
$ EXIT
$
$LINK:
$ !
$ !	Delete and re-create the image and map files.
$ !
$ !	Note: This link assumes that OBJ$:RMSGBL.OBJ produced in the
$ !	assembly phase above has been added to RESOBJ$:STARLET.OLB.
$ !
$ DELETE EXE$:RMS.EXE;*,MAP$:.MAP;*,EXE$:.STB;*
$ @COM$:RMSLNK
$ EXIT
$
$RESULT:
$ !
$ !
$ !	Copy the image and map files to a System area.
$ !
$ CPYRESEXE EXE$:RMS.EXE
$ CPYRESEXE EXE$:RMS.STB
$ CPYRESEXE MAP$:RMS.MAP
$ CPYRESMAP MAP$:RMS.MAP
$ !
$ !	Concatenate the listing files and copy them to the System area.
$ !
$ CPYRESLIS LIS$:*.LIS RMS.LSS
