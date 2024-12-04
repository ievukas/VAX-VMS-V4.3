$ !
$ ! [ P R T S M B . C O M ] S M B S H R L N K . C O M
$ !
$ !	Link the shareable image of symbiont services facility
$ !
$ DELETE EXE$:SMBSRVSHR.EXE;*, MAP$:SMBSRVSHR.MAP;*
$ LINK	/SHARE=EXE$:SMBSRVSHR -
	/MAP=MAP$:SMBSRVSHR /FULL /CROSS -
	-
	LIB$:PRTSMB /INCLUDE=TRANSFER /LIB , -
	EXSM:SYS.STB /SELECTIVE , -
	SYS$INPUT:/OPTIONS

!
! Set Global Section match control
!

GSMATCH = LEQUAL,1,0


!
! Define some messages as Universal Symbols for user
! written symbionts
!

UNIVERSAL = -

	PSM$_FLUSH		, -	! Service requests output flush
	PSM$_FUNNOTSUP		, -	! Function not supported
	PSM$_PENDING		, -	! Function pending
	PSM$_SUSPEND		, -	! Function suspended
	PSM$_EOF		, -	! End of input detected
	SMB$_NOMOREITEMS		! No more items in message

