	[ IDENT ('V04-000'),
{ ++
*****************************************************************************
**									    *
**  COPYRIGHT (c) 1978, 1980, 1982, 1984 BY				    *
**  DIGITAL EQUIPMENT CORPORATION, MAYNARD, MASSACHUSETTS.		    *
**  ALL RIGHTS RESERVED.						    *
** 									    *
**  THIS SOFTWARE IS FURNISHED UNDER A LICENSE AND MAY BE USED AND COPIED   *
**  ONLY IN  ACCORDANCE WITH  THE  TERMS  OF  SUCH  LICENSE  AND WITH THE   *
**  INCLUSION OF THE ABOVE COPYRIGHT NOTICE. THIS SOFTWARE OR  ANY  OTHER   *
**  COPIES THEREOF MAY NOT BE PROVIDED OR OTHERWISE MADE AVAILABLE TO ANY   *
**  OTHER PERSON.  NO TITLE TO AND OWNERSHIP OF  THE  SOFTWARE IS  HEREBY   *
**  TRANSFERRED.							    *
** 									    *
**  THE INFORMATION IN THIS SOFTWARE IS  SUBJECT TO CHANGE WITHOUT NOTICE   *
**  AND  SHOULD  NOT  BE  CONSTRUED AS  A COMMITMENT BY DIGITAL EQUIPMENT   *
**  CORPORATION.							    *
** 									    *
**  DIGITAL ASSUMES NO RESPONSIBILITY FOR THE USE  OR  RELIABILITY OF ITS   *
**  SOFTWARE ON EQUIPMENT WHICH IS NOT SUPPLIED BY DIGITAL.		    *
** 									    *
**									    *
*****************************************************************************




FACILITY:	VAX/VMS EDF (EDIT/FDL) UTILITY

ABSTRACT:	This facility is used to create, modify, and optimize
		FDL specification files.

ENVIRONMENT:	NATIVE/USER MODE

AUTHOR:		Ken F. Henderson Jr.

CREATION DATE:	27-Mar-1981

MODIFIED BY:
		V03-013 RRB0016		Rowland R. Bradley	 6 Mar 1984
			Signal error if insufficient information to do 
			analysis and disallow logging of file creation
			if AUTO_TUNE (/NOINT)

		V03-012 RRB0006		Rowland R. Bradley	12 Jan 1984
			Enable user to specify analysis filename within optimize
			script.

		V03-011	KFH0011		Ken Henderson		 8 Aug 1983
			Changes for seperate compilation.

		V03-010	KFH0010		Ken Henderson		26 Apr 1983
			Modified SET_PROC to set VISIBLE_QUESTION.
			REDESIGN => TOUCHUP.

		V03-009	KFH0009		Ken Henderson		14 Apr 1983
			Added SET_PROC.
			Removed DESIGN_SCRIPT_PROC.

		V03-008	KFH0008		Ken Henderson		20 Jan 1983
			Removed references to DASH.

		V03-007	KFH0007		Ken Henderson		11 Jan 1983
			Modified CREATE_NEW_FDL to output
			"Output not created" message on one
			line, in reverse video, with bell

		V03-006	KFH0006		Ken Henderson		15 Nov 1982
			Added support for Pascal V2

		V03-005	KFH0005		Ken Henderson		8 Sept 1982
			Modified call to Script_option to
			use new QUERY routine.

		V03-004	KFH0004		Ken Henderson		31 March 1982
			Modified CREATE_NEW_FDL to fix
			FT2 QAR 967

		V03-003	KFH0003		Ken Henderson		28 March 1982
			Modified CREATE_NEW_FDL to not output
			FDL file if the definition is empty.

		V03-002	KFH0002		Ken Henderson		23-Mar-1982
			Modified HELP_PROC to fix FT2 QAR 831

		V03-001	KFH0001		Ken Henderson		17-Mar-1982
			Modified a few routines to fix FT2
			QARs 500,510

-- }

ENVIRONMENT ('LIB$:EDFFUNCS'),

INHERIT (

'SYS$LIBRARY:STARLET',
'SHRLIB$:FDLPARDEF',
'LIB$:EDFSDLMSG',
'LIB$:EDFSTRUCT',
'LIB$:EDFCONST',
'LIB$:EDFTYPE',
'LIB$:EDFVAR',
'LIB$:EDFEXTERN',
'LIB$:EDFCHF',
'LIB$:EDFUTIL',
'LIB$:EDFASK',
'LIB$:EDFSHOW',
'LIB$:EDFDESIGN'

)]

MODULE EDFFUNCS (INPUT,OUTPUT);

{ ++

CREATE_NEW_FDL -- Routine to output a new FDL file.

This routine outputs the FDL file to the disk.

CALLING SEQUENCE:

CREATE_NEW_FDL;

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

none

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

none

ROUTINES CALLED:

none

ROUTINE VALUE:

none

SIGNALS:

none

SIDE EFFECTS:

none

-- }

PROCEDURE CREATE_NEW_FDL;

VAR
    TEMP_STRING255		: STRING255;
    FID_BLOCK			: ARRAY [0..2] OF LONG;
    I				: INTEGER;
    J				: INTEGER;

