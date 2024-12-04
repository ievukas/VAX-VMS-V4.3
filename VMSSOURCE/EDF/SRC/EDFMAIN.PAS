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

		V03-011	KFH0011		Ken Henderson		 8 Aug 1983
			Changes for seperate compilation.

		V03-010	KFH0010		Ken Henderson		26 Apr 1983
			Added ADD_KEY, DELETE_KEY scripts.
			Transferred some initializations from
			INIT_EDITOR to EDFVAR. Changed 'redesign'
			to 'touchup'.

		V03-009	KFH0009		Ken Henderson		14 Apr 1983
			Added SET_FUNCTION, RESPONSES,
			GRANULARITY, PROMPTING, JOURNAL_ENABLED.

		V03-008	KFH0008		Ken Henderson		20 Jan 1983
			Removed references to DASH.

		V03-007	KFH0007		Ken Henderson		30 Dec 1982
			Finished support of Pascal V2.

		V03-006	KFH0006		Ken Henderson		22 Nov 1982
			Added support for Pascal V2.
			Added support for additional FILE and
			CONNECT attributes.

		V03-005	KFH0005		Ken Henderson		8 Sept 1982
			Modified references to many variables
			to fit with database reorganization.

		V03-004	KFH0003		Ken Henderson		26-Mar-1982
			Modified Mainline code to establish
			the CTRLZ handler before asking to
			continue after an error parsing the
			FDL definition file - QAR 885.

		V03-002	KFH0002		Ken Henderson		23-Mar-1982
			Modified routines INPUT_FDL_FILE and
			INPUT_ANALYSIS_FILE and the mainline
			code to fix FT2 QARs 694,699

		V03-001	KFH0001		Ken Henderson		17-Mar-1982
			Reset TEMP_FULL_PROMPT to false in the main
			loop. (dispatch_function)

-- }

{ ++
This is the list of environments
-- }

INHERIT (

'SYS$LIBRARY:STARLET',		{ System definitions }
'SHRLIB$:FDLPARDEF',		{ FDL facility definitions }
'SHRLIB$:FDLSDLMSG',		{ FDL Message definitions }
'LIB$:EDFSTRUCT',		{ EDF Tparse and other definitions }
'LIB$:EDFSDLMSG',		{ EDF Message definitions }

'LIB$:EDFCONST',
'LIB$:EDFTYPE',
'LIB$:EDFVAR',
'LIB$:EDFEXTERN',
'LIB$:EDFCHF',
'LIB$:EDFUTIL',
'LIB$:EDFASK',
'LIB$:EDFSHOW',
'LIB$:EDFDESIGN',
'LIB$:EDFFUNCS'

)]

PROGRAM EDF (INPUT,OUTPUT);

{ ++

INIT_EDITOR -- Initialize EDF upon startup.

This is the setup code to create the initial conditions for EDF.

CALLING SEQUENCE:

INIT_EDITOR;

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

DCL (through the CLI$ routines)

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

EDITING
ANSI_RESET
ANSI_BOLD
ANSI_UNDERSCORE
ANSI_BLINK
ANSI_REVERSE
NULL_STRING4
SHIFT
LOW_SHIFT
TERMINAL_SPEED
RMS_INPUT_ERROR
VID_TERM
DEV_TYPE
LINE_WIDTH
LINES_PER_PAGE
VIDEO_TERMINAL
NULL_CHAR
CONTROL_G
CONTROL_W
CONTROL_Z
TAB
CRLF
ESCAPE
QUESTION_MARK
FDL_BLOCK
FDL$AL_BLOCK
EDF$GL_PROT_MASK
EDF$GL_FID1
EDF$GL_FID2
EDF$GL_FID3
EDF$GL_UIC_GROUP
EDF$GL_UIC_MEMBER
EDF$AB_STRING
EDF$AB_COMMENT
LIB$PUT_OUTPUT_PTR
LIB$GET_INPUT_PTR
DEF_CURRENT
DEF_HEAD
DEF_TAIL
DEF_PRED
DEF_SUCC
INPUT_FILENAME_DESC
OUTPUT_FILENAME_DESC
ANALYSIS_FILENAME_DESC
IDATA[EDF$K_FIRST_SCRIPT]
FULL_PROMPT

ROUTINES CALLED:

EDF$TERM_SETUP
ESTABLISH
LIB$SIGNAL
CLI$GET_VALUE
CLI$PRESENT

ROUTINE VALUE:

none

SIGNALS:

EDF$_SMALLPAGE - if term screen size too small

SIDE EFFECTS:

EDF is initialized.

-- }

PROCEDURE INIT_EDITOR;

VAR
    TEMP_DESCRIPTOR	: DESCRIPTOR;
    I			: INTEGER;

