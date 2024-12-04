$ !
$ ! [ D C X . C O M ] D C X S H R L N K . C O M
$ !
$ !	Link the shareable image of data compress / expansion procedures
$ !
$ DELETE EXE$:DCXSHR.EXE;*, EXE$:DCXSHR.STB;*, MAP$:DCXSHR.MAP;*
$ LINK /SHARE=EXE$:DCXSHR /MAP=MAP$:DCXSHR /FULL/CROSS -
	/SYMBOL=EXE$:DCXSHR SYS$INPUT:/OPTIONS
!
! Options for DCXSHRLNK.COM
!
LIB$:DCX/INCLUDE=(-
DCX_TRANSFER,-			!Transfer vector
DCX_ANALYZE,-			!Data Analysis
DCX_COMPRESS,-			!Data Compression
DCX_EXPAND,-			!Data expansion
DCX_SUBS,-			!Miscellaneous routines
DCXMSG)				!Message codes
!
! Set Global Section match control
!
GSMATCH=LEQUAL,1,1
!
!
!
PSECT=$$VECTOR_0_DCX,NOPIC,SHR
PSECT=$CODE$,SHR
!
! Define universal symbols
!
UNIVERSAL= -
DCX$ANALYZE_INIT,-	!Initialization for data analysis
DCX$ANALYZE_DATA,-	!Analyze data record
DCX$MAKE_MAP,-		!Compute compression / expansion map
DCX$ANALYZE_DONE,-	!Release analysis context
DCX$COMPRESS_INIT,-	!Initialization for data compression
DCX$COMPRESS_DATA,-	!Compress data record
DCX$COMPRESS_DONE,-	!Release compression context
DCX$EXPAND_INIT,-	!Initialization for data expansion
DCX$EXPAND_DATA,-	!Expand data record
DCX$EXPAND_DONE,-	!Release expansion context
!
!	DCX messages
! Success
	DCX$_NORMAL,-
! Informational codes
	DCX$_AGAIN,-
! Warning codes
	DCX$_TRUNC,-
! Error codes
	DCX$_INVARG,-
	DCX$_INVDATA,-
	DCX$_INVMAP,-
	DCX$_INVCTX,-
!
!	Item codes
	DCX$C_BOUNDED,-
	DCX$C_ONE_PASS,-
	DCX$C_EST_RECORDS,-
	DCX$C_EST_BYTES,-
	DCX$C_LIST