BEGIN

    { +
    Only output the FDL file if the definition is not empty.
    - }
    IF DEF_HEAD = DEF_TAIL THEN

    BEGIN

	FILE_CREATED	:= FALSE;

	WRITELN (CRLF,SHIFT,CONTROL_G,ANSI_REVERSE,
	'Output not created - Current FDL Definition empty.',ANSI_RESET);

    END		{ IF TRUE DEF_HEAD = DEF_TAIL }

    ELSE

    BEGIN

	RES_OUTPUT_FILENAME_DESC		:= NULL_STRING;
	NEW (RES_OUTPUT_FILENAME_DESC.DSC$A_POINTER);
	RES_OUTPUT_FILENAME_DESC.DSC$W_LENGTH	:= 255;
	FLAGS.FDL$V_SIGNAL			:= TRUE;
	FLAGS.FDL$V_$CALLBACK			:= FALSE;

	ISTATUS				:= FDL$CREATE (
						    NL_DEV_DESC,
						    OUTPUT_FILENAME_DESC,
						    DEFAULT_FILENAME_DESC,
						    RES_OUTPUT_FILENAME_DESC,
						    FID_BLOCK,
						    FLAGS
						    );

	IF ODD (ISTATUS) THEN

	BEGIN

	    { +
	    Open his file and initialize it.
	    - }
	    DEST_IS_TERMINAL	:= FALSE;

	    WITH RES_OUTPUT_FILENAME_DESC DO

	    BEGIN

		FOR I := 1 TO 255 DO

		    IF I > DSC$W_LENGTH THEN

			TEMP_STRING255[I]	:= ' '

		    ELSE

			TEMP_STRING255[I]	:= DSC$A_POINTER^[I];

	    END;

	    { +
	    Clear out the terminal in case the terminal is the output.
	    - }
	    IF NOT AUTO_TUNE THEN

	    BEGIN

		OPEN (FDL_DEST,SYS$OUTPUT_NAME,NEW,RECORD_LENGTH := 252);
		CLOSE (FDL_DEST);

	    END;

	    { +
	    Now implement 'granularity'.
	    - }
	    IF ISAM_ORG THEN

		SHUFFLE_AREAS;

	    { +
	    Now open the 'real' FDL file.
	    - }
	    OPEN (FDL_DEST,TEMP_STRING255,OLD);
	    REWRITE (FDL_DEST);

	    { +
	    Put the current definition out to the disk.
	    - }
	    GENERATE_FDL;

	    { +
	    We're done, close the file.
	    - }
	    CLOSE (FDL_DEST);

	    { +
	    Setup to show the created filename on exit.
	    - }
	    FILE_CREATED	:= TRUE;

{	    IF AUTO_TUNE THEN

		EDF$RESET_SCROLL;

}	END;	{ IF ODD (ISTATUS) }

    END;	{ IF FALSE DEF_HEAD = DEF_TAIL }

END;	{ CREATE_NEW_FDL }

{ ++

ADD_FDL_LINE -- Let user add a line_object to the Definition Linked List.

This routine prompts the user for his information and puts it into the
Deifinition.

CALLING SEQUENCE:

ADD_FDL_LINE;

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

SYS$INPUT:

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

The Definition Linked List
DEF_CURRENT

ROUTINES CALLED:

none

ROUTINE VALUE:

none

SIGNALS:

none

SIDE EFFECTS:

none

-- }

PROCEDURE ADD_FDL_LINE;

VAR
    DEF_TEST		: ^LINE_OBJECT;
    SAVE_CURRENT	: ^LINE_OBJECT;
    SAVE		: LINE_OBJECT;
    FOUND_PRI		: BOOLEAN;
    EXISTS		: BOOLEAN;
    PROCEED		: BOOLEAN;

