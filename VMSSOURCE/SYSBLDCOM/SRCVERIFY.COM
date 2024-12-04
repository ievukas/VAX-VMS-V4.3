$ DBG_VERIFY=F$EDIT("''SOURCE_KIT_VERIFY'","TRIM,UPCASE")
$ IF DBG_VERIFY.NES."1".AND.DBG_VERIFY.NES."T" THEN $ DBG_VERIFY:="0"
$ V='F$VERIFY(DBG_VERIFY)'
$ !
$ ! This command procedure verifies that the new master pack contains all
$ ! the files needed from the old (current) master pack.
$ !
$ !	P1 -	the device on which the source master pack resides
$ !		(required)
$ !
$ !	P2 -	the device on which the target master pack resides
$ !
$ !	P3 -	the label of the target master pack
$ !
$ !	P4 -	the name of the file to control the facilities verified
$ !		(default is SYSBLDCOM$:VMSNEWBLD.COM)
$ !
$ !	P5 -	the source of the update packets (ENH or BUG)
$ !		(default is ENH)
$ !
$ ON ERROR THEN $ GOTO CLEAN_UP
$ ON SEVERE_ERROR THEN $ GOTO CLEAN_UP
$ ON CONTROL_Y THEN $ GOTO CLEAN_UP
$ ON CONTROL_C THEN $ GOTO CLEAN_UP
$ !
$ BATCH="FALSE"
$ IF F$MODE().EQS."BATCH" THEN BATCH="TRUE"
$ !
$ CLEANUP=0
$ !
$ ! Get the source master pack device name if not given.
$ !
$ IF P1.NES."" THEN $ GOTO GOT_SRC
$ IF BATCH THEN $ GOTO CLEAN_UP
$ INQUIRE P1 "What device has the source master pack [DISK$VMSMASTER:]"
$ IF P1.EQS."" THEN P1="DISK$VMSMASTER:"
$GOT_SRC:
$ IF F$LOCATE(":",P1).GE.F$LENGTH(P1) THEN $ P1=P1+":"
$ SRC_MASTER=P1
$ !
$ ! Get the target master pack device name if not given.
$ !
$GET_DST:
$ IF P2.NES."" THEN $ GOTO GOT_DST
$ IF BATCH THEN $ CLEAN_UP
$ INQUIRE P2 "What device is the target master pack on (ddcn:)"
$ GOTO GET_DST
$GOT_DST:
$ IF F$LOCATE(":",P2).GE.F$LENGTH(P2) THEN $ P2=P2+":"
$ DST_MASTER=P2
$ IF F$GETDVI(DST_MASTER,"MNT") THEN $ GOTO GET_LABEL
$ ON WARNING THEN $ GOTO GET_DST
$ ALLOCATE 'DST_MASTER'
$ ON WARNING THEN $ CONTINUE
$ !
$ ! Determine the label of the target master pack.
$ !
$GET_LABEL:
$ DST_LABEL=P3
$ IF P3.NES."" THEN $ GOTO GOT_LABEL
$ IF .NOT.BATCH THEN $ INQUIRE P3 "Target master pack label [VMSMASTER]"
$ DST_LABEL=P3
$ IF P3.EQS."" THEN $ DST_LABEL="VMSMASTER"
$GOT_LABEL:
$ !
$ ! Determine the build data file to use.
$ !
$GET_FILE:
$ BUILD_FILE=P4
$ IF P4.NES."" THEN $ GOTO CHECK_FILE
$ IF .NOT.BATCH THEN -
	$ INQUIRE P4 "Control data file [''SRC_MASTER'[SYSBLDCOM]VMSNEWBLD.DAT]"
$ BUILD_FILE=P4
$ IF P4.EQS."" THEN $ BUILD_FILE=SRC_MASTER+"[SYSBLDCOM]VMSNEWBLD.DAT"
$CHECK_FILE:
$ ON WARNING THEN $ GOTO BUILD_FILE_ERROR
$ IF F$SEARCH(BUILD_FILE).NES."" THEN $ GOTO GOT_FILE
$BUILD_FILE_ERROR:
$ WRITE SYS$OUTPUT "%SRCMRG-E-FNF, file not found '",BUILD_FILE,"'"
$ IF BATCH THEN $ CLEAN_UP
$ P4=""
$ GOTO GET_FILE
$GOT_FILE:
$ ON WARNING THEN $ CONTINUE
$ !
$ ! Determine the type of master pack copy to do.
$ !
$GET_TYPE:
$ IF P5.EQS."BUG".OR.P5.EQS."ENH" THEN $ GOTO GOT_TYPE
$ IF BATCH THEN $ CLEAN_UP
$ INQUIRE P5 "What type of copy operation (BUG or ENH) [ENH]"
$ IF P5.EQS."" THEN $ P5="ENH"
$ GOTO GET_TYPE
$GOT_TYPE:
$ IGNORE_TYPE="BUG"
$ IF P5.EQS."BUG" THEN $ IGNORE_TYPE="ENH"
$ !
$ ! Open the build file to find out what facilities should be verified.
$ !
$ OPEN/SHARE/READ BLDFIL 'BUILD_FILE'
$ CLEANUP=CLEANUP.OR.1
$ !
$ ! Echo the selected input parameters so that the user knows what is
$ ! actually being used.
$ !
$ WRITE SYS$OUTPUT "	Source master pack:		",SRC_MASTER
$ WRITE SYS$OUTPUT "	Destination master pack:	",DST_MASTER
$ WRITE SYS$OUTPUT "	Destination master pack label:	",DST_LABEL
$ WRITE SYS$OUTPUT "	Build control file:		",BUILD_FILE
$ IF P5.EQS."ENH" THEN -
	$ WRITE SYS$OUTPUT "	This is an enhancement verify"
