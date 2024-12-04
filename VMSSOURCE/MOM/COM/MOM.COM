
$ SET NOON
$ !
$ ! NML sets up NML$MOM_MBX as a user mode logical name.  Define it
$ ! it again here, so, if any other commands are inserted that cause
$ ! process rundown, MOM can still translate it.
$ !
$ IF F$LOGICAL ("NML$MOM_MBX") .NES. "" THEN -
 	DEFINE NML$MOM_MBX 'F$LOG("NML$MOM_MBX")'
$ IF "''MOM$COMMAND'" .NES. "" THEN MOM$COMMAND
$ IF F$SEARCH("MOM.LOG;-10") .NES. "" THEN -
	PURGE /KEEP:5 MOM.LOG
$ RUN SYS$SYSTEM:MOM
$ EXIT