BEGIN

    SAVE.STRING		:= NULL_STRING;
    TEST.STRING		:= NULL_STRING;

    FULL_CHOICE		:= TRUE;
    QUERY (EDF$K_TEST_PRIMARY);

    FULL_CHOICE		:= TRUE;
    ASK_TEST_SECONDARY;

    SAVE		:= TEST;

    { +
    Setup to display definition on the terminal.
    - }
    OPEN	(FDL_DEST,SYS$OUTPUT_NAME,NEW,RECORD_LENGTH := 252);
    REWRITE	(FDL_DEST);

    NEW (DEF_TEST);
    DEF_TEST^		:= TEST;
    DEF_TEST^.FORE	:= NIL;
    DEF_TEST^.BACK	:= NIL;
    SAVE_CURRENT	:= DEF_CURRENT;
    DEF_CURRENT		:= DEF_TEST;

    SHOW_CUR_PRI_SEC (FALSE);

    DEF_CURRENT		:= SAVE_CURRENT;
    DISPOSE (DEF_TEST);

    CLOSE	(FDL_DEST);

    EXISTS	:=  FIND_OBJECT (
    SAVE.OBJECT_TYPE,SAVE.PRIMARY,SAVE.PRINUM,SAVE.SECONDARY,SAVE.SECNUM);

    IF EXISTS THEN

	PROCEED		:= QUERY (EDF$K_CONFIRM)

    ELSE

	PROCEED		:= TRUE;

    IF PROCEED THEN
    
    BEGIN
    
	TEST	:= SAVE;
    
	ASK_TEST_SECONDARY_VALUE;
	
	MAKE_SCRATCH;
    
	DEF_SCRATCH^ := TEST;
    
	IF DEF_SCRATCH^.PRIMARY = TITLE THEN
    
	    DEF_SCRATCH^.OBJECT_TYPE	:= PRI
    
	ELSE
    
	    DEF_SCRATCH^.OBJECT_TYPE	:= SEC;
    
    { **** SUPPORT END OF LINE COMMENTS !!! *** }
	
	INSERT_IN_ORDER (REPLACE_OBJ);
    
	IF TEST.PRIMARY <> TITLE THEN
    
	BEGIN
    
	    { +
	    If there wasn't one of these primaries, make one.
	    - }
	    DEF_CURRENT	:= DEF_HEAD;
	    FOUND_PRI	:= FALSE;
    
	    REPEAT
    
		IF (
		(DEF_CURRENT^.OBJECT_TYPE = PRI)
		AND
		(DEF_CURRENT^.PRIMARY = SAVE.PRIMARY)
		AND
		(DEF_CURRENT^.PRINUM = SAVE.PRINUM)
		) THEN
    
		    FOUND_PRI	:= TRUE
    
		ELSE
    
		    INCR_CURRENT;
    
	    UNTIL (FOUND_PRI OR (DEF_CURRENT = NIL));
    
	    IF NOT FOUND_PRI THEN
    
	    BEGIN
    
		TEST.OBJECT_TYPE	:= PRI;
		TEST.PRIMARY		:= SAVE.PRIMARY;
		TEST.PRINUM		:= SAVE.PRINUM;
		TEST.SECONDARY		:= DUMMY_SECONDARY$;
		TEST.SECNUM		:= 0;
		TEST.STRING		:= NULL_STRING;
		TEST.COMMENT		:= NULL_STRING;
    
		MAKE_SCRATCH;
    
		DEF_SCRATCH^		:= TEST;
    
		INSERT_IN_ORDER (REPLACE_OBJ);
    
	    END;	{ IF NOT FIND_OBJECT }
    
	END;	{ IF TEST.PRIMARY <> TITLE }
    
	CLEAR (SCREEN);
	
	WRITELN (SHIFT,TAB,TAB,ANSI_REVERSE,
	' Resulting Primary Section ',
	ANSI_RESET,CRLF);
	
	OPEN	(FDL_DEST,SYS$OUTPUT_NAME,NEW,RECORD_LENGTH := 252);
	REWRITE	(FDL_DEST);
	
	SHOW_PRIMARY_SECTION (SAVE);
	
	CLOSE (FDL_DEST);
    
    END;	{ IF TRUE PROCEED }

    TEST	:= SAVE;

    QUERY (EDF$K_RETURN);

END;	{ ADD_FDL_LINE }

{ ++

CHECK_DEFAULT -- See if the current default primary exists.

This routine searches the definition and checks to make sure that
the current default it OK.

CALLING SEQUENCE:

CHECK_DEFAULT;

INPUT PARAMETERS:

none

IMPLICIT INPUTS:


OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:


ROUTINES CALLED:


ROUTINE VALUE:

none

SIGNALS:

none

SIDE EFFECTS:

none

-- }

PROCEDURE CHECK_DEFAULT;

VAR
    FOUND_PRIMARY	: BOOLEAN;

BEGIN

    IF DEF_HEAD <> DEF_TAIL THEN

    BEGIN

	{ +
	Does the current default primary exist?
	- }
	DEF_CURRENT		:= DEF_HEAD;
	TEST.OBJECT_TYPE	:= PRI;
	TEST.PRIMARY		:= DEFAULT_PRIMARY;
	TEST.PRINUM		:= DEFAULT_PRINUM;
	FOUND_PRIMARY		:= FALSE;

	REPEAT

	    IF CURRENT_EQ_TEST (TEST,FALSE) THEN

		FOUND_PRIMARY	:= TRUE

	    ELSE

		INCR_CURRENT;

	UNTIL (DEF_CURRENT = NIL) OR FOUND_PRIMARY;

	IF NOT FOUND_PRIMARY THEN

	BEGIN

	    { +
	    Find out what the 1st 'real' primary is.
	    - }
	    DEF_CURRENT		:= DEF_HEAD;

	    IF DEF_CURRENT^.PRIMARY = IDENT THEN

		INCR_CURRENT;

	    { +
	    Set the default up to be the first one that exists.
	    - }
	    DEFAULT_PRIMARY		:= DEF_CURRENT^.PRIMARY;
	    DEFAULT_PRINUM		:= DEF_CURRENT^.PRINUM;
	    INPUT_NUMBER		:= DEFAULT_PRINUM;

	END;

    END;

END;	{ CHECK_DEFAULT }

{ ++

DELETE_FDL_LINE -- Get rid of a line_object.

This routine lets the user find and remove a line_object from the Definition
Linked List.

CALLING SEQUENCE:

DELETE_FDL_LINE;

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

FULL_PROMPT
ANSI_REVERSE
TAB
DEF_HEAD
DEF_CURRENT
SYS$INPUT:

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

FDL_DEST
DEF_CURRENT
SYS$OUTPUT:

ROUTINES CALLED:

CLEAR
ASK_DELETE_OPTION
SHOW_CURRENT
INCR_CURRENT

ROUTINE VALUE:

none

SIGNALS:

none

SIDE EFFECTS:

none

-- }

PROCEDURE DELETE_FDL_LINE;

