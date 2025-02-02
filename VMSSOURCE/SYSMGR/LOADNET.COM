$ !
$ ! Command procedure to create network ACP process and load network driver.
$ !
$ REQUIRED_PRIVILEGES = "ACNT,DETACH,CMKRNL,ALTPRI"
$ PREV_PRIVS = F$SETPRV(REQUIRED_PRIVILEGES)
$ IF .NOT. F$PRIVILEGE(REQUIRED_PRIVILEGES) THEN GOTO NO_PRIVILEGES
$ ON ERROR THEN GOTO EXIT
$ ON CONTROL_Y THEN GOTO EXIT
$
$ SYSGEN := $SYSGEN
$ IF F$GETDVI("_NET:","EXISTS") THEN SYSGEN RELOAD NETDRIVER
$ SYSGEN CONNECT NET/NOADAPTER/DRIVER=NETDRIVER
$ IF F$GETDVI("_NDA0:","EXISTS") THEN SYSGEN RELOAD NDDRIVER
$ SYSGEN CONNECT NDA0/NOADAPTER
$
$ IF P1 .EQS. "" THEN P1 = "SYS$SYSTEM:NETACP"
$ RUN 'P1' -
	/NOACCOUNTING-
	/NOAUTHORIZE-
	/AST_LIMIT=100-
	/BUFFER_LIMIT=65535-
	/EXTENT=1500-
	/FILE_LIMIT=10-
	/IO_BUFFERED=32767-
	/IO_DIRECT=32767-
	/QUEUE_LIMIT=16-
	/MAXIMUM_WORKING_SET=350-
	/PAGE_FILE=3076-
	/PRIORITY=8-
	/PRIVILEGES=CMKRNL-
	/PROCESS_NAME=NETACP-
	/UIC=[1,3]
$EXIT:
$ PREV_PRIVS = F$SETPRV(PREV_PRIVS)
$ EXIT
$
$NO_PRIVILEGES:
$ WRITE SYS$OUTPUT "Insufficient privileges to start the network ACP"
$ WRITE SYS$OUTPUT "Requires ",REQUIRED_PRIVILEGES," privileges."
$ GOTO EXIT