BEGIN

    { +
    See if the user wants batch mode or interactive.
    - }
    IF NOT (ODD (CLI$PRESENT ('INTERACTIVE'))) THEN

    { +
    At this point, the user has specified /NOINTERACTIVE and
    wants a quick, automatic tuneup for his file.
    - }
    BEGIN

	TAKE_DEFAULTS				:= TRUE;
	AUTO_TUNE				:= TRUE;
	JOURNAL_ENABLED				:= FALSE;
	QTAB[EDF$K_RETURN].DEFAULT_OK		:= TRUE;
	IDATA[EDF$K_RESPONSES]			:= EDF$K_AUTO;
	IDATA[EDF$K_FIRST_SCRIPT]		:= EDF$K_OPTIMIZE_FDL;
	QTAB[EDF$K_CURRENT_FUNCTION].DEFAULT	:= EDF$K_QUIT;
	QTAB[EDF$K_DESIGN_CYCLE].DEFAULT	:= EDF$K_FINIS;
	VIDEO_TERMINAL				:= FALSE;
	DEC_CRT					:= FALSE;
	ANSI_CRT				:= FALSE;
	REGIS					:= FALSE;

    END		{ IF TRUE NOT (ODD (CLI$PRESENT ('INTERACTIVE'))) }

    ELSE

    BEGIN

	{ +
	Do initialization on the terminal. Get its speed, setup exit handler,
	Also check to make sure that indeed the
	input is a terminal (and STOPs if not) and if the terminal isn't a scope,
	then it sets the page length to 16
	(as required by hardcopy surface plots).

	*******************
	The call to EDF$TERM_SETUP Must come BEFORE ANY calls to the
	SCREEN PACKAGE!!!
	*******************

	- }
	TERMINAL_SPEED	:= EDF$TERM_SETUP;

	{ +
	EDF$TERM_SETUP returns a status of EDF$_DEVCLASS if SYS$INPUT is
	not a terminal. In that case, see if the magic logical name
	EDF$$PLAYBACK_INPUT is defined. If so, then set the terminal speed
	to be 2400 baud and continue, if the logical is not defined,
	exit with the DEVCLASS status.
	NOTE THAT THE LOGICAL NAME "EDF$$PLAYBACK_INPUT" IS NOT SUPPORTED
	FOR CUSTOMERS AND IS USED INTERNALLY ONLY FOR REGRESSION TESTING!!!
	- }
	IF LIB$MATCH_COND (TERMINAL_SPEED,EDF$_DEVCLASS) THEN

	BEGIN

	    TEMP_STATUS	:= $TRNLOG ('EDF$$PLAYBACK_INPUT',,TEMP_STRING255);

	    IF LIB$MATCH_COND (TEMP_STATUS,SS$_NOTRAN) THEN

		LIB$STOP (EDF$_DEVCLASS,0,0,0)

	    ELSE IF LIB$MATCH_COND (TEMP_STATUS,SS$_NORMAL) THEN

		TERMINAL_SPEED	:= TT$C_BAUD_2400;

	END;

	{ +
	Set up ^C ast routine.
	- }
	EDF$CTRLCAST;

	{ +
	First find out what terminal characteristics we have.
	- }
	LIB$SCREEN_INFO (
			    SCREEN_FLAGS,
			    DEV_TYPE,
			    LINE_WIDTH,
			    LINES_PER_PAGE
			    );

	{ +
	Instead of using the actual terminal type,
	we'll just test on deccrt or not.
	- }
	VIDEO_TERMINAL		:= SCREEN_FLAGS.SCR$V_SCREEN;
	DEC_CRT			:= SCREEN_FLAGS.SCR$V_DECCRT;
	ANSI_CRT		:= SCREEN_FLAGS.SCR$V_ANSICRT;
	REGIS			:= SCREEN_FLAGS.SCR$V_REGIS;

	{ +
	See if we have enough room on the terminal.
	- }
	IF (
	(LINE_WIDTH < MINIMUM_TERM_WIDTH)
	OR
	(VIDEO_TERMINAL AND (LINES_PER_PAGE < MINIMUM_VIDEO_PAGE))
	) THEN

	    { +
	    Not enough room!
	    - }
	    LIB$SIGNAL (EDF$_SMALLPAGE,2,LINE_WIDTH,LINES_PER_PAGE);

	OPEN	(OUTPUT,SYS$OUTPUT_NAME,NEW,RECORD_LENGTH := 2148);
	REWRITE	(OUTPUT);

	{ +
	Open the journal file, if it's requested.
	NOTE THAT THE LOGICAL NAME 'EDF$$JOURNAL_INPUT' IS NOT SUPPORTED FOR
	CUSTOMERS, AND IS USED INTERNALLY ONLY FOR REGRESSION TESTING.
	- }
	TEMP_STATUS	:= $TRNLOG ('EDF$$JOURNAL_INPUT',,JOURNAL_FILENAME);

	JOURNAL_ENABLED	:= (
				(LIB$MATCH_COND (TEMP_STATUS,SS$_NORMAL))
				AND
				(NOT LIB$MATCH_COND (TEMP_STATUS,SS$_NOTRAN))
				);

	IF JOURNAL_ENABLED THEN

	BEGIN

	    OPEN	(
		    FILE_VARIABLE := JOURNAL_FILE,
		    FILE_NAME := JOURNAL_FILENAME,
		    HISTORY := NEW,
		    RECORD_LENGTH := 255,
		    RECORD_TYPE := VARIABLE
		    );
	    REWRITE	(JOURNAL_FILE);

	END;

    END;	{ IF FALSE (NOT ODD (CLI$PRESENT ('INTERACTIVE'))) }

    { +
    If we don't have an ANSI terminal (VT100-series and up), then zero out the
    video attribute arrays.
    - }
    IF NOT DEC_CRT THEN

    BEGIN

	FOR I := 1 TO 4 DO

	BEGIN

	    ANSI_RESET[I]		:= NULL_CHAR;
	    ANSI_BOLD[I]		:= NULL_CHAR;
	    ANSI_UNDERSCORE[I]		:= NULL_CHAR;
	    ANSI_BLINK[I]		:= NULL_CHAR;
	    ANSI_REVERSE[I]		:= NULL_CHAR;

	END;

    END;	{ IF NOT DEC_CRT }

    { +
    If we have more than 80 chars per line, we may have to shift everything
    over to the right. (if we also have a video terminal)
    - }
    IF (LINE_WIDTH > EDF$C_SHIFTPOINT) AND VIDEO_TERMINAL THEN

    BEGIN

	SHIFT[2]		:= TAB;
	SHIFT[3]		:= TAB;
	SHIFT[4]		:= TAB;
	CRLF_SHIFT[4]		:= TAB;
	CRLF_SHIFT[5]		:= TAB;
	CRLF_SHIFT[6]		:= TAB;

    END;

    { +
    The 'under-graph' text comes out in graphics mode for Regis devices.
    - }
    IF REGIS THEN

    BEGIN

	LOW_SHIFT[1]		:= NULL_CHAR;
	LOW_SHIFT[2]		:= NULL_CHAR;
	LOW_SHIFT[3]		:= NULL_CHAR;

    END		{ IF TRUE REGIS }

    ELSE

    BEGIN

	LOW_SHIFT[1]		:= SHIFT[2];
	LOW_SHIFT[2]		:= SHIFT[3];
	LOW_SHIFT[3]		:= SHIFT[4];

    END;	{ IF FALSE REGIS }

    { +
    OK, so let the user know that we're here.
    - }
    CLEAR (SCREEN);

    { +
    Initialize the TPARSE block.
    - }
    WITH PARAM_BLOCK DO

    BEGIN

	TPA$L_COUNT	:= TPA$K_COUNT0;
	TPA$V_ABBREV	:= TRUE;

    END;	{ DO }

    { +
    Stuff the pointer variable FDL_BLOCK with the address of FDL$AL_BLOCK
    PLUS the Contents of FDL$AL_BLOCK. The offset is introduced by the
    transfer vector in the shareable image FDLSHR.EXE. (home of FDL$AL_BLOCK)
    - }
    FDL_BLOCK::INTEGER		:= IADDRESS (FDL$AL_BLOCK) + FDL$AL_BLOCK;

    { +
    Now stuff the address of our EDF$LINE_PARSED routine into the callback
    address cell in the FDL$AL_BLOCK array.
    - }
    FDL_BLOCK^[FDL$L_PCALL]	:= IADDRESS (EDF$LINE_PARSED);

    { +
    Setup some defaults.
    - }
    IDATA[EDF$K_RESPONSES]	:= EDF$K_MAN;
    BDATA[EDF$K_BLOCK_SPAN]	:= TRUE;
    IDATA[EDF$K_BUCKET_WEIGHT]	:= EDF$K_FLATTER_FILES;

    { +
    This initializes the the QTAB table with the addresses of the TParse tables.
    - }
