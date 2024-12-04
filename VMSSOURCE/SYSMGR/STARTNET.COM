$ !
$ !	STARTNET.COM
$ !
$ !	Use this file to start the network after the permanent databases
$ !	are configured.  Insert the command "@SYS$MANAGER:STARTNET" in
$ !	SYS$MANAGER:SYSTARTUP.COM to automatically start the network on
$ !	each reboot.
$ !
$ !	If parameter P3 is supplied, it is assumed to be the username of
$ !	the default DECnet account for which NETSERVER$SERVERS_'P3' permanent
$ !	NETSERVER processes are to be started. This must correspond to the
$ !	default account for the FAL object.
$ !
$ NCP := $NCP
$ REQUIRED_PRIVILEGES = "ACNT,DETACH,CMKRNL,LOG_IO,WORLD,NETMBX,TMPMBX,SYSNAM,OPER,SYSPRV"
$ PREV_PRIVS = F$SETPRV(REQUIRED_PRIVILEGES)
$ IF .NOT. F$PRIVILEGE(REQUIRED_PRIVILEGES) THEN GOTO NO_PRIVILEGES
$ ON ERROR THEN GOTO EXIT
$ ON CONTROL_Y THEN GOTO EXIT
$ !
$ !   Make sure that the permanent database exists before attempting
$ !   to start the network.  If it doesn't, it's useless to start DECnet.
$ !
$ IF F$SEARCH(F$PARSE("NETNODE","SYS$SYSTEM:.DAT")) .EQS. "" -  ! For lognames
	.AND. F$SEARCH("SYS$SYSTEM:NETNODE.DAT") .EQS. "" -  ! For search lists
	THEN GOTO NO_DATABASE
$ !
$ !   Make sure that, in a VAXcluster, the nodename and node address of the
$ !   executor match the relevant SYSGEN parameters.
$ !
$ IF .NOT. F$GETSYI("CLUSTER_MEMBER") THEN GOTO NOT_IN_CLUSTER
$ CLUSTER_NODENAME = F$EXTRACT(0,6,F$GETSYI("SCSNODE"))-
		     - " " - " " - " " - " " - " " - " "
$ CLUSTER_NODEADDR = F$GETSYI("SCSSYSTEMID")
$ NCP LIST EXECUTOR SUMMARY TO SYS$MANAGER:STARTNET.TMP
$ OPEN/READ/ERROR=NOT_IN_CLUSTER FILE SYS$MANAGER:STARTNET.TMP
$ READ/END_OF_FILE=CLOSE_TEMP FILE LINE
$ READ/END_OF_FILE=CLOSE_TEMP FILE LINE
$ READ/END_OF_FILE=CLOSE_TEMP FILE LINE
$ READ/END_OF_FILE=CLOSE_TEMP FILE LINE
$ READ/END_OF_FILE=CLOSE_TEMP FILE LINE
$ LINE = F$EXTRACT(F$LOCATE("=",LINE),999,LINE) - "= "
$ EXEC_NAME = F$EXTRACT(F$LOCATE("(",LINE),999,LINE) - "(" - ")"
$ EXEC_ADDR = LINE - EXEC_NAME - "(" - ")" - " "
$ IF F$LOCATE(".",EXEC_ADDR) .EQ. F$LENGTH(EXEC_ADDR) THEN GOTO GOT_ADDR
$ EXEC_LOC = F$EXTRACT(F$LOCATE(".",EXEC_ADDR),999,EXEC_ADDR) - "."
$ EXEC_AREA = EXEC_ADDR - EXEC_LOC - "."
$ IF (EXEC_AREA .EQ. 1) .AND. (CLUSTER_NODEADDR .LT. 1024) THEN EXEC_AREA = 0
$ EXEC_ADDR = 1024*EXEC_AREA + EXEC_LOC
$GOT_ADDR:
$ IF EXEC_NAME .NES. CLUSTER_NODENAME THEN GOTO BAD_NAME
$ IF EXEC_ADDR .EQS. CLUSTER_NODEADDR THEN GOTO CLOSE_TEMP
$ WRITE SYS$OUTPUT "DECnet address of local node must match VAXcluster system ID."
$ GOTO NOT_STARTED
$BAD_NAME:
$ WRITE SYS$OUTPUT "DECnet nodename of local node must match VAXcluster nodename."
$NOT_STARTED:
$ WRITE SYS$OUTPUT "DECnet not started."
$ CLOSE FILE
$ DELETE SYS$MANAGER:STARTNET.TMP;*
$ EXIT
$CLOSE_TEMP:
$ CLOSE FILE
$ DELETE SYS$MANAGER:STARTNET.TMP;*
$NOT_IN_CLUSTER:
$ !
$ !   Install privileged images
$ !
$ INSTALL := $INSTALL
$ IF .NOT. F$FILE("SYS$SYSTEM:NICONFIG.EXE","KNOWN") -
	THEN INSTALL NICONFIG/PRIVILEGES=(SYSNAM,LOG_IO)
