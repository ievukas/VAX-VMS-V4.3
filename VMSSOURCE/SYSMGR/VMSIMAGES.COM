$!	IDENT V04-000
$!
$!++
$! Facility:	VMSIMAGES, Image Installing Procedure
$!
$! Module:	VMSIMAGES
$!
$! Abstract:	This procedure is used to install the required VMS images
$!		during STARTUP and to remove them during SHUTDOWN.
$!
$! Parameters:	P1 - "INSTALL" or "REMOVE"
$! 		P2 - File specification of input data file
$!
$! Author:	Peter George
$!
$! Created:	29-Feb-1984
$!
$! Modifications:
$!
$!--
$!
$! Process inputs and set up global variables.
$!
$ SET NOON
$ remove = (p1 .EQS. "REMOVE")
$ datafile = F$PARSE(p2,"SYS$MANAGER:.DAT")
$ immed = 0
$ install = "$INSTALL"
$
$!
$! Choose a facility name for the messages.
$!
$ fac = "STARTUP"
$ IF remove THEN fac = "SHUTDOWN"
$
$!
$! Make the procedure restartable so that if we are trying to remove the
$! images and we can't successfully create VMSIMAGES.TMP, we can try again 
$! in immediate mode.
$!
$restart:
$ DEFINE /USER sys$output nl:
$ DEFINE /USER sys$error nl:
$ DELETE sys$manager:vmsimages.tmp;*
$
$!
$! Open the input file (usually SYS$MANAGER:VMSIMAGES.DAT).  If not immediate 
$! mode, then also open the output file (SYS$MANAGER:VMSIMAGE.TMP).
$! 
$ OPEN /READ /ERROR=no_file input 'datafile'
$ IF immed THEN GOTO next_line
$ OPEN /WRITE /ERROR=no_room output sys$manager:vmsimages.tmp
$ IF remove THEN WRITE /ERROR=WRITEERR output -
	"$ SET MESSAGE /NOFACILITY /NOSEVERITY /NOIDENT /NOTEXT"
$ WRITE /ERROR=WRITEERR output "$ RUN SYS$SYSTEM:INSTALL"
$
$!
$! Read a record from the input file.  Ignore comments.
$!
$next_line:
$ READ /END=END_OF_FILE input line
$ IF F$EXTRACT(0,1,line) .EQS. "!" THEN GOTO next_line
$ line = F$EDIT(line,"UPCASE,TRIM,COMPRESS")
$
$!
$! If the image is marked /DELETE, and if we are removing images,
$! then ignore this record.
$!
$ IF F$LOCATE("/DEL",line) .EQ. F$LENGTH(line) THEN GOTO check_purge
$ IF remove THEN GOTO next_line
$ GOTO write_file
$
$!
$! If the image is marked /NOPURGE or /NOREMOVE, and if we are removing images,
$! then ignore this record.
$!
$check_purge:
$ IF (F$LOCATE("/NOREM",line) .EQ. F$LENGTH(line)) .AND. -
	(F$LOCATE("/NOPUR",line) .EQ. F$LENGTH(line)) THEN GOTO check_file
$ IF remove THEN GOTO next_line
$
$!
$! If we are installing images and the image can't be found, then ignore this
$! record.  If we are installing images and the image can be found, then 
$! write the record to the output file.
$! record.
$!
$check_file:
$ file = F$ELEMENT(0," ",line)
$ IF remove THEN GOTO write_remove
$ IF F$SEARCH(F$PARSE(file,".EXE")) .EQS. "" THEN GOTO next_line
$write_file:
$ WRITE /ERROR=WRITEERR output line
$ GOTO next_line
$
$!
$! We are removing images.  If we are not in immediate mode, then write the
$! image name and /DELETE qualifier to the output file.  If we are in immediate
$! mode, then use INSTALL to delete the image now.
$!
$write_remove:
$ IF immed THEN GOTO immed_remove
$ WRITE /ERROR=REMWRITERR output file,"	/DELETE"
$ GOTO next_line
$
$immed_remove:
$ SET MESSAGE /NOFACILITY /NOSEVERITY /NOIDENT /NOTEXT
$ INSTALL 'file' /DELETE
$ SET MESSAGE /FACILITY /SEVERITY /IDENT /TEXT
$ GOTO next_line
$
$!
$! We have reached the end of the input file.  Close it.  Then close, execute,
$! and delete the output file.
$!
$end_of_file:
$ CLOSE input
$ WRITE /ERROR=REMWRITERR output "$ SET MESSAGE /FACILITY /SEVERITY /IDENT /TEXT"
$ CLOSE output
$ @sys$manager:vmsimages.tmp
$
$cleanup:
$ DEFINE /USER sys$output nl:
$ DEFINE /USER sys$error nl:
$ DELETE sys$manager:vmsimages.tmp;*
$ EXIT
$
$!
$! The input file could not be found.  Issue the appropriate error message,
$! clean up, and exit.
$!
$no_file:
$ oper = "installed"
$ emsg = "IMGNOTINS"
$ IF remove THEN oper = "removed"
$ IF remove then emsg = "IMGNOTREM"
$ WRITE SYS$OUTPUT "%''FAC'-E-OPENIN, error opening input file ",datafile
$ WRITE SYS$OUTPUT "-''FAC'-E-''EMSG', known images will not be ",oper
$ GOTO cleanup
$
$!
$! The output file could not be created.  If we are removing images, then
$! switch to immediate mode and retry.  Otherwise, issue the appropriate 
$! warning messages and then try to use the input file to install the images.
$!
$no_room:
$ IF remove THEN GOTO set_immed
$ WRITE SYS$OUTPUT "%STARTUP-W-OPENOUT, error opening output file SYS$MANAGER:VMSIMAGES.TMP"
$ CLOSE input
$use_dat:
$ WRITE SYS$OUTPUT "-''FAC'-I-INSMSG, messages from INSTALL utility may follow"
$ DEFINE /USER sys$input 'datafile'
$ RUN sys$system:install
$ GOTO CLEANUP
$
$!
$! We failed to create an output file specifying the images to remove.
$! Use immediate mode to deinstall the images.
$!
$set_immed:
$ immed = 1
$ GOTO next_line
$
$!
$! We incurred an error while trying to write a record to the output file.
$! If we are removing images, then start from the beginning in immediate mode.
$! If we are installing images, then try to use the input file to install
$! the images.
$!
$writeerr:
$ IF remove THEN GOTO remwriterr
$ WRITE SYS$OUTPUT "%''FAC'-E-WRITEERR, error writing file SYS$MANAGER:VMSIMAGES.TMP"
$ CLOSE input
$ CLOSE output
$ GOTO use_dat
$
$remwriterr:
$ CLOSE input
$ CLOSE output
$ immed = 1
$ GOTO restart