VAR
    SAVE		: LINE_OBJECT;
    DEF_REM_PRI		: ^LINE_OBJECT;
    REMAINING_PRI	: BOOLEAN;
    REMAINING_SEC	: BOOLEAN;
    NO_MORE_PRI		: BOOLEAN;
    FOUND_IT		: BOOLEAN;

BEGIN

    { +
    If the Definition Linked List is not empty, then do it, else skip it.
    - }
    IF DEF_HEAD <> DEF_TAIL THEN

    BEGIN

	SAVE.STRING		:= NULL_STRING;
	TEST.STRING		:= NULL_STRING;

	CHECK_DEFAULT;

	{ +
	These routines will only return if an existing line_object has been given.
	If 'EXTANT_ONLY' is specified.
	- }
	FULL_CHOICE	:= FALSE;
	QUERY (EDF$K_TEST_PRIMARY);

	NO_MORE_PRI	:= FALSE;

	FULL_CHOICE	:= FALSE;
	ASK_TEST_SECONDARY;

	{ +
	Remember which primary it was.
	- }
	SAVE		:= TEST;

	FOUND_IT	:= FIND_OBJECT (
				TEST.OBJECT_TYPE,TEST.PRIMARY,
				TEST.PRINUM,TEST.SECONDARY,TEST.SECNUM
				);

	{ +
	Setup to display definition on the terminal.
	- }
	OPEN	(FDL_DEST,SYS$OUTPUT_NAME,NEW,RECORD_LENGTH := 252);
	REWRITE	(FDL_DEST);

	SHOW_CUR_PRI_SEC (TRUE);

	CLOSE	(FDL_DEST);

	QUERY (EDF$K_RETURN) ;

	DELETE_CURRENT;

	IF TEST.PRIMARY <> TITLE THEN

	BEGIN

	    { +
	    Look through the list to see what remains of this primary.
	    - }
	    REMAINING_PRI	:= FALSE;
	    REMAINING_SEC	:= FALSE;

	    DEF_CURRENT	:= DEF_HEAD;

	    REPEAT

		IF (
		(DEF_CURRENT^.PRIMARY = SAVE.PRIMARY)
		AND
		(DEF_CURRENT^.PRINUM = SAVE.PRINUM)
		) THEN

		BEGIN

		    IF DEF_CURRENT^.OBJECT_TYPE = PRI THEN

		    BEGIN

			REMAINING_PRI	:= TRUE;
			DEF_REM_PRI		:= DEF_CURRENT;

		    END

		    ELSE IF DEF_CURRENT^.OBJECT_TYPE = SEC THEN

			REMAINING_SEC	:= TRUE;

		END;

		INCR_CURRENT;

	    UNTIL (REMAINING_PRI AND REMAINING_SEC) OR (DEF_CURRENT = NIL);

	    IF (
	    (REMAINING_PRI)
	    AND
	    (NOT REMAINING_SEC)
	    ) THEN

	    BEGIN

		WRITELN (CRLF,SHIFT,ANSI_REVERSE,
		' No more Secondaries with this Primary, deleting Primary. ',
		ANSI_RESET);

		DEF_CURRENT		:= DEF_REM_PRI;
		DELETE_CURRENT;
		NO_MORE_PRI		:= TRUE;

		LIB$WAIT (3.0);

	    END

	    ELSE IF (
	    (NOT REMAINING_PRI)
	    AND
	    (REMAINING_SEC)
	    ) THEN

		{ NULL-STATEMENT }

	    ELSE IF (
	    (NOT REMAINING_PRI)
	    AND
	    (NOT REMAINING_SEC)
	    ) THEN

	    BEGIN

		WRITELN (CRLF,SHIFT,ANSI_REVERSE,
		' This Primary Section has now been entirely Deleted. ',
		ANSI_RESET);
		NO_MORE_PRI		:= TRUE;

		LIB$WAIT (2.0);

	    END

	    ELSE IF (
	    (REMAINING_PRI)
	    AND
	    (REMAINING_SEC)
	    ) THEN

	    BEGIN

		CLEAR (SCREEN);

		WRITELN (SHIFT,TAB,TAB,ANSI_REVERSE,
		' Resulting Primary Section ',
		ANSI_RESET,CRLF);

		OPEN	(FDL_DEST,SYS$OUTPUT_NAME,NEW,
			    RECORD_LENGTH := 252);
		REWRITE	(FDL_DEST);

		SHOW_PRIMARY_SECTION (SAVE);

		CLOSE (FDL_DEST);

	    END;

	    TEST.PRIMARY	:= SAVE.PRIMARY;
	    TEST.PRINUM		:= SAVE.PRINUM;

	    IF NOT NO_MORE_PRI THEN

		QUERY (EDF$K_RETURN);

	END;	{ IF TEST.PRIMARY <> TITLE }

    END		{ IF TRUE DEF_HEAD <> DEF_TAIL }

    ELSE

    BEGIN

	WRITELN (
	SHIFT,ANSI_REVERSE,' The Current Definition is Empty. ',ANSI_RESET);

	LIB$WAIT (3.0);

    END;	{ IF FALSE DEF_HEAD <> DEF_TAIL }

END;	{ DELETE_FDL_LINE }

{ ++

MODIFY_FDL_LINE -- Modify an extant line_object.

This routine lets the user view and change the contents of a particular
line_object in the Definition Linked List.

CALLING SEQUENCE:

MODIFY_FDL_LINE;

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

SYS$INPUT:
The Definition Linked List

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

SYS$OUTPUT:
The Definition Linked List

ROUTINES CALLED:

none

ROUTINE VALUE:

none

SIGNALS:

none

SIDE EFFECTS:

none

-- }

