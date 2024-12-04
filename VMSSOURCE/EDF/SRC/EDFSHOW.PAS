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

		V03-08	KFH0008		Ken Henderson		10 Sep 1983
			Support for named UICs

		V03-007	KFH0007		Ken Henderson		 8 Aug 1983
			Changes for seperate compilation.

		V03-006	KFH0006		Ken Henderson		30 Jul 1983
			Added never_RU_journal.

		V03-005	KFH0005		Ken Henderson		14 Apr 1983
			Fixed SHOW_PRIMARY_SECTION routine.
			Fixed CHECK_QUOTES routine.

		V03-004	KFH0004		Ken Henderson		22 Nov 1982
			Removed the EDF$_INTSWERR numbers.

		V03-003	KFH0003		Ken Henderson		8 Sept 1982
			Added CHECK_QUOTES routine.

		V03-002	KFH0002		Ken Henderson		23-Mar-1982
			Reorderred the EDF$_INTSWERR numbers.

		V03-001	KFH0001		Ken Henderson		17-Mar-1982
			Modified SHOW_CURRENT to fix FT2 QARs
			440,449

-- }

ENVIRONMENT ('LIB$:EDFSHOW'),

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
'LIB$:EDFASK'

)]

MODULE EDFSHOW (INPUT,OUTPUT);

