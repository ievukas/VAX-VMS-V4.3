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

		V03-007 RRB0018		Rowland R. Bradley	10 Mar 1984
			Changes for signaling errors when user is
			/NOINT.

		V03-006	KFH0006		Ken Henderson		 8 Aug 1983
			Changes for seperate compilation.

		V03-005	KFH0005		Ken Henderson		14 Apr 1983
			Changed lib$wait(5.0) to (3.0).
			Added display of "TOKEN" on errors.

		V03-004	KFH0004		Ken Henderson		26 Jan 1983
			Fixed signal-vector before $PUTMSG
			calls by subtracting off PC/PSL.
			Also changed $PUTMSG of "file not found"
			to "new file will be created".

		V03-003	KFH0003		Ken Henderson		20 Jan 1983
			Removed references to DASH.

		V03-002	KFH0002		Ken Henderson		31 March 1982
			Modified RMS_INPUT_COND_HANDLER to fix
			FT2 QAR 968

		V03-001	KFH0001		Ken Henderson		23-Mar-1982
			Modified RMS_INPUT_COND_HANDLER to fix
			FT2 QAR 694

-- }

ENVIRONMENT ('LIB$:EDFCHF'),

INHERIT (

'SYS$LIBRARY:STARLET',
'SHRLIB$:FDLPARDEF',
'LIB$:EDFSDLMSG',
'LIB$:EDFSTRUCT',
'LIB$:EDFCONST',
'LIB$:EDFTYPE',
'LIB$:EDFVAR',
'LIB$:EDFEXTERN'

)]

MODULE EDFCHF;

{ ++

CTRLZ_COND_HANDLER -- Handle user typing control/Z.

This routine checks for control/Z signal from sys$input_cond_handler
and unwinds to the top level if found.
It also is the outermost handler and does a putmsg if it wasn't a ^Z.

CALLING SEQUENCE:

LIB$SIGNAL;

INPUT PARAMETERS:

SIGARGS
MECHARGS

IMPLICIT INPUTS:

none

OUTPUT PARAMETERS:

SIGARGS
MECHARGS

IMPLICIT OUTPUTS:

none

ROUTINES CALLED:

LIB$MATCH_COND
SYS$UNWIND

ROUTINE VALUE:

SS$_RESIGNAL if unable to handle error.  N/A if able (ignored on unwind).

SIGNALS:

Resignals if unable to handle error.

SIDE EFFECTS:

none

-- }

[ASYNCHRONOUS] FUNCTION CTRLZ_COND_HANDLER (
			    VAR SIGARGS : SIGARR;
			    VAR MECHARGS : MECHARR
				) : INTEGER;

BEGIN

    { +
    If we're already unwinding, skip everything.
    - }
    IF NOT (
    (LIB$MATCH_COND (SIGARGS[1],SS$_UNWIND))
    ) THEN

    BEGIN

	{ +
	Check for the ^Z "error".
	- }
	IF NOT (
	(LIB$MATCH_COND (SIGARGS[1],EDF$_CTRLZ))
	) THEN

	BEGIN

	    { +
	    Tell the user what the disaster was.
	    - }
	    SIGARGS[0] := SIGARGS[0] - 2;
	    $PUTMSG (SIGARGS);
	    SIGARGS[0] := SIGARGS[0] + 2;

	    { +
	    Wait for the user to see what happened.
	    - }
	    LIB$WAIT (3.0);

	END;	{ IF NOT LIB$MATCH_COND }

	{ +
	Put the terminal straight.
	And close any files open to the terminal.
	- }
	IF NOT AUTO_TUNE THEN

	BEGIN

	    EDF$RESET_SCROLL;

	    IF DEST_IS_TERMINAL THEN

		CLOSE (FDL_DEST,ERROR := CONTINUE);

	END;

	{ +
	Unwind (pop up) to the caller of the handler establisher.
	- }
	$UNWIND;

	{ +
	The function value is ignored if we did an unwind.
	- }
	CTRLZ_COND_HANDLER	:= SS$_RESIGNAL;

    END;	{ IF NOT UNWINDING }