PROCEDURE MODIFY_FDL_LINE;

VAR
    SAVE		: LINE_OBJECT;
    FOUND_IT		: BOOLEAN;

BEGIN

    { +
    If the Definition Linked List is not empty, then do it, else skip it.
    - }
    IF DEF_HEAD <> DEF_TAIL THEN

    BEGIN

	SAVE.STRING		:= NULL_STRING;
	SAVE.COMMENT		:= NULL_STRING;
	TEST.STRING		:= NULL_STRING;
	TEST.COMMENT		:= NULL_STRING;

	CHECK_DEFAULT;

	{ +
	These routines will only return if an existing line_object has been given.
	If 'EXTANT_ONLY' is specified.
	- }
	FULL_CHOICE	:= FALSE;
	QUERY (EDF$K_TEST_PRIMARY);

	FULL_CHOICE	:= FALSE;
	ASK_TEST_SECONDARY;

	FOUND_IT	:= FIND_OBJECT (
				    TEST.OBJECT_TYPE,TEST.PRIMARY,TEST.PRINUM,
				    TEST.SECONDARY,TEST.SECNUM
				    );

	SAVE		:= DEF_CURRENT^;

	{ +
	Setup to display definition on the terminal.
	- }
	OPEN	(FDL_DEST,SYS$OUTPUT_NAME,NEW,RECORD_LENGTH := 252);
	REWRITE	(FDL_DEST);

	SHOW_CUR_PRI_SEC (TRUE);

	CLOSE	(FDL_DEST);

	TEST	:= SAVE;

	ASK_TEST_SECONDARY_VALUE;

	MAKE_SCRATCH;

	DEF_SCRATCH^	:= TEST;

	IF DEF_SCRATCH^.PRIMARY = TITLE THEN

	    DEF_SCRATCH^.OBJECT_TYPE	:= PRI

	ELSE

	    DEF_SCRATCH^.OBJECT_TYPE	:= SEC;

	INSERT_IN_ORDER (REPLACE_OBJ);

	CLEAR (SCREEN);

	WRITELN (SHIFT,TAB,TAB,ANSI_REVERSE,
	' Resulting Primary Section ',
	ANSI_RESET,CRLF);

	OPEN	(FDL_DEST,SYS$OUTPUT_NAME,NEW,RECORD_LENGTH := 252);
	REWRITE	(FDL_DEST);

	SHOW_PRIMARY_SECTION (SAVE);

	CLOSE (FDL_DEST);

	TEST	:= SAVE;

	QUERY (EDF$K_RETURN);

    END		{ IF TRUE DEF_HEAD <> DEF_TAIL }

    ELSE

    BEGIN

	WRITELN (
	SHIFT,ANSI_REVERSE,' The Current Definition is Empty. ',ANSI_RESET);

	LIB$WAIT (3.0);

    END;	{ IF FALSE DEF_HEAD <> DEF_TAIL }

END;	{ MODIFY_FDL_LINE }

{ ++

HELP_PROC -- Prompt for help and process it.

This routine interfaces to the LBR$OUTPUT_HELP routine to access the
help library.

CALLING SEQUENCE:

HELP_PROC;

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

The help library: SYS$LIBRARY:EDF.HLB

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

SYS$OUTPUT: (through lib$put_output)

ROUTINES CALLED:

LBR$OUTPUT_HELP

ROUTINE VALUE:

none

SIGNALS:

none

SIDE EFFECTS:

none

-- }

PROCEDURE HELP_PROC;

BEGIN

    { +
    Call the Librarian's help routine that will prompt the user for any
    additional information.
    - }
    ISTATUS	:= LBR$OUTPUT_HELP (
				    IADDRESS (LIB$PUT_OUTPUT),
				    LINE_WIDTH,
				    0,
				    EDFHLP_STRING,
				    0,
				    IADDRESS (LIB$GET_INPUT)
				    );

    { +
    Show what the problem is.
    - }
    IF NOT ODD (ISTATUS) THEN

	LIB$SIGNAL (ISTATUS,0,0,0);

END;	{ HELP_PROC }

{ ++

VERIFY_ISAM_DEFINITION -- Check the linked list.

This routine verifies that the FDL definition is there and is indexed.

CALLING SEQUENCE:

boolean := VERIFY_ISAM_DEFINITION;

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

none

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

none

ROUTINES CALLED:

none

ROUTINE VALUE:

true or false depending upon the checking

SIGNALS:

none

SIDE EFFECTS:

none

-- }

FUNCTION VERIFY_ISAM_DEFINITION : BOOLEAN;

VAR
    NON_EMPTY	: BOOLEAN;
    ISAM_FDL	: BOOLEAN;

