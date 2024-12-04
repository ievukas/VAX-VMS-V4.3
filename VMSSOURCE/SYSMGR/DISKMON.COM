$ !
$ ! Command file to control
$ ! Disk I/O performance monitoring
$ !
$ IF P1.EQS."" THEN GOTO NO_TAPE
$ !
$ ! Setup to log data to tape
$ !
$ ALLOC 'P1' TAPE
$ INIT TAPE: DSKMON
$ MOUNT/BLOCK=4096/RECORD=4096 TAPE: DSKMON
$ DEF IOCOLLECT TAPE:DISKMON.DAT
$ GOTO COMMON
$ !
$ ! Setup to log data to disk
$ !
$NO_TAPE:
$ DEF IOCOLLECT DISKMON.DAT
$ !
$COMMON:
$ RUN SYS$SYSTEM:DISKMON
30
$ ! Edit previous line to 
$ ! change monitoring interval
$ ! (specified as minutes)
$ !
$ IF P1.EQS."" THEN $ EXIT
$ !
$ ! Cleanup if logging to tape
$ !
$ DISM TAPE:
$ DEALLOC TAPE:
$ EXIT