$ IF P5.EQS."BUG" THEN -
	$ WRITE SYS$OUTPUT "	This is an bug packet verify"
$ !
$ ! Make sure that the destination master pack is mounted.
$ !
$ IF F$GETDVI(DST_MASTER,"MNT") THEN $ GOTO DST_MOUNTED
$ MOUNT/GROUP 'DST_MASTER' 'DST_LABEL'
$DST_MOUNTED:
$ !
$ ! Now go through the build control file and get the facilities to verify.
$ !
$START_VERIFY:
$ KEY_QUAL:="/INDEX=1/KEY=""AAINFO """
$NEXT_RECORD:
$ READ 'KEY_QUAL' BLDFIL RECORD
$ KEY_QUAL:=""
$ IF F$EDIT(F$EXTRACT(16,16,RECORD),"TRIM").NES."AAINFO" THEN $ GOTO VERIFY_DONE
$ FACILITY:='F$EDIT(F$EXTRACT(0,16,RECORD),"TRIM")'
$ !
$ WRITE SYS$OUTPUT "Now verifying the ''FACILITY' facility"
$ !
$ ! Now verify the directories associated with the facility
$ !
$VERIFY_DIR:
$ DIR_FILE=F$SEARCH(SRC_MASTER+"["+FACILITY+"...]*.DIR",1)
$ IF DIR_FILE.EQS."" THEN $ GOTO NEXT_RECORD
$ FILE_NAME=F$PARSE(DIR_FILE,,,"NAME")
$ !
$ ! Check to see if this directory should be ignored.
$ !
$ IF IGNORE_TYPE.NES."BUG" THEN $ GOTO CHECK_ENH
$ IF FILE_NAME.EQS."BUG".OR. -
     FILE_NAME.EQS."BUGCOM".OR. -
     FILE_NAME.EQS."BUGSRC".OR. -
     FILE_NAME.EQS."ENH" THEN $ GOTO VERIFY_DIR
$ GOTO CHECK_DONE
$CHECK_ENH:
$ IF IGNORE_TYPE.NES."ENH" THEN $ GOTO CHECK_DONE
$ IF FILE_NAME.EQS."BUG".OR. -
     FILE_NAME.EQS."ENH".OR. -
     FILE_NAME.EQS."COM".OR. -
     FILE_NAME.EQS."SRC" THEN $ GOTO VERIFY_DIR
$CHECK_DONE:
$ DIR=F$PARSE(DIR_FILE,,,"DIRECTORY")-"]"+"."+FILE_NAME+"]"
$VERIFY_FILES:
$ TFILE=F$SEARCH(SRC_MASTER+DIR+"*.*;",2)
$ IF TFILE.EQS."" THEN $ GOTO VERIFY_DIR
$ FILE_NAME=DIR+F$PARSE(TFILE,,,"NAME")+F$PARSE(TFILE,,,"TYPE")
$ IF F$SEARCH(DST_MASTER+FILE_NAME).NES."" THEN $ GOTO VERIFY_FILES
$ WRITE SYS$OUTPUT "%VFYMRG-W-NOFILE, nonexistant file on target disk"
$ WRITE SYS$OUTPUT "-VFYMRG-I-SOURCEFILE, ",SRC_MASTER,FILE_NAME
$ WRITE SYS$OUTPUT "-VFYMRG-I-TARGETFILE, ",DST_MASTER,FILE_NAME
$ GOTO VERIFY_FILES
$ !
$ ! Either some fatal error has occurred or the master pack has been
$ ! successfully copied.  In either case some cleanup is required before
$ ! control may be returned to DCL.
$ !
$VERIFY_DONE:
$CLEAN_UP:
$ IF (CLEANUP.AND.1).NE.0 THEN $ CLOSE BLDFIL
$ IF V THEN $ SET VERIFY
