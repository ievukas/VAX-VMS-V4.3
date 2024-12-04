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

		V03-011 RRB0009		Rowland R. Bradley	22 Jan 1984
			Enhancement for display of # of buckets in index,
			# pages to cache index, and average # key exams.

		V03-010	KFH0010		Ken Henderson		 8 Aug 1983
			Changes for seperate compilation.

		V03-009	KFH0009		Ken Henderson		27 Jul 1983
			Fix to CALC_ALLOC to prevent div by 0.
			Fixed record and bucket overhead
			calculations in prologue3_buckets and
			prologue3_depth.

		V03-008	KFH0008		Ken Henderson		27 May 1983
			Fix insertion of DATA_RECORD_COMPRESSION
			into database to only do it for Key 0.

		V03-007	KFH0007		Ken Henderson		26 Apr 1983
			Fix location of breakpoint_right.
			Add reset of IDATA[EDF$K_Y_LOW/HIGH/INCR]
			in SETUP_GRAPH. Clean up calls to
			ASK_KEY_SIZE, ASK_KEY_POSITION.
			Move call to ASK_GLOBAL_WANTED
			to APPEND_DEF.

		V03-006	KFH0006		Ken Henderson		14 Apr 1983
			Removed mandatory VIEWs after
			each design. Changed lib$wait(5.0)
			to (3.0). Took out DESIGN_STYLE.
			Consolidated PLOT_SIMPLE_GRAPH
			and PLOT_SURFACE_GRAPH. Added
			SHUFFLE_AREAS and MERGE_AREA
			to implement GRANULARITY.

		V03-005	KFH0005		Ken Henderson		20 Jan 1983
			Added support for DEPTHPOINTs
			and removed references to DASH.

		V03-004	KFH0004		Ken Henderson		22 Nov 1982
			Combined SURFACE_DESIGN and
			LINE_DESIGN into one routine.

		V03-003	KFH0003		Ken Henderson		8 Sept 1982
			Modified most references to main
			variables to fit with database
			reorganization.

		V03-002	KFH0002		Ken Henderson		23-Mar-1982
			Modified several routines to fix FT2
			QAR 746

		V03-001	KFH0001		Ken Henderson		17-Mar-1982
			Modified several routines to fix FT2
			QARs 509,559,510,574

-- }

ENVIRONMENT ('LIB$:EDFDESIGN'),

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
'LIB$:EDFSHOW'

)]

MODULE EDFDESIGN (INPUT,OUTPUT);

{ ++

PROLOGUE3_BUCKETS -- Routine to calculate the number of buckets at a level.

This routine combines the various file parameters of a prologue3 file and
calls itself recursively to find the number of buckets at each level.

CALLING SEQUENCE:

PROLOGUE3_BUCKETS (INIT_NUMBER_RECORDS,ADDED_NUMBER_RECORDS,INDEX_LEVEL);

INPUT PARAMETERS:

NUMBER_RECORDS
INDEX_LEVEL

IMPLICIT INPUTS:

VARIABLE_RECORDS
BDATA[EDF$K_KEY_DUPS]
IDATA[EDF$K_KEY_SIZE]
IDATA[EDF$K_MEAN_RECORD_SIZE]
RDATA[EDF$K_LOAD_FILL]
BYTES_PER_BUCKET

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

INIT_NUMBER_BUCKETS
ADDED_NUMBER_BUCKETS
DEEPEST

ROUTINES CALLED:

PROLOGUE3_BUCKETS
LIB$SIGNAL

ROUTINE VALUE:

none

SIGNALS:

EDF$_CTRLZ - if a file > 31 index levels was spec'd

SIDE EFFECTS:

none

-- }

PROCEDURE PROLOGUE3_BUCKETS (
			INIT_NUMBER_RECORDS	: INTEGER;
			ADDED_NUMBER_RECORDS	: INTEGER;
			INDEX_LEVEL		: INTEGER
			);

VAR
    INIT_RECORDS_PER_BUCKET	: INTEGER;
    ADDED_RECORDS_PER_BUCKET	: INTEGER;
    RECORD_OVERHEAD		: INTEGER;
    RECORD_SIZE			: INTEGER;
    INIT_AVAILABLE_BYTES	: INTEGER;
    ADDED_AVAILABLE_BYTES	: INTEGER;
    KEY_SAVINGS			: INTEGER;
    DATA_SAVINGS		: INTEGER;
    INDEX_SAVINGS		: INTEGER;
    BUCKET_OVERHEAD		: INTEGER;
    TEMP_REC			: INTEGER;
    FOUND			: BOOLEAN;

BEGIN

    { +
    Level 0 is the data level, calculate the filling of the data buckets.
    - }
    BUCKET_OVERHEAD	:= CALC_BUC_OVERHEAD(INDEX_LEVEL);
    RECORD_OVERHEAD	:= CALC_REC_OVERHEAD(INDEX_LEVEL);

    IF INDEX_LEVEL = 0 THEN

    BEGIN

	IF IDATA[EDF$K_ACTIVE_KEY] = 0 THEN

	BEGIN

	    { +
	    DATA BUCKET
	    - }

	    { +
	    Combine the two compression factors to get one to weight the record
	    size by.
	    - }
	    KEY_SAVINGS		:=
		TRUNC (IDATA[EDF$K_KEY_SIZE] * RDATA[EDF$K_DATA_KEY_COMP]);
	    DATA_SAVINGS	:=
	  	TRUNC ((IDATA[EDF$K_MEAN_RECORD_SIZE] - IDATA[EDF$K_KEY_SIZE])
		* RDATA[EDF$K_DATA_RECORD_COMP]);

	    { +
	    The 'actual' record size will have the compression subtracted from it.
	    - }
	    RECORD_SIZE		:=
		IDATA[EDF$K_MEAN_RECORD_SIZE] - (KEY_SAVINGS + DATA_SAVINGS);

	END	{ IF TRUE KEY = 0 }

	ELSE

	BEGIN

	    { +
	    SIDR BUCKET
	    - }

	    INDEX_SAVINGS	:=
		TRUNC (IDATA[EDF$K_KEY_SIZE] * RDATA[EDF$K_DATA_KEY_COMP]);

	    TEMP_REC		:= IDATA[EDF$K_KEY_SIZE] - INDEX_SAVINGS;

	    TEMP_REC	       := TEMP_REC + 
	    			(IDATA[EDF$K_NUMBER_DUPS] * IRC$C_RRVOVHSZ3);

	    RECORD_SIZE		:= TEMP_REC DIV (IDATA[EDF$K_NUMBER_DUPS] + 1);

	    IF (TEMP_REC MOD (IDATA[EDF$K_NUMBER_DUPS] + 1) <> 0) THEN

		RECORD_SIZE	:= RECORD_SIZE + 1;

	END;	{ IF FALSE KEY = 0 }

    END		{ IF TRUE INDEX_LEVEL = 0 (DATA LEVEL) }

    ELSE

    { +
    For the index levels (L>0), the overheads are as follows.
    - }
    BEGIN

	{ +
	INDEX BUCKET
	- }

	INDEX_SAVINGS		:=
		TRUNC (IDATA[EDF$K_KEY_SIZE] * RDATA[EDF$K_INDEX_RECORD_COMP]);
	RECORD_SIZE		:= IDATA[EDF$K_KEY_SIZE] - INDEX_SAVINGS;

    END;	{ IF FALSE INDEX_LEVEL = 0 }

    { +
    Now that we've figured out the overheads, how many records can we fit
    in a bucket at this level?
    - }

    { +
    First figure out how many bytes are available to use for records.
    - }
    INIT_AVAILABLE_BYTES	:=
    	TRUNC ((BYTES_PER_BUCKET - BUCKET_OVERHEAD) * RDATA[EDF$K_LOAD_FILL]);
    ADDED_AVAILABLE_BYTES	:=
   	TRUNC ((BYTES_PER_BUCKET - BUCKET_OVERHEAD) * RDATA[EDF$K_ADDED_FILL]);

    { +
    The number of records that will fit is simply the space available
    divided by the space for each record. (integer division)
    - }
    INIT_RECORDS_PER_BUCKET	:=
		INIT_AVAILABLE_BYTES DIV (RECORD_SIZE + RECORD_OVERHEAD);
    ADDED_RECORDS_PER_BUCKET	:=
		ADDED_AVAILABLE_BYTES DIV (RECORD_SIZE + RECORD_OVERHEAD);

    { +
    CONVERT or RMS will put at least one (1) record in a data level bucket.
    And it will put at least two (2) records in an index level bucket.
    - }
    IF (INDEX_LEVEL = 0) AND (INIT_RECORDS_PER_BUCKET < 1) THEN

	INIT_RECORDS_PER_BUCKET		:= 1

    ELSE IF (INDEX_LEVEL > 0) AND (INIT_RECORDS_PER_BUCKET < 2) THEN

	INIT_RECORDS_PER_BUCKET		:= 2;

    IF (INDEX_LEVEL = 0) AND (ADDED_RECORDS_PER_BUCKET < 1) THEN

	ADDED_RECORDS_PER_BUCKET	:= 1

    ELSE IF (INDEX_LEVEL > 0) AND (ADDED_RECORDS_PER_BUCKET < 2) THEN

	ADDED_RECORDS_PER_BUCKET	:= 2;

    { + Record the number of buckets for later.
    - }
    RECS_PER_BUCKET [INDEX_LEVEL]	:= 
		INIT_RECORDS_PER_BUCKET  +  ADDED_RECORDS_PER_BUCKET;
					   
    { +
    Now record the number of buckets at this level.
    - }
    INIT_NUMBER_BUCKETS [INDEX_LEVEL]	:=
		INIT_NUMBER_RECORDS DIV INIT_RECORDS_PER_BUCKET;
    ADDED_NUMBER_BUCKETS [INDEX_LEVEL]	:=
		ADDED_NUMBER_RECORDS DIV ADDED_RECORDS_PER_BUCKET;

    { +
    If there was a remainder, we need just one more bucket at this level.
    - }
    IF (INIT_NUMBER_RECORDS MOD INIT_RECORDS_PER_BUCKET) <> 0 THEN

	INIT_NUMBER_BUCKETS [INDEX_LEVEL] :=
	INIT_NUMBER_BUCKETS [INDEX_LEVEL] + 1;

    IF (ADDED_NUMBER_RECORDS MOD ADDED_RECORDS_PER_BUCKET) <> 0 THEN

	ADDED_NUMBER_BUCKETS [INDEX_LEVEL] :=
	ADDED_NUMBER_BUCKETS [INDEX_LEVEL] + 1;

    { +
    Save the number of buckets for later if this is key 0.
    They are used in global buffer count calculations.
    - }
    IF IDATA[EDF$K_ACTIVE_KEY] = 0 THEN

    BEGIN

	INIT_PRIMARY_BUCKETS [INDEX_LEVEL]	:=
				INIT_NUMBER_BUCKETS [INDEX_LEVEL];
	ADDED_PRIMARY_BUCKETS [INDEX_LEVEL]	:=
				ADDED_NUMBER_BUCKETS [INDEX_LEVEL];

    END;

    { +
    Bump the high-water marker.
    - }
    DEEPEST		:= INDEX_LEVEL;

    { +
    If we're at the data level, or we had more than one bucket at this level,
    then repeat the calculations for the next level up (down?).
    - }
    IF (
    (INDEX_LEVEL = 0)
    OR
    (INIT_NUMBER_BUCKETS [INDEX_LEVEL] > 1)
    OR
    (ADDED_NUMBER_BUCKETS [INDEX_LEVEL] > 1)
    ) THEN

    BEGIN

	{ +
	In the index, the records merely point to buckets.
	- }
	IF INDEX_LEVEL = 0 THEN

	BEGIN

	    FOUND	:= FALSE;

	    IF OPTIMIZING THEN

	    BEGIN

		POINT_AT_ANALYSIS;

		FOUND	:=  FIND_OBJECT (SEC,ANALYSIS_OF_KEY,
					    IDATA[EDF$K_ACTIVE_KEY],
					    LEVEL1_RECORD_COUNT,0);

		POINT_AT_DEFINITION;

	    END;

	    IF FOUND THEN

	    BEGIN

		INIT_NUMBER_RECORDS	:= DEF_CURRENT^.NUMBER;

	    END

	    ELSE

	    BEGIN

		INIT_NUMBER_RECORDS	:= INIT_NUMBER_BUCKETS [INDEX_LEVEL];

	    END;

	END

	ELSE

	BEGIN

	    INIT_NUMBER_RECORDS	:= INIT_NUMBER_BUCKETS [INDEX_LEVEL];

	END;

	ADDED_NUMBER_RECORDS	:= ADDED_NUMBER_BUCKETS [INDEX_LEVEL];

	INDEX_LEVEL		:= INDEX_LEVEL + 1;

	{ +
	Pathological file here - tell the user and pop him up.
	- }
	IF INDEX_LEVEL > 31 THEN

	BEGIN

	    WRITELN (SHIFT,ANSI_REVERSE,
	    ' A File of Greater than 31 Index Levels has been specified. ',
	    ANSI_RESET);

	    LIB$WAIT (3.0);

	    LIB$SIGNAL (EDF$_CTRLZ,0,0,0);

	END;

	{ +
	Recurse to the next level.
	- }
	PROLOGUE3_BUCKETS (
			    INIT_NUMBER_RECORDS,
			    ADDED_NUMBER_RECORDS,
			    INDEX_LEVEL
			    );

    END;

END;	{ PROLOGUE3_BUCKETS }