QTAB[EDF$K_CARR_CTRL].KEY_TABLE		:= IADDRESS (EDF$AB_CARR_TABLE_KEY);
QTAB[EDF$K_CARR_CTRL].STATE_TABLE	:= IADDRESS (EDF$AB_CARR_TABLE_STA);
QTAB[EDF$K_RECORD_FORMAT].KEY_TABLE	:= IADDRESS (EDF$AB_FORMAT_TABLE_KEY);
QTAB[EDF$K_RECORD_FORMAT].STATE_TABLE	:= IADDRESS (EDF$AB_FORMAT_TABLE_STA);
QTAB[EDF$K_KEY_TYPE].KEY_TABLE		:= IADDRESS (EDF$AB_TYPE_TABLE_KEY);
QTAB[EDF$K_KEY_TYPE].STATE_TABLE	:= IADDRESS (EDF$AB_TYPE_TABLE_STA);
QTAB[EDF$K_LOAD_METHOD].KEY_TABLE	:= IADDRESS (EDF$AB_LOAD_METHOD_TABLE_KEY);
QTAB[EDF$K_LOAD_METHOD].STATE_TABLE	:= IADDRESS (EDF$AB_LOAD_METHOD_TABLE_STA);
QTAB[EDF$K_BUCKET_WEIGHT].KEY_TABLE	:= IADDRESS (EDF$AB_WEIGHT_TABLE_KEY);
QTAB[EDF$K_BUCKET_WEIGHT].STATE_TABLE	:= IADDRESS (EDF$AB_WEIGHT_TABLE_STA);
QTAB[EDF$K_SURFACE_OPTION].KEY_TABLE	:= IADDRESS (EDF$AB_SURFACE_OPTION_TABLE_KEY);
QTAB[EDF$K_SURFACE_OPTION].STATE_TABLE	:= IADDRESS (EDF$AB_SURFACE_OPTION_TABLE_STA);
QTAB[EDF$K_CURRENT_FUNCTION].KEY_TABLE	:= IADDRESS (EDF$AB_CURRENT_FUNC_TABLE_KEY);
QTAB[EDF$K_CURRENT_FUNCTION].STATE_TABLE := IADDRESS (EDF$AB_CURRENT_FUNC_TABLE_STA);
QTAB[EDF$K_DESIGN_CYCLE].KEY_TABLE	:= IADDRESS (EDF$AB_DESIGN_CYCLE_TABLE_KEY);
QTAB[EDF$K_DESIGN_CYCLE].STATE_TABLE	:= IADDRESS (EDF$AB_DESIGN_CYCLE_TABLE_STA);
QTAB[EDF$K_SCRIPT_OPTION].KEY_TABLE	:= IADDRESS (EDF$AB_SCRIPT_OPTION_TABLE_KEY);
QTAB[EDF$K_SCRIPT_OPTION].STATE_TABLE	:= IADDRESS (EDF$AB_SCRIPT_OPTION_TABLE_STA);
QTAB[EDF$K_KEY_COMP_WANTED].KEY_TABLE	:= IADDRESS (EDF$AB_YES_NO_TABLE_KEY);
QTAB[EDF$K_KEY_COMP_WANTED].STATE_TABLE	:= IADDRESS (EDF$AB_YES_NO_TABLE_STA);
QTAB[EDF$K_REC_COMP_WANTED].KEY_TABLE	:= IADDRESS (EDF$AB_YES_NO_TABLE_KEY);
QTAB[EDF$K_REC_COMP_WANTED].STATE_TABLE	:= IADDRESS (EDF$AB_YES_NO_TABLE_STA);
QTAB[EDF$K_IDX_COMP_WANTED].KEY_TABLE	:= IADDRESS (EDF$AB_YES_NO_TABLE_KEY);
QTAB[EDF$K_IDX_COMP_WANTED].STATE_TABLE	:= IADDRESS (EDF$AB_YES_NO_TABLE_STA);
QTAB[EDF$K_CONFIRM].KEY_TABLE		:= IADDRESS (EDF$AB_YES_NO_TABLE_KEY);
QTAB[EDF$K_CONFIRM].STATE_TABLE		:= IADDRESS (EDF$AB_YES_NO_TABLE_STA);
QTAB[EDF$K_BLOCK_SPAN].KEY_TABLE	:= IADDRESS (EDF$AB_YES_NO_TABLE_KEY);
QTAB[EDF$K_BLOCK_SPAN].STATE_TABLE	:= IADDRESS (EDF$AB_YES_NO_TABLE_STA);
QTAB[EDF$K_ASCENDING_ADDED].KEY_TABLE	:= IADDRESS (EDF$AB_YES_NO_TABLE_KEY);
QTAB[EDF$K_ASCENDING_ADDED].STATE_TABLE	:= IADDRESS (EDF$AB_YES_NO_TABLE_STA);
QTAB[EDF$K_ASCENDING_LOAD].KEY_TABLE	:= IADDRESS (EDF$AB_YES_NO_TABLE_KEY);
QTAB[EDF$K_ASCENDING_LOAD].STATE_TABLE	:= IADDRESS (EDF$AB_YES_NO_TABLE_STA);
QTAB[EDF$K_RETURN].KEY_TABLE		:= IADDRESS (EDF$AB_YES_NO_TABLE_KEY);
QTAB[EDF$K_RETURN].STATE_TABLE		:= IADDRESS (EDF$AB_YES_NO_TABLE_STA);
QTAB[EDF$K_KEY_DUPS].KEY_TABLE		:= IADDRESS (EDF$AB_YES_NO_TABLE_KEY);
QTAB[EDF$K_KEY_DUPS].STATE_TABLE	:= IADDRESS (EDF$AB_YES_NO_TABLE_STA);
QTAB[EDF$K_KEY_DIST].KEY_TABLE		:= IADDRESS (EDF$AB_YES_NO_TABLE_KEY);
QTAB[EDF$K_KEY_DIST].STATE_TABLE	:= IADDRESS (EDF$AB_YES_NO_TABLE_STA);
QTAB[EDF$K_KEY_CHANGES].KEY_TABLE	:= IADDRESS (EDF$AB_YES_NO_TABLE_KEY);
QTAB[EDF$K_KEY_CHANGES].STATE_TABLE	:= IADDRESS (EDF$AB_YES_NO_TABLE_STA);
QTAB[EDF$K_SEGMENTED].KEY_TABLE		:= IADDRESS (EDF$AB_YES_NO_TABLE_KEY);
QTAB[EDF$K_SEGMENTED].STATE_TABLE	:= IADDRESS (EDF$AB_YES_NO_TABLE_STA);
QTAB[EDF$K_GLOBAL_WANTED].KEY_TABLE	:= IADDRESS (EDF$AB_YES_NO_TABLE_KEY);
QTAB[EDF$K_GLOBAL_WANTED].STATE_TABLE	:= IADDRESS (EDF$AB_YES_NO_TABLE_STA);
QTAB[EDF$K_TEST_PRIMARY].KEY_TABLE	:= IADDRESS (EDF$AB_PRIMARY_TABLE_KEY);
QTAB[EDF$K_TEST_PRIMARY].STATE_TABLE	:= IADDRESS (EDF$AB_PRIMARY_TABLE_STA);
QTAB[EDF$K_SET_FUNCTION].KEY_TABLE	:= IADDRESS (EDF$AB_SET_FUNCTION_TABLE_KEY);
QTAB[EDF$K_SET_FUNCTION].STATE_TABLE	:= IADDRESS (EDF$AB_SET_FUNCTION_TABLE_STA);
QTAB[EDF$K_GRANULARITY].KEY_TABLE	:= IADDRESS (EDF$AB_GRANULARITY_TABLE_KEY);
QTAB[EDF$K_GRANULARITY].STATE_TABLE	:= IADDRESS (EDF$AB_GRANULARITY_TABLE_STA);
QTAB[EDF$K_PROMPTING].KEY_TABLE		:= IADDRESS (EDF$AB_PROMPTING_TABLE_KEY);
QTAB[EDF$K_PROMPTING].STATE_TABLE	:= IADDRESS (EDF$AB_PROMPTING_TABLE_STA);
QTAB[EDF$K_RESPONSES].KEY_TABLE		:= IADDRESS (EDF$AB_RESPONSES_TABLE_KEY);
QTAB[EDF$K_RESPONSES].STATE_TABLE	:= IADDRESS (EDF$AB_RESPONSES_TABLE_STA);

    { +
    Create an Ident line_object and put it into the list.
    - }
    NEW_IDENT_LINE;

    { +
    See what we have.
    - }
    ANALYSIS_SPECIFIED	:= ODD (CLI$PRESENT ('ANALYSIS'));

    IF ANALYSIS_SPECIFIED THEN

    BEGIN

	{ +
	Save the analysis filename.
	- }
	ANALYSIS_FILENAME_DESC	:= NULL_STRING;
	CLI$GET_VALUE ('ANALYSIS',ANALYSIS_FILENAME_DESC);

    END;	{ IF ANALYSIS_SPECIFIED }

    { +
    Save the input filename.
    - }
    INPUT_FILENAME_DESC	:= NULL_STRING;
    CLI$GET_VALUE ('P1',INPUT_FILENAME_DESC);

    { +
    Find out which output filename we're using, the /OUTPUT, or the
    command parameter.
    - }
    OUTPUT_FILENAME_DESC	:= NULL_STRING;

    IF ODD (CLI$PRESENT ('OUTPUT')) THEN

    BEGIN

	{ +
	The /OUTPUT switch overrides, so use it if present.
	- }
	CLI$GET_VALUE ('OUTPUT',OUTPUT_FILENAME_DESC);

    END

    ELSE

	{ +
	The user just wants another version of the input file.
	- }
	LIB$SCOPY_DXDX (INPUT_FILENAME_DESC,OUTPUT_FILENAME_DESC);

    { +
    The following qualifiers make sense only if we're in normal
    interactive mode.
    - }
    IF ODD (CLI$PRESENT ('INTERACTIVE')) THEN

    BEGIN

	{ +
	Set up the script to the one specified in the DCL command. (if any)
	- }
	IF ODD (CLI$PRESENT('SCRIPT')) THEN

	BEGIN

	    TEMP_DESCRIPTOR	:= NULL_STRING;
	    CLI$GET_VALUE ('SCRIPT',TEMP_DESCRIPTOR);

	    { +
	    Case on the 1st letter.
	    - }
	    CASE TEMP_DESCRIPTOR.DSC$A_POINTER^[1] OF

		'A' :	IDATA[EDF$K_FIRST_SCRIPT]	:= EDF$K_ADD_KEY_FDL;

		'D' :	IDATA[EDF$K_FIRST_SCRIPT]	:= EDF$K_DELETE_KEY_FDL;

		'I' :	IDATA[EDF$K_FIRST_SCRIPT]	:= EDF$K_IDX_DESIGN_FDL;

		'S' :	IDATA[EDF$K_FIRST_SCRIPT]	:= EDF$K_SEQ_DESIGN_FDL;

		'O' :	IDATA[EDF$K_FIRST_SCRIPT]	:= EDF$K_OPTIMIZE_FDL;

		'R' :	IDATA[EDF$K_FIRST_SCRIPT]	:= EDF$K_REL_DESIGN_FDL;

		'T' :	IDATA[EDF$K_FIRST_SCRIPT]	:= EDF$K_REDESIGN_FDL;

	    OTHERWISE

		{ +
		If the user blows it, give him nothing.
		- }
		IDATA[EDF$K_FIRST_SCRIPT]		:= EDF$K_ZERO_SCRIPT;

	    END;	{ CASE }

	    STR$FREE1_DX (TEMP_DESCRIPTOR);

	END		{ IF TRUE SCRIPT PRESENT }

	ELSE

	    IDATA[EDF$K_FIRST_SCRIPT]	:= EDF$K_ZERO_SCRIPT;

	{ +
	Find out how many keys the user wants.
	- }
	IF ODD (CLI$PRESENT('NUMBER_KEYS')) THEN

	BEGIN

	    TEMP_DESCRIPTOR			:= NULL_STRING;
	    CLI$GET_VALUE ('SCRIPT',TEMP_DESCRIPTOR);
	    ISTATUS			:= OTS$CVT_TI_L (TEMP_DESCRIPTOR,
	    					IDATA[EDF$K_NUMBER_KEYS]);
	    QTAB[EDF$K_NUMBER_KEYS].DEFAULT	:= IDATA[EDF$K_NUMBER_KEYS];
	    NUMBER_KEYS_SET			:= TRUE;

	    STR$FREE1_DX (TEMP_DESCRIPTOR);

	END;		{ IF TRUE SCRIPT PRESENT }

	{ +
	If the user specified a prompt level, set EDF's level to that,
	otherwise set it according to the type of terminal (hardcopy gets Brief).
	- }
	IF ODD (CLI$PRESENT ('PROMPTING')) THEN

	BEGIN

	    { +
	    Get the prompting level specified by the user.
	    - }
	    TEMP_DESCRIPTOR	:= NULL_STRING;
	    CLI$GET_VALUE ('PROMPTING',TEMP_DESCRIPTOR);
    
	    { +
	    The 1st character of the string is unique.
	    - }
	    CASE TEMP_DESCRIPTOR.DSC$A_POINTER^[1] OF
    
		{ +
		Brief prompting
		- }
		'B' :

		    FULL_PROMPT	:= FALSE;
    
		{ +
		Full prompting
		- }
		'F' :
    
		    FULL_PROMPT	:= TRUE;
    
	    OTHERWISE
    
		{ +
		Automatic prompting.
		Default to Brief prompting for non-scope (or slow) terminals.
		- }
		IF ( VIDEO_TERMINAL
		    AND
		    ( TERMINAL_SPEED >= TT$C_BAUD_2400 ) ) THEN

		    FULL_PROMPT	:= TRUE

		ELSE

		    FULL_PROMPT	:= FALSE;

	    END;		{ CASE }

	    STR$FREE1_DX (TEMP_DESCRIPTOR);

	END		{ IF TRUE (ODD) }

	ELSE

	BEGIN

	    { +
	    Default to Brief prompting for non-scope (or slow) terminals.
	    - }
	    IF VIDEO_TERMINAL AND (TERMINAL_SPEED >= TT$C_BAUD_2400) THEN
    
		FULL_PROMPT	:= TRUE

	    ELSE

		FULL_PROMPT	:= FALSE;

	END;	{ IF FALSE (ODD) }

	IF ODD (CLI$PRESENT ('DISPLAY')) THEN

	BEGIN

	    CLI$GET_VALUE ('DISPLAY',TEMP_DESCRIPTOR);

	    CASE TEMP_DESCRIPTOR.DSC$A_POINTER^[1] OF

		'L' :	IDATA[EDF$K_SURFACE_OPTION] := EDF$K_LINE_SURFACE;
		'F' :	IDATA[EDF$K_SURFACE_OPTION] := EDF$K_FILL_SURFACE;
		'A' :	IDATA[EDF$K_SURFACE_OPTION] := EDF$K_ADDED_SURFACE;
		'I' :	IDATA[EDF$K_SURFACE_OPTION] := EDF$K_INIT_SURFACE;
		'R' :	IDATA[EDF$K_SURFACE_OPTION] := EDF$K_SIZE_SURFACE;
		'K' :	IDATA[EDF$K_SURFACE_OPTION] := EDF$K_KEY_SURFACE;

	    OTHERWISE

		{ NULL-STATEMENT } ;

	    END;	{ CASE }

	    QTAB[EDF$K_SURFACE_OPTION].DEFAULT := IDATA[EDF$K_SURFACE_OPTION];

	END;	{ IF ODD (CLI$PRESENT ('DISPLAY')) }

	IF ODD (CLI$PRESENT ('RESPONSES')) THEN

	BEGIN

	    CLI$GET_VALUE ('RESPONSES',TEMP_DESCRIPTOR);

	    CASE TEMP_DESCRIPTOR.DSC$A_POINTER^[1] OF

		'A' :	IDATA[EDF$K_RESPONSES] := EDF$K_AUTO;
		'M' :	IDATA[EDF$K_RESPONSES] := EDF$K_MAN;

	    OTHERWISE

		{ NULL-STATEMENT } ;

	    END;	{ CASE }

	END;	{ IF ODD (CLI$PRESENT ('RESPONSES')) }

	NO_INPUT	:= ODD (CLI$PRESENT ('CREATE'));

	AUTO_TUNE	:= FALSE;

    END		{ IF TRUE ODD (CLI$PRESENT ('INTERACTIVE')) }

    ELSE

    BEGIN

	{ +
	We don't want shifting or centering if we're nointeractive.
	- }
	FOR I := 1 TO 4 DO

	BEGIN

	    SHIFT[I]		:= NULL_CHAR;
	    CRLF_SHIFT[I+2]	:= NULL_CHAR;

	END;

	FOR I := 1 TO 3 DO

	    LOW_SHIFT[I]	:= NULL_CHAR;

    END;

    IF ODD (CLI$PRESENT ('GRANULARITY')) THEN

    BEGIN

	CLI$GET_VALUE ('GRANULARITY',TEMP_DESCRIPTOR);

	CASE TEMP_DESCRIPTOR.DSC$A_POINTER^[1] OF

	    'O','1' :	IDATA[EDF$K_GRANULARITY] := EDF$K_ONE;
	    '2' :	IDATA[EDF$K_GRANULARITY] := EDF$K_TWO;
	    '3' :	IDATA[EDF$K_GRANULARITY] := EDF$K_THREE;
	    'F','4' :	IDATA[EDF$K_GRANULARITY] := EDF$K_FOUR;
	    'D' :	IDATA[EDF$K_GRANULARITY] := EDF$K_DOUBLE;

	    'T' :	IF TEMP_DESCRIPTOR.DSC$A_POINTER^[2] = 'H' THEN

			    IDATA[EDF$K_GRANULARITY] := EDF$K_THREE

			ELSE

			    IDATA[EDF$K_GRANULARITY] := EDF$K_TWO;

	OTHERWISE

	    { NULL-STATEMENT } ;

	END;	{ CASE }

    END		{ IF ODD (CLI$PRESENT ('GRANULARITY')) }

    ELSE

	IDATA[EDF$K_GRANULARITY] 	:= EDF$K_THREE;

    IF ODD (CLI$PRESENT ('EMPHASIS')) THEN

    BEGIN

	CLI$GET_VALUE ('EMPHASIS',TEMP_DESCRIPTOR);

	CASE TEMP_DESCRIPTOR.DSC$A_POINTER^[1] OF

	    'F' :	IDATA[EDF$K_BUCKET_WEIGHT] := EDF$K_FLATTER_FILES;
	    'S' :	IDATA[EDF$K_BUCKET_WEIGHT] := EDF$K_SMALLER_BUFFERS;

	OTHERWISE

	    { NULL-STATEMENT } ;

	END;	{ CASE }

	QTAB[EDF$K_BUCKET_WEIGHT].DEFAULT := IDATA[EDF$K_BUCKET_WEIGHT];

    END		{ IF ODD (CLI$PRESENT ('EMPHASIS')) }

    ELSE

	IDATA[EDF$K_BUCKET_WEIGHT] 	:= EDF$K_FLATTER_FILES;

    DEFAULT_FILENAME_DESC	:= NULL_STRING;
    STR$TRIM (DEFAULT_FILENAME_DESC,'.FDL');

    NL_DEV_DESC	:= NULL_STRING;
    STR$TRIM (NL_DEV_DESC,'NL:');

    { +
    Set the main loop variable to true so we can execute the main cycle.
    - }
    EDITING		:= TRUE;

