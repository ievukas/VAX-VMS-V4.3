$ !
$ ! PROCEDURE TO LINK NETACP
$ !
$ QUAL := NOTRACE
$ IF P1 .NES. "" THEN QUAL := DEBUG
$ DELETE EXE$:NETACP.EXE;*, MAP$:NETACP.MAP;*, EXE$:NETACP.STB;*
$ LINK /NOSYSSHR /EXE=EXE$:NETACP /MAP=MAP$:NETACP/FULL/CROSS /'QUAL' -
	/SYMBOLS=EXE$:NETACP -
	LIB$:NETACP/LIB/INCLUDE=NETACPTRN,-
	SHRLIB$:LOGINMSG/SELECTIVE,-
	EXSM:SYS.STB/SELECTIVE,-
	SYS$INPUT/OPTIONS
COLLECT=$LINECNF, -		! This MUST be at location 200 - do not change!
	$$$LINECNF
COLLECT=TABLES, -
	DATABASE_IMPURE, -
	TABLES_IMPURE, -
	TABLES_PURE
COLLECT=HIGH_IPL, -
	NET_LOCK_A, -
	NET_LOCK_IMPURE, -
	NET_LOCK_PURE, -
	NET_LOCK_CODE, -
	NET_LOCK_Z