BEGIN

    NON_EMPTY	:= FALSE;
    ISAM_FDL	:= FALSE;

    { +
    Check for a definition that has more than an Ident.
    - }
    IF (
    (DEF_HEAD <> DEF_TAIL)
    OR
    (DEF_HEAD^.PRIMARY <> IDENT)
    ) THEN

    BEGIN

	NON_EMPTY	:= TRUE;

	{ +
	See what type of file the definition is now.
	1st, find the line_object that tells that.
	- }
	IF FIND_OBJECT (SEC,FILE$,0,ORGANIZATION,0) THEN

	BEGIN

	    IF DEF_CURRENT^.QUALIFIER = FDL$C_IDX THEN

		ISAM_FDL	:= TRUE;

	END;	{ IF TRUE FIND_OBJECT () }

	IF NOT ISAM_FDL THEN

	BEGIN

	    WRITELN (SHIFT,ANSI_REVERSE,
	    ' The current file organization is not Indexed. ',
	    ANSI_RESET);

	    LIB$WAIT (3.0);

	END;	{ IF FALSE ISAM_FDL }

    END	{ IF TRUE (DEF_HEAD <> DEF_TAIL) OR (DEF_HEAD^.PRIMARY <> IDENT) }

    ELSE

    IF NOT AUTO_TUNE THEN
	BEGIN

	{ +
	Slap the user's wrist.
	- }
	WRITELN (SHIFT,ANSI_REVERSE,
	' The current FDL Definition is empty. ',
	ANSI_RESET);

	LIB$WAIT (3.0);

	END
    ELSE
	BEGIN
	LIB$SIGNAL (EDF$_INSFANL,0,0,0); {no definition like above}
 	END;


    { +
    We must have something, and that something must be indexed.
    - }
    VERIFY_ISAM_DEFINITION	:= (NON_EMPTY AND ISAM_FDL);

END;	{ VERIFY_ISAM_DEFINITION }

{ ++

REDESIGN_SCRIPT_PROC -- Redesign a definition.

This routine allows old definitions to done over.

CALLING SEQUENCE:

REDESIGN_SCRIPT_PROC;

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

none

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

none

ROUTINES CALLED:

INDEXED_DESIGN

ROUTINE VALUE:

none

SIGNALS:

none

SIDE EFFECTS:

none

-- }

PROCEDURE REDESIGN_SCRIPT_PROC;

BEGIN

    IF VERIFY_ISAM_DEFINITION THEN

	INDEXED_DESIGN (TRUE,FALSE);

END;	{ REDESIGN_SCRIPT_PROC }

{ ++

ADD_KEY_SCRIPT_PROC -- Define a new key.

This routine allows new keys to be added to the definition.

CALLING SEQUENCE:

ADD_KEY_SCRIPT_PROC;

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

none

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

none

ROUTINES CALLED:

REDESIGN_FDL

ROUTINE VALUE:

none

SIGNALS:

none

SIDE EFFECTS:

none

-- }

PROCEDURE ADD_KEY_SCRIPT_PROC;

BEGIN

    IF VERIFY_ISAM_DEFINITION THEN

    BEGIN

	{ +
	See what we have already.
	- }
	SCAN_DEFINITION (FALSE);

	{ +
	Set the key that we have to redesign.
	- }
	IDATA[EDF$K_ACTIVE_KEY]	:= HIGH_KEY;

	IF FOUND_0 THEN

	    IDATA[EDF$K_ACTIVE_KEY]	:= IDATA[EDF$K_ACTIVE_KEY] + 1;

	{ +
	Go model and select those parameters.
	- }
	INDEXED_DESIGN (TRUE,TRUE);

    END;	{ IF TRUE VERIFY_ISAM_DEFINITION }

END;	{ ADD_KEY_SCRIPT_PROC }

{ ++

DELETE_KEY_SCRIPT_PROC -- Remove a key definition from the Link List.

This routine allows key definitions to be removed - along with the
accompanying area proposals.

CALLING SEQUENCE:

DELETE_KEY_SCRIPT_PROC;

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

none

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

none

ROUTINES CALLED:

INDEXED_DESIGN

ROUTINE VALUE:

none

SIGNALS:

none

SIDE EFFECTS:

none

-- }

PROCEDURE DELETE_KEY_SCRIPT_PROC;

    PROCEDURE DELETE_SECTION (SECTION : PRIMARY_TYPE; SECT_NUM : INTEGER);

	BEGIN

	    IF FIND_OBJECT (PRI,SECTION,SECT_NUM,DUMMY_SECONDARY$,0) THEN

	    BEGIN

		WRITELN (SHIFT,'Deleting ',
		SECTION:PRIMARY_WIDTH[SECTION],SECT_NUM:3,' primary section.');
		QUERY (EDF$K_RETURN);
		DELETE_PRIMARY_SECTION (SECTION,SECT_NUM);

	    END;	{ IF TRUE FIND_OBJECT () }

	END;	{ DELETE_AREA }

VAR
    L0_AREA	: INTEGER;
    L1_AREA	: INTEGER;
    LX_AREA	: INTEGER;