{ ++

PROLOGUE3_DEPTH -- Routine to calculate the depth of a prologue3 index.

This routine combines the various file parameters of a prologue3 file and
'builds' and index from the data level up to the root - to find its depth.

CALLING SEQUENCE:

DEPTH	:= PROLOGUE3_DEPTH;

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

TOTAL_RECORDS
IDATA[EDF$K_BLOCKS_IN_BUCKET]
DEEPEST

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

BYTES_PER_BUCKET
NUMBER_BUCKETS

ROUTINES CALLED:

PROLOGUE3_BUCKETS

ROUTINE VALUE:

Depth of the index

SIGNALS:

none

SIDE EFFECTS:

none

-- }

FUNCTION PROLOGUE3_DEPTH : INTEGER;

VAR
    BUCKET_OVERHEAD	: INTEGER;
    RECORD_OVERHEAD	: INTEGER;
    RECORD_SIZE		: INTEGER;
    I			: INTEGER;

BEGIN

    { +
    Clear out the arrays that holds the number of buckets per level.
    - }
    FOR I := 0 TO 31 DO

    BEGIN

	INIT_NUMBER_BUCKETS [I]		:= 0;
	ADDED_NUMBER_BUCKETS [I]	:= 0;
	RECS_PER_BUCKET [I]		:= 0;

    END;

    { +
    Convert block/bucket to bytes/bucket.
    - }
    BYTES_PER_BUCKET		:= IDATA[EDF$K_BLOCKS_IN_BUCKET] * 512;

    { +
    Reset depth and calculate how deep the index will be.
    - }
    DEEPEST			:= 0;

    { +
    Figure depth only if the record will fit in the bucket.
    Otherwise flag it.
    - }
    BUCKET_OVERHEAD	:= CALC_BUC_OVERHEAD(0);
    RECORD_OVERHEAD	:= CALC_REC_OVERHEAD(0);

    IF IDATA[EDF$K_MAX_RECORD_SIZE] = 0 THEN

	RECORD_SIZE	:= CUR_MAX_REC

    ELSE

	RECORD_SIZE	:= IDATA[EDF$K_MAX_RECORD_SIZE];

    { +
    Only do the depth calculation if the record will fit in the bucket,
    and the key will fit in the record.
    - }
    IF (
    ((BYTES_PER_BUCKET - (BUCKET_OVERHEAD + RECORD_OVERHEAD)) >=
    IDATA[EDF$K_MEAN_RECORD_SIZE])
    AND
    (RECORD_SIZE >= (IDATA[EDF$K_KEY_SIZE] + IDATA[EDF$K_KEY_POSITION]))
    ) THEN

    BEGIN

	CASE IDATA[EDF$K_LOAD_METHOD] OF

	    EDF$K_FAST_CONVERT :

		RDATA[EDF$K_LOAD_FILL]	:= IDATA[EDF$K_DESIRED_FILL] / 100.0;

	    EDF$K_NOFAST_CONVERT :

		IF BDATA[EDF$K_ASCENDING_LOAD] THEN

		    RDATA[EDF$K_LOAD_FILL]	:=
				0.90 * (IDATA[EDF$K_DESIRED_FILL] / 100.0)

		ELSE

		    RDATA[EDF$K_LOAD_FILL]	:=
				0.6667 * (IDATA[EDF$K_DESIRED_FILL] / 100.0);

	    EDF$K_RMS_PUTS :

	    BEGIN

		IF BDATA[EDF$K_ASCENDING_LOAD] THEN

		    RDATA[EDF$K_LOAD_FILL]	:=
				0.90 * (IDATA[EDF$K_DESIRED_FILL] / 100.0)

		ELSE

		    RDATA[EDF$K_LOAD_FILL]	:=
				0.6667 * (IDATA[EDF$K_DESIRED_FILL] / 100.0);

		IDATA[EDF$K_FDL_FILL]	:= 100;

	    END;

	OTHERWISE

	    { NULL-STATEMENT } ;

	END;	{ CASE }

	IF BDATA[EDF$K_ASCENDING_ADDED] THEN

	    RDATA[EDF$K_ADDED_FILL]	:= 0.90

	ELSE

	    RDATA[EDF$K_ADDED_FILL]	:= 0.6667;

       PROLOGUE3_BUCKETS(IDATA[EDF$K_INITIAL_COUNT],IDATA[EDF$K_ADDED_COUNT],0);
    
	{ +
	The deepest we went is the function value.
	- }
	PROLOGUE3_DEPTH		:= DEEPEST;

    END

    ELSE

	PROLOGUE3_DEPTH		:= 0;

END;	{ PROLOGUE3_DEPTH }

{ ++

NATURAL_DEPTH -- Find most typical depth of file.

This routine does calculations to find out the most reasonable bucketsize
for an index.

CALLING SEQUENCE:

BUCKET_DEFAULT	:= NATURAL_DEPTH;

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

none

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

COLOR_ROW

ROUTINES CALLED:

none

ROUTINE VALUE:

BUCKET_DEFAULT

SIGNALS:

none

SIDE EFFECTS:

none

-- }

[GLOBAL] FUNCTION NATURAL_DEPTH : INTEGER;

VAR
    DEPTH		: ARRAY [1..BKT$C_MAXBKTSIZ] OF INTEGER;
    TALLY		: ARRAY [1..BKT$C_MAXBKTSIZ] OF REAL;
    CURRENT_WEIGHT	: REAL;
    CURRENT_TALLY	: REAL;
    MAX_TALLY		: REAL;
    TEMP_DIST		: INTEGER;
    LEFT_ADJ_RANGE	: INTEGER;
    CURRENT_DEPTH	: INTEGER;
    RANGE		: INTEGER;
    MAX_RANGE		: INTEGER;
    MIN_BKS		: INTEGER;



	PROCEDURE EXTEND_INDEX_INFO (VAR EXAMPOINT, 
					 NUMPOINT, 
					 PAGEPOINT, 
					 BREAKPOINT : INTEGER);
	{ +
	    Calculate and save more index information.
	- }
	VAR
	    I			: INTEGER;

	BEGIN
	    IDATA [EDF$K_BLOCKS_IN_BUCKET]	:= BREAKPOINT;
	    TEMP_DIST				:= PROLOGUE3_DEPTH;
	    EXAMPOINT				:= 0;
	    NUMPOINT				:= 0;

	    FOR I := 1 TO 31 DO
	    BEGIN

		EXAMPOINT	:= EXAMPOINT  +  RECS_PER_BUCKET [I];
		NUMPOINT	:= 
		NUMPOINT  +  INIT_NUMBER_BUCKETS [I]   +  ADDED_NUMBER_BUCKETS [I];

	    END; { FOR }

	    EXAMPOINT	:= EXAMPOINT DIV 2;
	    PAGEPOINT	:= NUMPOINT * BREAKPOINT;

	END; { procedure EXTEND_INDEX_INFO }


