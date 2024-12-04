$ !
$ ! This command cleans up dangling directory entries on a Release 3/4 system.
$ !
$ !	P1 = the device that is to be cleaned up.
$ !	P2 = 0 if running on V3.? system, 1 if on V4.
$ !
$ V = F$VERIFY(0)
$ FINALMSG = "Directory cleanup terminated abnormally."
$ ON CONTROL_Y THEN GOTO 200
$ ON ERROR THEN GOTO 200
$ DEVICE = P1
$ DEVICE = DEVICE - ":" + ":"
$ WRITE SYS$OUTPUT "        Start directory clean up."
$ WRITE SYS$OUTPUT "This section takes a variable amount of time"
$ WRITE SYS$OUTPUT "depending on the number of files on the disk."
$ ! WRITE SYS$OUTPUT "(Please ignore possible undefined symbol messages.)"
$ DIRECTORY = "DIRECTORY"
$ WIDTH = "/WIDTH=FILE=96"		!Force on one line
$ IF .NOT. P2 THEN WIDTH = ""
$ DIRECTORY 'WIDTH' /COLUMN=1 /NOHEAD /NOTRAIL /SIZE /OUTPUT=DIRCLENUP.LIS -
			'DEVICE'[000000...]
$ OPEN/READ DIRFILE DIRCLENUP.LIS
$30:
$ READ/END_OF_FILE=100 DIRFILE RECORD
$ IF F$LOCATE("no such file",RECORD) .EQ. F$LENGTH(RECORD) THEN GOTO 30
$! Delete this dangling directory entry.
$ FILENAM = F$EXT(0,F$LOC(" ",RECORD),RECORD)
$ ON ERROR THEN CONTINUE
$ WRITE SYS$OUTPUT "$ SET FILE /REMOVE ''FILENAM'"
$ SET FILE /REMOVE 'FILENAM'
$ ON ERROR THEN GOTO 200
$ GOTO 30
$100:
$ FINALMSG = "Directory cleanup complete."
$200:
$ CLOSE DIRFILE
$ IF F$SEARCH("DIRCLENUP.LIS") .NES. "" THEN DELETE DIRCLENUP.LIS;*
$ WRITE SYS$OUTPUT FINALMSG
$ V = F$VERIFY(V)
$ EXIT
