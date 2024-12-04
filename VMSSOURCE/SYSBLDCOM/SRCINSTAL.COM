$ V='F$VERIFY(0)'
$ !
$ ! SRCINSTAL.COM - the VMS source kit installation procedure
$ !
$ OLD_UIC=F$USER()
$ OLD_DIR=F$DIRECTORY()
$ OLD_DEV=F$LOGICAL("SYS$DISK")
$ MOUNT_TYPE="GROUP"
$ JOB_LIMIT=0
$ TYPE SYS$INPUT:

This command procedure installs the necessary environment in  which  VMS  system
builds  may  be done.  It will prompt you for the device names of (1) the device
on which the source kit will be located (either single components or the  entire
source  kit), (2) the device on which the source kit magtapes are to be mounted,
and (3) then device on which to locate the home  directory  of  the  SYSTEMBUILD
account.   You  may supply either physical or logical device names.  However, if
logical names are given, since the device names are referenced by  this  command
procedure, they must be defined before the installation procedure can continue.

This command procedure will create the SYSTEMBUILD account,  and  move  all  the
necessary command procedures into the default directory.  An indirect pointer to
the system build startup command procedure, SBSTARTUP.COM, will be  appended  to
your SYSTARTUP.COM command procedure.  Therefore, make sure that it does not end
with a $EXIT;  otherwise the system builds will not be restartable.

You should be logged in under the SYSTEM account to  execute  this  installation
procedure.   At  the  very least, you will need the following privileges:  OPER,
SYSPRV, CMKRNL, SYSNAM, GRPNAM, and VOLPRO.

If you do not already have  the  .L32  forms  of  the  BLISS  require  files  in
SYS$LIBRARY:,  this  command  procedure  will  compile  thwm.  You should have a
working set quota of at least 1000 pages for this to complete  in  a  reasonable
length of time.