END;	{ CTRLZ_COND_HANDLER }

{ ++

RMS_INPUT_COND_HANDLER -- Handle input file errors.

This routine checks for recoverable input errors from RMS files.

CALLING SEQUENCE:

LIB$SIGNAL;

INPUT PARAMETERS:

SIGARGS
MECHARGS

IMPLICIT INPUTS:

TAB
ANSI_REVERSE

OUTPUT PARAMETERS:

SIGARGS
MECHARGS

IMPLICIT OUTPUTS:

RMS_INPUT_ERROR
SYS$OUTPUT:, if the error is one we handle.

ROUTINES CALLED:

DELAY
LIB$MATCH_COND
SYS$UNWIND

ROUTINE VALUE:

SS$_RESIGNAL if unable to handle error.  N/A if able (ignored on unwind).

SIGNALS:

Resignals if unable to handle error.

SIDE EFFECTS:

none

-- }

[ASYNCHRONOUS] FUNCTION RMS_INPUT_COND_HANDLER (
			    VAR SIGARGS : SIGARR;
			    VAR MECHARGS : MECHARR
				) : INTEGER;

VAR
    FILENAME_PTR	: DESCRIPTOR_PTR;
    SEVERITY		: INTEGER;
    NEW_SEV		: INTEGER;

BEGIN

    { +
    If we're already unwinding, skip everything.
    - }
    IF NOT (
    (LIB$MATCH_COND (SIGARGS[1],SS$_UNWIND))
    ) THEN

    BEGIN

	RMS_INPUT_ERROR	:= TRUE;

	{ +
	Find out the severity of the error.
	- }
	SEVERITY  := LIB$EXTZV (STS$V_SEVERITY,STS$S_SEVERITY,SIGARGS[1]);

	{ +
	Show the user what's wrong, unless it'll come out on exit anyway.
	- }
	IF SEVERITY <> STS$K_SEVERE THEN

	BEGIN

	    SIGARGS[0] := SIGARGS[0] - 2;
	    $PUTMSG (SIGARGS);
	    SIGARGS[0] := SIGARGS[0] + 2;

	END;

	{ +
	Don't continue editing if this was a bad error.
	- }
	IF (SEVERITY IN [ STS$K_ERROR, STS$K_SEVERE ]) THEN

	    EDITING	:= FALSE;

	{ +
	Unwind if it's a file-not-found (only for definition file).
	Otherwise, let EDF exit on bad errors.
	- }
	IF (
	((SIGARGS[5] = RMS$_FNF) OR (SIGARGS[5] = SS$_NOSUCHFILE))
	AND
	(NOT ANALYSIS_ONLY)
	) THEN
	    BEGIN
	    { +
	    Keep editing;
	    Make the FDL error informational;
	    Tell the user what file wasn't found;
	    Unwind (pop up) to the caller of the handler establisher.
	    - }
	    IF NOT (AUTO_TUNE) 
	    THEN
		BEGIN
		EDITING	:= TRUE;
		NEW_SEV	:= STS$K_INFO;
		LIB$INSV (NEW_SEV,STS$V_SEVERITY,STS$S_SEVERITY,SIGARGS[1]);
		CHFFLAGS	:= 0;
		WRITEV (OUT_LINE,CRLF);
		LIB$PUT_LINE(OUT_LINE,ONE,CHFFLAGS);

		FILENAME_PTR	:= SIGARGS[3]::DESCRIPTOR_PTR;
		WRITEV (OUT_LINE,CRLF_SHIFT,
		FILENAME_PTR^.DSC$A_POINTER^:FILENAME_PTR^.DSC$W_LENGTH,
		' will be created.');
		LIB$PUT_LINE(OUT_LINE,ONE,CHFFLAGS);
		END
	    ELSE
		BEGIN
		SIGARGS[0] := SIGARGS[0] - 2;
		$PUTMSG (SIGARGS);
		SIGARGS[0] := SIGARGS[0] + 2;
		END;
	    $UNWIND;
	END;  { if sigargs } 
	{ +
	The function value is ignored if we did an unwind.
	- }
	RMS_INPUT_COND_HANDLER	:= SS$_CONTINUE;

    END;	{ IF NOT UNWINDING }

