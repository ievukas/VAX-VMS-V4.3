$ ! 	EXTRLDVEC
$ ! 
$ ! Routine to extract loadable service vectors from source and merge it into
$ ! a second source.
$ ! 
$ ! P1 - loadable service prefix (ex. CJF$)
$ ! P2 - source into which vectors will be merged
$ ! P3 - source module containing the vectors
$ ! P4 - output file
$ ! 
$ ! The following types of lines will be extracted from the P3 file:
$ ! 	P1'KCASCTR - initial CHMK number for facility
$ ! 	P1'ECASCTR - initial CHME number for facility
$ ! 	LDBSRV vectors for the specified facility (P1)
$ ! 
$ ! The lines will be merged into the P2 source immediately following a 
$ ! line (non-comment) containing $INSERT_MACROS_HERE
$ ! 
$ ! 
$ ! 
$ !
$ VERIFY = F$VERIFY(0)
$ ON ERROR THEN GOTO ERR_OUT
$ ON CONTROL_Y THEN GOTO ERR_OUT
$ OPEN/WRITE OUTPUT 'P4
$ OPEN /READ SOURCE 'P2
$ NEXT_SOURCE:
$ READ/END_OF_FILE=ERR_OUT SOURCE LINE
$ IF F$LOCATE("$INSERT_MACROS_HERE",LINE) .NE. F$LENGTH(LINE) THEN GOTO GOT_IT
$NOT_IT:
$ WRITE OUTPUT LINE
$ GOTO NEXT_SOURCE
$GOT_IT:
$ IF F$LOCATE(";",LINE) .LT. F$LOCATE("$INSERT_MACROS_HERE",LINE) THEN GOTO NOT_IT
$ LINE := ";''LINE'"
$ WRITE OUTPUT LINE
$ OPEN /READ CMODSSDSP 'P3
$NEXT_LINE:
$ READ/END_OF_FILE=CMODSSDSP_DONE CMODSSDSP LINE
$ IF F$LOCATE(P1,LINE) .EQ. F$LENGTH(LINE) THEN GOTO NEXT_LINE
$STRIP_NEXT:
$ CHAR = F$EXTRACT(0,1,LINE)
$ IF CHAR .EQS. " " THEN GOTO STRIP_ONE
$ IF CHAR .NES. "	" THEN GOTO STRIP_DONE
$STRIP_ONE:
$ LINE = F$EXTRACT(1,999,LINE)
$ GOTO STRIP_NEXT
$STRIP_DONE:
$ IF F$LOCATE("''P1'KCASCTR",LINE) .EQ. 0 THEN GOTO MATCH
$ IF F$LOCATE("''P1'ECASCTR",LINE) .EQ. 0 THEN GOTO MATCH
$ IF F$LOCATE("LDBSRV",LINE) .EQ. 0 THEN GOTO MATCH
$ GOTO NEXT_LINE
$MATCH:
$ WRITE OUTPUT LINE
$ GOTO NEXT_LINE
$CMODSSDSP_DONE:
$ READ/END_OF_FILE=ERR_OUT SOURCE LINE
$ WRITE OUTPUT LINE
$ GOTO CMODSSDSP_DONE
$ERR_OUT:
$ IF F$LOG("OUTPUT") .NES. "" THEN CLOSE OUTPUT
$ IF F$LOG("SOURCE") .NES. "" THEN CLOSE SOURCE
$ IF F$LOG("CMODSSDSP") .NES. "" THEN CLOSE CMODSSDSP
$ VERIFY = F$VERIFY(VERIFY)
$ EXIT