$ IF .NOT. F$FILE("SYS$SYSTEM:EVL.EXE","KNOWN") -
	THEN INSTALL EVL/PRIVILEGES=(SYSNAM,OPER,SYSPRV)
$ !
$ !   Load NETDRIVER and start the NETACP process
$ !
$ @SYS$MANAGER:LOADNET 'P1'
$ !
$ !   Make sure NETACP is finished initializing before continuing.
$ !
$WAIT_FOR_NETACP:
$ IF F$GETDVI("_NET0","MNT") THEN GOTO NETACP_INITIALIZED
$ WAIT 0:0:1
$ GOTO WAIT_FOR_NETACP
$NETACP_INITIALIZED:
$ !
$ !   Configure the basic volatile database
$ !
$ NCP
	SET EXECUTOR ALL
	SET KNOWN OBJECTS ALL
	SET KNOWN LOGGING ALL
$ !
$ !   If VAX-11 PSI is installed on the system, then invoke the PSI
$ !   configuration procedure.  Otherwise, just setup the line/circuit
$ !   database.
$ !
$ IF F$SEARCH("SYS$MANAGER:STARTPSI.COM") .EQS. "" THEN GOTO PSI_NOT_INSTALLED
$ @SYS$MANAGER:STARTPSI 'P2'
$ GOTO DATALINKS_CONFIGURED
$
$PSI_NOT_INSTALLED:
$ NCP
	SET KNOWN LINES ALL
	SET KNOWN CIRCUITS ALL
$
$DATALINKS_CONFIGURED:
$ NCP	SET MODULE CONFIGURATOR KNOWN CIRCUITS ALL
$ !
$ !   Start remote command terminal ACP and load RTTDRIVER
$ !
$ @SYS$MANAGER:RTTLOAD
$ !
$ !   Setup the node database (this is last, because it takes the longest,
$ !   and isn't needed to get the network up).
$ !
$ NCP	SET KNOWN NODES ALL
$ !
$ !   Start up NETSERVER$SERVERS "permanent" network servers running under
$ !   the default FAL account, if any. Default is 0 servers. 
$ !
$ IF P3 .EQS. "" THEN GOTO SERVER_STARTUP_EXIT
$ NUM_SERVERS = F$TRNLNM ("NETSERVER$SERVERS_''P3'")
$ IF NUM_SERVERS .EQ. "" THEN NUM_SERVERS = 0
$ IF NUM_SERVERS .LE. 0 THEN GOTO EXIT
$SERVER_STARTUP_LOOP:
$ IF NUM_SERVERS .LE. 0 THEN GOTO SERVER_STARTUP_EXIT
$ DEFINE/USER SYS$OUTPUT _NL:
$ DEFINE/USER SYS$ERROR _NL:
$ DIRECTORY/OUTPUT=NL: 0""::.
$ NUM_SERVERS = NUM_SERVERS - 1
$ GOTO SERVER_STARTUP_LOOP
$SERVER_STARTUP_EXIT:
$EXIT:
$ PREV_PRIVS = F$SETPRV(PREV_PRIVS)
$ EXIT
$
$NO_PRIVILEGES:
$ WRITE SYS$OUTPUT "Insufficient privileges to start the network"
$ WRITE SYS$OUTPUT "Requires ",REQUIRED_PRIVILEGES," privileges."
$ GOTO EXIT
$
$NO_DATABASE:
$ TYPE SYS$INPUT
You have not yet configured your DECnet permanent database.  You must
either use NCP to define your DECnet database, or invoke the command
procedure SYS$MANAGER:NETCONFIG.COM, which will do it for you.
$ GOTO EXIT
