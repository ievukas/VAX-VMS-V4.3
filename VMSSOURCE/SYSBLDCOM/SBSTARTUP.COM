$ !
$ ! SBSTARTUP.COM -- system startup file to handle system build specific
$ ! startup functions. Mount the master pack and result disks, if they
$ ! are not already mounted, and restart the system build if one was in
$ ! progress.
$ !
$ SET NOON
$ UIC = F$USER()
$ DIR = F$DIRECTORY()
$ SETUSER = "$SETUSER"
$ SETUSER SYSTEMBUILD
$ SET UIC [11,177]
$ RESTART = 1
$ HOME_DEVICE = "AAAA"
$ MASTER_DEVICE = "BBBB"
$ DEFINE/TABLE=LNM$GROUP_000011 BUILD$MOUNT_TYPE DDDD
$ JOB_LIMIT = EEEE
$ DEFINE/TABLE=LNM$GROUP_000011 WRKD$ 'HOME_DEVICE'
$ COMMAND="DEFINE/SYSTEM MASD$ "+MASTER_DEVICE
$ IF F$LOGICAL("BUILD$MOUNT_TYPE").EQS."GROUP" THEN -
	$ COMMAND="DEFINE/TABLE=LNM$GROUP_000011 MASD$ "+MASTER_DEVICE
$ 'COMMAND'
$ !
$ ! If the master device in on the UDA, it is necessary to wait about 30
$ ! seconds to all the devices to appear.
$ !
$CHECK_MASD:
$ IF F$GETDVI("MASD$","EXISTS") THEN $ GOTO MASD_THERE
$ WAIT 00:00:30
$ GOTO CHECK_MASD
$MASD_THERE:
$ !
$ IF F$GETDVI("MASD$","MNT") THEN $ GOTO MASD_MOUNTED
$ MOUNT /'F$LOGICAL("BUILD$MOUNT_TYPE")' /ACCESS=12 MASD$: CCCC
$ IF .NOT. $STATUS THEN RESTART = 0
$MASD_MOUNTED:
$ !
$ ! *** Following area is edited by VMSGEN.COM
$ ! *** Mount the current result disk
$ ! *** End of edited area
$ !
$ !
$ ! Start the sysstem build batch queue
$ !
$ INIT/QUEUE/START/BATCH/JOB='JOB_LIMIT' SYS$BUILD
$ IF .NOT. $STATUS THEN $ RESTART = 0
$ !
$ ! If a restartable build was in progress, restart it.
$ !
$ IF .NOT. RESTART THEN GOTO NORESTART
$ OPEN /ERROR=NORESTART FILE WRKD$:[SYSBLDCOM]VMSACTBLD.COM
$ CLOSE FILE
$ @WRKD$:[SYSBLDCOM]VMSACTBLD
$NORESTART:
$ !
$ SET UIC 'UIC'
$ SET DEFAULT 'DIR'
$ SETUSER SYSTEM