END;	{ INIT_EDITOR }

{ ++

INPUT_FDL_FILE -- Uses FDL$PARSE to read the user's input FDL file.

This routine parses the input file using FDL$PARSE.

CALLING SEQUENCE:

INPUT_FDL_FILE;

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

none

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

The Definition Linked List

ROUTINES CALLED:

FDL$PARSE

ROUTINE VALUE:

none

SIGNALS:


SIDE EFFECTS:

none

-- }

PROCEDURE INPUT_FDL_FILE;

BEGIN

    { +
    Set up the condition handler for the disk.
    - }
    ESTABLISH (RMS_INPUT_COND_HANDLER);

    { +
    Now tell the user what we're doing.
    - }
    IF NOT AUTO_TUNE THEN

	WRITELN (SHIFT,TAB,TAB,'Parsing Definition File');

    { +
    Make sure edf$line_parsed gets the non-analysis stuff.
    - }
    ANALYSIS_ONLY	:= FALSE;

    { +
    Turn on the $CALLBACK flags bit to make FDL$PARSE call us.
    Also, turn on the SIGNAL bit to make FDL$PARSE signal errors to us.
    - }
    FLAGS.FDL$V_$CALLBACK	:= TRUE;
    FLAGS.FDL$V_SIGNAL		:= TRUE;

    { +
    Parse the input file to get the old definition.
    If the input file doesn't exist, this will signal up to the main loop.
    - }
    ISTATUS	:= FDL$PARSE (
			    INPUT_FILENAME_DESC,
			    FAB_DUMMY,
			    RAB_DUMMY,
			    FLAGS
			    );

    IF (
    (ODD (ISTATUS))
    AND
    (NOT AUTO_TUNE)
    ) THEN

	WRITELN (SHIFT,TAB,TAB,'Definition Parse Complete');

