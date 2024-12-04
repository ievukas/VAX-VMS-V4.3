$ VERIFY = 'F$VERIFY(0)
$ IF "''DEBUG_VFY'N" THEN SET VERIFY
$ !
$ !	VECTORTST.COM - Compares the offsets of universal symbols in a
$ !	shareable image, or global symbols in an object module,
$ !	against the proper offsets stored in a data file, and reports 
$ !	on discrepancies.
$ !
$ !	Version 2.1 - Steven B. Lionel - 24-Feb-1983
$ !
$ !	See end of file for instructions on use.
$ !
$ ON ERROR THEN GOTO QUIT
$ ON CONTROL_Y THEN GOTO ABORT
$ ABORT=0
$ SEVERITY=1
$ ANLSYMB:=" "
$ MASSYMB:=" "
$ IF P1 .EQS. "" THEN P1 := 
$ P1 = F$PARSE(P1,"SYS$LIBRARY:VMSRTL.EXE")
$ OPEN/READ ZZZZ 'P1
$ CLOSE ZZZZ
$ P1 = F$SEARCH(P1)
$ FNM = F$PARSE(P1,,,"NAME")
$ TYP = F$PARSE(P1,,,"TYPE")
$ IF P2 .EQS. "" THEN P2 := 
$ IF P3 .EQS. "" THEN P3 :=
$ P2 = F$PARSE(P2,"COM$:.DAT",FNM+"VEC")
$ IF P3 .EQS. "CREATE" THEN GOTO NOP3
$ OPEN/READ ZZZZ 'P2
$ CLOSE ZZZZ
$NOP3:
$ ON ERROR THEN CONTINUE
$ QUAL = "/IMAGE"
$ IF TYP .NES. ".EXE" THEN QUAL = "/OBJECT/MHD/GSD"
$ DEFINE/USER SYS$OUTPUT NL:
$ DEFINE/USER SYS$ERROR VECERR.TMP
$ ANALYZE'QUAL'/OUT=VECTST.ANL 'P1'
$ IF $STATUS THEN GOTO ANLOK
$ SEVERITY=$SEVERITY
$ TYPE VECERR.TMP
$ GOTO QUIT2
$ANLOK:
$ ON ERROR THEN GOTO QUIT
$ OPEN/ERR=QUIT ANLFIL VECTST.ANL
$ IF P3 .NES. "CREATE" THEN OPEN MASTER 'P2'
$ WRITE SYS$OUTPUT "%VECTST-I-IDENT, analyzing ",P1,","
$ IF TYP .EQS. ".EXE" THEN GOTO F10
$F05:
$ READ ANLFIL LINE
$ M = F$LOCATE("module name:",LINE)
$ IF M .EQ. F$LENGTH(LINE) THEN GOTO F05
$ WRITE SYS$OUTPUT LINE,","
$ GOTO F12
$F10:
$ READ ANLFIL LINE
$ M = F$LOCATE("global section",LINE)
$ IF M .EQ. F$LENGTH(LINE) THEN GOTO F10
$ WRITE SYS$OUTPUT "''F$EXTRACT(1,99,LINE)',"
$F11:
$ READ ANLFIL LINE
$ M = F$LOCATE("Identification",LINE)
$ IF M .EQ. F$LENGTH(LINE) THEN GOTO F11
$ READ ANLFIL LINE
$ READ ANLFIL LINE
$ WRITE SYS$OUTPUT LINE,","
$ READ ANLFIL LINE
$ WRITE SYS$OUTPUT LINE,","
$F12:
$ READ ANLFIL LINE
$ WRITE SYS$OUTPUT LINE,","
$ READ ANLFIL LINE
$ WRITE SYS$OUTPUT LINE
$ RETURN:="10"
$ GOTO SORTANL
$10:
$ RETURN:="TOP"
$ PRVMAS:=
$ GOTO GETMAS
$TOP:
$ IF "''ANLSYMB'" .NES. "''MASSYMB'" THEN GOTO 20
$ IF "''ANLADDR'" .EQS. "''MASADDR'" THEN GOTO GETBOTH
$ IF "''MASADDR'" .EQS. "*" THEN GOTO GETBOTH	! Non-vectored symbol
$ LINE:="%VECTST-E-SYMHASMOV, symbol ''MASSYMB' has moved from ''MASADDR' to ''ANLADDR'"
$ WRITE SYS$OUTPUT LINE
$ IF SEVERITY .LT. 2 THEN SEVERITY=2
$ GOTO GETBOTH
$20:
$ IF "''ANLSYMB'" .LTS. "''MASSYMB'" THEN GOTO 30
$ LINE:="%VECTST-E-SYMDEL, symbol ''MASSYMB' has been deleted"
$ WRITE SYS$OUTPUT LINE
$ IF SEVERITY .LT. 2 THEN SEVERITY=2
$ RETURN:="TOP"
$ GOTO GETMAS
$30:
$ LINE:="%VECTST-W-NEWSYM, master file does not contain symbol ''ANLSYMB', address ''ANLADDR'"
$ WRITE SYS$OUTPUT LINE
$ IF SEVERITY .LT. 2 THEN SEVERITY=0
$ RETURN:="TOP"
$ GOTO GETANL
$GETBOTH:
$ RETURN:="40"
$ GOTO GETMAS
$40:
$ RETURN:="TOP"
$ GOTO GETANL
$GETMAS:
$ READ/END=MASEND MASTER LINE
$ IF "''F$EXTRACT(0,1,LINE)'" .EQS. "!" THEN GOTO GETMAS
$ N='F$LOCATE("-",LINE)
$ IF N .EQ. 'F$LENGTH(LINE) THEN GOTO MASERR
$ MASSYMB:="''F$EXTRACT(0,N,LINE)'"
$ L='F$LENGTH(LINE) - N - 1
$ N=N+1
$ MASADDR:="''F$EXTRACT(N,L,LINE)'"
$ IF MASSYMB .LES. PRVMAS THEN -
 WRITE SYS$OUTPUT "%VECTST-W-NOTALPORD, master file symbol ",MASSYMB," not in alphabetic order"