BEGIN

    IF VERIFY_ISAM_DEFINITION THEN

    BEGIN

	{ +
	See what we have.
	- }
	SCAN_DEFINITION (TRUE);

	IF HIGH_KEY <> 0 THEN

	BEGIN

	    { +
	    See which areas are used by this key.
	    - }
	    IF FIND_OBJECT (SEC,KEY,HIGH_KEY,DATA_AREA,0) THEN

		L0_AREA		:= DEF_CURRENT^.NUMBER

	    ELSE

		L0_AREA		:= -1;

	    IF FIND_OBJECT (SEC,KEY,HIGH_KEY,LEVEL1_INDEX_AREA,0) THEN

		L1_AREA		:= DEF_CURRENT^.NUMBER

	    ELSE

		L1_AREA		:= -1;

	    IF FIND_OBJECT (SEC,KEY,HIGH_KEY,INDEX_AREA,0) THEN

		LX_AREA		:= DEF_CURRENT^.NUMBER

	    ELSE

		LX_AREA		:= -1;

	    { +
	    Eliminate those areas that are also used by other keys.
	    - }
	    DEF_CURRENT		:= DEF_HEAD;

	    WITH DEF_CURRENT^ DO

	    BEGIN

		REPEAT

		    IF (
		    (PRIMARY = KEY)
		    AND
		    (PRINUM <> HIGH_KEY)
		    AND
		    (SECONDARY = DATA_AREA)
		    AND
		    (NUMBER = L0_AREA)
		    ) THEN

			L0_AREA	:= -1;

		    IF (
		    (PRIMARY = KEY)
		    AND
		    (PRINUM <> HIGH_KEY)
		    AND
		    (SECONDARY = LEVEL1_INDEX_AREA)
		    AND
		    (NUMBER = L1_AREA)
		    ) THEN

			L1_AREA	:= -1;

		    IF (
		    (PRIMARY = KEY)
		    AND
		    (PRINUM <> HIGH_KEY)
		    AND
		    (SECONDARY = INDEX_AREA)
		    AND
		    (NUMBER = LX_AREA)
		    ) THEN

			LX_AREA	:= -1;

		    INCR_CURRENT;

		UNTIL DEF_CURRENT = NIL;

	    END;	{ DO }

	    { +
	    Get rid of the key definition.
	    - }
	    DELETE_SECTION (KEY,HIGH_KEY);

	    { +
	    Get rid of any now obsolete area definitions.
	    - }
	    IF NOT (L0_AREA < 0) THEN

		DELETE_SECTION (AREA,L0_AREA);

	    IF NOT (L1_AREA < 0) THEN

		DELETE_SECTION (AREA,L1_AREA);

	    IF NOT (LX_AREA < 0) THEN

		DELETE_SECTION (AREA,LX_AREA);

	    WRITELN (SHIFT,'End of Delete_Key_Indexed Script.');
	    QUERY (EDF$K_RETURN);

	END

	ELSE

	BEGIN

	    WRITELN (SHIFT,ANSI_REVERSE,
	    ' This script will not delete the Primary Key. ',
	    ANSI_RESET);

	    LIB$WAIT (3.0);

	END;

    END;	{ IF TRUE VERIFY_ISAM_DEFINITION }

END;	{ DELETE_KEY_SCRIPT_PROC }

{ ++

OPTIMIZE_SCRIPT_PROC -- Optimize extant definitions.

This routine allows old definitions to modified and optimized.

CALLING SEQUENCE:

OPTIMIZE_SCRIPT_PROC;

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

none

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

none

ROUTINES CALLED:

none

ROUTINE VALUE:

none

SIGNALS:

none

SIDE EFFECTS:

none

-- }

PROCEDURE OPTIMIZE_SCRIPT_PROC;

VAR
    AN_KEY_FOUND	: BOOLEAN;

BEGIN

    IF NOT ANALYSIS_SPECIFIED THEN

    BEGIN
	IF NOT (AUTO_TUNE) THEN
	    WRITELN (SHIFT,
	    'An Input Analysis File is necessary for Optimizing Keys.',
	    CRLF_SHIFT)
	ELSE 	
	{ + exit since nointerative and no analysis file
	- }
	    LIB$STOP (EDF$_INSFANL,0,0,0);

	VISIBLE_QUESTION	:= TRUE;

	QUERY (EDF$K_ANALYSIS);

	VISIBLE_QUESTION	:= FALSE;

	ANALYSIS_SPECIFIED	:= TRUE;	

    END;

    INPUT_ANALYSIS_FILE;
	
    AN_KEY_FOUND	:= FALSE;

    POINT_AT_ANALYSIS;

    DEF_CURRENT	:= DEF_HEAD;

    REPEAT

	IF DEF_CURRENT^.PRIMARY = ANALYSIS_OF_KEY THEN

	    AN_KEY_FOUND	:= TRUE;

	INCR_CURRENT;

    UNTIL (AN_KEY_FOUND = TRUE) OR (DEF_CURRENT = NIL);

    POINT_AT_DEFINITION;

    IF AN_KEY_FOUND THEN

    BEGIN

	OPTIMIZING	:= TRUE;
	REDESIGN_SCRIPT_PROC;

    END

    ELSE

    BEGIN

    IF NOT (AUTO_TUNE) THEN
    BEGIN
	    WRITELN (SHIFT,
	    'The Analysis File must contain ANALYSIS_OF_KEY primary sections.');
	    WRITELN (SHIFT,
	    'The DCL command "ANALYZE/RMS_FILE/FDL" produces Analysis Files.');

	    CLEAR (PAUSE);
    END
    END;

    OPTIMIZING	:= FALSE;

END;	{ OPTIMIZE_SCRIPT_PROC }

{ ++

INVOKE_SCRIPT -- Start up a series of questions.

This routine dispatches to the script procedures.

CALLING SEQUENCE:

INVOKE_SCRIPT;

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

IDATA[EDF$K_SCRIPT_OPTION]
SYS$INPUT_ERROR
SYS$INPUT:

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

SYS$INPUT_ERROR
TEMP_FULL_PROMPT

ROUTINES CALLED:

OPTIMIZE_SCRIPT_PROC
DESIGN_SCRIPT_PROC

ROUTINE VALUE:

none

SIGNALS:


SIDE EFFECTS:

none

-- }