END;	{ INPUT_FDL_FILE }

{ ++

INPUT_ANALYSIS_FILE -- Read in the analysis file if specified.

This routine parses the user's analysis file if he has specified one.

CALLING SEQUENCE:

INPUT_ANALYSIS_FILE;

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

none

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

The Analysis Linked List

ROUTINES CALLED:

FDL$PARSE

ROUTINE VALUE:

none

SIGNALS:


SIDE EFFECTS:

none

-- }

[GLOBAL] PROCEDURE INPUT_ANALYSIS_FILE;

BEGIN

    { +
    Only do this if the user wants to.
    - }
    IF EDITING AND ANALYSIS_SPECIFIED THEN

    BEGIN

	{ +
	Set up the condition handler for the disk.
	- }
	ESTABLISH (RMS_INPUT_COND_HANDLER);

	{ +
	Now tell the user what we're doing.
	- }
	IF NOT AUTO_TUNE THEN

	    WRITELN (SHIFT,'Parsing Analysis File');

	{ +
	Make sure edf$line_parsed gets only the analysis stuff.
	- }
	ANALYSIS_ONLY	:= TRUE;
	POINT_AT_ANALYSIS;

	{ +
	Create an Ident line_object and put it into the list.
	- }
	NEW_IDENT_LINE;

	{ +
	Turn on the $CALLBACK flags bit to make FDL$PARSE call us.
	Also, turn on the SIGNAL bit to make FDL$PARSE signal errors to us.
	- }
	FLAGS.FDL$V_$CALLBACK		:= TRUE;
	FLAGS.FDL$V_SIGNAL		:= TRUE;

	{ +
	Parse the analysis file to get the analysis sections.
	If it doesn't exist, this will signal up to the main loop.
	- }
	ISTATUS	:= FDL$PARSE (
			    ANALYSIS_FILENAME_DESC,
			    FAB_DUMMY,
			    RAB_DUMMY,
			    FLAGS
			    );

	ANALYSIS_ONLY	:= FALSE;
	POINT_AT_DEFINITION;

	IF (
	(ODD (ISTATUS))
	AND
	(NOT AUTO_TUNE)
	) THEN

	    WRITELN (SHIFT,'Analysis Parse Complete',CRLF);

    END;	{ IF EDITING AND ANALYSIS_SPECIFIED }

