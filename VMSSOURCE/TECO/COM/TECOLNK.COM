$ !
$ !	[ T E C O . C O M ] T E C O L N K . C O M
$ !
$ !	Link procedure for TECO
$ !
$ DELETE EXE$:*.EXE;*, MAP$:*.MAP;*
$ DEBUG := NOTRACE
$ IF P1 .NES. "" THEN DEBUG := DEBUG
$ LINK	/EXE=EXE$:TECO/'DEBUG' -
	/MAP=MAP$:TECO/FULL/CROSS -
	SYS$INPUT:/OPTION
!
! Include the compatibility mode code in a special cluster based at 0
!
CLUSTER=COMPATIBILITY,0,,-
	LIB$:TECO/INCLUDE=(TECO,TECOIO,SCREEN,SCRINS,SCROLL,CRTRUB)
!
! Include the native mode code, help library code, and command decoder macro
!
LIB$:TECO/INCLUDE=(TECONAT,TECOLBR,TECOCMD)
