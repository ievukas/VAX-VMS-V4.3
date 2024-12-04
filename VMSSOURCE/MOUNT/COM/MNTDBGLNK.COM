$!
$! [MOUNT.COM]MNTDBGLNK.COM
$!
$! 	This command procedure will produce a debug version of the MOUNTSHR
$!	sharable image.  Through judicious use of LINKER options, the ISECTs
$!	of the debug version correspond to the ISECTs of the standard MOUNTSHR
$!	image.  This means that for all practical purposes, the normal map
$!	and the map produced by this command procedure are identical.  To use
$!	the image produced by this procedure, enter the following DCL commands:
$!
$!		$ define mountshr exe$:mountdbg.exe
$!		$ mcr install
$!		INSTALL> exe$:mountdbg.exe /share/prot/open/header/write
$!		INSTALL> /exit
$!
$!	This technique will allow you to redirect the MOUNTSHR image activation
$!	to your DEBUG version without having to remove the existing mount image,
$!	and without having to copy your image to SYS$SHARE.  The image produced
$!	will have writeable, copy-on-reference code, which means that you may
$!	set breakpoints with the appropriate debugger.  Note that the necessity
$!	of linking /SHARE excludes /DEBUG and /TRACE.
$!
$ LINK/NOTRACE/NOSYSSHR/PROT/SHARE=EXE$:MOUNTDBG/MAP:MAP$:MOUNTDBG/FULL/CROSS -
	SYS$INPUT:/OPTIONS
	RESOBJ$:MTAACP/INCLUDE:(COMLABPROC)-
	,RESOBJ$:F11AACP/INCLUDE:(CHKSUM,CHKHDR,INIFCB,CVT_ATB,SNDERL)-
	,RESOBJ$:F11BXQP/INCLUDE:(CHKHD2,GETPTR,GETRVN)-
	,RESOBJ$:DISMOUNT/INCLUDE:(DISMOU,LOCKDB)-
	,LIB$:VMOUNT/INCLUDE:(CHNUCB,GETUIC,LEFTONE,REBUILD,ALLOCM,VMOUNT-
			     ,RDHOME,STACP,MOUDK1,MOUDK2,MOUTAP,MRDBLK,INIFC2-
			     ,SRCVOL,TRNLOG,MWTUR1,MWTUR2,MAKLOG,BINDVL-
			     ,CHKSM2,CHKHM1,CHKHM2,MAKRVT,ERASE,CLUSTRMNT-
			     ,ASSIST,MOUPAR,RUJMAN)/LIBRARY-
	,EXSM:SYS.STB/SELECTIVE
CLUSTER=TRANSFER_VECTOR,,,LIB$:VMOUNT/INCLUDE:(MOUNTDSP)
PSECT=$MSG_INDEX,SHR
PSECT=$MSG_TEXT,SHR
PSECT=$PLIT$,SHR
COLLECT=$$ADDRESS_DATA,$MSG_INDEX,$MSG_TEXT,$PLIT$
PSECT=$CODE$,NOSHR,WRT
PSECT=$LOCKEDC1$,NOSHR,WRT
PSECT=_LIB$CODE,NOPIC,NOSHR,WRT
PSECT=_LIB$KEY0$,NOPIC,NOSHR,WRT
PSECT=_LIB$KEY1$,NOPIC,NOSHR,WRT
PSECT=_LIB$STATE$,NOPIC,NOSHR,WRT
COLLECT=$$CODE,$CODE$,$LOCKEDC1$,_LIB$CODE,_LIB$KEY0$,_LIB$KEY1$,_LIB$STATE$
PSECT=_LIB$DATA,NOPIC
COLLECT=$$DATA,$GLOBAL$,$OWN$,$USER_DATA$,_LIB$DATA,LIB$ANALYZE_SDESC
GSMATCH=LEQUAL,1,1