END;		{ INPUT_ANALYSIS_FILE }

{ ++

SETUP_CONTINUE -- Get ready to ask the user if he wants to continue after
an input parse error.

CALLING SEQUENCE:

SETUP_CONTINUE;

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

none

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

none

ROUTINES CALLED:

CLEAR

ROUTINE VALUE:

none

SIGNALS:

none

SIDE EFFECTS:

none

-- }

PROCEDURE SETUP_CONTINUE;

BEGIN

    { +
    Set up the control/Z handler in case the user types ^Z.
    - }
    ESTABLISH (CTRLZ_COND_HANDLER);

    CLEAR (PAUSE);

END;	{ SETUP_CONTINUE }

{ ++

DISPATCH_FUNCTION -- Branch off to the selected function.

This routine is just a big CASE statement to execute the operation the
user wants.

CALLING SEQUENCE:

DISPATCH_FUNCTION

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

IDATA[EDF$K_FIRST_SCRIPT]
IDATA[EDF$K_CURRENT_FUNCTION]

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

EDITING
IDATA[EDF$K_SCRIPT_OPTION]

ROUTINES CALLED:

ADD_FDL_LINE
DELETE_FDL_LINE
CREATE_NEW_FDL
HELP_PROC
MODIFY_FDL_LINE
INVOKE_SCRIPT
VIEW_DEF

ROUTINE VALUE:

none

SIGNALS:


SIDE EFFECTS:

none

-- }