$ INQUIRE ANS "Are you ready to proceed (Y/N)"
$ IF .NOT.ANS THEN $ GOTO CLEAN_UP1
$ ON ERROR THEN $ GOTO CLEAN_UP
$ ON CONTROL_Y THEN $ GOTO CLEAN_UP
$ SET UIC [11,177]
$ !
$ ! Get the device names for the source disk, the source kit tape drive, and
$ ! the home directory device.  Also, find out whether the disks are to be
$ ! mounted cluster-wide, system-wide, or simply group-wide.
$ !
$GET_SOURCE:
$ INQUIRE DST_MASTER "On what device is the master pack to be located (Dxcu:)"
$ IF DST_MASTER.EQS."" THEN $ GOTO GET_SOURCE
$ IF 'F$LOCATE(":",DST_MASTER)'.GE.'F$LENGTH(DST_MASTER)' THEN $ DST_MASTER:='DST_MASTER':
$ IF .NOT."''F$GETDVI(DST_MASTER,"MNT")'" THEN $ MOUNT/OVERRIDE=IDENTIFICATION 'DST_MASTER' MASD$
$ DST_LABEL=F$GETDVI(DST_MASTER,"VOLNAM")
$ !
$GET_TAPE:
$ INQUIRE TAPE_DRIVE "On what device are the source kit tapes to be mounted (Mxcu:)"
$ IF TAPE_DRIVE.EQS."" THEN $ GOTO GET_TAPE
$ IF 'F$LOCATE(":",TAPE_DRIVE)'.GE.'F$LENGTH(TAPE_DRIVE)' THEN $ TAPE_DRIVE:='TAPE_DRIVE':
$ IF F$GETDVI(TAPE_DRIVE,"MNT") THEN $ DISMOUNT/NOUNLOAD 'TAPE_DRIVE'
$ ALLOCATE 'TAPE_DRIVE'
$ MOUNT 'TAPE_DRIVE' VMSRC1			! To verify the label
$ DISMOUNT/NOUNLOAD 'TAPE_DRIVE'
$ MOUNT/FOREIGN 'TAPE_DRIVE' VMSRC1
$ !
$GET_HOME:
$ INQUIRE BUILD_HOME "On what device will the SYSTEMBUILD account be located (Dxcu:)"
$ IF BUILD_HOME.EQS."" THEN $ GOTO GET_HOME
$ IF 'F$LOCATE(":",BUILD_HOME)'.GE.'F$LENGTH(BUILD_HOME)' THEN $ BUILD_HOME:='BUILD_HOME':
$GET_CLUSTER:
$ IF .NOT.F$GETSYI("CLUSTER_MEMBER") THEN $ GOTO GET_SYSTEM
$ INQUIRE ANS "Are the master source disk and result disk(s) to be mounted cluster wide [N]"
$ IF .NOT.ANS THEN $ GOTO GET_SYSTEM
$ MOUNT_TYPE="CLUSTER"
$ GOTO CREATE_ACCT
$GET_SYSTEM:
$ INQUIRE ANS "Are the master source disk and result disk(s) to be mounted system wide [N]"
$ IF ANS THEN $ MOUNT_TYPE="SYSTEM"
$ !
$CREATE_ACCT:
$ WRITE SYS$OUTPUT "Creating the SYSTEMBUILD account..."
$ !
$ ! See if the SYSTEMBUILD account exists.  If not, create it.
$ !
$ SEARCH/OUTPUT=NL: SYS$SYSTEM:SYSUAF.DAT SYSTEMBUILD
$ IF $STATUS.EQ.1 THEN $ GOTO NO_CREATE
$ !
$ OPEN/WRITE FILE SYS$MANAGER:CREATACNT.COM
$ WRITE FILE "$ SET DEFAULT SYS$SYSTEM:"
$ WRITE FILE "$ RUN AUTHORIZE"
$ WRITE FILE "ADD SYSTEMBUILD /OWNER=""Source Kit"" /ACCOUNT=SYSBUILD -"
$ WRITE FILE "/UIC=[11,177] /DEVICE=''BUILD_HOME' /DIRECTORY=[SYSBLDCOM]"
$ WRITE FILE "MOD SYSTEMBUILD /CLI=DCL /CLITABLES=DCLTABLES /PRIMEDAYS=(MON, -"
$ WRITE FILE "TUE,WED,THU,FRI,SAT,SUN) /FLAGS=(NODISCTLY,NOLOCKPWD,NODEFCLI, -"
$ WRITE FILE "NOCAPTIVE,NODISNEWMAIL,NODISWELCOME,NODISUSER)"
$ WRITE FILE "MOD SYSTEMBUILD /ACCESS /MAXJOBS=0 /MAXACCTJOBS=0 /MAXDETACH=0 -"
$ WRITE FILE "/PRCLM=24 /QUEPRIORITY=0 /CPUTIME=0 /FILLM=60 /SHRFILLM=0"
$ WRITE FILE "MOD SYSTEMBUILD /BIOLM=18 /DIOLM=18 /ASTLM=18 /TQELM=24 /ENQLM=50 -"
$ WRITE FILE "/BYTLM=30720 /PBYTLM=0 /JTQUOTA=1024 /WSDEF=600 /WSQUO=600"
$ WRITE FILE "MOD SYSTEMBUILD /WSEXT=32767 /PGFLQUOTA=40000 /PRIVILEGES=(CMKRNL, -"
$ WRITE FILE "SYSNAM, GRPNAM, DETACH, LOG_IO, GROUP, PRMCEB, SETPRV, TMPMBX, -"
$ WRITE FILE "OPER, NETMBX, VOLPRO, SYSPRV)"
$ WRITE FILE "MOD SYSTEMBUILD /DEFPRIVILEGES=(CMKRNL, -"
$ WRITE FILE "SYSNAM, GRPNAM, DETACH, LOG_IO, GROUP, PRMCEB, SETPRV, TMPMBX, -"
$ WRITE FILE "OPER, NETMBX, VOLPRO, SYSPRV) /PASSWORD=CAVEAT_EMPTOR"
$ CLOSE FILE
$ @SYS$MANAGER:CREATACNT.COM
$ DELETE SYS$MANAGER:CREATACNT.COM;
$ !
$NO_CREATE:
$ WRITE SYS$OUTPUT "Creating the SYSTEMBUILD directory..."
$ !
$ SET DEFAULT 'BUILD_HOME'[SYSBLDCOM]
$ !
$ WRITE SYS$OUTPUT "Ignore the following errors if you are not using disk quotas..."
$ !
$ RUN SYS$SYSTEM:DISKQUOTA
ADD [11,177] /PERMQUOTA=20000 /OVERDRAFT=1000
$ !
$ IF "''F$SEARCH("[0,0]SYSBLDCOM.DIR")'".NES."" THEN $ GOTO GOT_SYSBLDCOM
$ CREATE/DIRECTORY/OWNER=[11,177]/PROTECTION=(S:R,O:RW,G:R,W) [SYSBLDCOM]
$GOT_SYSBLDCOM:
$ IF "''F$SEARCH("[0,0]SYS.DIR")'".EQS."" THEN $ GOTO CREATE_SRC
$ IF "''F$SEARCH("[SYS]SRC.DIR")'".NES."" THEN $ GOTO GOT_SRC
$CREATE_SRC:
$ CREATE/DIRECTORY/OWNER=[11,177]/PROTECTION=(S:R,O:RW,G:R,W) [SYS.SRC]
$GOT_SRC:
$ IF "''F$SEARCH("[SYS]OBJ.DIR")'".NES."" THEN $ GOTO GOT_OBJ
$ CREATE/DIRECTORY/OWNER=[11,177]/PROTECTION=(S:R,O:RW,G:R,W) [SYS.OBJ]
$GOT_OBJ:
$ IF "''F$SEARCH("[SYS]LIS.DIR")'".NES."" THEN $ GOTO GOT_LIS
$ CREATE/DIRECTORY/OWNER=[11,177]/PROTECTION=(S:R,O:RW,G:R,W) [SYS.LIS]
$GOT_LIS:
$ IF "''F$SEARCH("[0,0]SYSOBJ.DIR")'".NES."" THEN $ GOTO GOT_SYSOBJ
$ CREATE/DIRECTORY/OWNER=[11,177]/PROTECTION=(S:R,O:RW,G:R,W) [SYSOBJ]
$GOT_SYSOBJ:
$ !
$ WRITE SYS$OUTPUT "Restoring SYSTEMBUILD command procedures and compilers..."
$ !
$ BACKUP 'TAPE_DRIVE'SYSBLDCOM/EXCLUDE=(SRCINSTAL.COM) 'DST_MASTER'[*...]/OWNER=ORIGINAL/NEW_VERSION
$ IF BUILD_HOME.EQS.DST_MASTER THEN $ GOTO COPY_DONE
$ COPY 'DST_MASTER'[SYSBLDCOM]SBSTARTUP.COM,LOGIN.COM,SCANALL.COM,-
	SETUSER.B32 'BUILD_HOME'[SYSBLDCOM]
