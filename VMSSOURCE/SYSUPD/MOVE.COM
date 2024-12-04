$ V = F$VERIFY(0)
$ ON CONTROL_Y THEN GOTO 200
$ ON ERROR THEN GOTO 200
$ SOURCE = P1
$ SOURCE_D = F$PARSE(SOURCE,,,"DEVICE","SYNTAX_ONLY") + -
		F$PARSE(SOURCE,,,"DIRECTORY","SYNTAX_ONLY")
$ FILENAME = F$PARSE(SOURCE,,,"NAME","SYNTAX_ONLY") + -
		F$PARSE(SOURCE,,,"TYPE","SYNTAX_ONLY")
$ TARGET = P2
$ OPERATION = P3
$ IF OPERATION .NES. "MOVE" THEN GOTO BAD_PARAM
$ LOCATION = P4
$ IF (LOCATION .EQS. "NULL") THEN GOT GET_DIR
$ IF (LOCATION .EQS. "OVER") THEN -
	RENAME 'SOURCE_D''FILENAME';* 'SOURCE_D''FILENAME';0
$ IF F$SEARCH("''TARGET'''FILENAME';") .NES. "" THEN -
		RENAME 'TARGET''FILENAME'; 'SOURCE_D';0
$ IF (LOCATION .EQS. "OVER") THEN -
	RENAME 'SOURCE_D''FILENAME';* 'SOURCE_D''FILENAME';0
$GET_DIR:
$ RENAME 'SOURCE_D''FILENAME';* 'TARGET'
$200:
$ IF V THEN SET VERIFY
$ EXIT
$BAD_PARAM:
$ WRITE SYS$OUTPUT "''OPERATION' is an invalid operation."
$ EXIT
$ !
$ ! This command moves files from one directory to another maintaining
$ ! the order of the version numbers.
$ !
$ ! NOTE:  There may be only ONE version of the target file already
$ !	   in the target directory!!!
$ !
$ !	P1 = the file specifications to be moved (DDCU:[DIR]file)
$ !		(any file spec that DIRECTORY understands)
$ !
$ !	P2 = the destination disk and directory
$ !		(no other pieces of file specs allowed)
$ !
$ !	P3 = the desired operation:  MOVE
$ !		MOVE - does a RENAME
$ !
$ !	P4 = the desired version number change:  OVER or UNDER or NULL
$ !		UNDER - places moved files as lower version numbers
$ !		OVER - places moved files as higher version numbers
$ !		NULL - just RENAME files, don't worry about version numbers
$ !