PROCEDURE DISPATCH_FUNCTION;

BEGIN

    { +
    Set up the control/Z handler and reinitialize some flags.
    - }
    ESTABLISH (CTRLZ_COND_HANDLER);

    IF NOT AUTO_TUNE THEN

	CLOSE (FDL_DEST,ERROR := CONTINUE);

    POINT_AT_DEFINITION;
    DEST_IS_TERMINAL	:= TRUE;
    OPTIMIZING		:= FALSE;
    VISIBLE_QUESTION	:= FALSE;
    TEMP_FULL_PROMPT	:= FALSE;
    TAKE_DEFAULTS	:= AUTO_TUNE;

    { +
    Ask the user only if he hadn't requested one from DCL.
    - }
    IF IDATA[EDF$K_FIRST_SCRIPT] = EDF$K_ZERO_SCRIPT THEN

    BEGIN

	{ +
	Get the user's top-level function and dispatch on it.
	- }
	QUERY (EDF$K_CURRENT_FUNCTION);

	CASE IDATA[EDF$K_CURRENT_FUNCTION] OF

	    EDF$K_ADD :		ADD_FDL_LINE;	{ Add a new line_object to the list. }
	    EDF$K_DELETE :	DELETE_FDL_LINE; { Remove a line_object from the list. }
	    EDF$K_HELP :	HELP_PROC;	{ Prompt for help and process it. }
	    EDF$K_INVOKE :	INVOKE_SCRIPT; { Ask a bunch of related questions. }
	    EDF$K_MODIFY :	MODIFY_FDL_LINE; { Edit an extant line_object. }
	    EDF$K_QUIT :	EDITING := FALSE; { Wipe out! All bets are off! }
	    EDF$K_SET :		SET_PROC;	{ Set the editor characteristics. }
	    EDF$K_VIEW :	VIEW_DEF;	{ Show the user the definition. }

	    EDF$K_EXIT :

	    BEGIN

		{ +
		Stop the editing loop and output the new FDL file.
		- }
		EDITING	:= FALSE;
		CREATE_NEW_FDL;

	    END;

	OTHERWISE

	    { NULL-STATEMENT } ;

	END;	{ CASE }

    END		{ IF TRUE IDATA[EDF$K_FIRST_SCRIPT] = EDF$K_ZERO_SCRIPT }

    ELSE

    BEGIN

	{ +
	The user wants to do a script right off, do it.
	- }
	IDATA[EDF$K_SCRIPT_OPTION]	:= IDATA[EDF$K_FIRST_SCRIPT];

	ISAM_ORG	:= (IDATA[EDF$K_SCRIPT_OPTION] IN [ EDF$K_ADD_KEY_FDL,
			    EDF$K_DELETE_KEY_FDL, EDF$K_IDX_DESIGN_FDL,
			    EDF$K_REDESIGN_FDL, EDF$K_OPTIMIZE_FDL ]);

	INVOKE_SCRIPT;

    END;	{ IF FALSE IDATA[EDF$K_FIRST_SCRIPT] = EDF$K_ZERO_SCRIPT }