$ COPY 'DST_MASTER'[SYS.SRC]VERSION.MAR 'BUILD_HOME'[SYS.SRC]
$COPY_DONE:
$ COPY 'DST_MASTER'[SYSEXE]CVTMSG.* SYS$SYSTEM:
$ PURGE [SYS.SRC]VERSION.MAR
$ !
$ ! Determine if the VIRTUALPAGECNT SYSGEN parameter is large enough to allow
$ ! the SDLing of SYSDEF in the VMSLIB SRCLIB phase.
$ !
$ IF F$GETSYI("VIRTUALPAGECNT").GE.10240 THEN $ GOTO GET_MEM_SIZE
$ WRITE SYS$OUTPUT "***Warning*** VIRTUALPAGECNT SYSGEN parameter is not large enough to"
$ WRITE SYS$OUTPUT "allow the VMSLIB facility to build SYSDEF; minimum is 10240 pages"
$ !
$ ! Modify SBSTARTUP.COM to reflect the desires of the installer.
$ !
$GET_MEM_SIZE:
$ DEFINE/USER SYS$OUTPUT SYS$LOGIN:MEMORY.TMP
$ SHOW MEMORY/PHYSICAL_MEMORY
$ OPEN/READ FILE SYS$LOGIN:MEMORY.TMP
$READ_LOOP:
$ READ FILE RECORD
$ LENGTH = F$LENGTH(RECORD)
$ IF F$LOCATE("Main Memory",RECORD) .EQ. LENGTH THEN GOTO READ_LOOP
$ CLOSE FILE
$ DELETE SYS$LOGIN:MEMORY.TMP;
$ TEMP = F$LOCATE(")",RECORD)
$ RECORD = F$EDIT(F$EXTRACT(TEMP+1,LENGTH-TEMP-1,RECORD),"TRIM,COMPRESS")
$ MEMSIZE = F$EXTRACT(0,F$LOCATE(" ",RECORD),RECORD)
$ JOB_LIMIT=MEMSIZE/1024+1
$ IF JOB_LIMIT.LE.1 THEN $ JOB_LIMIT=2
$ IF JOB_LIMIT.GT.7 THEN $ JOB_LIMIT=7
$DO_EDITSTART:
$ MUNG:=$TECO MUNG
$ MUNG 'DST_MASTER'[SYSBLDCOM]EDITSTART,'BUILD_HOME','DST_MASTER','DST_LABEL','MOUNT_TYPE','JOB_LIMIT'
$ PURGE [SYSBLDCOM]*.*
$ !
$ ! Now modify the site SYSTARTUP.COM file to invoke SBSTARTUP.COM
$ !
$ SET DEFAULT SYS$MANAGER:
$ MUNG 'DST_MASTER'[SYSBLDCOM]EDITSYST,'BUILD_HOME'
$ !
$ WRITE SYS$OUTPUT "Compiling the BLISS libraries..."
$ !
$ SET UIC 'OLD_UIC'
$ SET DEFAULT SYS$LIBRARY:
$ DEFINE BLISS32 'DST_MASTER'[SYSEXE]BLISS32
$ SET COMMAND 'DST_MASTER'[SYSBLDCOM]BLISS.CLD
$ SET WORKING_SET/LIMIT=4096
$ IF "''F$SEARCH("CLIMAC.L32")'".NES."" THEN $ GOTO GOT_CLIMAC
$ BLISS/LIBRARY CLIMAC
$GOT_CLIMAC:
$ IF "''F$SEARCH("TPAMAC.L32")'".NES."" THEN $ GOTO GOT_TPAMAC
$ BLISS/LIBRARY TPAMAC
$GOT_TPAMAC:
$ IF "''F$SEARCH("STARLET.L32")'".NES."" THEN $ GOTO GOT_STARLET
$ WRITE SYS$OUTPUT "Compiling STARLET.L32...take a short break..."
$ BLISS/LIBRARY STARLET
$GOT_STARLET:
$ IF "''F$SEARCH("LIB.L32")'".NES."" THEN $ GOTO GOT_LIB
$ WRITE SYS$OUTPUT "Compiling LIB.L32...take a longer break..."
$ BLISS/LIBRARY=LIB STARLET+LIB
$GOT_LIB:
$ !
$ ! Now build SETUSER.EXE
$ !
$ SET DEFAULT 'BUILD_HOME'[SYSBLDCOM]
$ BLISS SETUSER
$ LINK SETUSER,SYS$SYSTEM:SYS.STB/SEL
$ COPY SETUSER.EXE SYS$SYSTEM:
$ !
$ DEASSIGN BLISS32
$ SET WORKING_SET/LIMIT=150
$ TYPE SYS$INPUT:

To complete installation of the VMS source kit, now  dismount  the  source  disk
/NOUNLOAD,  and  execute  the  system  build  startup command file by typing the
command:

$ WRITE SYS$OUTPUT "	@",BUILD_HOME,"[SYSBLDCOM]SBSTARTUP"
$ TYPE SYS$INPUT:

This will mount the source disk /GROUP, and it  will  create  the  system  build
batch queues.  Once you have done this, log out and log in under the SYSTEMBUILD
account just created.  The password is CAVEAT_EMPTOR;  remember to change it  to
one    of    your    own    choosing.     For    further    information,    read
[SYSBLDCOM]SOURCEKIT.DOC.

$CLEAN_UP:
$ IF "''F$GETDVI(TAPE_DRIVE,"MNT")'" THEN $ DISMOUNT 'TAPE_DRIVE'
$CLEAN_UP1:
$ SET UIC 'OLD_UIC'
$ SET DEFAULT 'OLD_DEV''OLD_DIR'
$ IF V THEN $ SET VERIFY