{ ++

CHECK_QUOTES -- Bracket the output string with quotes.

This routine scans for quotes that bracket a string-valued output secondary.
If they aren't there, it puts on "s. If there is a " in the string, it puts
on 's. If there are both in the string, then it puts on "s (doubling embedded
"s).

CALLING SEQUENCE:

CHECK_QUOTES (DESC);

INPUT PARAMETERS:

DESC - the character string to scan.

IMPLICIT INPUTS:

APOSTROPHE

OUTPUT PARAMETERS:

DESC - the scanned character string

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

PROCEDURE CHECK_QUOTES (VAR DESC: DESCRIPTOR);

VAR
    SCAN_INDEX	: INTEGER;
    INDEX	: INTEGER;
    QUOTE_FOUND	: BOOLEAN;
    APOST_FOUND	: BOOLEAN;
    QCHAR	: CHAR;
    QUOTES	: CHAR;

BEGIN

    QUOTES	:= CHR (34);

    { +
    Non-null strings are the most interesting.
    - }
    IF DESC.DSC$W_LENGTH <> 0 THEN

    BEGIN

	{ +
	Don't disturb a string that already is enclosed in (')s or (")s.
	- }
	IF NOT (
	    (
	    (DESC.DSC$A_POINTER^[1] = APOSTROPHE)
	    AND
	    (DESC.DSC$A_POINTER^[DESC.DSC$W_LENGTH] = APOSTROPHE)
	    )
	OR
	    (
	    (DESC.DSC$A_POINTER^[1] = QUOTES)
	    AND
	    (DESC.DSC$A_POINTER^[DESC.DSC$W_LENGTH] = QUOTES)
	    )
	) THEN

	BEGIN

	    { +
	    First, see if there are any nasty embedded quotes or apostrophes.
	    - }
	    QUOTE_FOUND	:= FALSE;
	    APOST_FOUND	:= FALSE;

	    FOR INDEX	:= 1 TO DESC.DSC$W_LENGTH DO

	    BEGIN

		IF DESC.DSC$A_POINTER^[INDEX] = QUOTES THEN

		    QUOTE_FOUND	:= TRUE;

		IF DESC.DSC$A_POINTER^[INDEX] = APOSTROPHE THEN

		    APOST_FOUND	:= TRUE;

	    END;

	    { +
	    Just bracket the string with quotes if no quotes are found,
	    or if just bracket it with apostrophes if no apostrophes are
	    found.
	    - }
	    IF QUOTE_FOUND THEN

	    BEGIN

		IF APOST_FOUND THEN

		BEGIN

		    SCAN_INDEX	:= DESC.DSC$W_LENGTH;

		    REPEAT

			IF DESC.DSC$A_POINTER^[SCAN_INDEX] = QUOTES THEN
    
			BEGIN
    
			    FOR INDEX := DESC.DSC$W_LENGTH DOWNTO SCAN_INDEX DO
		
				DESC.DSC$A_POINTER^[INDEX+1]
						:= DESC.DSC$A_POINTER^[INDEX];
    
			    IF DESC.DSC$W_LENGTH < 254 THEN
    
				DESC.DSC$W_LENGTH := DESC.DSC$W_LENGTH + 1;

			END;
    
			SCAN_INDEX	:= SCAN_INDEX - 1;

		    UNTIL SCAN_INDEX < 1;

		    QCHAR	:= QUOTES;

		END	{ IF TRUE APOST_FOUND (AND QUOTE_FOUND) -YUK }

		ELSE

		BEGIN

		    QCHAR	:= APOSTROPHE;

		END;	{ IF FALSE APOST_FOUND }

	    END		{ IF TRUE QUOTE_FOUND }

	    ELSE

	    BEGIN

		QCHAR		:= QUOTES;

	    END;	{ IF FALSE QUOTE_FOUND }

	    { +
	    Shift the string down one char.
	    - }
	    FOR INDEX	:= DESC.DSC$W_LENGTH DOWNTO 1 DO

		DESC.DSC$A_POINTER^[INDEX+1]	:= DESC.DSC$A_POINTER^[INDEX];

	    { +
	    Update the length and add the quotes.
	    - }
	    DESC.DSC$W_LENGTH			:= DESC.DSC$W_LENGTH + 2;
	    DESC.DSC$A_POINTER^[1]			:= QCHAR;
	    DESC.DSC$A_POINTER^[DESC.DSC$W_LENGTH]	:= QCHAR;

	END;	{ IF NOT (ALREADY QUOTED) }

    END		{ IF TRUE DESC.DSC$W_LENGTH <> 0 }

    ELSE

    BEGIN

	STR$TRIM (DESC,EMPTY_STRING);

    END;	{ IF FALSE DESC.DSC$W_LENGTH <> 0 }

END;	{ CHECK_QUOTES }

{ ++

SHOW_PRIMARY -- Output the text string for the primary.

This routine outputs the primary keyword.

CALLING SEQUENCE:

SHOW_PRIMARY;

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

DEF_CURRENT
PRIMARY_WIDTH

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

FDL_DEST

ROUTINES CALLED:

none

ROUTINE VALUE:

none

SIGNALS:

none

SIDE EFFECTS:

The text is shown on the terminal or put in the file. Wherever FDL_DEST points.

-- }

PROCEDURE SHOW_PRIMARY;

VAR
    TEMP_PRI	: PRIMARY_TYPE;

BEGIN

    WITH DEF_CURRENT^ DO

    BEGIN

	{ +
	Fetch the primary we're showing.
	- }
	TEMP_PRI	:= PRIMARY;
    
	{ +
	Output it, using the correct width.
	- }
	WRITE (FDL_DEST,TEMP_PRI:PRIMARY_WIDTH[TEMP_PRI]);
    
	{ +
	If it's one with a PRINUM, put that out too.
	- }
	IF TEMP_PRI IN [ ANALYSIS_OF_AREA, ANALYSIS_OF_KEY, AREA, KEY ] THEN
    
	    WRITE (FDL_DEST,' ',PRINUM:NUM_LEN(PRINUM));
    
	{ +
	If it's one with a string value, put that out too.
	- }
	IF TEMP_PRI IN [ IDENT, TITLE ] THEN

	BEGIN    

	    CHECK_QUOTES (STRING);

	    IF (STRING.DSC$W_LENGTH > 0) THEN

		WRITE (FDL_DEST,'	',STRING.DSC$A_POINTER^:
		STRING.DSC$W_LENGTH);

	END;

    END;	{ WITH DEF_CURRENT^ }

END;	{ SHOW_PRIMARY }

{ ++

SHOW_SECONDARY -- Output a text string for the secondary keyword.

This routine outputs a secondary keyword.

CALLING SEQUENCE:

SHOW_SECONDARY;

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

DEF_CURRENT
SECONDARY_WIDTH

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

FDL_DEST

ROUTINES CALLED:

none

ROUTINE VALUE:

none

SIGNALS:

none

SIDE EFFECTS:

The secondary keyword is put into the file or onto the terminal. (FDL_DEST)

-- }

PROCEDURE SHOW_SECONDARY;

VAR
    TEMP_SEC	: SECONDARY_TYPE;

BEGIN

    WITH DEF_CURRENT^ DO

    BEGIN

	{ +
	Fetch the secondary.
	- }
	TEMP_SEC	:= SECONDARY;
    
	{ +
	Output the secondary if it's a simply structured one.
	- }
	IF NOT ( TEMP_SEC IN [ SEG_LENGTH, SEG_POSITION, SEG_TYPE ] ) THEN
    
	BEGIN
    
	    WRITE (FDL_DEST,'	',TEMP_SEC:SECONDARY_WIDTH[TEMP_SEC]);
    
	    { +
	    Put out extra tabs to compensate for short secondaries.
	    - }
	    IF (
	    (TEMP_SEC = POSITION$)
	    AND
	    (NOT (QUALIFIER IN [ FDL$C_ANYPOS, FDL$C_NOPOS ]))
	    ) THEN

		WRITE (FDL_DEST,'    ')

	    ELSE IF SECONDARY_WIDTH[TEMP_SEC] < 8 THEN
    
		WRITE (FDL_DEST,'		')
    
	    ELSE IF SECONDARY_WIDTH[TEMP_SEC] < 16 THEN
    
		WRITE (FDL_DEST,'	');
    
	END
    
	ELSE
    
	{ +
	Here for the complicated secondaries: SEGn_xxx
	- }
	BEGIN
    
	    IF TEMP_SEC = SEG_LENGTH THEN
    
		WRITE (FDL_DEST,'	SEG',SECNUM:1,'_LENGTH	');
    
	    { +
	    Now do the same for the SEGn_POSITION secondary.
	    - }
	    IF TEMP_SEC = SEG_POSITION THEN
    
		WRITE (FDL_DEST,'	SEG',SECNUM:1,'_POSITION	');
    
	    { +
	    Ditto for SEGn_TYPE.
	    - }
	    IF TEMP_SEC = SEG_TYPE THEN
    
		WRITE (FDL_DEST,'	TYPE		');

{ +
SEGn_TYPE will NOT be supported until after version V3B
- }

{		WRITE (FDL_DEST,'	SEG',SECNUM:1,'_TYPE	'); }

	END;

    END;	{ WITH DEF_CURRENT^ }

END;	{ SHOW_SECONDARY }

{ ++

SHOW_QUALIFIER -- Output a text string for the qualifier keyword.

This routine outputs the qualifier keyword.

CALLING SEQUENCE:

SHOW_QUALIFIER;

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

DEF_CURRENT

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

FDL_DEST

ROUTINES CALLED:

none

ROUTINE VALUE:

none

SIGNALS:

none

SIDE EFFECTS:

The keyword is put into the file or onto the terminal. (FDL_DEST)

-- }

PROCEDURE SHOW_QUALIFIER;

BEGIN

    { +
    Output the qualifiers.
    - }
    CASE DEF_CURRENT^.QUALIFIER OF

	FDL$C_ANYPOS :		WRITE (FDL_DEST,'	any_cylinder');
	FDL$C_CLUSPOS :		WRITE (FDL_DEST,'cluster');
	FDL$C_CYLPOS :		WRITE (FDL_DEST,'cylinder');
	FDL$C_FIDPOS :		WRITE (FDL_DEST,'file_ID');
	FDL$C_FNMPOS :		WRITE (FDL_DEST,'file_name');
	FDL$C_LOGPOS :		WRITE (FDL_DEST,'logical');
	FDL$C_VIRPOS :		WRITE (FDL_DEST,'virtual');
	FDL$C_NOPOS,
	FDL$C_NONE :		WRITE (FDL_DEST,'	none');
	FDL$C_IDX :		WRITE (FDL_DEST,'	indexed');
	FDL$C_REL :		WRITE (FDL_DEST,'	relative');
	FDL$C_SEQ :		WRITE (FDL_DEST,'	sequential');
	FDL$C_IF_IN :		WRITE (FDL_DEST,'	if_in_recovery_unit');
	FDL$C_NEC :		WRITE (FDL_DEST,'	necessary_to_write');
	FDL$C_NEVER :		WRITE (FDL_DEST,'	never_RU_journal');
	FDL$C_CR :		WRITE (FDL_DEST,'	carriage_return');
	FDL$C_FTN :		WRITE (FDL_DEST,'	FORTRAN');
	FDL$C_PRINT :		WRITE (FDL_DEST,'	print');
	FDL$C_FIX :		WRITE (FDL_DEST,'	fixed');
	FDL$C_STM :		WRITE (FDL_DEST,'	stream');
	FDL$C_STMCR :		WRITE (FDL_DEST,'	stream_CR');
	FDL$C_STMLF :		WRITE (FDL_DEST,'	stream_LF');
	FDL$C_UDF :		WRITE (FDL_DEST,'	undefined');
	FDL$C_VAR :		WRITE (FDL_DEST,'	variable');
	FDL$C_VFC :		WRITE (FDL_DEST,'	VFC');
	FDL$C_BN2 :		WRITE (FDL_DEST,'	bin2');
	FDL$C_BN4 :		WRITE (FDL_DEST,'	bin4');
	FDL$C_BN8 :		WRITE (FDL_DEST,'	bin8');
	FDL$C_PAC :		WRITE (FDL_DEST,'	decimal');
	FDL$C_IN2 :		WRITE (FDL_DEST,'	int2');
	FDL$C_IN4 :		WRITE (FDL_DEST,'	int4');
	FDL$C_IN8 :		WRITE (FDL_DEST,'	int8');
	FDL$C_STG :		WRITE (FDL_DEST,'	string');
	FDL$C_IAS :		WRITE (FDL_DEST,'	IAS');
	FDL$C_RSTS :		WRITE (FDL_DEST,'	RSTS/E');
	FDL$C_M :		WRITE (FDL_DEST,'	RSX-11M');
	FDL$C_MPLUS :		WRITE (FDL_DEST,'	RSX-11M-PLUS');
	FDL$C_RT :		WRITE (FDL_DEST,'	RT-11');
	FDL$C_TRAX :		WRITE (FDL_DEST,'	TRAX-11');
	FDL$C_VMS :		WRITE (FDL_DEST,'	VAX/VMS');

    OTHERWISE

	{ NULL-STATEMENT } ;

    END;	{ CASE }

END;	{ SHOW_QUALIFIER }

{ ++

SHOW_CURRENT -- Display (or output) the current line_object.

This routine outputs the textual representation of the line_object pointed
to by DEF_HEAD.

CALLING SEQUENCE:

SHOW_CURRENT (PLUS_VALUE);

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

DEF_CURRENT
DEST_IS_TERMINAL
LINES_PER_PAGE

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

FDL_DEST

ROUTINES CALLED:

SHOW_PRIMARY
SHOW_SECONDARY
SHOW_QUALIFIER
CLEAR
LIB$SIGNAL

ROUTINE VALUE:

none

SIGNALS:


SIDE EFFECTS:

none

-- }

PROCEDURE SHOW_CURRENT (PLUS_VALUE : BOOLEAN);

VAR
    RETLEN	: [VOLATILE]$WORD;

    PROCEDURE SHOW_PROT (PROTECTION : CTRL_ARRAY; FIELD_OFFSET : INTEGER);

    BEGIN

	IF PROTECTION[FIELD_OFFSET+EDF$V_NOREAD] THEN

	    WRITE (FDL_DEST,'R');

	IF PROTECTION[FIELD_OFFSET+EDF$V_NOWRITE] THEN

	    WRITE (FDL_DEST,'W');

	IF PROTECTION[FIELD_OFFSET+EDF$V_NOEXE] THEN

	    WRITE (FDL_DEST,'E');

	IF PROTECTION[FIELD_OFFSET+EDF$V_NODEL] THEN

	    WRITE (FDL_DEST,'D');

    END;	{ SHOW_PROT }

BEGIN

    { +
    If it's going to the terminal, shift it.
    - }
    IF DEST_IS_TERMINAL THEN

	WRITE (FDL_DEST,SHIFT);

    { +
    Write to FDL_DEST, according to the type of object it is.
    - }
    CASE DEF_CURRENT^.OBJECT_TYPE OF

	PRI :

	WITH DEF_CURRENT^ DO

	BEGIN

	    { +
	    Output the primary.
	    - }
	    SHOW_PRIMARY;

	    { +
	    Show only the primary if wanted.
	    - }
	    IF PLUS_VALUE THEN

		{ +
		If it has an end-of-line comment on it, output that also.
		- }
		IF (COMMENT.DSC$W_LENGTH > 0) THEN
    
		    WRITE (FDL_DEST,'	',COMMENT.DSC$A_POINTER^:
		    COMMENT.DSC$W_LENGTH);

	    { +
	    This actually does the QIO.
	    - }
	    WRITELN (FDL_DEST);

	END;	{ PRI }

	SEC :

	WITH DEF_CURRENT^ DO

	BEGIN

	    { +
	    Output the secondary.
	    - }
	    SHOW_SECONDARY;

	    { +
	    Don't show the value unless wanted.
	    - }
	    IF PLUS_VALUE THEN

	    BEGIN

		{ +
		If it's a string valued secondary, put the string out.
		- }
		IF SEC_TYPE[SECONDARY].STR THEN
    
		BEGIN

		    CHECK_QUOTES (STRING);

		    IF (STRING.DSC$W_LENGTH > 0) THEN

			WRITE (FDL_DEST,'	',STRING.DSC$A_POINTER^:
			STRING.DSC$W_LENGTH);

		END;
    
		{ +
		If it's a qualifier valued secondary, put the qualifier out.
		- }
		IF SEC_TYPE[SECONDARY].QUAL THEN
    
		    SHOW_QUALIFIER;
    
		{ +
		If it's a number valued secondary, put the number out.
		- }
		IF SEC_TYPE[SECONDARY].NUM THEN
    
		    { +
		    Show the number.
		    - }
		    WRITE (FDL_DEST,'	',NUMBER:NUM_LEN(NUMBER));

		{ +
		If it's a boolean valued secondary, put YES or NO out.
		- }
		IF SEC_TYPE[SECONDARY].SW THEN
    
		    IF SWITCH THEN
    
			WRITE (FDL_DEST,'	yes')
    
		    ELSE
    
			WRITE (FDL_DEST,'	no');
    
		IF (
		(SECONDARY = NULL_VALUE)
		OR
		(SECONDARY = MT_PROTECTION)
		) THEN

		BEGIN

		    IF (
		    (NUMBER < %X20)	{ SPACE }
		    OR
		    (NUMBER > %X7E)	{ ~ }
		    ) THEN

			WRITE (FDL_DEST,'	',NUMBER:NUM_LEN(NUMBER))

		    ELSE

			WRITE (FDL_DEST,'	''',CHR(NUMBER),'''');

		END;	{ IF SECONDARY = NULL_VALUE OR MT_PROTECTION }

		{ +
		Area Position is a special case.
		- }
		IF SECONDARY = POSITION$ THEN

		BEGIN

		    SHOW_QUALIFIER;

		    IF (
		    QUALIFIER IN [ FDL$C_CYLPOS, FDL$C_LOGPOS, FDL$C_VIRPOS, FDL$C_CLUSPOS ]
		    ) THEN

			{ +
			Show the number.
			- }
			WRITE (FDL_DEST,'	',NUMBER:NUM_LEN(NUMBER))

		    ELSE

		    BEGIN

			CASE QUALIFIER OF

			    FDL$C_FIDPOS :

			    BEGIN

				WRITE (FDL_DEST,
				'	(',FID1:NUM_LEN(FID1),',',
				FID2:NUM_LEN(FID2),',',
				FID3:NUM_LEN(FID3),')');

			    END;	{ FILE_ID }

			    FDL$C_FNMPOS :

			    BEGIN

				CHECK_QUOTES (STRING);

				IF (STRING.DSC$W_LENGTH > 0) THEN

				    WRITE (FDL_DEST,'	',STRING.DSC$A_POINTER^:
				    STRING.DSC$W_LENGTH);

			    END;	{ FILE_NAME }

			OTHERWISE

			    { NULL-STATEMENT } ;

			END;	{ CASE }

		    END;	{ IF FALSE QUALIFIER IN [ ... ] }
    
		END;	{ IF SECONDARY = POSITION$ }

		{ +
		OWNER is a special case.
		Use the special FAO directive to format the UIC.
		- }
		IF (SECONDARY = OWNER) THEN
    
		BEGIN

		    TEMP_INT2 := OWNER_UIC;
		    $FAOL ('!_!%I',RETLEN,TEMP_STRING255,TEMP_INT2);
		    WRITE (FDL_DEST,TEMP_STRING255:RETLEN);

		END;
    
		{ +
		PROTECTION is also a special case.
		- }
		IF (SECONDARY = PROTECTION) THEN
    
		BEGIN

		    WRITE (FDL_DEST,'	(system:');
		    SHOW_PROT (PROT_MASK,EDF$V_SYS);
		    WRITE (FDL_DEST,', owner:');
		    SHOW_PROT (PROT_MASK,EDF$V_OWN);
		    WRITE (FDL_DEST,', group:');
		    SHOW_PROT (PROT_MASK,EDF$V_GRP);
		    WRITE (FDL_DEST,', world:');
		    SHOW_PROT (PROT_MASK,EDF$V_WLD);
		    WRITE (FDL_DEST,')');

		END;	{ IF TRUE SECONDARY = PROTECTION }
    
		{ +
		If it has an end-of-line comment, put that out too.
		- }
		IF (COMMENT.DSC$W_LENGTH > 0) THEN
    
		    WRITE (FDL_DEST,'	',COMMENT.DSC$A_POINTER^:
		    COMMENT.DSC$W_LENGTH);
    
		{ +
		This actually does the QIO.
		- }
		WRITELN (FDL_DEST);

	    END;	{ IF PLUS_VALUE }

	END;	{ SEC }

	COM :

	WITH DEF_CURRENT^ DO

	BEGIN

	    { +
	    This is a full-line comment. Just output it.
	    - }
	    IF (COMMENT.DSC$W_LENGTH > 0) THEN

		WRITELN (FDL_DEST,COMMENT.DSC$A_POINTER^:
		COMMENT.DSC$W_LENGTH);

	END;	{ COM }

    OTHERWISE

	{ NULL-STATEMENT } ;

    END;	{ CASE }

    { +
    Keep track of the number of lines shown.
    - }
    LINES_SHOWN	:= LINES_SHOWN + 1;

    IF DEST_IS_TERMINAL THEN

    BEGIN

	IF DEF_CURRENT^.FORE <> NIL THEN

	    IF (
	    (((LINES_PER_PAGE - EDF$C_HEADROOM) - LINES_SHOWN) < 4)
	    AND
	    ((DEF_CURRENT^.PRIMARY <> DEF_CURRENT^.FORE^.PRIMARY)
	    OR
	    (DEF_CURRENT^.PRINUM <> DEF_CURRENT^.FORE^.PRINUM))
	    ) THEN

	    BEGIN

		{ +
		We're about to output a short primary, reset and
		clear the screen (after the user hits RETURN).
		- }
		LINES_SHOWN	:= 0;
		CLEAR (PAUSE);

	    END;

	IF (
	(LINES_SHOWN >= (LINES_PER_PAGE - EDF$C_HEADROOM))
	) THEN

	BEGIN

	    { +
	    The counter tripped, reset and clear the screen
	    (after the user hits RETURN).
	    - }
	    LINES_SHOWN	:= 0;
	    CLEAR (PAUSE);

	END;

    END;	{ IF DEST_IS_TERMINAL }

END;	{ SHOW_CURRENT }

{ ++

GENERATE_FDL -- Routine to output the FDL definition.

This routine outputs the FDL definition.

CALLING SEQUENCE:

GENERATE_FDL;

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

DEF_CURRENT
ANSI_REVERSE

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

FDL_DEST
LINES_SHOWN

ROUTINES CALLED:

CLEAR
SHOW_CURRENT
INCR_CURRENT
LIB$SIGNAL

ROUTINE VALUE:

none

SIGNALS:


SIDE EFFECTS:

none

-- }

PROCEDURE GENERATE_FDL;

VAR
    PREV_PRIMARY	: PRIMARY_TYPE;
    PREV_PRINUM		: INTEGER;

BEGIN

    { +
    Do the Primaries as stored in the Definition Linked List.
    - }
    DEF_CURRENT	:= DEF_HEAD;

    { +
    Setup to keep track of new primaries.
    - }
    PREV_PRINUM	:= -1;

    { +
    Initialize the line counter (incremented in SHOW_CURRENT).
    - }
    LINES_SHOWN	:= 0;

    { +
    Do it, if there is something to show.
    - }
    IF DEF_CURRENT <> NIL THEN

    BEGIN

	{ +
	List isn't empty, cycle through the line_objects and show them.
	At least until the end of the list, or until the user types ^Z.
	- }

	REPEAT

	    { +
	    Produce the textual version of the Definition Linked List.
	    Precede the 1st occurance of a primary with 2 blank lines.
	    - }
	    WITH DEF_CURRENT^ DO

	    BEGIN

		IF PREV_PRINUM < 0 THEN
    
		BEGIN
    
		    { +
		    Initial primary, don't skip lines here, just setup.
		    - }
		    PREV_PRIMARY	:= PRIMARY;
		    PREV_PRINUM		:= PRINUM;
    
		END
    
		ELSE
    
		BEGIN
    
		    { +
		    Skip a line if this is a new primary.
		    - }
		    IF NOT (
		    (PREV_PRIMARY = PRIMARY) AND (PREV_PRINUM = PRINUM)
		    ) THEN

		    BEGIN;

			PREV_PRIMARY	:= PRIMARY;
			PREV_PRINUM	:= PRINUM;

			{ +
			This is a new primary, put out a blank line.
			- }
			WRITELN (FDL_DEST);
			LINES_SHOWN	:= LINES_SHOWN + 1;

		    END;
    
		END;	{ IF FALSE PREV_PRINUM >= 0 }

	    END;	{ WITH DEF_CURRENT^ }

	    SHOW_CURRENT (TRUE);
	    INCR_CURRENT;

	UNTIL DEF_CURRENT = NIL;

    END;	{ IF FALSE DEF_CURRENT = NIL }

END;	{ GENERATE_FDL }

{ ++

VIEW_DEF -- Routine to show the user the Definition Linked List.

This routine will display the definition on the user's terminal.

CALLING SEQUENCE:

VIEW_DEF;

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

SYS$OUTPUT_NAME
DEF_CURRENT
CONTROL_ZEE_TYPED

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

SYS$INPUT: the terminal
DEST_IS_TERMINAL

ROUTINES CALLED:

CLEAR
GENERATE_FDL

ROUTINE VALUE:

none

SIGNALS:

none

SIDE EFFECTS:

none

-- }

PROCEDURE VIEW_DEF;

BEGIN

    { +
    Erase the user's screen.
    - }
    CLEAR (SCREEN);

    { +
    'Open' his terminal and initialize it.
    Close it first to avoid conflicts.
    - }
    DEST_IS_TERMINAL	:= TRUE;

    CLOSE	(FDL_DEST,ERROR := CONTINUE);
    OPEN	(FDL_DEST,SYS$OUTPUT_NAME,NEW,RECORD_LENGTH := 252);
    REWRITE	(FDL_DEST);

    { +
    Put the current definition out to the terminal.
    - }
    GENERATE_FDL;

    { +
    We're done, close it off.
    - }
    CLOSE	(FDL_DEST);

    { +
    Don't clear if the user hit ^Z, or if SHOW_CURRENT had just done a PAUSE.
    - }
    IF (NOT CONTROL_ZEE_TYPED) AND (LINES_SHOWN <> 0) THEN

    BEGIN

	WRITELN;
	CLEAR (PAUSE);

    END;

END;	{ VIEW_DEF }

{ ++

SHOW_PRIMARY_SECTION -- Display the whole primary section.

This routine outputs the selected primary section to the screen.

CALLING SEQUENCE:

SHOW_PRIMARY_SECTION (TEST);

INPUT PARAMETERS:

TEST

IMPLICIT INPUTS:

FDL_DEST
CONTROL_ZEE_TYPED
DEF_CURRENT
DEF_HEAD

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

SYS$OUTPUT:
DEF_CURRENT

ROUTINES CALLED:

CLEAR
INCR_CURRENT
SECTION_MATCH

ROUTINE VALUE:

none

SIGNALS:

none

SIDE EFFECTS:

none

-- }

[GLOBAL] PROCEDURE SHOW_PRIMARY_SECTION (TEST : LINE_OBJECT);

VAR
    AT_PRIMARY	: BOOLEAN;

BEGIN

    { +
    Show him that whole primary section.
    - }
    LINES_SHOWN		:= 0;

    { +
    Step through the whole list.
    - }
    DEF_CURRENT		:= DEF_HEAD;
    AT_PRIMARY		:= FALSE;

    REPEAT

	{ +
	If DEF_CURRENT points to a line_object in that primary, show it.
	- }
	IF CURRENT_EQ_TEST (TEST,FALSE) THEN
    
	BEGIN

	    SHOW_CURRENT (TRUE);
	    AT_PRIMARY	:= TRUE;

	END

	ELSE

	BEGIN

	    IF AT_PRIMARY THEN

		DEF_CURRENT	:= NIL;

	END;

	{ +
	Try the next.
	- }
	INCR_CURRENT;

    UNTIL DEF_CURRENT = NIL;
	
    WRITELN (FDL_DEST);

END;	{ SHOW_PRIMARY_SECTION }

{ ++

SHOW_ALL_PRIMARIES -- Display the existing primary attributes.

This routine outputs the existing primaries on the screen.

CALLING SEQUENCE:

SHOW_ALL_PRIMARIES;

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

FDL_DEST
CONTROL_ZEE_TYPED
DEF_CURRENT
DEF_HEAD

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

SYS$OUTPUT:
DEF_CURRENT

ROUTINES CALLED:

CLEAR
INCR_CURRENT
SECTION_MATCH

ROUTINE VALUE:

none

SIGNALS:

none

SIDE EFFECTS:

none

-- }

[GLOBAL] PROCEDURE SHOW_ALL_PRIMARIES;

BEGIN

    { +
    Show him all the primary attributes.
    - }
    LINES_SHOWN		:= 0;

    { +
    Step through the whole list.
    - }
    DEF_CURRENT		:= DEF_HEAD;

    REPEAT

	{ +
	If DEF_CURRENT points to a line_object that is a primary, show it.
	But not the Ident.
	- }
	IF (
	(DEF_CURRENT^.OBJECT_TYPE = PRI)
	AND
	(DEF_CURRENT^.PRIMARY <> IDENT)
	) THEN
    
	    SHOW_CURRENT (TRUE);
    
	{ +
	Try the next.
	- }
	INCR_CURRENT;

    UNTIL DEF_CURRENT = NIL;

    WRITELN (FDL_DEST);

END;	{ SHOW_ALL_PRIMARIES }

{ ++

SHOW_CUR_PRI_SEC -- Display the line_object pointed to by def_current.

This routine outputs the def_current line_object.

CALLING SEQUENCE:

SHOW_CUR_PRI_SEC;

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

FDL_DEST
CONTROL_ZEE_TYPED
DEF_CURRENT
DEF_HEAD

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

SYS$OUTPUT:
DEF_CURRENT

ROUTINES CALLED:

CLEAR
INCR_CURRENT
SECTION_MATCH

ROUTINE VALUE:

none

SIGNALS:

none

SIDE EFFECTS:

none

-- }

[GLOBAL] PROCEDURE SHOW_CUR_PRI_SEC (PLUS_VALUE : BOOLEAN);

VAR
    SAVE_OBJECT_TYPE		: LINE_OBJECT_TYPE;

BEGIN

    LINES_SHOWN			:= 0;

    { +
    Now display the 2 versions of the line_object.
    All this only works because the primary that a line_object is in
    is stored redundantly in all the subsequent secondaries.
    - }
    SAVE_OBJECT_TYPE		:= DEF_CURRENT^.OBJECT_TYPE;

    DEF_CURRENT^.OBJECT_TYPE	:= PRI;
    SHOW_CURRENT (PLUS_VALUE);

    IF DEF_CURRENT^.PRIMARY <> TITLE THEN

    BEGIN

	DEF_CURRENT^.OBJECT_TYPE := SEC;
	SHOW_CURRENT (PLUS_VALUE);

    END;

    DEF_CURRENT^.OBJECT_TYPE	:= SAVE_OBJECT_TYPE;

END;	{ SHOW_CUR_PRI_SEC }

END.
    { End of file: SRC$:EDFSHOW.PAS }