{ +
Main Function Begins Here
- }
BEGIN

    BREAKPOINT_RIGHT	:= 0;

    { +
    Fill the depth array with the depths at each bucketsize.
    And zero out the tally array.
    - }
    FOR RANGE := 1 TO BKT$C_MAXBKTSIZ DO

    BEGIN

	IDATA[EDF$K_BLOCKS_IN_BUCKET]	:= RANGE;
	DEPTH[RANGE]			:= PROLOGUE3_DEPTH;
	TALLY[RANGE]			:= 0;

    END;	{ FOR }

    { +
    Add up the lengths of the ranges.
    - }
    CURRENT_WEIGHT	:= 1.0;
    CURRENT_DEPTH	:= 0;
    CURRENT_TALLY	:= 0;

    FOR RANGE := BKT$C_MAXBKTSIZ DOWNTO 1 DO

    BEGIN

	IF DEPTH[RANGE] = 0 THEN

	BEGIN

	    IF RANGE < BKT$C_MAXBKTSIZ THEN

		IF DEPTH[RANGE+1] > 0 THEN

		    TALLY[RANGE+1]	:= CURRENT_TALLY;

	    TALLY[RANGE]	:= 0;

	END

	ELSE IF DEPTH[RANGE] > CURRENT_DEPTH THEN

	BEGIN

	    IF RANGE < BKT$C_MAXBKTSIZ THEN

		TALLY[RANGE+1]	:= CURRENT_TALLY;

	    CURRENT_DEPTH	:= DEPTH[RANGE];
	    CURRENT_TALLY	:= CURRENT_WEIGHT;

	END

	ELSE

	BEGIN

	    { +
	    Bucket sizes from 33 to 63 aren't added in.
	    - }
	    IF RANGE < 33 THEN

		CURRENT_TALLY	:= CURRENT_TALLY + CURRENT_WEIGHT;

	END;

	IF IDATA[EDF$K_BUCKET_WEIGHT] = EDF$K_SMALLER_BUFFERS THEN

	    CURRENT_WEIGHT	:= CURRENT_WEIGHT + BUCKET_LEFT_WEIGHT;

    END;	{ FOR }

    MAX_TALLY		:= 0;
    MAX_RANGE		:= 0;
    MIN_BKS		:= 1;

    { +
    Minimum bucket size may be greater than one.  Determine it here.
    - }
    FOR RANGE := 1 TO BKT$C_MAXBKTSIZ DO

	IF DEPTH[RANGE] < 1 THEN
	BEGIN
	    MIN_BKS		:= RANGE + 1;
	END;

    { +
    Now find the left end of the most common range (that's not 0).
    - }
    FOR RANGE := BKT$C_MAXBKTSIZ DOWNTO MIN_BKS DO

	IF TALLY[RANGE] > MAX_TALLY THEN

	BEGIN

	    MAX_TALLY	:= TALLY[RANGE];
	    MAX_RANGE	:= RANGE;

	END;

    { +
    Sometimes there aren't any values at all on a row...
    - }
    IF MAX_RANGE < 1 THEN

	MAX_RANGE	:= 1;

    { +
    Now let's calculate what the colors are for this row.
    Right part 1st...
    - }
    FOR RANGE := MAX_RANGE TO BKT$C_MAXBKTSIZ DO

    BEGIN

	TEMP_DIST	:= RANGE - MAX_RANGE;

	IF TEMP_DIST < 9 THEN

	BEGIN

	    COLOR_ROW[RANGE-1]	:= EDF$C_LIGHT_GREEN;

	END

	ELSE IF (
	(TEMP_DIST > 8)
	AND
	(TEMP_DIST < 21)
	) THEN

	BEGIN

	    COLOR_ROW[RANGE-1]	:= EDF$C_MEDIUM_YELLOW;

	END

	ELSE

	BEGIN

	    COLOR_ROW[RANGE-1]	:= EDF$C_DARK_RED;

	END;

	{ +
	Make sure the green region includes only one depth.
	- }
	IF (
	(DEPTH[RANGE] <> DEPTH[MAX_RANGE])
	AND
	(COLOR_ROW[RANGE-1] = EDF$C_LIGHT_GREEN)
	) THEN

	    COLOR_ROW[RANGE-1]	:= EDF$C_MEDIUM_YELLOW;

	{ +
	If there's a point where we can get even a flatter file,
	note that.
	- }
	IF (
	(DEPTH[RANGE] < DEPTH[MAX_RANGE])
	AND
	(BREAKPOINT_RIGHT = 0)
	) THEN

	    BREAKPOINT_RIGHT	:= MAX_FACTOR (IDATA[EDF$K_CLUSTER_SIZE],
					RANGE,BKT$C_MAXBKTSIZ);

    END;	{ FOR }

    { +
    Now do to the left of natural.
    - }
    IF MAX_RANGE = 1 THEN

    BEGIN

	COLOR_ROW[0]	:= EDF$C_LIGHT_GREEN;
	LEFT_ADJ_RANGE	:= DEPTH[MAX_RANGE];

    END

    ELSE

    BEGIN

	LEFT_ADJ_RANGE	:= DEPTH[MAX_RANGE-1];
    
	FOR RANGE := (MAX_RANGE-1) DOWNTO 1 DO
    
	BEGIN
    
	    IF DEPTH[RANGE] = LEFT_ADJ_RANGE THEN
    
		COLOR_ROW[RANGE-1]	:= EDF$C_MEDIUM_YELLOW
    
	    ELSE
    
		COLOR_ROW[RANGE-1]	:= EDF$C_DARK_RED;
    
	END;

    END;	{ IF FALSE MAX_RANGE = 1 }

    { +
    Now blank out any illegal spots.
    - }
    FOR RANGE := 1 TO BKT$C_MAXBKTSIZ DO

	IF DEPTH[RANGE] < 1 THEN
	BEGIN
	    COLOR_ROW[RANGE-1]	:= EDF$C_BACKGROUND_COLOR;
	END;
    { +
    Now fill in the breakpoint variables.
    Mid is easy.
    - }
    BREAKPOINT_MID	:= MAX_FACTOR (IDATA[EDF$K_CLUSTER_SIZE],
				MAX_RANGE,BKT$C_MAXBKTSIZ);

    IF BREAKPOINT_RIGHT = 0 THEN

    BEGIN

	{ +
	Breakpoint_right.
	- }
	RANGE		:= MAX_RANGE;

	WHILE (
	(RANGE < BKT$C_MAXBKTSIZ)
	AND
	(COLOR_ROW[RANGE-1] = EDF$C_LIGHT_GREEN)
	) DO

	    RANGE		:= RANGE + 1;

	IF COLOR_ROW[RANGE-1] <> EDF$C_BACKGROUND_COLOR THEN

	    BREAKPOINT_RIGHT	:= MAX_FACTOR (IDATA[EDF$K_CLUSTER_SIZE],
					RANGE,BKT$C_MAXBKTSIZ)

	ELSE IF RANGE <> MAX_RANGE THEN

	    BREAKPOINT_RIGHT	:= MAX_FACTOR (IDATA[EDF$K_CLUSTER_SIZE],
					(RANGE-1),BKT$C_MAXBKTSIZ)

	ELSE

	    BREAKPOINT_RIGHT	:= MAX_FACTOR (IDATA[EDF$K_CLUSTER_SIZE],
					MAX_RANGE,BKT$C_MAXBKTSIZ);

    END;	{ IF BREAKPOINT_RIGHT = 0 }

    { +
    Breakpoint_left.
    - }
    RANGE		:= MAX_RANGE - 1;

    IF RANGE > 0 THEN

	WHILE (RANGE > 1) AND (DEPTH[RANGE] = LEFT_ADJ_RANGE) DO

	    RANGE		:= RANGE - 1;

    { +
    Backup
    - }
    RANGE		:= RANGE + 1;

    IF RANGE >= MAX_RANGE THEN

	BREAKPOINT_LEFT	:= MAX_FACTOR (IDATA[EDF$K_CLUSTER_SIZE],
				MAX_RANGE,BKT$C_MAXBKTSIZ)

    ELSE

	BREAKPOINT_LEFT	:= MAX_FACTOR (IDATA[EDF$K_CLUSTER_SIZE],
				RANGE,BKT$C_MAXBKTSIZ);

    { +
    Now stuff the depthpoint variables.
    - }
    DEPTHPOINT_LEFT	:= DEPTH[BREAKPOINT_LEFT];
    DEPTHPOINT_MID	:= DEPTH[BREAKPOINT_MID];
    DEPTHPOINT_RIGHT	:= DEPTH[BREAKPOINT_RIGHT];

    { +
    Calculate and save more index information. Left side display.
    - }
    EXTEND_INDEX_INFO (	EXAMPOINT_LEFT, NUMPOINT_LEFT,
			PAGEPOINT_LEFT, BREAKPOINT_LEFT);

    { +
    Calculate and save more index information. Mid of display.
    - }
    EXTEND_INDEX_INFO (	EXAMPOINT_MID, NUMPOINT_MID,
			PAGEPOINT_MID, BREAKPOINT_MID);

    { +
    Calculate and save more index information. Right side display.
    - }
    EXTEND_INDEX_INFO (	EXAMPOINT_RIGHT, NUMPOINT_RIGHT,
			PAGEPOINT_RIGHT, BREAKPOINT_RIGHT);

    { +
    Now stuff the function value and leave.
    - }
    NATURAL_DEPTH	:= BREAKPOINT_MID;

END;	{ NATURAL_DEPTH }

{ ++

PLOT_GRAPH -- Calculate index depths and plot them.

This routine figures out what the index depths will be for all bucketsizes
and plots them on the screen.

CALLING SEQUENCE:

PLOT_GRAPH;

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

FIRST_PLOT

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

SYS$OUTPUT:
IDATA[EDF$K_BLOCKS_IN_BUCKET]
XY_ARRAY

ROUTINES CALLED:

PROLOGUE3_DEPTH
EDF$GRAPH

ROUTINE VALUE:

none

SIGNALS:

none

SIDE EFFECTS:

none

-- }

PROCEDURE PLOT_GRAPH;

VAR
    RANGE		: INTEGER;
    GRAPH_SWITCH	: INTEGER;
    TEMP_INTEGER	: INTEGER;
    TEMP_INT2		: INTEGER;

BEGIN

    IF IDATA[EDF$K_SURFACE_OPTION] = EDF$K_LINE_SURFACE THEN

    BEGIN

	{ +
	Do the simple graph.
	- }
	GRAPH_TYPE		:= EDF$C_LINE;
	Y_LABEL		:= 'Index Depth                     ';

	{ +
	Swap the graph_index (for double buffering)
	- }
	TEMP_INTEGER		:= CURRENT_GRAPH_INDEX;
	CURRENT_GRAPH_INDEX	:= LAST_GRAPH_INDEX;
	LAST_GRAPH_INDEX	:= TEMP_INTEGER;

    END;

    IF FIRST_PLOT THEN

    BEGIN

	{ +
	Hard set the graph index if this is the 1st time through.
	Plus set the graph switch to non-move-mode to plot the entire
	axis as well as the points.
	- }
	GRAPH_SWITCH		:= -1;
	CURRENT_GRAPH_INDEX	:= 0;
	LAST_GRAPH_INDEX	:= 1;

    END	{ IF TRUE FIRST_PLOT }

    ELSE

	{ +
	Not the 1st time through, just 'move' the points from their
	last position.
	- }
	IF IDATA[EDF$K_SURFACE_OPTION] = EDF$K_LINE_SURFACE THEN

	    GRAPH_SWITCH		:= LAST_GRAPH_INDEX

	ELSE

	    GRAPH_SWITCH		:= 1;

    IF IDATA[EDF$K_SURFACE_OPTION] <> EDF$K_LINE_SURFACE THEN

    BEGIN

	CURRENT_GRAPH_INDEX		:= 0;

    END

    ELSE

    BEGIN

	{ +
	Fill the row in the xy_plot with the depths at each bucketsize.
	- }
	FOR RANGE := 0 TO 31 DO

	BEGIN

	    IDATA[EDF$K_BLOCKS_IN_BUCKET]	:= RANGE + 1;
	    XY_PLOT[CURRENT_GRAPH_INDEX,RANGE]	:= PROLOGUE3_DEPTH;

	END;	{ FOR }

	{ +
	Fill the color_row, and copy that into the array.
	- }
	TEMP_INTEGER	:= NATURAL_DEPTH;

	FOR TEMP_INT2 := 0 TO 31 DO

	    COLOR_PLOT[CURRENT_GRAPH_INDEX,TEMP_INT2] := COLOR_ROW[TEMP_INT2];

    END;	{ IF FALSE IDATA[EDF$K_SURFACE_OPTION] <> EDF$K_LINE_SURFACE }

    IF NOT AUTO_TUNE THEN

    BEGIN

	{ +
	Since edfgrf doesn't for VT125s...
	- }
	IF REGIS THEN

	BEGIN

	    { +
	    Force the screen out of reverse video to let all the
	    characters be visible (VT125 HACK!!!)
	    - }
	    WRITELN (''(27)'[?5l');

	    { +
	    Can't use CLEAR (SCREEN) because that also does a graphics clear.
	    - }
	    LIB$ERASE_PAGE (LINE_ONE,COL_ONE);

	END;

	{ +
	Plot that graph, tote that barge, lift that bale...
	- }
	EDF$GRAPH (
		    GRAPH_TYPE,
		    XY_PLOT,
		    CURRENT_GRAPH_INDEX,
		    GRAPH_SWITCH,
		    IDATA[EDF$K_Y_HIGH],
		    IDATA[EDF$K_Y_LOW],
		    IDATA[EDF$K_Y_INCR],
		    Y_LABEL,
		    COLOR_PLOT
		    );

    END;	{ IF NOT AUTO_TUNE }

    { +
    Only DEC_CRTs can scroll only at the bottom, so if we don't have one of
    those, always do a complete screen rewrite (in case of full screen scroll).
    - }
    IF DEC_CRT THEN

	FIRST_PLOT	:= FALSE;

END;	{ PLOT_GRAPH }

{ ++

WARN_OF_ERASE -- Tell user we're about to clobber his definition.

This routine warns the user that we're about to erase the definition and
asks for confirmation.

CALLING SEQUENCE:

WARN_OF_ERASE;

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

SYS$INPUT:

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

PROCEDURE WARN_OF_ERASE;

BEGIN

    IF NOT AUTO_TUNE THEN

    BEGIN

	{ +
	If the list has more than the IDENT in it,
	query the user about replacing it.
	- }
	IF (
	(DEF_HEAD <> DEF_TAIL)
	OR
	(DEF_HEAD^.PRIMARY <> IDENT)
	) THEN

	BEGIN

	    IF (
		((IDATA[EDF$K_SCRIPT_OPTION] = EDF$K_REDESIGN_FDL)
		OR
		(IDATA[EDF$K_SCRIPT_OPTION] = EDF$K_OPTIMIZE_FDL))
	    AND
	    (ISAM_ORG)
	    ) THEN

		WRITE (SHIFT,ANSI_REVERSE,
		'The Definition of Key',IDATA[EDF$K_ACTIVE_KEY]:3,
		' will be replaced.',CRLF)

	    ELSE

		WRITELN (SHIFT,ANSI_REVERSE,
		' The Current Definition will be replaced. ',
		ANSI_RESET,CRLF);

	    QUERY (EDF$K_RETURN);

	END;	{ IF TRUE DEF_HEAD <> DEF_TAIL }

    END;	{ IF NOT AUTO_TUNE }

END;	{ WARN_OF_ERASE }

{ ++

NON_KEY_DEF -- Put into the definition the File, Record, etc stuff.

This routine handles the initial addition of the non-repeating attributes.

CALLING SEQUENCE:

NON_KEY_DEF;

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

none

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

DEF_CURRENT
DEF_HEAD

ROUTINES CALLED:

none

ROUTINE VALUE:

none

SIGNALS:

none

SIDE EFFECTS:

none

-- }

PROCEDURE NON_KEY_DEF;

BEGIN

    { +
    Get the rest of the non-key data.
    - }
    QUERY (EDF$K_FDL_TITLE);
    QUERY (EDF$K_DATA_FILE_NAME);
    QUERY (EDF$K_CARR_CTRL);

    { +
    Now make up the rest of the definition.
    - }
    IF BDATA[EDF$K_FDL_TITLE] THEN

    BEGIN

	MAKE_SCRATCH;

	WITH DEF_SCRATCH^ DO

	BEGIN

	    { +
	    TITLE primary.
	    - }
	    LIB$SCOPY_DXDX (SDATA[EDF$K_FDL_TITLE],STRING);
	    STR$FREE1_DX (SDATA[EDF$K_FDL_TITLE]);

	    PRIMARY			:= TITLE;
	    OBJECT_TYPE			:= PRI;

	    INSERT_IN_ORDER (REPLACE_OBJ);

	END;	{ WITH DEF_SCRATCH^ DO }

    END		{ IF TRUE BDATA[EDF$K_FDL_TITLE] }

    ELSE

    BEGIN

	IF FIND_OBJECT (PRI,TITLE,0,DUMMY_SECONDARY$,0) THEN

	    DELETE_CURRENT;

    END;	{ IF FALSE BDATA[EDF$K_FDL_TITLE] }

    MAKE_SCRATCH;

    WITH DEF_SCRATCH^ DO

    BEGIN

	{ +
	SYSTEM primary.
	- }
	OBJECT_TYPE		:= PRI;
	PRIMARY			:= SYSTEM;

	INSERT_IN_ORDER (REPLACE_OBJ);

    END;	{ WITH DEF_SCRATCH^ DO }

    MAKE_SCRATCH;

    WITH DEF_SCRATCH^ DO

    BEGIN

	{ +
	SOURCE Secondary.
	- }
	PRIMARY			:= SYSTEM;
	SECONDARY		:= SOURCE;
	QUALIFIER		:= FDL$C_VMS;

	INSERT_IN_ORDER (REPLACE_OBJ);

    END;	{ WITH DEF_SCRATCH^ DO }

    MAKE_SCRATCH;

    WITH DEF_SCRATCH^ DO

    BEGIN

	{ +
	FILE primary.
	- }
	OBJECT_TYPE		:= PRI;
	PRIMARY			:= FILE$;

	INSERT_IN_ORDER (REPLACE_OBJ);

    END;	{ WITH DEF_SCRATCH^ DO }

    { +
    NAME secondary.
    - }
    IF BDATA[EDF$K_DATA_FILE_NAME] THEN

    BEGIN

	MAKE_SCRATCH;

	WITH DEF_SCRATCH^ DO

	BEGIN

	    LIB$SCOPY_DXDX (SDATA[EDF$K_DATA_FILE_NAME],STRING);
	    STR$FREE1_DX (SDATA[EDF$K_DATA_FILE_NAME]);

	    PRIMARY			:= FILE$;
	    SECONDARY			:= NAME;

	    INSERT_IN_ORDER (REPLACE_OBJ);

	END;	{ WITH DEF_SCRATCH^ }

    END		{ IF TRUE BDATA[EDF$K_DATA_FILE_NAME] }

    ELSE

    BEGIN

	IF FIND_OBJECT (SEC,FILE$,0,NAME,0) THEN

	    DELETE_CURRENT;

    END;	{ IF FALSE BDATA[EDF$K_DATA_FILE_NAME] }

    MAKE_SCRATCH;

    WITH DEF_SCRATCH^ DO

    BEGIN

	{ +
	ORGANIZATION secondary.
	- }
	PRIMARY			:= FILE$;
	SECONDARY		:= ORGANIZATION;

	CASE IDATA[EDF$K_SCRIPT_OPTION] OF

	    EDF$K_OPTIMIZE_FDL,
	    EDF$K_REDESIGN_FDL,
	    EDF$K_IDX_DESIGN_FDL :	QUALIFIER := FDL$C_IDX;
	    EDF$K_SEQ_DESIGN_FDL :	QUALIFIER := FDL$C_SEQ;
	    EDF$K_REL_DESIGN_FDL :	QUALIFIER := FDL$C_REL;

	OTHERWISE

	    { NULL-STATEMENT } ;

	END;	{ CASE }

	INSERT_IN_ORDER (REPLACE_OBJ);

    END;	{ WITH DEF_SCRATCH^ DO }

    MAKE_SCRATCH;

    WITH DEF_SCRATCH^ DO

    BEGIN

	{ +
	RECORD primary.
	- }
	OBJECT_TYPE		:= PRI;
	PRIMARY			:= RECORD$;

	INSERT_IN_ORDER (REPLACE_OBJ);

    END;	{ WITH DEF_SCRATCH^ DO }

    IF IDATA[EDF$K_SCRIPT_OPTION] = EDF$K_SEQ_DESIGN_FDL THEN

    BEGIN

	{ +
	BLOCK_SPAN secondary.
	- }
	MAKE_SCRATCH;

	WITH DEF_SCRATCH^ DO

	BEGIN

	    PRIMARY			:= RECORD$;
	    SECONDARY			:= BLOCK_SPAN;
	    SWITCH			:= BDATA[EDF$K_BLOCK_SPAN];

	    INSERT_IN_ORDER (REPLACE_OBJ);

	END;	{ WITH DEF_SCRATCH^ DO }

    END;	{ IF TRUE DESIGN_ORG = SEQUENTIAL }

    { +
    CARRIAGE_CONTROL secondary.
    - }
    MAKE_SCRATCH;

    WITH DEF_SCRATCH^ DO

    BEGIN

	PRIMARY			:= RECORD$;
	SECONDARY		:= CARRIAGE_CONTROL;
	QUALIFIER		:= IDATA[EDF$K_CARR_CTRL];

	INSERT_IN_ORDER (REPLACE_OBJ);

    END;

    IF (
    ((IDATA[EDF$K_SCRIPT_OPTION] = EDF$K_SEQ_DESIGN_FDL)
    OR
    (IDATA[EDF$K_SCRIPT_OPTION] = EDF$K_REL_DESIGN_FDL))
    AND
    (IDATA[EDF$K_RECORD_FORMAT] = FDL$C_VFC)
    ) THEN

    BEGIN

	{ +
	CONTROL_FIELD_SIZE secondary.
	- }
	MAKE_SCRATCH;
    
	WITH DEF_SCRATCH^ DO
    
	BEGIN
    
	    PRIMARY			:= RECORD$;
	    SECONDARY			:= CONTROL_FIELD_SIZE;
	    NUMBER			:= IDATA[EDF$K_CONTROL_SIZE];
    
	    INSERT_IN_ORDER (REPLACE_OBJ);
    
	END;

    END;	{ IF DESIGN_ORG = SEQ OR REL AND RECORD_FORMAT = VFC }

    MAKE_SCRATCH;

    WITH DEF_SCRATCH^ DO

    BEGIN

	{ +
	FORMAT secondary.
	- }
	PRIMARY			:= RECORD$;
	SECONDARY		:= FORMAT;
	QUALIFIER		:= IDATA[EDF$K_RECORD_FORMAT];

	INSERT_IN_ORDER (REPLACE_OBJ);

    END;	{ WITH DEF_SCRATCH^ DO }

    { +
    SIZE secondary.
    - }
    MAKE_SCRATCH;

    WITH DEF_SCRATCH^ DO

    BEGIN

	PRIMARY			:= RECORD$;
	SECONDARY		:= SIZE;
	NUMBER			:= IDATA[EDF$K_MAX_RECORD_SIZE];

	INSERT_IN_ORDER (REPLACE_OBJ);

    END;

END;	{ NON_KEY_DEF }

{ ++

CALC_ALLOC -- Calculate the allocation for seq and rel files.

This routine handles the calculations for allocation for seq and rel files.

CALLING SEQUENCE:

ALLOC	:= CALC_ALLOC (RECORD_TOT);

INPUT PARAMETERS:

RECORD_TOT

IMPLICIT INPUTS:

none

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:


ROUTINES CALLED:

none

ROUTINE VALUE:

ALLOCATION CALCULATED

SIGNALS:

none

SIDE EFFECTS:

none

-- }

FUNCTION CALC_ALLOC (RECORD_TOT : INTEGER) : INTEGER;

VAR
    ALLOC	: INTEGER;
    RATIO	: REAL;
    BYTES_REAL	: REAL;
    NUMRECS_REAL : REAL;

BEGIN

    { +
    Now let's figure out the allocation needed.
    - }
    BYTES_REAL		:= RECORD_TOT;
    NUMRECS_REAL	:= IDATA[EDF$K_INITIAL_COUNT];

    IF NUMRECS_REAL < 1.0 THEN

	NUMRECS_REAL	:= 1.0;

    RATIO		:= BYTES_REAL / 512.0;

    IF (RATIO > (EDF$C_1GIGA / NUMRECS_REAL)) THEN

	CALC_ALLOC	:= EDF$C_1GIGA

    ELSE

	CALC_ALLOC	:= ROUND (RATIO * NUMRECS_REAL);

END;	{ CALC_ALLOC }

{ ++

SEQ_DEF -- Handle seq file stuff.

This routine handles the addition of the sequential file attributes.

CALLING SEQUENCE:

SEQ_DEF;

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

none

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

DEF_CURRENT
DEF_HEAD

ROUTINES CALLED:

none

ROUTINE VALUE:

none

SIGNALS:

none

SIDE EFFECTS:

none

-- }

PROCEDURE SEQ_DEF;

VAR
    ALLOC	: INTEGER;
    RECORD_TOT	: INTEGER;
    RECORD_INT	: INTEGER;
    RECORD_REAL	: REAL;

BEGIN

    { +
    Figure out how big each record is.
    - }
    RECORD_TOT		:= IDATA[EDF$K_MEAN_RECORD_SIZE];

    IF VARIABLE_RECORDS THEN

	RECORD_TOT	:= RECORD_TOT + 2;

    { +
    Assumes record size is less than 512 if BDATA[EDF$K_BLOCK_SPAN] is false.
    - }
    IF NOT BDATA[EDF$K_BLOCK_SPAN] THEN

    BEGIN

	{ +
	Increase the virtual size of each record so that it looks like
	an integer number of them fit in a block.
	- }
	RECORD_REAL	:= 512.0 / RECORD_TOT;
	RECORD_INT	:= TRUNC (RECORD_REAL);
	RECORD_TOT	:= 512 DIV RECORD_INT;

    END;

    ALLOC		:= CALC_ALLOC (RECORD_TOT);

    { +
    Now actually stuff the secondary from the above calculations.
    - }
    MAKE_SCRATCH;

    WITH DEF_SCRATCH^ DO

    BEGIN

	{ +
	ALLOCATION secondary.
	- }
	PRIMARY			:= FILE$;
	SECONDARY		:= ALLOCATION;
	NUMBER			:= ALLOC;

	INSERT_IN_ORDER (REPLACE_OBJ);

    END;	{ WITH DEF_SCRATCH^ DO }

    MAKE_SCRATCH;

    WITH DEF_SCRATCH^ DO

    BEGIN

	{ +
	BEST_TRY_CONTIGUOUS secondary.
	- }
	PRIMARY			:= FILE$;
	SECONDARY		:= BEST_TRY_CONTIGUOUS;

	INSERT_IN_ORDER (REPLACE_OBJ);

    END;	{ WITH DEF_SCRATCH^ DO }

    MAKE_SCRATCH;

    WITH DEF_SCRATCH^ DO

    BEGIN

	{ +
	EXTENSION secondary.
	- }
	PRIMARY			:= FILE$;
	SECONDARY		:= EXTENSION;
	NUMBER			:= ALLOC DIV 10;

	INSERT_IN_ORDER (REPLACE_OBJ);

    END;	{ WITH DEF_SCRATCH^ DO }

END;	{ SEQ_DEF }

{ ++

REL_DEF -- Handle relative file stuff.

This routine handles the addition of the relative file attributes.

CALLING SEQUENCE:

REL_DEF;

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

none

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

DEF_CURRENT
DEF_HEAD

ROUTINES CALLED:

none

ROUTINE VALUE:

none

SIGNALS:

none

SIDE EFFECTS:

none

-- }

PROCEDURE REL_DEF;

VAR
    ALLOC		: INTEGER;
    RECORD_TOT		: INTEGER;
    BUCKET_TOT		: INTEGER;
    BUCKET		: INTEGER;
    RECS_PER_BUCKET	: INTEGER;
    NUM_BUCKETS		: INTEGER;

BEGIN

    { +
    See what the disk clustersize is.
    - }
    QUERY (EDF$K_CLUSTER_SIZE);

    { +
    Calculate how large the bucketsize should be.
    Make them big enough for 16 records.
    - }
    RECORD_TOT		:= IDATA[EDF$K_MAX_RECORD_SIZE] + 1;

    IF VARIABLE_RECORDS THEN

	RECORD_TOT	:= RECORD_TOT + 2;

    BUCKET_TOT		:= 16 * RECORD_TOT;

    BUCKET		:= BUCKET_TOT DIV 512;

    IF BUCKET < 1 THEN

	BUCKET		:= 1;

    IF (BUCKET_TOT MOD 512) <> 0 THEN

	BUCKET		:= BUCKET + 1;

    BUCKET		:= MAX_FACTOR (IDATA[EDF$K_CLUSTER_SIZE],
				BUCKET,BKT$C_MAXBKTSIZ);

    RECS_PER_BUCKET	:= (BUCKET * 512) DIV RECORD_TOT;

    IF RECS_PER_BUCKET < 1 THEN

	RECS_PER_BUCKET	:= 1;

    NUM_BUCKETS		:= IDATA[EDF$K_INITIAL_COUNT] DIV RECS_PER_BUCKET;

    IF NUM_BUCKETS < 1 THEN

	NUM_BUCKETS	:= 1;

    IF (IDATA[EDF$K_INITIAL_COUNT] MOD RECS_PER_BUCKET) <> 0 THEN

	NUM_BUCKETS	:= NUM_BUCKETS + 1;

    { +
    Add one more disk cluster into the allocation for the prolog.
    - }
    ALLOC		:= (BUCKET * NUM_BUCKETS) + IDATA[EDF$K_CLUSTER_SIZE];

    { +
    Now actually stuff the secondary from the above calculations.
    - }
    MAKE_SCRATCH;

    WITH DEF_SCRATCH^ DO

    BEGIN

	{ +
	ALLOCATION secondary.
	- }
	PRIMARY			:= FILE$;
	SECONDARY		:= ALLOCATION;
	NUMBER			:= ALLOC;

	INSERT_IN_ORDER (REPLACE_OBJ);

    END;	{ WITH DEF_SCRATCH^ DO }

    MAKE_SCRATCH;

    WITH DEF_SCRATCH^ DO

    BEGIN

	{ +
	BEST_TRY_CONTIGUOUS secondary.
	- }
	PRIMARY			:= FILE$;
	SECONDARY		:= BEST_TRY_CONTIGUOUS;

	INSERT_IN_ORDER (REPLACE_OBJ);

    END;	{ WITH DEF_SCRATCH^ DO }

    MAKE_SCRATCH;

    WITH DEF_SCRATCH^ DO

    BEGIN

	{ +
	BUCKET_SIZE secondary.
	- }
	PRIMARY			:= FILE$;
	SECONDARY		:= BUCKET_SIZE;
	NUMBER			:= BUCKET;

	INSERT_IN_ORDER (REPLACE_OBJ);

    END;	{ WITH DEF_SCRATCH^ DO }

    MAKE_SCRATCH;

    WITH DEF_SCRATCH^ DO

    BEGIN

	{ +
	EXTENSION secondary.
	- }
	PRIMARY			:= FILE$;
	SECONDARY		:= EXTENSION;
	NUMBER			:= MAX_FACTOR (
				    BUCKET,
				    (ALLOC DIV 4),
				    EDF$C_1GIGA);

	INSERT_IN_ORDER (REPLACE_OBJ);

    END;	{ WITH DEF_SCRATCH^ DO }

    MAKE_SCRATCH;

    WITH DEF_SCRATCH^ DO

    BEGIN

	{ +
	MAX_RECORD_NUMBER secondary.
	- }
	PRIMARY			:= FILE$;
	SECONDARY		:= MAX_RECORD_NUMBER;
	NUMBER			:= IDATA[EDF$K_INITIAL_COUNT];

	INSERT_IN_ORDER (REPLACE_OBJ);

    END;	{ WITH DEF_SCRATCH^ DO }

END;	{ REL_DEF }

{ ++

APPEND_DEF -- Add a key/areas def segment onto the end of the definition.

This routine puts all the attributes for a key and its areas onto the tail
of the linked list.

CALLING SEQUENCE:

APPEND_DEF;

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

none

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

DEF_CURRENT
DEF_HEAD

ROUTINES CALLED:

none

ROUTINE VALUE:

none

SIGNALS:

none

SIDE EFFECTS:

none

-- }

PROCEDURE APPEND_DEF;

VAR
    DATA_AREA_NUMBER		: INTEGER;
    INDEX_AREA_NUMBER		: INTEGER;
    INIT_DATA_ALLOC		: INTEGER;
    INIT_INDEX_ALLOC		: INTEGER;
    ADDED_DATA_ALLOC		: INTEGER;
    ADDED_INDEX_ALLOC		: INTEGER;
    DATA_ALLOC			: INTEGER;
    INDEX_ALLOC			: INTEGER;
    DATA_EXT			: INTEGER;
    INDEX_EXT			: INTEGER;
    USED_DATA_BUCKETS		: INTEGER;
    UNUSED_DATA_BUCKETS		: INTEGER;
    USED_INDEX_BUCKETS		: INTEGER;
    UNUSED_INDEX_BUCKETS	: INTEGER;
    CHOSEN_DEPTH		: INTEGER;
    CHOSEN_DEPTH2		: INTEGER;
    TEMP_ALLOC			: INTEGER;
    I				: INTEGER;

BEGIN

    { +
    Get the user's decision on the value of the plotted file parameter.
    - }
    IF IDATA[EDF$K_SURFACE_OPTION] <> EDF$K_LINE_SURFACE THEN

	CASE IDATA[EDF$K_SURFACE_OPTION] OF

	    EDF$K_FILL_SURFACE :	QUERY (EDF$K_DESIRED_FILL);

	    EDF$K_INIT_SURFACE :	QUERY (EDF$K_INITIAL_COUNT);

	    EDF$K_ADDED_SURFACE :	QUERY (EDF$K_ADDED_COUNT);

	    EDF$K_KEY_SURFACE :		ASK_KEY_SIZE;

	    EDF$K_SIZE_SURFACE :

	    BEGIN

		ASK_MEAN_RECORD_SIZE;

		{ +
		Redo the SIZE secondary if this was a Record Size Surface.
		- }
		MAKE_SCRATCH;

		WITH DEF_SCRATCH^ DO
	    
		BEGIN
	    
		    PRIMARY			:= RECORD$;
		    SECONDARY			:= SIZE;
		    NUMBER			:= IDATA[EDF$K_MAX_RECORD_SIZE];
	    
		    INSERT_IN_ORDER (REPLACE_OBJ);
	    
		END;	{ WITH DEF_SCRATCH^ DO }

	    END;	{ SIZE_SURFACE }

	OTHERWISE

	    { NULL-STATEMENT } ;

	END;	{ CASE }

    { +
    See what bucketsize the user chose and recalculate the depth
    based on that bucketsize alone.  Find out the most reasonable
    bucketsize default by looking for the left end of the 'natural depth'.
    The primary_buckets arrays are reset to zero now as well.
    - }
    BUCKET_DEFAULT	:= NATURAL_DEPTH;

    QUERY (EDF$K_BLOCKS_IN_BUCKET);

    FOR I := 0 TO 31 DO

    BEGIN

	INIT_PRIMARY_BUCKETS[I]		:= 0;
	ADDED_PRIMARY_BUCKETS[I]	:= 0;

    END;

    CHOSEN_DEPTH	:= PROLOGUE3_DEPTH;

    { +
    Now finish getting the info to flesh out the FDL definition.
    - }
    QUERY (EDF$K_KEY_CHANGES);
    QUERY (EDF$K_KEY_NAME);

    { +
    Figure the index allocation at the same time, though.
    - }
    INIT_DATA_ALLOC	:= INIT_NUMBER_BUCKETS[0];
    ADDED_DATA_ALLOC	:= ADDED_NUMBER_BUCKETS[0];

    { +
    Find total number of buckets in index.
    - }
    INIT_INDEX_ALLOC	:= 0;
    ADDED_INDEX_ALLOC	:= 0;

    FOR I := 1 TO CHOSEN_DEPTH DO

    BEGIN

	INIT_INDEX_ALLOC	:= INIT_INDEX_ALLOC + INIT_NUMBER_BUCKETS[I];
	ADDED_INDEX_ALLOC	:= ADDED_INDEX_ALLOC + ADDED_NUMBER_BUCKETS[I];

    END;

    { +
    Now merge any additional records into the existing ones.
    - }
    IF IDATA[EDF$K_ADDED_COUNT] <> 0 THEN

    BEGIN

	USED_DATA_BUCKETS	:=
		TRUNC (RDATA[EDF$K_LOAD_FILL] * INIT_DATA_ALLOC) + 1;
	USED_INDEX_BUCKETS	:=
		TRUNC (RDATA[EDF$K_LOAD_FILL] * INIT_INDEX_ALLOC) + 1;
	UNUSED_DATA_BUCKETS	:= INIT_DATA_ALLOC - USED_DATA_BUCKETS;
	UNUSED_INDEX_BUCKETS	:= INIT_INDEX_ALLOC - USED_INDEX_BUCKETS;

	IF ADDED_DATA_ALLOC > UNUSED_DATA_BUCKETS THEN

	    ADDED_DATA_ALLOC	:= ADDED_DATA_ALLOC - UNUSED_DATA_BUCKETS

	ELSE

	    ADDED_DATA_ALLOC	:= 0;

	IF ADDED_INDEX_ALLOC > UNUSED_INDEX_BUCKETS THEN

	    ADDED_INDEX_ALLOC	:= ADDED_INDEX_ALLOC - UNUSED_INDEX_BUCKETS

	ELSE

	    ADDED_INDEX_ALLOC	:= 0;

	IF ADDED_DATA_ALLOC > 0 THEN

	    INIT_DATA_ALLOC	:= INIT_DATA_ALLOC + ADDED_DATA_ALLOC;

	IF ADDED_INDEX_ALLOC > 0 THEN

	    INIT_INDEX_ALLOC	:= INIT_INDEX_ALLOC + ADDED_INDEX_ALLOC;

    END;	{ IF TRUE IDATA[EDF$K_ADDED_COUNT] <> 0 }

    { +
    Calc to get total number of blocks for that many buckets.
    And also round the allocations 'slightly' up.
    Double check boundaries to prevent integer overflows. Enforce max of 1Giga.
    - }
    IF INIT_DATA_ALLOC > (EDF$C_1GIGA DIV IDATA[EDF$K_BLOCKS_IN_BUCKET]) THEN

	DATA_ALLOC	:= EDF$C_1GIGA

    ELSE

	DATA_ALLOC	:= INIT_DATA_ALLOC * IDATA[EDF$K_BLOCKS_IN_BUCKET];

    IF INIT_INDEX_ALLOC >
		(EDF$C_1GIGA DIV IDATA[EDF$K_BLOCKS_IN_BUCKET]) THEN

	INDEX_ALLOC	:= EDF$C_1GIGA

    ELSE

	INDEX_ALLOC	:= INIT_INDEX_ALLOC * IDATA[EDF$K_BLOCKS_IN_BUCKET];

    { +
    Since we're just about to allocate the user's file based on multiple
    areas, get rid of any existing secondaries that would be confusing.
    - }
    POINT_AT_DEFINITION;

    IF FIND_OBJECT (PRI,FILE$,0,DUMMY_SECONDARY$,0) THEN

    BEGIN

	REPEAT

	    IF (
	    (DEF_CURRENT^.PRIMARY = FILE$)
	    AND
	    (DEF_CURRENT^.SECONDARY IN [ ALLOCATION, EXTENSION,
	     BUCKET_SIZE, BEST_TRY_CONTIGUOUS, CLUSTER_SIZE ])
	    ) THEN

		DELETE_CURRENT

	    ELSE

		INCR_CURRENT;

	UNTIL (DEF_CURRENT = NIL) OR (DEF_CURRENT^.PRIMARY <> FILE$);

    END;	{ IF TRUE FIND_OBJECT (FILE$) }

    { +
    Compute the correct area numbers.
    - }
    IF IDATA[EDF$K_ACTIVE_KEY] < 127 THEN

	DATA_AREA_NUMBER	:= (2*IDATA[EDF$K_ACTIVE_KEY])

    ELSE

	DATA_AREA_NUMBER	:= 254;

    INDEX_AREA_NUMBER		:= DATA_AREA_NUMBER + 1;

    { +
    Make the area primary.
    - }
    MAKE_SCRATCH;

    WITH DEF_SCRATCH^ DO

    BEGIN

	{ +
	AREA m primary (for data).
	- }
	OBJECT_TYPE		:= PRI;
	PRIMARY			:= AREA;
	PRINUM			:= DATA_AREA_NUMBER;

	INSERT_IN_ORDER (REPLACE_OBJ);

    END;	{ WITH DEF_SCRATCH^ DO }

    { +
    Now actually stuff the secondary from the above calculations.
    - }
    IF IDATA[EDF$K_ACTIVE_KEY] < 127 THEN

	TEMP_ALLOC	:= 0

    ELSE IF FIND_OBJECT (SEC,AREA,254,ALLOCATION$,0) THEN

	TEMP_ALLOC	:= DEF_CURRENT^.NUMBER

    ELSE

	TEMP_ALLOC	:= 0;

    MAKE_SCRATCH;

    WITH DEF_SCRATCH^ DO

    BEGIN

	{ +
	ALLOCATION secondary (for data area).
	- }
	PRIMARY			:= AREA;
	PRINUM			:= DATA_AREA_NUMBER;
	SECONDARY		:= ALLOCATION$;

	NUMBER			:= DATA_ALLOC + TEMP_ALLOC;

	INSERT_IN_ORDER (REPLACE_OBJ);

    END;	{ WITH DEF_SCRATCH^ DO }

    MAKE_SCRATCH;

    WITH DEF_SCRATCH^ DO

    BEGIN

	{ +
	BEST_TRY_CONTIGUOUS secondary (for data area).
	- }
	PRIMARY			:= AREA;
	PRINUM			:= DATA_AREA_NUMBER;
	SECONDARY		:= BEST_TRY_CONTIGUOUS$;

	INSERT_IN_ORDER (REPLACE_OBJ);

    END;	{ WITH DEF_SCRATCH^ DO }

    MAKE_SCRATCH;

    WITH DEF_SCRATCH^ DO

    BEGIN

	{ +
	BUCKET_SIZE secondary (for data area).
	- }
	PRIMARY			:= AREA;
	PRINUM			:= DATA_AREA_NUMBER;
	SECONDARY		:= BUCKET_SIZE$;
	NUMBER			:= IDATA[EDF$K_BLOCKS_IN_BUCKET];

	INSERT_IN_ORDER (REPLACE_OBJ);

    END;	{ WITH DEF_SCRATCH^ DO }

    MAKE_SCRATCH;

    WITH DEF_SCRATCH^ DO

    BEGIN

	{ +
	EXTENSION secondary (for data area).
	- }
	PRIMARY			:= AREA;
	PRINUM			:= DATA_AREA_NUMBER;
	SECONDARY		:= EXTENSION$;
	NUMBER			:= MAX_FACTOR (
				    IDATA[EDF$K_BLOCKS_IN_BUCKET],
				    ((DATA_ALLOC+TEMP_ALLOC) DIV 4),
				    EDF$C_1GIGA);

	INSERT_IN_ORDER (REPLACE_OBJ);

    END;	{ WITH DEF_SCRATCH^ DO }

    MAKE_SCRATCH;

    WITH DEF_SCRATCH^ DO

    BEGIN

	{ +
	AREA n primary (for index).
	- }
	OBJECT_TYPE		:= PRI;
	PRIMARY			:= AREA;
	PRINUM			:= INDEX_AREA_NUMBER;

	INSERT_IN_ORDER (REPLACE_OBJ);

    END;	{ WITH DEF_SCRATCH^ DO }

    MAKE_SCRATCH;

    IF IDATA[EDF$K_ACTIVE_KEY] < 127 THEN

	TEMP_ALLOC	:= 0

    ELSE IF FIND_OBJECT (SEC,AREA,255,ALLOCATION$,0) THEN

	TEMP_ALLOC	:= DEF_CURRENT^.NUMBER

    ELSE

	TEMP_ALLOC	:= 0;

    WITH DEF_SCRATCH^ DO

    BEGIN

	{ +
	ALLOCATION secondary (for index area).
	- }
	PRIMARY			:= AREA;
	PRINUM			:= INDEX_AREA_NUMBER;
	SECONDARY		:= ALLOCATION$;
	NUMBER			:= INDEX_ALLOC + TEMP_ALLOC;

	INSERT_IN_ORDER (REPLACE_OBJ);

    END;	{ WITH DEF_SCRATCH^ DO }

    MAKE_SCRATCH;

    WITH DEF_SCRATCH^ DO

    BEGIN

	{ +
	BEST_TRY_CONTIGUOUS secondary (for index area).
	- }
	PRIMARY			:= AREA;
	PRINUM			:= INDEX_AREA_NUMBER;
	SECONDARY		:= BEST_TRY_CONTIGUOUS$;

	INSERT_IN_ORDER (REPLACE_OBJ);

    END;	{ WITH DEF_SCRATCH^ DO }

    MAKE_SCRATCH;

    WITH DEF_SCRATCH^ DO

    BEGIN

	{ +
	BUCKET_SIZE secondary (for index area).
	- }
	PRIMARY			:= AREA;
	PRINUM			:= INDEX_AREA_NUMBER;
	SECONDARY		:= BUCKET_SIZE$;
	NUMBER			:= IDATA[EDF$K_BLOCKS_IN_BUCKET];

	INSERT_IN_ORDER (REPLACE_OBJ);

    END;	{ WITH DEF_SCRATCH^ DO }

    MAKE_SCRATCH;

    WITH DEF_SCRATCH^ DO

    BEGIN

	{ +
	EXTENSION secondary (for index area).
	- }
	PRIMARY			:= AREA;
	PRINUM			:= INDEX_AREA_NUMBER;
	SECONDARY		:= EXTENSION$;
	NUMBER			:= MAX_FACTOR (
				    IDATA[EDF$K_BLOCKS_IN_BUCKET],
				    ((INDEX_ALLOC+TEMP_ALLOC) DIV 4),
				    EDF$C_1GIGA);

	INSERT_IN_ORDER (REPLACE_OBJ);

    END;	{ WITH DEF_SCRATCH^ DO }

    MAKE_SCRATCH;

    WITH DEF_SCRATCH^ DO

    BEGIN

	{ +
	KEY n primary.
	- }
	OBJECT_TYPE		:= PRI;
	PRINUM			:= IDATA[EDF$K_ACTIVE_KEY];

	INSERT_IN_ORDER (REPLACE_OBJ);

    END;	{ WITH DEF_SCRATCH^ DO }

    MAKE_SCRATCH;

    WITH DEF_SCRATCH^ DO

    BEGIN

	{ +
	CHANGES secondary.
	- }
	PRINUM			:= IDATA[EDF$K_ACTIVE_KEY];
	SECONDARY		:= CHANGES;
	SWITCH			:= BDATA[EDF$K_KEY_CHANGES];

	INSERT_IN_ORDER (REPLACE_OBJ);

    END;	{ WITH DEF_SCRATCH^ DO }

    MAKE_SCRATCH;

    WITH DEF_SCRATCH^ DO

    BEGIN

	{ +
	DATA_AREA secondary.
	- }
	PRINUM			:= IDATA[EDF$K_ACTIVE_KEY];
	SECONDARY		:= DATA_AREA;
	NUMBER			:= DATA_AREA_NUMBER;

	INSERT_IN_ORDER (REPLACE_OBJ);

    END;	{ WITH DEF_SCRATCH^ DO }

    MAKE_SCRATCH;

    WITH DEF_SCRATCH^ DO

    BEGIN

	{ +
	DATA_FILL secondary.
	- }
	PRINUM			:= IDATA[EDF$K_ACTIVE_KEY];
	SECONDARY		:= DATA_FILL;
	NUMBER			:= IDATA[EDF$K_FDL_FILL];

	INSERT_IN_ORDER (REPLACE_OBJ);

    END;	{ WITH DEF_SCRATCH^ DO }

    MAKE_SCRATCH;

    WITH DEF_SCRATCH^ DO

    BEGIN

	{ +
	DATA_KEY_COMPRESSION secondary.
	- }
	PRINUM			:= IDATA[EDF$K_ACTIVE_KEY];
	SECONDARY		:= DATA_KEY_COMPRESSION;
	SWITCH			:= BDATA[EDF$K_KEY_COMP_WANTED];

	INSERT_IN_ORDER (REPLACE_OBJ);

    END;	{ WITH DEF_SCRATCH^ DO }

    MAKE_SCRATCH;

    IF IDATA[EDF$K_ACTIVE_KEY] = 0 THEN

    BEGIN

	WITH DEF_SCRATCH^ DO

	BEGIN

	    { +
	    DATA_RECORD_COMPRESSION secondary.
	    - }
	    PRINUM		:= IDATA[EDF$K_ACTIVE_KEY];
	    SECONDARY		:= DATA_RECORD_COMPRESSION;
	    SWITCH		:= BDATA[EDF$K_REC_COMP_WANTED];

	    INSERT_IN_ORDER (REPLACE_OBJ);

	END;	{ WITH DEF_SCRATCH^ DO }

	MAKE_SCRATCH;

    END;	{ IDATA[EDF$K_ACTIVE_KEY] = 0 }

    WITH DEF_SCRATCH^ DO

    BEGIN

	{ +
	DUPLICATES secondary.
	- }
	PRINUM			:= IDATA[EDF$K_ACTIVE_KEY];
	SECONDARY		:= DUPLICATES;
	SWITCH			:= BDATA[EDF$K_KEY_DUPS];

	INSERT_IN_ORDER (REPLACE_OBJ);

    END;	{ WITH DEF_SCRATCH^ DO }

    MAKE_SCRATCH;

    WITH DEF_SCRATCH^ DO

    BEGIN

	{ +
	INDEX_AREA secondary.
	- }
	PRINUM			:= IDATA[EDF$K_ACTIVE_KEY];
	SECONDARY		:= INDEX_AREA;
	NUMBER			:= INDEX_AREA_NUMBER;

	INSERT_IN_ORDER (REPLACE_OBJ);

    END;	{ WITH DEF_SCRATCH^ DO }

    MAKE_SCRATCH;

    WITH DEF_SCRATCH^ DO

    BEGIN

	{ +
	INDEX_FILL secondary.
	- }
	PRINUM			:= IDATA[EDF$K_ACTIVE_KEY];
	SECONDARY		:= INDEX_FILL;
	NUMBER			:= IDATA[EDF$K_FDL_FILL];

	INSERT_IN_ORDER (REPLACE_OBJ);

    END;	{ WITH DEF_SCRATCH^ DO }

    MAKE_SCRATCH;

    WITH DEF_SCRATCH^ DO

    BEGIN

	{ +
	INDEX_COMPRESSION secondary.
	- }
	PRINUM			:= IDATA[EDF$K_ACTIVE_KEY];
	SECONDARY		:= INDEX_COMPRESSION;
	SWITCH			:= BDATA[EDF$K_IDX_COMP_WANTED];

	INSERT_IN_ORDER (REPLACE_OBJ);

    END;	{ WITH DEF_SCRATCH^ DO }

    IF NOT BDATA[EDF$K_SEGMENTED] THEN

    BEGIN

	MAKE_SCRATCH;

	WITH DEF_SCRATCH^ DO

	BEGIN

	    { +
	    LENGTH secondary.
	    - }
	    PRINUM		:= IDATA[EDF$K_ACTIVE_KEY];
	    SECONDARY		:= SEG_LENGTH;
	    NUMBER		:= IDATA[EDF$K_KEY_SIZE];

	    INSERT_IN_ORDER (REPLACE_OBJ);

	END;

    END		{ IF TRUE NOT SEGMENTED }

    ELSE

    FOR SEGMENT_NUMBER := 0 TO 7 DO

    BEGIN

	IF SEGMENT_WANTED[SEGMENT_NUMBER] THEN

	BEGIN

	    MAKE_SCRATCH;

	    WITH DEF_SCRATCH^ DO

	    BEGIN

		{ +
		LENGTH secondary.
		- }
		PRINUM			:= IDATA[EDF$K_ACTIVE_KEY];
		SECONDARY		:= SEG_LENGTH;
		NUMBER			:= SEGMENT_LENGTH[SEGMENT_NUMBER];
		SECNUM			:= SEGMENT_NUMBER;

		INSERT_IN_ORDER (REPLACE_OBJ);

	    END;

	END;

    END;	{ IF TRUE BDATA[EDF$K_SEGMENTED] }

    MAKE_SCRATCH;

    WITH DEF_SCRATCH^ DO

    BEGIN

	{ +
	LEVEL1_INDEX_AREA secondary.
	- }
	PRINUM			:= IDATA[EDF$K_ACTIVE_KEY];
	SECONDARY		:= LEVEL1_INDEX_AREA;
	NUMBER			:= INDEX_AREA_NUMBER;

	INSERT_IN_ORDER (REPLACE_OBJ);

    END;	{ WITH DEF_SCRATCH^ DO }

    { +
    NAME secondary.
    - }
    IF BDATA[EDF$K_KEY_NAME] THEN

    BEGIN

	MAKE_SCRATCH;

	WITH DEF_SCRATCH^ DO
    
	BEGIN
    
	    LIB$SCOPY_DXDX (SDATA[EDF$K_KEY_NAME],STRING);
	    STR$FREE1_DX (SDATA[EDF$K_KEY_NAME]);
    
	    PRINUM			:= IDATA[EDF$K_ACTIVE_KEY];
	    SECONDARY			:= NAME$;
    
	    INSERT_IN_ORDER (REPLACE_OBJ);
    
	END;	{ WITH DEF_SCRATCH^ }

    END		{ IF TRUE BDATA[EDF$K_KEY_NAME] }

    ELSE

    BEGIN

	IF FIND_OBJECT (SEC,KEY,IDATA[EDF$K_ACTIVE_KEY],NAME$,0) THEN

	    DELETE_CURRENT;

    END;	{ IF FALSE BDATA[EDF$K_KEY_NAME] }

    IF (
    (IDATA[EDF$K_ACTIVE_KEY] = 0)
    AND
    (VDATA[EDF$K_PROLOGUE_VERSION])
    ) THEN

    BEGIN

	MAKE_SCRATCH;

	WITH DEF_SCRATCH^ DO

	BEGIN

	    { +
	    PROLOGUE secondary.
	    - }
	    PRINUM			:= IDATA[EDF$K_ACTIVE_KEY]; { = 0 }
	    SECONDARY			:= PROLOGUE;
	    NUMBER			:= IDATA[EDF$K_PROLOGUE_VERSION];

	    INSERT_IN_ORDER (REPLACE_OBJ);

	END;	{ WITH DEF_SCRATCH^ DO }

    END;  { IF (IDATA[EDF$K_ACTIVE_KEY] = 0) AND (VDATA[EDF$K_PROLOGUE_VERSION]) }

    IF NOT BDATA[EDF$K_SEGMENTED] THEN

    BEGIN

	MAKE_SCRATCH;

	WITH DEF_SCRATCH^ DO

	BEGIN

	    { +
	    POSITION secondary.
	    - }
	    PRINUM		:= IDATA[EDF$K_ACTIVE_KEY];
	    SECONDARY		:= SEG_POSITION;
	    NUMBER		:= IDATA[EDF$K_KEY_POSITION];

	    INSERT_IN_ORDER (REPLACE_OBJ);

	END;

    END		{ IF TRUE NOT SEGMENTED }

    ELSE

    FOR SEGMENT_NUMBER := 0 TO 7 DO

    BEGIN

	IF SEGMENT_WANTED[SEGMENT_NUMBER] THEN

	BEGIN

	    MAKE_SCRATCH;

	    WITH DEF_SCRATCH^ DO

	    BEGIN

		{ +
		POSITION secondary.
		- }
		PRINUM			:= IDATA[EDF$K_ACTIVE_KEY];
		SECONDARY		:= SEG_POSITION;
		NUMBER			:= SEGMENT_POSITION[SEGMENT_NUMBER];
		SECNUM			:= SEGMENT_NUMBER;

		INSERT_IN_ORDER (REPLACE_OBJ);

	    END;

	END;

    END;	{ IF TRUE BDATA[EDF$K_SEGMENTED] }

    { +
    TYPE secondary.
    - }
    MAKE_SCRATCH;

    WITH DEF_SCRATCH^ DO

    BEGIN

	PRINUM			:= IDATA[EDF$K_ACTIVE_KEY];
	SECONDARY		:= SEG_TYPE;
	QUALIFIER		:= IDATA[EDF$K_KEY_TYPE];

	{ +
	Make type the last secondary in the key primary.
	- }
	SECNUM			:= 7;

	INSERT_IN_ORDER (REPLACE_OBJ);

    END;	{ WITH DEF_SCRATCH^ DO }

    { +
    After the user has chosen his bucketsize, ask about
    global buffers.
    - }
    IF IDATA[EDF$K_ACTIVE_KEY] = 0 THEN

    BEGIN

	ASK_GLOBAL_WANTED;

	{ +
	GLOBAL_BUFFER_COUNT secondary.
	- }
	IF BDATA[EDF$K_GLOBAL_WANTED] THEN

	BEGIN

	    MAKE_SCRATCH;

	    WITH DEF_SCRATCH^ DO

	    BEGIN

		PRIMARY		:= FILE$;
		SECONDARY	:= GLOBAL_BUFFER_COUNT;
		NUMBER		:= IDATA[EDF$K_GLOBAL_COUNT];

		INSERT_IN_ORDER (REPLACE_OBJ);

	    END;	{ WITH DEF_SCRATCH^ DO }

	END		{ IF TRUE BDATA[EDF$K_GLOBAL_WANTED] }

	ELSE

	BEGIN

	    IF FIND_OBJECT (SEC,FILE$,0,GLOBAL_BUFFER_COUNT,0) THEN

		DELETE_CURRENT;

	END;	{ IF FALSE BDATA[EDF$K_GLOBAL_WANTED] }

    END;	{ IF TRUE IDATA[EDF$K_ACTIVE_KEY] = 0 }

    { +
    Show the user what he has.
    - }
    CHOSEN_DEPTH2	:= CHOSEN_DEPTH + 1;

    IF NOT AUTO_TUNE THEN

    BEGIN

	WRITELN (
	CRLF,
	SHIFT,'The Depth of Key',IDATA[EDF$K_ACTIVE_KEY]:3,
	' is Estimated to be No Greater',CRLF_SHIFT,
	'than ',
	CHOSEN_DEPTH:NUM_LEN(CHOSEN_DEPTH),' Index levels, which is ',
	CHOSEN_DEPTH2:NUM_LEN(CHOSEN_DEPTH2),' Total levels.'
	);

	QUERY (EDF$K_RETURN);

    END;

END;	{ APPEND_DEF }

{ ++

LINK_RESULTS -- Incorporate the 'designed' variables into the linked list.

This routine puts the final state of the variables into the Definition.

CALLING SEQUENCE:

LINK_RESULTS;

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

none

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

DEF_CURRENT
DEF_HEAD

ROUTINES CALLED:

none

ROUTINE VALUE:

none

SIGNALS:

none

SIDE EFFECTS:

none

-- }

PROCEDURE LINK_RESULTS;

BEGIN

    { +
    Put the terminal back.
    - }
    EDF$RESET_SCROLL;
    CLEAR (SCREEN);
    VISIBLE_QUESTION	:= FALSE;
    WAIT_HELP		:= FALSE;
    TAKE_DEFAULTS	:= TRUE;

    { +
    If this is the 1st time through, get the general file attributes.
    - }
    IF IDATA[EDF$K_ACTIVE_KEY] = 0 THEN

	NON_KEY_DEF;

    { +
    Add this key's data to the linked list.
    - }
    APPEND_DEF;

    LINKED	:= TRUE;

END;	{ LINK_RESULTS }

{ ++

MERGE_AREA -- Collapse area definitions onto one another.

This routine updates the area sections after adding together allocations.

CALLING SEQUENCE:

MERGE_AREA (CURKEY,MAXKEY,SRCDATA,DSTDATA,SRCIDX,DSTIDX);

INPUT PARAMETERS:

CURKEY
MAXKEY
SRCDATA
DSTDATA
SRCIDX
DSTIDX

IMPLICIT INPUTS:

DEF_CURRENT
DEF_HEAD

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

DEF_CURRENT
DEF_HEAD

ROUTINES CALLED:

none

ROUTINE VALUE:

none

SIGNALS:

none

SIDE EFFECTS:

none

-- }

PROCEDURE MERGE_AREA (CURKEY,MAXKEY,SRCDATA,DSTDATA,SRCIDX,DSTIDX : INTEGER);

VAR
    KEYNUM		: INTEGER;
    SOURCE_DATA_BUCKET	: INTEGER;
    SOURCE_DATA_ALLOC	: INTEGER;
    SOURCE_DATA_EXT	: INTEGER;
    SOURCE_INDEX_BUCKET	: INTEGER;
    SOURCE_INDEX_ALLOC	: INTEGER;
    SOURCE_INDEX_EXT	: INTEGER;

BEGIN

    { +
    Set up the defaults in case some line_objects are not found.
    - }
    SOURCE_DATA_BUCKET		:= 3;
    SOURCE_DATA_ALLOC		:= 0;
    SOURCE_DATA_EXT		:= 0;
    SOURCE_INDEX_BUCKET		:= 3;
    SOURCE_INDEX_ALLOC		:= 0;
    SOURCE_INDEX_EXT		:= 0;

    { +
    Get the bucket sizes, allocations, and extensions of the areas that
    are going away.

    THESE COULD ALL BE OPTIMIZED BY REALIZING THAT THEY'RE ALL
    ADJACENT LINE_OBJECTS!!!

    - }
    IF FIND_OBJECT (SEC,AREA,SRCDATA,BUCKET_SIZE$,0) THEN

	SOURCE_DATA_BUCKET	:= DEF_CURRENT^.NUMBER;

    IF FIND_OBJECT (SEC,AREA,SRCDATA,ALLOCATION$,0) THEN

	SOURCE_DATA_ALLOC	:= DEF_CURRENT^.NUMBER;

    IF FIND_OBJECT (SEC,AREA,SRCDATA,EXTENSION$,0) THEN

	SOURCE_DATA_EXT		:= DEF_CURRENT^.NUMBER;

    IF FIND_OBJECT (SEC,AREA,SRCIDX,BUCKET_SIZE$,0) THEN

	SOURCE_INDEX_BUCKET	:= DEF_CURRENT^.NUMBER;

    IF FIND_OBJECT (SEC,AREA,SRCIDX,ALLOCATION$,0) THEN

	SOURCE_INDEX_ALLOC	:= DEF_CURRENT^.NUMBER;

    IF FIND_OBJECT (SEC,AREA,SRCIDX,EXTENSION$,0) THEN

	SOURCE_INDEX_EXT	:= DEF_CURRENT^.NUMBER;


    { +
    If SRC = DST, then ignore the above numbers.
    - }
    IF SRCDATA = DSTDATA THEN

    BEGIN

	SOURCE_DATA_BUCKET		:= 0;
	SOURCE_DATA_ALLOC		:= 0;
	SOURCE_DATA_EXT		:= 0;

    END;

    IF SRCIDX = DSTIDX THEN

    BEGIN

	SOURCE_INDEX_BUCKET		:= 0;
	SOURCE_INDEX_ALLOC		:= 0;
	SOURCE_INDEX_EXT		:= 0;

    END;

    { +
    Now add these to the areas that we're merging into.
    Bucket sizes get maximized.
    - }
    IF FIND_OBJECT (SEC,AREA,DSTDATA,BUCKET_SIZE$,0) THEN

	IF SOURCE_DATA_BUCKET > DEF_CURRENT^.NUMBER THEN

	    DEF_CURRENT^.NUMBER	:= SOURCE_DATA_BUCKET;

    IF FIND_OBJECT (SEC,AREA,DSTDATA,ALLOCATION$,0) THEN

	DEF_CURRENT^.NUMBER	:= DEF_CURRENT^.NUMBER + SOURCE_DATA_ALLOC;

    IF FIND_OBJECT (SEC,AREA,DSTDATA,EXTENSION$,0) THEN

	DEF_CURRENT^.NUMBER	:= DEF_CURRENT^.NUMBER + SOURCE_DATA_EXT;

    IF FIND_OBJECT (SEC,AREA,DSTIDX,BUCKET_SIZE$,0) THEN

	IF SOURCE_INDEX_BUCKET > DEF_CURRENT^.NUMBER THEN

	    DEF_CURRENT^.NUMBER	:= SOURCE_INDEX_BUCKET;

    IF FIND_OBJECT (SEC,AREA,DSTIDX,ALLOCATION$,0) THEN

	DEF_CURRENT^.NUMBER	:= DEF_CURRENT^.NUMBER + SOURCE_INDEX_ALLOC;

    IF FIND_OBJECT (SEC,AREA,DSTIDX,EXTENSION$,0) THEN

	DEF_CURRENT^.NUMBER	:= DEF_CURRENT^.NUMBER + SOURCE_INDEX_EXT;

    FOR KEYNUM := CURKEY TO MAXKEY DO

    BEGIN

	{ +
	Now point the key section(s) to the right areas.
	- }
	IF FIND_OBJECT (SEC,KEY,KEYNUM,DATA_AREA,0) THEN

	    DEF_CURRENT^.NUMBER	:= DSTDATA;

	IF FIND_OBJECT (SEC,KEY,KEYNUM,INDEX_AREA,0) THEN

	    DEF_CURRENT^.NUMBER	:= DSTIDX;

	IF FIND_OBJECT (SEC,KEY,KEYNUM,LEVEL1_INDEX_AREA,0) THEN

	    DEF_CURRENT^.NUMBER	:= DSTIDX;

    END;	{ FOR }

    { +
    Now get rid of the old area sections.
    - }
    IF SRCDATA <> DSTDATA THEN

	DELETE_PRIMARY_SECTION (AREA,SRCDATA);

    IF SRCIDX <> DSTIDX THEN

	DELETE_PRIMARY_SECTION (AREA,SRCIDX);

END;	{ MERGE_AREA }

{ ++

SHUFFLE_AREAS -- Implement Granularity.

This routine puts the area primary sections into their final state.

CALLING SEQUENCE:

SHUFFLE_AREAS;

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

DEF_CURRENT
DEF_HEAD

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

DEF_CURRENT
DEF_HEAD

ROUTINES CALLED:

none

ROUTINE VALUE:

none

SIGNALS:

none

SIDE EFFECTS:

none

-- }

PROCEDURE SHUFFLE_AREAS;

VAR
    TEMP_KEY		: INTEGER;
    TEMP_AREA		: INTEGER;
    PROLOG_FOR_KEYS	: INTEGER;
    PROLOG_FOR_AREAS	: INTEGER;

BEGIN

    { +
    First, see what we have.
    - }
    SCAN_DEFINITION (TRUE);

    { +
    You need at least 2 keys to support 3 or 4 areas.
    IF (
    (HIGH_KEY < 1)
    AND
    (IDATA[EDF$K_GRANULARITY] IN [ EDF$K_THREE, EDF$K_FOUR ])
    ) THEN

	IDATA[EDF$K_GRANULARITY]	:= EDF$K_TWO;

    { +
    Now merge the areas according to whatever granularity was chosen.
    - }
    IF (
    (HIGH_KEY > 1)
    AND
    (IDATA[EDF$K_GRANULARITY] <> EDF$K_DOUBLE)
    ) THEN

    BEGIN

	TEMP_KEY	:= HIGH_KEY;

	{ +
	Put all the alternate keys into areas 2 and 3.
	- }
	REPEAT

	    TEMP_AREA	:= TEMP_KEY * 2;

	    MERGE_AREA (TEMP_KEY,TEMP_KEY,TEMP_AREA,2,(TEMP_AREA+1),3);

	    TEMP_KEY	:= TEMP_KEY - 1;

	UNTIL TEMP_KEY < 2;

    END;

    CASE IDATA[EDF$K_GRANULARITY] OF

	EDF$K_ONE :

	BEGIN

	    IF HIGH_AREA > 1 THEN

		MERGE_AREA (1,HIGH_KEY,2,0,3,0);

	    MERGE_AREA (0,HIGH_KEY,0,0,1,0);

	END;

	EDF$K_TWO :

	{ +
	If we only have one key, then there's nothing to do.
	- }
	IF HIGH_KEY > 0 THEN

	BEGIN

	    MERGE_AREA (1,HIGH_KEY,2,1,3,1);

	END;

	EDF$K_THREE :

	BEGIN

	    MERGE_AREA (1,HIGH_KEY,2,2,3,2);

	END;

	EDF$K_FOUR :

	BEGIN

	    { NULL-STATEMENT - all the work was done above } ;

	END;

	EDF$K_DOUBLE :

	BEGIN

	    { NULL-STATEMENT - this is the initial situation } ;

	END;

    OTHERWISE

	{ NULL-STATEMENT } ;

    END;	{ CASE }

    { +
    Lastly, add the length of the prolog to area 0.
    - }
    PROLOG_FOR_KEYS	:= 0;

    { +
    Key 0 descriptor is in the 1st prolog block. Others must go in following
    prolog blocks, 5 per block.
    - }
    IF HIGH_KEY > 0 THEN

    BEGIN

	PROLOG_FOR_KEYS		:= HIGH_KEY DIV 5;

	IF ((HIGH_KEY MOD 5) <> 0) THEN

	    PROLOG_FOR_KEYS	:= PROLOG_FOR_KEYS + 1;

    END;

    { +
    Add in the key 0 descriptor.
    - }
    PROLOG_FOR_KEYS		:= PROLOG_FOR_KEYS + 1;

    { +
    Prolog blocks for areas start after the prolog blocks for keys.
    No mixing is allowed. 7 area descriptors fit in a block.
    - }
    PROLOG_FOR_AREAS		:= (HIGH_AREA+1) DIV 7;

    IF (((HIGH_AREA+1) MOD 7) <> 0) THEN

	PROLOG_FOR_AREAS	:= PROLOG_FOR_AREAS + 1;

    { +
    Locate the line_object that has the area 0 allocation in it
    and add the prolog size to it. If not found, let RMS default it all.
    - }
    IF FIND_OBJECT (SEC,AREA,0,ALLOCATION$,0) THEN

	DEF_CURRENT^.NUMBER	:= DEF_CURRENT^.NUMBER +
				    MAX_FACTOR (IDATA[EDF$K_CLUSTER_SIZE],
					(PROLOG_FOR_KEYS+PROLOG_FOR_AREAS),
					89);  { = largest possible prolog }

END;	{ SHUFFLE_AREAS }

{ ++

CALC_ARRAY -- Do the calculations for a surface plot.

This routine sets up xy_array.

CALLING SEQUENCE:

CALC_ARRAY;

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

PROCEDURE CALC_ARRAY;

VAR
    I			: INTEGER;
    J			: INTEGER;
    TEMP_INTEGER	: INTEGER;
    TEMP_INT2		: INTEGER;

BEGIN

    WRITELN (SHIFT,'Working ...');

    IF IDATA[EDF$K_SURFACE_OPTION] = EDF$K_FILL_SURFACE THEN

	GRAPH_TYPE	:= EDF$C_SRF_DECREASING

    ELSE

	GRAPH_TYPE	:= EDF$C_SRF_INCREASING;

    CASE IDATA[EDF$K_SURFACE_OPTION] OF

	EDF$K_FILL_SURFACE :

	BEGIN

	    Y_LABEL	:= 'Initial Load Fill Percent       ';
	    IDATA[EDF$K_DESIRED_FILL] := IDATA[EDF$K_Y_LOW];

	END;

	EDF$K_SIZE_SURFACE :

	BEGIN

	    IF VARIABLE_RECORDS THEN

		Y_LABEL	:= 'Mean Record Size                '

	    ELSE

		Y_LABEL	:= 'Record Size                     ';

	    IDATA[EDF$K_MEAN_RECORD_SIZE]	:= IDATA[EDF$K_Y_LOW];

	END;

	EDF$K_KEY_SURFACE :

	BEGIN

	    Y_LABEL	:= 'Key Length                      ';
	    IDATA[EDF$K_KEY_SIZE]	:= IDATA[EDF$K_Y_LOW];

	END;

	EDF$K_INIT_SURFACE :

	BEGIN

	    Y_LABEL	:= 'Initial Load Record Count       ';
	    IDATA[EDF$K_INITIAL_COUNT] := IDATA[EDF$K_Y_LOW];

	END;

	EDF$K_ADDED_SURFACE :

	BEGIN

	    Y_LABEL	:= 'Additional Record Count         ';
	    IDATA[EDF$K_ADDED_COUNT]	:= IDATA[EDF$K_Y_LOW];

	END;

    OTHERWISE

	{ NULL-STATEMENT } ;

    END;	{ CASE }

    FOR I := 0 TO MAX_ARRAY_ROW DO

    BEGIN

	FOR J := 0 TO 31 DO

	BEGIN

	    { +
	    Bump the bucketsize and recalculate.
	    - }
	    IDATA[EDF$K_BLOCKS_IN_BUCKET]	:= J + 1;
	    XY_PLOT[I,J]			:= PROLOGUE3_DEPTH;

	END;	{ FOR J }

	{ +
	Fill the color_row, and copy that into the array.
	- }
	TEMP_INTEGER	:= NATURAL_DEPTH;

	FOR TEMP_INT2 := 0 TO 31 DO

	    COLOR_PLOT[I,TEMP_INT2]	:= COLOR_ROW[TEMP_INT2];

	CASE IDATA[EDF$K_SURFACE_OPTION] OF

	    EDF$K_FILL_SURFACE :	IDATA[EDF$K_DESIRED_FILL]	:=
				IDATA[EDF$K_DESIRED_FILL] + IDATA[EDF$K_Y_INCR];

	    EDF$K_SIZE_SURFACE :	IDATA[EDF$K_MEAN_RECORD_SIZE] :=
			IDATA[EDF$K_MEAN_RECORD_SIZE] + IDATA[EDF$K_Y_INCR];

	    EDF$K_KEY_SURFACE :		IDATA[EDF$K_KEY_SIZE]	:=
				IDATA[EDF$K_KEY_SIZE] + IDATA[EDF$K_Y_INCR];

	    EDF$K_INIT_SURFACE :	IDATA[EDF$K_INITIAL_COUNT]	:=
			IDATA[EDF$K_INITIAL_COUNT] + IDATA[EDF$K_Y_INCR];

	    EDF$K_ADDED_SURFACE :	IDATA[EDF$K_ADDED_COUNT]	:=
				IDATA[EDF$K_ADDED_COUNT] + IDATA[EDF$K_Y_INCR];

	OTHERWISE

	    { NULL-STATEMENT } ;

	END;	{ CASE }

    END;	{ FOR I }

END;	{ CALC_ARRAY }

{ ++

SETUP_GRAPH -- Setup to call EDF$GRAPH.

This routine sets up to call EDF$GRAPH.

CALLING SEQUENCE:

SETUP_GRAPH;

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

PROCEDURE SETUP_GRAPH;

BEGIN

    { +
    Reset the boundary markers.
    - }
    IDATA[EDF$K_Y_LOW]	:= 0;
    IDATA[EDF$K_Y_HIGH]	:= 0;
    IDATA[EDF$K_Y_INCR]	:= 0;

    IF NOT AUTO_TUNE THEN

	WRITELN;

    { +
    Now fill up the xy_array (if needed).
    - }
    IF IDATA[EDF$K_SURFACE_OPTION] = EDF$K_INIT_SURFACE THEN

    BEGIN

	QUERY (EDF$K_INITIAL_COUNT_LOW);
	QUERY (EDF$K_INITIAL_COUNT_HIGH);
	AUTO_SCALE (0,EDF$C_1GIGA);

    END

    ELSE

	QUERY (EDF$K_INITIAL_COUNT);

    QUERY (EDF$K_LOAD_METHOD);
    QUERY (EDF$K_ASCENDING_LOAD);

    IF IDATA[EDF$K_SURFACE_OPTION] = EDF$K_ADDED_SURFACE THEN

    BEGIN

	QUERY (EDF$K_ADDED_COUNT_LOW);
	QUERY (EDF$K_ADDED_COUNT_HIGH);
	AUTO_SCALE (0,EDF$C_1GIGA);

    END

    ELSE

	QUERY (EDF$K_ADDED_COUNT);

    QUERY (EDF$K_ASCENDING_ADDED);
    QUERY (EDF$K_KEY_DIST);

    IF IDATA[EDF$K_SURFACE_OPTION] = EDF$K_FILL_SURFACE THEN

    BEGIN

	QUERY (EDF$K_FILL_LOW);
	QUERY (EDF$K_FILL_HIGH);
	AUTO_SCALE (31,100);

    END

    ELSE

	QUERY (EDF$K_DESIRED_FILL);

    QUERY (EDF$K_RECORD_FORMAT);

    IF IDATA[EDF$K_SURFACE_OPTION] = EDF$K_SIZE_SURFACE THEN

    BEGIN

	QUERY (EDF$K_SIZE_LOW);
	QUERY (EDF$K_SIZE_HIGH);
	AUTO_SCALE (1,CUR_MAX_REC);
	IDATA[EDF$K_MAX_RECORD_SIZE]	:= IDATA[EDF$K_Y_HIGH];

    END

    ELSE

	ASK_MEAN_RECORD_SIZE;

    QUERY (EDF$K_KEY_TYPE);
    QUERY (EDF$K_SEGMENTED);
    SEGMENT_NUMBER	:= 0;

    IF IDATA[EDF$K_SURFACE_OPTION] = EDF$K_KEY_SURFACE THEN

    BEGIN

	QUERY (EDF$K_KEY_LOW);
	QUERY (EDF$K_KEY_HIGH);
	AUTO_SCALE (1,MAX_KEY_SIZE);

    END

    ELSE

	ASK_KEY_SIZE;

    ASK_KEY_POSITION;
    ASK_KEY_DUPS;
    QUERY (EDF$K_PROLOGUE_VERSION);
    ASK_KEY_COMP;
    ASK_REC_COMP;
    ASK_IDX_COMP;

    IF NOT AUTO_TUNE THEN

	WRITELN;

    { +
    Since calc_array is called only if it's not a line plot, we don't
    have to conditionalize its writes for not auto_tune. (nointeractive
    uses only line plots)
    - }
    IF IDATA[EDF$K_SURFACE_OPTION] <> EDF$K_LINE_SURFACE THEN

	{ +
	Now fill the xy_array (if needed).
	- }
	CALC_ARRAY;

END;	{ SETUP_GRAPH }

{ ++

PLOT_AND_DESIGN -- Show the graph on the screen and design the file.

This routine displays the graph for the file and lets the user change
the file parameters (design the file).

CALLING SEQUENCE:

PLOT_AND_DESIGN;

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

CONTROL_ZEE_TYPED
SYS$INPUT:

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

CONTROL_ZEE_TYPED
SYS$OUTPUT:

ROUTINES CALLED:

QUERY (EDF$K_SURFACE_OPTION)
SETUP_GRAPH

ROUTINE VALUE:

none

SIGNALS:

none

SIDE EFFECTS:

none

-- }

PROCEDURE PLOT_AND_DESIGN;

BEGIN

    { +
    See what kind of graph he wants.
    - }
    QUERY (EDF$K_SURFACE_OPTION);

    { +
    Find out what the user's parameters are, and fill the xy_array (if needed).
    Indicate that questions should be visible now - even if optimizing.
    - }
    SETUP_GRAPH;
    VISIBLE_QUESTION	:= TRUE;
    TAKE_DEFAULTS	:= AUTO_TUNE;

    { +
    Make bottom lines of screen scroll.
    - }
    LIB$SET_SCROLL (PROMPT_LINE,LINES_PER_PAGE);
    SCROLLING_SET	:= TRUE;
    WAIT_HELP		:= TRUE;

    { +
    Init to do non-move on 1st time thru
    - }
    FIRST_PLOT		:= TRUE;

    { +
    Show the user the calculated depths.
    - }
    PLOT_GRAPH;

    { +
    This will loop until the user types control/Z or
    LINK_RESULTS makes LINKED true.
    - }
    LINKED	:= FALSE;

    WHILE NOT LINKED DO

    BEGIN

	{ +
	See what the user wants to vary.
	- }
	QUERY (EDF$K_DESIGN_CYCLE);

	CASE IDATA[EDF$K_DESIGN_CYCLE] OF

	    EDF$K_RF :		QUERY (EDF$K_RECORD_FORMAT);

	    EDF$K_RS :		ASK_MEAN_RECORD_SIZE;

	    EDF$K_KL :		ASK_KEY_SIZE;

	    EDF$K_BF :		QUERY (EDF$K_DESIRED_FILL);

	    EDF$K_EM :		QUERY (EDF$K_BUCKET_WEIGHT);

	    EDF$K_IL :		QUERY (EDF$K_INITIAL_COUNT);

	    EDF$K_KP :		ASK_KEY_POSITION;

	    EDF$K_LM :		QUERY (EDF$K_LOAD_METHOD);

	    EDF$K_AR :		QUERY (EDF$K_ADDED_COUNT);

	    EDF$K_DK :		ASK_KEY_DUPS;

	    EDF$K_RC :		ASK_REC_COMP;

	    EDF$K_KC :		ASK_KEY_COMP;

	    EDF$K_IC :		ASK_IDX_COMP;

	    EDF$K_PV :		QUERY (EDF$K_PROLOGUE_VERSION);

	    EDF$K_KT :		QUERY (EDF$K_KEY_TYPE);

	    EDF$K_FINIS :	LINK_RESULTS;

	    EDF$K_WP :

	    BEGIN

		{ +
		This is the write fresh plot function.
		- }
		FIRST_PLOT	:= TRUE;
		PLOT_GRAPH;

	    END;

	OTHERWISE

	    { NULL-STATEMENT } ;

	END;	{ CASE }

	{ +
	If we just finished putting up a new plot, or we're done,
	don't do it again.
	- }
	IF NOT ((IDATA[EDF$K_DESIGN_CYCLE] = EDF$K_WP) OR LINKED) THEN

	BEGIN

	    IF IDATA[EDF$K_SURFACE_OPTION] <> EDF$K_LINE_SURFACE THEN

		CALC_ARRAY;

	    PLOT_GRAPH;

	END;	{ IF IDATA[EDF$K_DESIGN_CYCLE] <> EDF$K_WP }

    END;	{ WHILE }

    EDF$RESET_SCROLL;

END;	{ PLOT_AND_DESIGN }

{ ++

SEQ_REL_WORK -- Do the calculations for designing Seq and Rel files.

This routine does all the work.

CALLING SEQUENCE:

SEQ_REL_WORK;

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

PROCEDURE SEQ_REL_WORK;

BEGIN

    { +
    Find out how the user is going to use the file.
    - }
    QUERY (EDF$K_NUMBER_RECORDS);
    QUERY (EDF$K_RECORD_FORMAT);
    QUERY (EDF$K_BLOCK_SPAN);
    ASK_MEAN_RECORD_SIZE;

    { +
    Stuff the definition.
    - }
    INIT_DEF;
    NON_KEY_DEF;

END;	{ SEQ_REL_WORK }

{ ++

INDEXED_DESIGN -- Do the dirty work to design an indexed file.

This routine does all the calculations needed to design an indexed file.
It also serves the redesign and optimize functions.

CALLING SEQUENCE:

INDEXED_DESIGN (REDESIGN_FLAG,ADD_KEY_FLAG);

INPUT PARAMETERS:

REDESIGN_FLAG
ADD_KEY_FLAG

IMPLICIT INPUTS:

OPTIMIZING
CONTROL_ZEE_TYPED
SYS$INPUT:

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

CONTROL_ZEE_TYPED
SYS$OUTPUT:

ROUTINES CALLED:

PLOT_AND_DESIGN

ROUTINE VALUE:

none

SIGNALS:

none

SIDE EFFECTS:

none

-- }

PROCEDURE INDEXED_DESIGN (REDESIGN_FLAG,ADD_KEY_FLAG : BOOLEAN);

VAR
    BEGINING_KEY	: INTEGER;
    ENDING_KEY		: INTEGER;
    ACTIVE_KEY_INDEX	: INTEGER;

BEGIN

    { +
    Find out the cluster factor of the target disk.
    - }
    QUERY (EDF$K_CLUSTER_SIZE);

    { +
    Initialize the script.
    - }
    IF NOT OPTIMIZING THEN

    BEGIN

	IF REDESIGN_FLAG THEN

	BEGIN

	    { +
	    The add_key script has already setup [active_key].
	    - }
	    IF NOT ADD_KEY_FLAG THEN

		QUERY (EDF$K_ACTIVE_KEY);

	    BEGINING_KEY	:= IDATA[EDF$K_ACTIVE_KEY];
	    ENDING_KEY		:= BEGINING_KEY;

	END

	ELSE

	BEGIN

	    QUERY (EDF$K_NUMBER_KEYS);
	    BEGINING_KEY	:= 0;
	    ENDING_KEY		:= IDATA[EDF$K_NUMBER_KEYS] - 1;

	END;

    END		{ IF TRUE NOT OPTIMIZING }

    ELSE

    BEGIN

	SCAN_DEFINITION (TRUE);
	IDATA[EDF$K_NUMBER_KEYS]	:= HIGH_KEY + 1;
	BEGINING_KEY			:= 0;
	ENDING_KEY			:= HIGH_KEY;

    END;	{ IF FALSE NOT OPTIMIZING }

    { +
    Now loop until all his keys are (re)defined.
    - }
    FOR ACTIVE_KEY_INDEX := BEGINING_KEY TO ENDING_KEY DO

    BEGIN

	IDATA[EDF$K_ACTIVE_KEY]	:= ACTIVE_KEY_INDEX;

	IF (
	(REDESIGN_FLAG)
	AND
	(NOT ADD_KEY_FLAG)
	) THEN

	    WARN_OF_ERASE;

	PLOT_AND_DESIGN;

    END;	{ FOR ... }

    { +
    Now that we're done with the hard part, set the function default
    to succeed.
    - }
    IF AUTO_TUNE THEN

	QTAB[EDF$K_CURRENT_FUNCTION].DEFAULT	:= EDF$K_EXIT;

END;	{ INDEXED_DESIGN }

END.
    { End of file: SRC$:EDFDESIGN.PAS }