END;	{ RMS_INPUT_COND_HANDLER }

{ ++

SYS$INPUT_COND_HANDLER -- Check for recoverable typing errors.

This routine handles Pascal input errors caused by user garbage.

CALLING SEQUENCE:

LIB$SIGNAL;

INPUT PARAMETERS:

SIGARGS
MECHARGS

IMPLICIT INPUTS:

CONTROL_Z
TAB
ANSI_REVERSE

OUTPUT PARAMETERS:

SIGARGS
MECHARGS

IMPLICIT OUTPUTS:

CONTROL_ZEE_TYPED
ERR_CHAR
QUESTION_TYPED
TEMP_FULL_PROMPT
SYS$INPUT_ERROR
SYS$OUTPUT:, if the error is one we can handle.

ROUTINES CALLED:

DELAY
LIB$MATCH_COND
SYS$UNWIND

ROUTINE VALUE:

SS$_RESIGNAL, if not unwinding.  N/A if it is unwinding.

SIGNALS:

Resignals if it can't process the signal.

SIDE EFFECTS:

none

-- }

[ASYNCHRONOUS] FUNCTION SYS$INPUT_COND_HANDLER (
			    VAR SIGARGS : SIGARR;
			    VAR MECHARGS : MECHARR
				) : INTEGER;

VAR
    TEMP_UNSIGNED	: UNSIGNED;