PROCEDURE INVOKE_SCRIPT;

BEGIN

    { +
    Reset so 1st (DCL) script only gets done once.
    - }
    IDATA[EDF$K_FIRST_SCRIPT]	:= EDF$K_ZERO_SCRIPT;

    { +
    Prompt for the desired script if we don't already have one. (from DCL)
    - }
    IF IDATA[EDF$K_SCRIPT_OPTION] = EDF$K_ZERO_SCRIPT THEN

    BEGIN

	{ +
	See which script the user wants.
	- }
	QUERY (EDF$K_SCRIPT_OPTION);

    END		{ IF TRUE IDATA[EDF$K_SCRIPT_OPTION] = EDF$K_ZERO_SCRIPT }

    ELSE

    BEGIN

	IF NOT AUTO_TUNE THEN

	BEGIN

	    CLEAR (SCREEN);
	    WRITE (SHIFT,TAB,TAB,ANSI_REVERSE);

	    CASE IDATA[EDF$K_SCRIPT_OPTION] OF

		EDF$K_ADD_KEY_FDL :	WRITE (' Add_Key');
		EDF$K_DELETE_KEY_FDL :	WRITE (' Delete_Key');
		EDF$K_IDX_DESIGN_FDL :	WRITE (' Indexed');
		EDF$K_SEQ_DESIGN_FDL :	WRITE (' Sequential');
		EDF$K_REL_DESIGN_FDL :	WRITE (' Relative');
		EDF$K_OPTIMIZE_FDL :	WRITE (' Optimize');
		EDF$K_REDESIGN_FDL :	WRITE (' Touchup');

	    OTHERWISE

		{ NULL-STATEMENT } ;

	    END;	{ CASE }

	    WRITELN (' Script ',ANSI_RESET,CRLF);

	END;	{ IF NOT AUTO_TUNE }

    END;	{ IF FALSE IDATA[EDF$K_SCRIPT_OPTION] = EDF$K_ZERO_SCRIPT }

    TAKE_DEFAULTS	:= TRUE;

    CASE IDATA[EDF$K_SCRIPT_OPTION] OF

	EDF$K_IDX_DESIGN_FDL :

				BEGIN

				    WARN_OF_ERASE;
				    INIT_DEF;
				    INDEXED_DESIGN (FALSE,FALSE);

				END;

	EDF$K_SEQ_DESIGN_FDL :

				BEGIN

				    WARN_OF_ERASE;
				    INIT_DEF;
				    SEQ_REL_WORK;
				    SEQ_DEF;

				END;

	EDF$K_REL_DESIGN_FDL :

				BEGIN

				    WARN_OF_ERASE;
				    INIT_DEF;
				    SEQ_REL_WORK;
				    REL_DEF;

				END;

	EDF$K_ADD_KEY_FDL :	ADD_KEY_SCRIPT_PROC;

	EDF$K_DELETE_KEY_FDL :	DELETE_KEY_SCRIPT_PROC;

	EDF$K_OPTIMIZE_FDL :	OPTIMIZE_SCRIPT_PROC;

	EDF$K_REDESIGN_FDL :	REDESIGN_SCRIPT_PROC;

    OTHERWISE

	{ NULL-STATEMENT } ;

    END;	{ CASE }

    TAKE_DEFAULTS	:= FALSE;

END;	{ INVOKE_SCRIPT }

{ ++

SET_PROC -- Set the characteristics of the FDL Editor.

This routine asks which characteristics are to be set and sets them.

CALLING SEQUENCE:

SET_PROC;

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

SYS$INPUT_ERROR
SYS$INPUT:

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

SYS$INPUT_ERROR

ROUTINES CALLED:


ROUTINE VALUE:

none

SIGNALS:


SIDE EFFECTS:

none

-- }

PROCEDURE SET_PROC;

BEGIN

    VISIBLE_QUESTION	:= TRUE;

    QUERY (EDF$K_SET_FUNCTION);

    CASE IDATA[EDF$K_SET_FUNCTION] OF

	EDF$K_SET_DISPLAY :	QUERY (EDF$K_SURFACE_OPTION);
	EDF$K_SET_EMPHASIS :	QUERY (EDF$K_BUCKET_WEIGHT);
	EDF$K_SET_GRANULARITY :	QUERY (EDF$K_GRANULARITY);
	EDF$K_SET_RESPONSES :	QUERY (EDF$K_RESPONSES);
	EDF$K_SET_PROMPTING :	QUERY (EDF$K_PROMPTING);
	EDF$K_SET_ANALYSIS :	QUERY (EDF$K_ANALYSIS);
	EDF$K_SET_OUTPUT :	QUERY (EDF$K_OUTPUT);

	EDF$K_SET_NUMBER_KEYS :

	BEGIN

	    QUERY (EDF$K_NUMBER_KEYS);
	    NUMBER_KEYS_SET	:= TRUE;

	END;

    OTHERWISE

	{ NULL-STATEMENT } ;

    END;	{ CASE }

    VISIBLE_QUESTION	:= FALSE;

END;	{ SET_PROC }

END.
    { End of file: SRC$:EDFFUNCS.PAS }