$ PRVMAS = MASSYMB
$ GOTO 'RETURN
$MASERR:
$ WRITE SYS$OUTPUT "%VECTST-E-SYNERRMAS, syntax error in master file - line follows"
$ WRITE SYS$OUTPUT " ""''LINE'"""
$ IF SEVERITY .LT. 2 THEN SEVERITY=2
$ GOTO GETMAS
$MASEND:
$ MASSYMB:="~"
$ MASADDR:="0"
$ IF "''ANLSYMB'" .EQS. "!" THEN GOTO QUIT
$ GOTO 'RETURN
$GETANL:
$ READ/END=ANLEND ANLFIL LINE
$ N='F$LOCATE("-",LINE)
$ IF N .EQ. 'F$LENGTH(LINE) THEN GOTO ANLERR
$ ANLSYMB:="''F$EXTRACT(0,N,LINE)'"
$ L='F$LENGTH(LINE) - N - 1
$ N=N+1
$ ANLADDR:="''F$EXTRACT(N,L,LINE)'"
$ COUNT=COUNT+1
$ IF COUNT .LT. 100 THEN GOTO 'RETURN
$ SUM=SUM+COUNT
$ WRITE SYS$OUTPUT "%VECTST-I-PROGRESS, ''SUM symbols processed"
$ COUNT=0
$ GOTO 'RETURN
$ANLERR:
$ WRITE SYS$OUTPUT "%VECTST-E-SYNERRANL, syntax error in analyze file - line follows"
$ WRITE SYS$OUTPUT " ""''LINE'"""
$ IF SEVERITY .LT. 2 THEN SEVERITY=2
$ GOTO GETANL
$ANLEND:
$ ANLSYMB:="~"
$ ANLADDR:="0"
$ IF "''MASSYMB'" .EQS. "~" THEN GOTO QUIT
$ GOTO 'RETURN
$SORTANL:
$ WRITE SYS$OUTPUT "%VECTST-I-STARTPASS, start of pass 1"
$ OPEN/WRITE SRTANL VECTST.TMP
$ COUNT=0
$ SUM=0
$S10:
$ READ/END=SRTEND ANLFIL LINE
$ IF F$LENGTH(LINE) .LE. 10 THEN GOTO S10
$ IF F$LOCATE("value:",LINE) .NES. 2 THEN GOTO S10
$ N = 'F$LOCATE("%X",LINE)+3
$ ANLADDR := "''F$EXTRACT(N,8,LINE)'"
$A10:
$ READ/END=SRTEND ANLFIL LINE
$ IF "''F$EXTRACT(2,7,LINE)'" .NES. "symbol:" THEN GOTO A10
$ ANLSYMB := "''F$EXTRACT(11,32,LINE)'"
$ N = 'F$LENGTH(ANLSYMB) - 1
$ ANLSYMB := "''F$EXTRACT(0,N,ANLSYMB)'"
$ WRITE SRTANL "''ANLSYMB'-''ANLADDR'"
$ COUNT=COUNT+1
$ IF COUNT .LT. 100 THEN GOTO S10
$ SUM=SUM+100
$ WRITE SYS$OUTPUT "%VECTST-I-PROGRESS, ''SUM' symbols processed"
$ COUNT=0
$ GOTO S10
$SRTEND:
$ CLOSE SRTANL
$ CLOSE ANLFIL
$ SUM=SUM+COUNT
$ WRITE SYS$OUTPUT "%VECTST-I-PROGRESS, ''SUM' symbols processed"
$ DEFINE/USER SYS$OUTPUT NL:
$ SORT VECTST.TMP VECTST.TMP
$ PURGE VECTST.TMP
$ IF P3 .EQS. "CREATE" THEN GOTO NEWMASTER
$ OPEN ANLFIL VECTST.TMP
$ COUNT=0
$ SUM=0
$ WRITE SYS$OUTPUT "%VECTST-I-STARTPASS, start of pass 2"
$ GOTO GETANL
$NEWMASTER:
$ COPY VECTST.TMP 'P2'
$ WRITE SYS$OUTPUT "%VECTST-I-NEWMASTER, new master file ''P2' created"
$ GOTO QUIT
$ABORT:
$ ABORT=1
$QUIT:
$ N=$SEVERITY
$QUIT2:
$ SET NOON
$ IF F$TYPE(N) .EQS. "" THEN N = 0	! In case we get here via QUIT2
$ IF N .EQ. 1 THEN N=0
$ IF SEVERITY .LT. N THEN SEVERITY=N
$ IF "''F$LOG("MASTER")" .NES. "" THEN CLOSE MASTER
$ IF "''F$LOG("ANLFIL")" .NES. "" THEN CLOSE ANLFIL
$ IF "''F$LOG("SRTANL")" .NES. "" THEN CLOSE SRTANL
$ IF F$SEARCH("VECTST.ANL") .NES. "" THEN DELETE VECTST.ANL;*
$ IF F$SEARCH("VECTST.TMP") .NES. "" THEN DELETE VECTST.TMP;*
$ IF F$SEARCH("VECERR.TMP") .NES. "" THEN DELETE VECERR.TMP;*
$ IF SEVERITY .EQ. 0 THEN WITH := "completed with warnings"
$ IF SEVERITY .EQ. 1 THEN WITH := "completed successfully"
$ IF SEVERITY .GE. 2 THEN WITH := "completed with errors"
$ IF ABORT THEN WITH := "aborted with ^Y"
$ LET := "''F$EXTRACT(SEVERITY,1,"WSEIF???")
$ SEVERITY = SEVERITY + %X10000000
$ WRITE SYS$OUTPUT "%VECTST-''LET'-DONE, analysis ''WITH'"
$ IF VERIFY THEN SET VERIFY
$ EXIT 'SEVERITY
!
! Instructions for use of VECTORTST.COM
!
! VECTORTST.COM is used to ensure that the universal symbols (vector entry
! points) in a shareable image, or global symbols in an object module, do
! not change incompatibly from a base version.  You supply a data
! file that lists each symbol and what its value should be.
! VECTORTST then analyzes the image or object and compares
! the values actually in the image or object against those in the master data 
! file. If there are any discrepancies, such as symbols which have been added,
! deleted or moved, an error is reported.
!
! VECTORTST is designed to be run as part of the system build procedure for
! a component.  Its output is produced in a form that SCAN (the tool that
! scans log files for errors) will report on errors found by VECTORTST, but
! will otherwise ignore a successful test.  It may also be run interactively,
! and cleans up after itself if ^Y is pressed.  During each of the two
! passes, it displays a "progress" report each time 100 symbols have been
! processed, so that you are assured that it is not hung.  Being entirely
! in DCL, it is not very fast.
!
! Parameters:
!
!	P1 is the name of the shareable image or object module to test.  
!	   The default name string is SYS$LIBRARY:VMSRTL.EXE.  Typically, 
!	   you would specify P1 in the form EXE$:FACSHR, or OBJ$:objname.OBJ
!	   for object modules.  It is important that you specify the file
!	   type if it is not .EXE.
!
!	P2 is the name of the master data file containing the names and
!	   offsets of the universal symbols.  The default is
!	   COM$:shrimgVEC.DAT, where "shrimg" is the NAME portion of the
!	   shareable image name.  For the example P1 of EXE$:FACSHR, P2
!	   would be defaulted to COM$:FACSHRVEC.DAT.  Note that if the
!	   default master file name would be invalid, e.g. if the file
!	   being analyzed had more than six characters in its filename,
!	   you must explicitly specify this parameter.
!
!	P3 If P3 is present and is "CREATE", VECTORTST merely creates
!	   a new master file by the name given in P2 from the file being
!	   analyzed.
!
! Form of the master data file:
!
!	The master data file (COM$:imgnamVEC.DAT) is a sequential text file.
!	Records beginning with exclamation points are ignored.  Each symbol
!	is listed on its own record in the form:
!		symbol-offset
!	where:
!	   "symbol" is the name of the symbol.  All letters must
!	      be uppercase.
!	   "offset" is the eight-digit hexadecimal value of
!	      the symbol.  Leading zeroes must be supplied to
!	      pad the offset to eight digits.  However, if the file contains
!	      symbols which are permitted to change offsets (such
!	      as the address of a patch area), the offset is to be specified
!	      as an asterisk.
!
!	Each symbol-value pair must begin in column 1 of the record.  No
!	extraneous characters (blanks, tabs, etc.) may be present.
!
!	Symbols must appear in the file in ascending alphabetic order.  Failure
!	to sort the symbols properly will result in diagnostic messages from
!	VECTORTST.
!
!	Examples:
!
!	   MTH$SQRT_R2-00000408
!	   RTL$$PATCHAREA-*
!