BEGIN

    { +
    If we're already unwinding, skip everything.
    - }
    IF NOT (
    (LIB$MATCH_COND (SIGARGS[1],SS$_UNWIND))
    ) THEN

    BEGIN

	{ +
	Check for bad typed input.
	- }
	IF (

	(LIB$MATCH_COND (SIGARGS[1],PAS$_GETAFTEOF))
	OR
	(LIB$MATCH_COND (SIGARGS[1],PAS$_SUBASGVAL))
	OR
	(LIB$MATCH_COND (SIGARGS[1],PAS$_AMBVALENU))
	OR
	(LIB$MATCH_COND (SIGARGS[1],PAS$_INVSYNENU))
	OR
	(LIB$MATCH_COND (SIGARGS[1],PAS$_INVSYNINT))
	OR
	(LIB$MATCH_COND (SIGARGS[1],PAS$_INVSYNREA))
	OR
	(LIB$MATCH_COND (SIGARGS[1],PAS$_INVSYNUNS))
	OR
	(LIB$MATCH_COND (SIGARGS[1],PAS$_NOTVALTYP))

	OR

	(LIB$MATCH_COND (SIGARGS[1],EDF$_CTRLZ))
	OR
	(LIB$MATCH_COND (SIGARGS[1],EDF$_AMBIG))
	OR
	(LIB$MATCH_COND (SIGARGS[1],EDF$_BADSYNTAX))
	OR
	(LIB$MATCH_COND (SIGARGS[1],EDF$_BADVALUE))
	OR
	(LIB$MATCH_COND (SIGARGS[1],EDF$_NODEFAULT))

	) THEN

	BEGIN

	    CONTROL_ZEE_TYPED	:= LIB$MATCH_COND (SIGARGS[1],EDF$_CTRLZ);

	    { +
	    Fudge for top-level ^Z exiting.
	    - }
	    IF MAIN_LEVEL THEN

		MAIN_CTRLZ		:= CONTROL_ZEE_TYPED;

	    { +
	    If it was ^Z, don't look at the input string - there's nothing there.
	    - }
	    IF CONTROL_ZEE_TYPED THEN

		ERR_CHAR		:= CONTROL_Z

	    ELSE

		{ +
		Get the offending character to see what it is.
		- }
		ERR_CHAR		:= INPUT_STRING[1];

	    { +
	    One "garbage" character is "?" - which causes flags to get set.
	    - }
	    IF ERR_CHAR = QUESTION_MARK THEN

	    BEGIN

		QUESTION_TYPED		:= TRUE;
		TEMP_FULL_PROMPT	:= TRUE;

	    END

	    ELSE

		QUESTION_TYPED	:= FALSE;

	    { +
	    Tell the user he messed up, if he didn't type control/Z or "?".
	    - }
	    IF NOT ( CONTROL_ZEE_TYPED OR QUESTION_TYPED ) THEN

	    BEGIN

		{ +
		Fetch the token that messed up.
		- }
		TEMP_DESCRIPTOR			:= NULL_STRING;
		TEMP_DESCRIPTOR.DSC$A_POINTER	:= PARAM_BLOCK.TPA$L_TOKENPTR;
		TEMP_UNSIGNED			:= PARAM_BLOCK.TPA$L_TOKENCNT;
		TEMP_DESCRIPTOR.DSC$W_LENGTH	:= TEMP_UNSIGNED::WORD;

		{ +
		Print out the appropriate error message.
		- }
		IF (LIB$MATCH_COND (SIGARGS[1],EDF$_NODEFAULT)) THEN

		    WRITEV (OUT_LINE,SHIFT,
		    ' You must provide an answer here (or ^Z for Main Menu). ')

		ELSE IF (LIB$MATCH_COND (SIGARGS[1],EDF$_AMBIG)) THEN

		    WRITEV (OUT_LINE,SHIFT,
		    ' "',TEMP_DESCRIPTOR.DSC$A_POINTER^:
		    TEMP_DESCRIPTOR.DSC$W_LENGTH,
		    '" is ambiguous in this context. ')

		ELSE IF (LIB$MATCH_COND (SIGARGS[1],EDF$_BADSYNTAX)) THEN

		    WRITEV (OUT_LINE,SHIFT,
		    ' "',TEMP_DESCRIPTOR.DSC$A_POINTER^:
		    TEMP_DESCRIPTOR.DSC$W_LENGTH,
		    '" contains a syntax error. ')

		ELSE IF (LIB$MATCH_COND (SIGARGS[1],EDF$_BADVALUE)) THEN

		    WRITEV (OUT_LINE,SHIFT,
		    ' "',TEMP_DESCRIPTOR.DSC$A_POINTER^:
		    TEMP_DESCRIPTOR.DSC$W_LENGTH,
		    '" is not appropriate in this context. ');

		CHFFLAGS	:= SCR$M_REVERSE;
		LIB$PUT_LINE(OUT_LINE,ONE,CHFFLAGS);
		STR$FREE1_DX (INPUT_DESC);

		{ +
		Let the user see the message.
		- }
		LIB$WAIT (2.0);

		{ +
		Give the user some help.
		- }
		QUESTION_TYPED		:= TRUE;
		TEMP_FULL_PROMPT	:= TRUE;

	    END;

	    { +
	    Flag the error and unwind back to the caller of the establisher.
	    - }
	    SYS$INPUT_ERROR	:= TRUE;

	    IF NOT CONTROL_ZEE_TYPED THEN

		{ +
		Unwind (pop up) to the caller of the handler establisher.
		- }
		$UNWIND;

	END;

	{ +
	If we unwound, the function value will be ignored.
	If we didn't, we couldn't handle the error, so resignal.
	- }
	SYS$INPUT_COND_HANDLER	:= SS$_RESIGNAL;

    END;	{ IF NOT UNWINDING }

END;	{ SYS$INPUT_COND_HANDLER }

END.
    { End of file: SRC$:EDFCHF.PAS }