END;	{ DISPATCH_FUNCTION }

{ ++
+----------------------------------------------------+
| *** THIS IS THE TOP LEVEL CODE IN THE UTILITY. *** |
+----------------------------------------------------+
-- }


BEGIN

    { +
    Set up the editor, setup the exit and condition hanlders, a control/C
    AST routine, and get all the DCL switch options.
    Set EDITING to TRUE.
    - }
    INIT_EDITOR;

    { +
    Read in the FDL file, and possibly an analysis file.
    1st clear the error flag.
    - }
    RMS_INPUT_ERROR	:= FALSE;

    IF NOT NO_INPUT THEN

	INPUT_FDL_FILE;

    { +
    If we had an error, pause to let the user read the messages,
    otherwise, continue on.
    - }
    IF EDITING AND RMS_INPUT_ERROR THEN

	SETUP_CONTINUE

    ELSE IF NOT NO_INPUT THEN

	LIB$WAIT (3.0);

    { +
    This is the Main Loop.
    - }
    WHILE EDITING DO

    BEGIN

	DISPATCH_FUNCTION;

	IF MAIN_CTRLZ THEN

	BEGIN

	    { +
	    Stop the editing loop and output the new FDL file.
	    - }
	    EDITING	:= FALSE;
	    CREATE_NEW_FDL;

	END;

    END;	{ WHILE EDITING }

    { +
    Close the journal file if we had one.
    - }
    IF JOURNAL_ENABLED THEN

	CLOSE (JOURNAL_FILE);

END.	{ EDF UTILITY. }
