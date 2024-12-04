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
		V03-018 JWT0191		Jim Teague		 2 Aug 1984
			Remove knowledge of ERASE_ON_DELETE.

		V03-017 RRB0017		Rowland R. Bradley	 6 Mar 1984
			Disallow ACLs - Commented out ACLs, will support
			later.

		V03-016 RRB0009		Rowland R. Bradley	22 Jan 1984
			Enhancement for display of # buckets in index, # of
			pages to cache index, and average # key examinations.

		V03-015 RRB0007		Rowland R. Bradley	19 Jan 1984
			Fix set analysis file to update the correct data
			structure.

		V03-014	KFH0014		Ken Henderson		10 Sep 1983
			Support for named UICs

		V03-013	KFH0013		Ken Henderson		 8 Aug 1983
			Bugfixing for FT1.
			Changes for seperate compilation.

		V03-012	KFH0012		Ken Henderson		27 Jul 1983
			Fixed calculation of record and bucket
			overheads in blocks_in_bucket question.
			Added DEFERRED_WRITE.

		V03-011	KFH0011		Ken Henderson		27 May 1983
			Modified PRE_PROCESS for KEY_COMP_WANTED,
			REC_COMP_WANTED, IDX_COMP_WANTED to
			force not wanted if not String datatype.
			Also force REC_COMP_WANTED to false if
			not Key 0.

		V03-010	KFH0010		Ken Henderson		26 Apr 1983
			Modified PRE_PROCESS for
			EDF$K_NUMBER_KEYS, EDF$K_SURFACE_OPTION.
			Add ASK_KEY_SIZE, ASK_KEY_POSITION.
			Add ADD_KEY, DELETE_KEY	to SCRIPT_OPTION.
			Removed EDF$K_GLOBAL_COUNT question.

		V03-009	KFH0009		Ken Henderson		14 Apr 1983
			Changed max bucketsize to 63 from 65.
			Added SET_FUNCTION, GRANULARITY, PROMPTING,
			JOURNAL_ENABLED, and RESPONSES. Modified
			questions about DUPLICATES, COMPRESSION_WANTED.

		V03-008	KFH0008		Ken Henderson		 7 Mar 1983
			Changed max bucketsize to 65 from 127.

		V03-007	KFH0007		Ken Henderson		20 Jan 1983
			Fixed REGIS support in DESIGN_CYCLE
			section of PRE_PROCESS. Also removed
			references to DASH. Also added
	    		Depthpoint displays to bucketsize
	    		question.

		V03-006	KFH0006		Ken Henderson		22 Nov 1982
			Added support for additional FILE and
			CONNECT attributes.

		V03-005	KFH0005		Ken Henderson		8 Sept 1982
			Modifed almost all variables to fit into
			new database scheme of arrays. Also added
			QUERY routine to process the QTAB table-
			driven Q+As. Also added support routines
			for QUERY. Also replaced almost ALL the
			"ASK_xxx" routines with QTAB/QUERY.

		V03-004	KFH0004		Ken Henderson		19 April 1982
			Modified ASK_BUCKET to correct its
			handling of alternate keys.

		V03-003	KFH0003		Ken Henderson		24-Mar-1982
			Modified ASK_TEST_SECONDARY_VALUE to fix
			QAR 833

		V03-002	KFH0002		Ken Henderson		23-Mar-1982
			Modified several 'ASK_' routines to fix
			FT2 QARs 745,746

		V03-001	KFH0001		Ken Henderson		17-Mar-1982
			Modified several 'ASK_' routines to fix
			FT2 QARs 509,449,574,575

-- }

ENVIRONMENT ('LIB$:EDFASK'),

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
'LIB$:EDFUTIL'

)]

MODULE EDFASK (INPUT,OUTPUT);

{ ++

WRITE_HELP -- Routine to output per question help text.

This procedure cases on qtab-offset to output the help text.

CALLING SEQUENCE:

WRITE_HELP;

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


-- }

PROCEDURE WRITE_HELP;

BEGIN

    CASE QTAB_OFFSET OF

	EDF$K_DESIGN_CYCLE :

	    WRITELN (SHIFT,'Type the 2 letter mnemonic of the selected option.');

	EDF$K_KEY_POSITION :

	    WRITELN (SHIFT,
	    'This is the starting byte of the key or key segment.');

	EDF$K_KEY_DIST :

	    WRITELN (
	    SHIFT,'This refers to records that are added to the',CRLF_SHIFT,
	    'file after it is initially loaded.');

	EDF$K_KEY_CHANGES :

	    WRITELN (SHIFT,'This enables or disables the RMS option.');

	EDF$K_KEY_DUPS :

	    WRITELN (SHIFT,'This enables or disables the RMS option.');

	EDF$K_SEGMENTED :

	    WRITELN (SHIFT,'Each string key may consist of up to 8 parts.');

	EDF$K_GLOBAL_WANTED :

	    WRITELN (
	    SHIFT,'These usually increase the speed of file sharing,',
	    CRLF_SHIFT,'at the expense of using more physical memory.');

	EDF$K_RESPONSES :

	    WRITELN (
	    SHIFT,'Automatic means the default answers will be used without',
	    CRLF_SHIFT,'waiting for confirmation.');

	EDF$K_PROMPTING :

	    WRITELN (SHIFT,'This controls whether full menus are displayed.');

	EDF$K_NUMBER_RECORDS :

	    WRITELN (SHIFT,'This will determine the allocation of the file.');

	EDF$K_ASCENDING_LOAD :

	    WRITELN (
	    SHIFT,'This refers to the order of the initial records loaded.');

	EDF$K_INITIAL_COUNT,
	EDF$K_INITIAL_COUNT_LOW,
	EDF$K_INITIAL_COUNT_HIGH :

	    WRITELN (SHIFT,
	    'These are the records initially loaded into the file.',CRLF_SHIFT,
	    'If the file will have no "Load" operation, specify "0".');

	EDF$K_ADDED_COUNT,
	EDF$K_ADDED_COUNT_LOW,
	EDF$K_ADDED_COUNT_HIGH :

	    WRITELN (SHIFT,
	    'These are the records added after the initial file load.');

	EDF$K_BLOCK_SPAN :

	    WRITELN (
	    SHIFT,'If no, each record plus overhead must fit in a disk block.',
	    CRLF_SHIFT,'Also, some space may be wasted at the end of blocks.');

	EDF$K_KEY_LOW,
	EDF$K_KEY_HIGH,
	EDF$K_KEY_SIZE :

	    WRITELN (SHIFT,'This is the length of the key (segment) in bytes.',
	    CRLF_SHIFT,
	    '(With multi-segment keys, answer "0" after the last segment.)');

	EDF$K_PROLOGUE_VERSION :

	    WRITELN (SHIFT,
	    'This refers to the structure level of the data file.',
	    CRLF_SHIFT,
	    'A value of 0 lets RMS choose an appropriate prolog.');

	EDF$K_KEY_COMP_WANTED,
	EDF$K_REC_COMP_WANTED,
	EDF$K_IDX_COMP_WANTED :

	    WRITELN (SHIFT,
	    'If an Analyze/RMS indicates little compression is acheived',
	    CRLF_SHIFT,
	    'then answer No, otherwise it is usually better to answer Yes.');

	EDF$K_CLUSTER_SIZE :

	    WRITELN (SHIFT,
	    'SHOW DEVICE/FULL can be used to determine this value.');

	EDF$K_ASCENDING_ADDED :

	    WRITELN (SHIFT,
	    'This refers to the orderring of additional records.');

	EDF$K_BLOCKS_IN_BUCKET :

	    WRITELN (SHIFT,
	    'Legal range is 1 to 63 blocks per bucket, and buckets must',
	    CRLF_SHIFT,
	    'be large enough to hold at least 1 record plus overhead.');

	EDF$K_BUCKET_WEIGHT :

	    WRITELN (SHIFT,
	    'Smaller_Buffers: less memory and RMS processing used',
	    CRLF_SHIFT,
	    'Flatter_Files:   fewer actual disk accesses needed');

	EDF$K_LOAD_METHOD :

	    IF WAIT_HELP THEN

		WRITELN (SHIFT,
		'Legal values: Fast_Convert, NoFast_Convert, RMS_Puts')

	    ELSE

		WRITELN (SHIFT,
		'Fast_Convert:   using the VAX-11 Convert/Fast_Load option',
		CRLF_SHIFT,
		'NoFast_Convert: using the VAX-11 Convert/NoFast_Load option',
		CRLF_SHIFT,
		'RMS_Puts:       writing to a file from a High Level Language');

	EDF$K_FILL_LOW,
	EDF$K_FILL_HIGH,
	EDF$K_DESIRED_FILL :

	    WRITELN (SHIFT,'This is the initial file loading fill factor.');

	EDF$K_KEY_TYPE :

	BEGIN

	    IF WAIT_HELP THEN

		WRITELN (SHIFT,
		'Legal types: Bin2 Bin4 Bin8 Int2 Int4 Int8 Decimal String')

	    ELSE

		WRITELN (SHIFT,
		'Use',
		CRLF_SHIFT,
		'"Binx" types for unsigned binary keys of 2, 4 or 8 bytes,',
		CRLF_SHIFT,
		'"Intx" types for signed binary key of 2, 4 or 8 bytes,',
		CRLF_SHIFT,
		'"Decimal" type for packed decimal key of 1 to 16 bytes,',
		CRLF_SHIFT,
		'"String" type for character string key of 1 to 255 bytes.');

	END;	{ EDF$K_KEY_TYPE }

	EDF$K_RECORD_FORMAT :

	    WRITELN (
	    SHIFT,'Indexed files are only Fixed or Variable.',CRLF_SHIFT,
	    'Stream format (Seq only) is Stream, Stream_CR, or Stream_LF.');

	EDF$K_ACTIVE_KEY :

	    WRITELN (SHIFT,'Select an already defined key.');

	EDF$K_NUMBER_KEYS :

	    WRITELN (SHIFT,'An Indexed file can have from 1 to 255 keys.');

	EDF$K_CONTROL_SIZE :

	    WRITELN (SHIFT,'This refers to the Fixed portion of the record.');

	EDF$K_SIZE_LOW,
	EDF$K_SIZE_HIGH,
	EDF$K_MEAN_RECORD_SIZE :

	    WRITELN (SHIFT,'This refers to the records in the data file.');

	EDF$K_MAX_RECORD_SIZE :

	BEGIN

	    WRITELN (SHIFT,
	    'This sets the longest record that can be stored in the file.');

	    IF IDATA[EDF$K_SCRIPT_OPTION] <> EDF$K_REL_DESIGN_FDL THEN

		WRITELN (SHIFT,
		'A maximum of 0 will set no explicit maximum.');

	END;	{ EDF$K_MAX_RECORD_SIZE }

	EDF$K_CARR_CTRL :

	    WRITELN (SHIFT,'This sets the Record attributes of the file.');

    OTHERWISE

	{ NULL-STATEMENT } ;

    END;	{ CASE }

    IF (
    (WAIT_HELP)
    AND
    (NOT AUTO_TUNE)
    ) THEN

	LIB$WAIT (3.0);

END;	{ WRITE_HELP }

{ ++

WRITE_QUESTION -- Routine to output the question text.

This procedure cases on the qtab-offset and outputs the correct string.

CALLING SEQUENCE:

WRITE_QUESTION;

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


-- }

PROCEDURE WRITE_QUESTION;

BEGIN

    CASE QTAB_OFFSET OF

	EDF$K_INITIAL_COUNT_LOW :

	    WRITE (SHIFT,
	    'Low bound: Initial Load of Recs	(0-1Giga)[0]	: ');

	EDF$K_INITIAL_COUNT_HIGH :

	BEGIN

	    WRITE (SHIFT,'High bound: Initial Load of Recs(',
	    IDATA[EDF$K_Y_LOW]:NUM_LEN(IDATA[EDF$K_Y_LOW]),
	    '-1Giga)[',DEF:NUM_LEN(DEF),']');

	    IF (NUM_LEN(IDATA[EDF$K_Y_LOW])+NUM_LEN(DEF)) <= 3 THEN

		WRITE ('	: ')

	    ELSE

		WRITE (' : ');

	END;	{ EDF$K_INITIAL_COUNT_HIGH }

	EDF$K_ADDED_COUNT_LOW :

	BEGIN

	    WRITE (SHIFT,
	    'Low bound: Number of Added Recs	(0-1Giga)[0]	: ');

	END;	{ EDF$K_ADDED_COUNT_LOW }

	EDF$K_ADDED_COUNT_HIGH :

	BEGIN

	    WRITE (SHIFT,'High bound: Number of Added Recs(',
	    IDATA[EDF$K_Y_LOW]:NUM_LEN(IDATA[EDF$K_Y_LOW]),
	    '-1Giga)[',DEF:NUM_LEN(DEF),']');

	    IF (NUM_LEN(IDATA[EDF$K_Y_LOW])+NUM_LEN(DEF)) <= 3 THEN

		WRITE ('	: ')

	    ELSE

		WRITE (' : ');

	END;	{ EDF$K_ADDED_COUNT_HIGH }

	EDF$K_KEY_LOW :

	    WRITE (SHIFT,'Low bound: Key',
	    IDATA[EDF$K_ACTIVE_KEY]:3,
	    ' Length	(1-',
	    MAX_KEY_SIZE:NUM_LEN(MAX_KEY_SIZE),')[1]	: ');

	EDF$K_KEY_HIGH :

	    WRITE (SHIFT,'High bound: Key',
	    IDATA[EDF$K_ACTIVE_KEY]:3,' Length	(',
	    IDATA[EDF$K_Y_LOW]:NUM_LEN(IDATA[EDF$K_Y_LOW]),
	    '-',MAX_KEY_SIZE:NUM_LEN(MAX_KEY_SIZE),')[',
	    MAX_KEY_SIZE:NUM_LEN(MAX_KEY_SIZE),']	: ');

	EDF$K_SIZE_LOW :

	BEGIN

	    WRITE (SHIFT,'Low bound: Record Size		(1-',
	    CUR_MAX_REC:5,')[1]	: ');

	END;	{ EDF$K_SIZE_LOW }

	EDF$K_SIZE_HIGH :

	BEGIN

	    WRITE (SHIFT,'High bound: Record Size		(',
	    IDATA[EDF$K_Y_LOW]:NUM_LEN(IDATA[EDF$K_Y_LOW]),'-',
	    CUR_MAX_REC:5,')[1000]');

	    IF NUM_LEN(IDATA[EDF$K_Y_LOW]) < 3 THEN

		WRITE ('	: ')

	    ELSE

		WRITE (' : ');

	END;	{ EDF$K_SIZE_HIGH }

	EDF$K_FILL_LOW :

	    WRITE (SHIFT,'Low bound: Key',
	    IDATA[EDF$K_ACTIVE_KEY]:3,
	    ' Init Fill %	(50-100)[50]	: ');

	EDF$K_FILL_HIGH :

	    WRITE (SHIFT,'High bound: Key',
	    IDATA[EDF$K_ACTIVE_KEY]:3,
	    ' Init Fill %	(50-100)[100]	: ');

	EDF$K_SCRIPT_OPTION :

	BEGIN

	    CLEAR (IF_FULL_PROMPT);

	    { +
	    Show the menu only if we're being verbose.
	    - }
	    IF FULL_PROMPT OR TEMP_FULL_PROMPT THEN

	    BEGIN

		{ +
		Put the title out in reverse video.
		- }
		WRITELN (
		SHIFT,
		'		',
		ANSI_REVERSE,
		' Script Title Selection ',
		ANSI_RESET,
		CRLF,
		CRLF_SHIFT,
    'Add_Key		modeling and addition of a new index''s parameters',
		CRLF_SHIFT,
    'Delete_Key	removal of the highest index''s parameters',
		CRLF_SHIFT,
    'Indexed		modeling of parameters for an entire Indexed file',
		CRLF_SHIFT,
    'Optimize	tuning of all indices'' parameters using file statistics',
		CRLF_SHIFT,
    'Relative	selection of parameters for a Relative file',
		CRLF_SHIFT,
    'Sequential	selection of parameters for a Sequential file',
		CRLF_SHIFT,
    'Touchup		remodeling of parameters for a particular index',
		CRLF
		);

	    END

	    ELSE

		WRITELN (SHIFT,
		'(Add_Key Delete_Key Indexed Optimize',
		CRLF_SHIFT,
		' Relative Sequential Touchup)');

	    { +
	    Pop the question.
	    - }
	    WRITE (SHIFT,'Editing Script Title		(Keyword)',
	    ANSI_REVERSE,'[-]',ANSI_RESET,'	: ');

	END;	{ EDF$K_SCRIPT_OPTION }

	EDF$K_RETURN :

	    WRITE (CRLF_SHIFT,ANSI_REVERSE,CONTINUE_TEXT,
	    ANSI_RESET,'	');

	EDF$K_DESIGN_CYCLE :

	    WRITE (SHIFT,'(Type "FD" to Finish Design)',
	    CRLF_SHIFT,
	    'Which File Parameter	(Mnemonic)[refresh]	: ');

	EDF$K_CURRENT_FUNCTION :

	BEGIN

	    CLEAR (SCREEN);

	    { +
	    Only show the menu if we're being verbose.
	    - }
	    IF FULL_PROMPT OR TEMP_FULL_PROMPT THEN

	    BEGIN

		{ +
		Show the header in reverse video, and then the
		rest of the menu.
		- }
		WRITELN (
		SHIFT,
		'		',
		ANSI_REVERSE,
		EDF_HEADER,
		ANSI_RESET,
		CRLF,
		CRLF_SHIFT,
	    'Add	to insert one or more lines into the FDL definition',
		CRLF_SHIFT,
	    'Delete	to remove one or more lines from the FDL definition',
		CRLF_SHIFT,
	    'Exit	to leave the FDL Editor after creating the FDL file',
		CRLF_SHIFT,
	    'Help	to obtain information about the FDL Editor',
		CRLF_SHIFT,
	    'Invoke	to initiate a script of related questions',
		CRLF_SHIFT,
	    'Modify	to change existing line(s) in the FDL definition',
		CRLF_SHIFT,
	    'Quit	to abort the FDL Editor with no FDL file creation',
		CRLF_SHIFT,
	    'Set	to specify FDL Editor characteristics',
		CRLF_SHIFT,
	    'View	to display the current FDL Definition',
		CRLF);

	    END	{ IF TRUE FULL_PROMPT OR TEMP_FULL_PROMPT }

	    ELSE

		WRITELN (SHIFT,
		'(Add Delete Exit Help Invoke Modify Quit Set View)');

	    { +
	    Pop the question.
	    - }
	    WRITE (SHIFT,
	    'Main Editor Function		(Keyword)[Help]	: ');

	END;	{ EDF$K_CURRENT_FUNCTION }


	EDF$K_RESPONSES :

	BEGIN

	    WRITE (SHIFT,'(Automatic Manual)',CRLF_SHIFT,
	    'Default responses in scripts	(Keyword)[Auto]	: ');

	END;

	EDF$K_PROMPTING :

	BEGIN

	    WRITELN (SHIFT,'(Brief Full)');
	    WRITE (SHIFT,
	    'Prompting level for menus	(Keyword)[Full]	: ');

	END;

	EDF$K_KEY_POSITION :

	BEGIN

	    WRITE (SHIFT,'Key',IDATA[EDF$K_ACTIVE_KEY]:3,
	    ' Position		');

	    IF BDATA[EDF$K_SEGMENTED] THEN

		WRITE ('SEG',SEGMENT_NUMBER:1);

	    WRITE ('	(0-',
	    MAX_KEY_POSITION:NUM_LEN(MAX_KEY_POSITION),')[0]	: ');

	END;	{ EDF$K_KEY_POSITION }

	EDF$K_KEY_DIST :

	BEGIN

	    WRITELN (SHIFT,
	    'Will Added Records be Distributed Evenly over the');

	    IF NOT OPTIMIZING THEN

		WRITE (SHIFT,'Initial')

	    ELSE

		WRITE (SHIFT,'Reloaded');

	    WRITE (' Range of Pri Key Values');

	    IF NOT OPTIMIZING THEN

		WRITE (TAB);

	    WRITE ('(Yes/No)[No]	: ');

	END;	{ EDF$K_KEY_DIST }

	EDF$K_KEY_CHANGES :

	    WRITE (SHIFT,'Key',IDATA[EDF$K_ACTIVE_KEY]:3,
	    ' Changes allowed		(Yes/No)[Yes]	: ');

	EDF$K_KEY_DUPS :

	BEGIN

	    WRITE (SHIFT,'Key',IDATA[EDF$K_ACTIVE_KEY]:3,
	    ' Duplicates allowed	(Yes/No)[');

	    { +
	    The default for the primary key is NO, for alternates YES.
	    - }
	    IF IDATA[EDF$K_ACTIVE_KEY] = 0 THEN

		WRITE ('No]	: ')

	    ELSE

		WRITE ('Yes]	: ');

	END;	{ EDF$K_KEY_DUPS }

	EDF$K_SEGMENTED :

	    WRITE (SHIFT,
	    'Key',IDATA[EDF$K_ACTIVE_KEY]:3,
	    ' Segmentation desired	(Yes/No)[No]	: ');

	EDF$K_GLOBAL_WANTED :

	    WRITE (SHIFT,
	    'Global Buffers desired		(Yes/No)[No]	: ');

	EDF$K_NUMBER_RECORDS :

	    WRITE (SHIFT,'File Capacity in Records	(0-1Giga)',
	    ANSI_REVERSE,'[-]',ANSI_RESET,'	: ');

	EDF$K_INITIAL_COUNT :

	BEGIN

	    IF NOT OPTIMIZING THEN

		WRITELN (SHIFT,
		'Number of Records that will be Initially Loaded')

	    ELSE

		WRITELN (SHIFT,'Number of Records that will be Reloaded');

	    WRITE (SHIFT,'into the File','			(0-1Giga)');

	    IF NOT OPTIMIZING THEN

		WRITE (ANSI_REVERSE,'[-]',ANSI_RESET,'	: ')

	    ELSE

	    BEGIN

		WRITE ('[',OLD_COUNT:NUM_LEN(OLD_COUNT),']');

		IF NUM_LEN(OLD_COUNT) > 4 THEN

		    WRITE (' : ')

		ELSE

		    WRITE ('	: ');

	    END;

	END;	{ EDF$K_INITIAL_COUNT }

	EDF$K_LOAD_METHOD :

	BEGIN

	    WRITELN (SHIFT,'(Fast_Convert NoFast_Convert RMS_Puts)');

	    IF NOT OPTIMIZING THEN

		WRITE (SHIFT,'Initial File Load Method	')

	    ELSE

		WRITE (SHIFT,'File Reloading Method		');

	    WRITE ('(Keyword)[Fast]	: ');

	END;	{ EDF$K_LOAD_METHOD }

	EDF$K_ASCENDING_LOAD :

	BEGIN

	    IF NOT OPTIMIZING THEN

		WRITELN (SHIFT,
		'Will Initial Records Typically be Loaded in Order')

	    ELSE

		WRITELN (SHIFT,
		'Will the Records be Reloaded Typically in Order');

	    WRITE (SHIFT,
	    'by Ascending Primary Key	(Yes/No)[No]	: ');

	END;	{ EDF$K_ASCENDING_LOAD }

	EDF$K_ADDED_COUNT :

	BEGIN

	    WRITELN (SHIFT,
	    'Number of Additional Records to be Added After');

	    IF NOT OPTIMIZING THEN

		WRITE (SHIFT,'the Initial File Load')

	    ELSE

		WRITE (SHIFT,'the Reloading the File');

	    WRITE ('		(0-1Giga)[0]	: ');

	END;	{ EDF$K_ADDED_COUNT }

	EDF$K_KEY_COMP_WANTED :

	    WRITE (SHIFT,
	    'Data Key Compression desired	(Yes/No)[Yes]	: ');

	EDF$K_REC_COMP_WANTED :

	    WRITE (SHIFT,
	    'Data Record Compression desired	(Yes/No)[Yes]	: ');

	EDF$K_IDX_COMP_WANTED :

	    WRITE (SHIFT,
	    'Index Compression desired	(Yes/No)[Yes]	: ');

	EDF$K_CLUSTER_SIZE :

	    WRITE (SHIFT,
	    'Target disk volume Cluster Size	(1-1Giga)[3]	: ');

	EDF$K_BLOCK_SPAN :

	    WRITE (SHIFT,
	    'Records can span disk blocks	(Yes/No)[Yes]	: ');

	EDF$K_ASCENDING_ADDED :

	    WRITE (SHIFT,
	    'Will Additional Records Typically be Added in',CRLF_SHIFT,
	    'Order by Ascending Primary Key	(Yes/No)[No]	: ');

	EDF$K_PROLOGUE_VERSION :

	    WRITE (SHIFT,
	    'File Prolog Version		(0-3)[3]	: ');

	EDF$K_KEY_SIZE :

	BEGIN

	    WRITE (SHIFT,'Key',IDATA[EDF$K_ACTIVE_KEY]:3,
	    ' Length		');

	    IF BDATA[EDF$K_SEGMENTED] THEN

		WRITE ('SEG',SEGMENT_NUMBER:1);

	    WRITE ('	(',MIN_KEY_SIZE:NUM_LEN(MIN_KEY_SIZE),'-',
	    MAX_KEY_SIZE:NUM_LEN(MAX_KEY_SIZE),')',
	    ANSI_REVERSE,'[-]',ANSI_RESET,'	: ');

	END;	{ EDF$K_KEY_SIZE }

	EDF$K_BLOCKS_IN_BUCKET :

	BEGIN

	    WRITE (SHIFT,'Emphasis Used In Defining Default:	( ');

	    IF IDATA[EDF$K_BUCKET_WEIGHT] = EDF$K_SMALLER_BUFFERS THEN

		WRITELN ('   Smaller_buffers )')

	    ELSE

		WRITELN ('   Flatter_files   )');

	    WRITELN (SHIFT,'Suggested Bucket Sizes:			( ',
	    BREAKPOINT_LEFT:6,
	    BREAKPOINT_MID:6,BREAKPOINT_RIGHT:6,' )');

	    WRITELN (SHIFT,'Number of Levels in Index:		( ',
	    DEPTHPOINT_LEFT:6,
	    DEPTHPOINT_MID:6,DEPTHPOINT_RIGHT:6,' )');

	    WRITELN (SHIFT,'Number of Buckets in Index:		( ',
	    NUMPOINT_LEFT:6,
	    NUMPOINT_MID:6,NUMPOINT_RIGHT:6,' )');

	    WRITELN (SHIFT,'Pages Required to Cache Index:		( ',
	    PAGEPOINT_LEFT:6,
	    PAGEPOINT_MID:6,PAGEPOINT_RIGHT:6,' )');

	    WRITELN (SHIFT,'Processing Used to Search Index:	( ',
	    EXAMPOINT_LEFT:6,
	    EXAMPOINT_MID:6,EXAMPOINT_RIGHT:6,' )');

	    WRITE (CRLF_SHIFT,'Key',
	    IDATA[EDF$K_ACTIVE_KEY]:3,
	    ' Bucket Size		(',MIN_BUCKET:NUM_LEN(MIN_BUCKET),
	    '-63)[',
	    QTAB[QTAB_OFFSET].DEFAULT:NUM_LEN(QTAB[QTAB_OFFSET].DEFAULT),
	    ']	: ');

	END;	{ EDF$K_BLOCKS_IN_BUCKET }

	EDF$K_BUCKET_WEIGHT :

	BEGIN

	    WRITE (SHIFT,'(Smaller_Buffers Flatter_Files)',
	    CRLF_SHIFT,'Emphasis for Default Bucket_Size(Keyword)[');

	    IF QTAB[QTAB_OFFSET].DEFAULT = EDF$K_FLATTER_FILES THEN

		WRITE ('Flat]	: ')

	    ELSE

		WRITE ('Small] : ');

	END;	{ EDF$K_BUCKET_WEIGHT }

	EDF$K_DESIRED_FILL :

	    WRITE (SHIFT,'Key',IDATA[EDF$K_ACTIVE_KEY]:3,
	    ' Load Fill Percent	(50-100)[100]	: ');

	EDF$K_CONFIRM :

	    WRITE (SHIFT,
	    'Replace this existing secondary	(Yes/No)[No]	: ');

	EDF$K_DATA_FILE_NAME :

	    WRITE (SHIFT,
	    'Data File file-spec		(1-126 chars)[null]',
	    CRLF_SHIFT,': ');

	EDF$K_ANALYSIS :

	    WRITE (SHIFT,'Analysis File file-spec	(1-126 chars)[null]',
	    CRLF_SHIFT,': ');

	EDF$K_OUTPUT :

	    WRITE (SHIFT,
	    'Output File file-spec		(1-126 chars)[null]',
	    CRLF_SHIFT,': ');

	EDF$K_FDL_TITLE :

	    WRITE (SHIFT,
	    'Text for FDL Title Section	(1-126 chars)[null]',
	    CRLF_SHIFT,': ');

	EDF$K_KEY_NAME :

	    WRITE (SHIFT,'Key',IDATA[EDF$K_ACTIVE_KEY]:3,
	    ' Name			(1-32 chars)[null]',CRLF_SHIFT,
	    ': ');

	EDF$K_KEY_TYPE :

	BEGIN

	    WRITE (SHIFT,'(Bin2 Bin4 Bin8 Int2 Int4 Int8 Decimal String)',
	    CRLF_SHIFT,'Key',IDATA[EDF$K_ACTIVE_KEY]:3,
	    ' Data Type		(Keyword)[Str]	: ');

	END;	{ EDF$K_KEY_TYPE }

	EDF$K_ACTIVE_KEY :

	    WRITE (SHIFT,'Key of Reference		(',
	    LOW_KEY:NUM_LEN(LOW_KEY),'-',HIGH_KEY:NUM_LEN(HIGH_KEY)
	    ,')[0]	: ');

	EDF$K_NUMBER_KEYS :

	BEGIN

	    WRITE (SHIFT,'Number of Keys to Define	(1-255)[',
	    QTAB[QTAB_OFFSET].DEFAULT:NUM_LEN(QTAB[QTAB_OFFSET].DEFAULT),
	    ']	: ');

	END;

	EDF$K_CARR_CTRL :

	BEGIN

	    WRITE (SHIFT,'(Carriage_Return FORTRAN None Print)',
	    CRLF_SHIFT,'Carriage Control		(Keyword)[Carr]	: ');

	END;	{ EDF$K_CARR_CTRL }

	EDF$K_RECORD_FORMAT :

	BEGIN

	    CASE IDATA[EDF$K_SCRIPT_OPTION] OF

		EDF$K_ADD_KEY_FDL,
		EDF$K_DELETE_KEY_FDL,
		EDF$K_REDESIGN_FDL,
		EDF$K_OPTIMIZE_FDL,
		EDF$K_IDX_DESIGN_FDL : WRITELN (SHIFT,'(Fixed Variable)');
		EDF$K_REL_DESIGN_FDL : WRITELN (SHIFT,'(Fixed Variable VFC)');
		EDF$K_SEQ_DESIGN_FDL : WRITELN (SHIFT,
			'(Fixed Stream _CR _LF Undefined Variable VFC)');

	    OTHERWISE

		{ NULL-STATEMENT } ;

	    END;	{ CASE }

	    WRITE (SHIFT,
	    'Record Format			(Keyword)[Var]	: ');

	END;	{ EDF$K_RECORD_FORMAT }

	EDF$K_CONTROL_SIZE :

	    WRITE (SHIFT,'Control Field Size		(1-',
	    CUR_MAX_FIXED:NUM_LEN(CUR_MAX_FIXED),')[2]	: ');

	EDF$K_MEAN_RECORD_SIZE :

	BEGIN

	    WRITE (SHIFT);
    
	    IF VARIABLE_RECORDS THEN
    
		WRITE ('Mean ');
    
	    WRITE ('Record Size');
    
	    IF IDATA[EDF$K_RECORD_FORMAT] = FDL$C_VFC THEN
    
		WRITE (' w/fix');
    
	    IF NOT VARIABLE_RECORDS THEN
    
		WRITE (TAB);
    
	    WRITE ('		(1-',
	    CUR_MAX_REC:NUM_LEN(CUR_MAX_REC),')',
	    ANSI_REVERSE,'[-]',ANSI_RESET,'	: ');

	END;	{ EDF$K_MEAN_RECORD_SIZE }

	EDF$K_SURFACE_OPTION :

	BEGIN

	    { +
	    See which surface.
	    - }
	    CLEAR (IF_FULL_PROMPT);

	    IF FULL_PROMPT OR TEMP_FULL_PROMPT THEN

	    BEGIN

		WRITELN (
		SHIFT,
		'		',
		ANSI_REVERSE,
		' Key',IDATA[EDF$K_ACTIVE_KEY]:3,' Graph Type Selection ',
		ANSI_RESET,
		CRLF,
		CRLF_SHIFT,
    'Line	Bucket Size vs Index Depth	as a 2 dimensional plot',
		CRLF_SHIFT,
    'Fill	Bucket Size vs     Load Fill Percent     vs Index Depth',
		CRLF_SHIFT,
    'Key	Bucket Size vs         Key Length        vs Index Depth'
		);

		IF IDATA[EDF$K_ACTIVE_KEY] = 0 THEN

		BEGIN

WRITELN (SHIFT,
'Record	Bucket Size vs        Record Size        vs Index Depth',
CRLF_SHIFT,
'Init	Bucket Size vs Initial Load Record Count vs Index Depth',
CRLF_SHIFT,
'Add	Bucket Size vs  Additional Record Count  vs Index Depth');

		END;

		WRITELN;

	    END

	    ELSE

	    BEGIN

		WRITE (SHIFT,'(Line Fill Key');

		IF IDATA[EDF$K_ACTIVE_KEY] = 0 THEN

		    WRITE (' Record Init Add)')

		ELSE

		    WRITE (')');

		WRITELN;

	    END;	{ IF FULL_PROMPT OR TEMP_FULL_PROMPT }

	    { +
	    Always ask the question, even for brief prompting.
	    - }
	    WRITE (SHIFT,'Graph type to display		(Keyword)[');

	    CASE QTAB[QTAB_OFFSET].DEFAULT OF

		EDF$K_LINE_SURFACE :	WRITE ('Line]	: ');
		EDF$K_FILL_SURFACE :	WRITE ('Fill]	: ');
		EDF$K_KEY_SURFACE :	WRITE ('Key]	: ');
		EDF$K_SIZE_SURFACE :	WRITE ('Rec]	: ');
		EDF$K_INIT_SURFACE :	WRITE ('Init]	: ');
		EDF$K_ADDED_SURFACE :	WRITE ('Add]	: ');

	    OTHERWISE

		{ NULL-STATEMENT } ;

	    END;	{ CASE }

	END;	{ EDF$K_SURFACE_OPTION }

	EDF$K_GRANULARITY :

	BEGIN

	    { +
	    See what level of granularity.
	    - }
	    CLEAR (IF_FULL_PROMPT);

	    IF FULL_PROMPT OR TEMP_FULL_PROMPT THEN

	    BEGIN

		WRITELN (
		SHIFT,
		'		',
		ANSI_REVERSE,
		' Area Granularity Selection ',
		ANSI_RESET);

		IF DEC_CRT THEN

		BEGIN

		WRITELN (CRLF,LOW_SHIFT,
'   '(27)')0'(14)'lqqqqqqqqqqqqqk'(15)'     '(14)'lqqqqqqqqqqqqqk'(15)'     '(14)'lqqqqqqqqqqqqqk'(15)'     '(14)'lqqqqqqqqqqqqqk'(15)' ',
		CRLF,LOW_SHIFT,
' 0 '(14)'x'(15)' Key 0 Data  '(14)'x'(15)'   0 '(14)'x'(15)' Key 0 Data  '(14)'x'(15)'   0 '(14)'x'(15)' Key 0 Data  '(14)'x'(15)'   0 '(14)'x'(15)' Key 0 Data  '(14)'x'(15)' ',
		CRLF,LOW_SHIFT,
'   '(14)'x'(15)'             '(14)'x'(15)'     '(14)'tqqqqqqqqqqqqqu'(15)'     '(14)'tqqqqqqqqqqqqqu'(15)'     '(14)'tqqqqqqqqqqqqqu'(15)' ',
		CRLF,LOW_SHIFT,
'   '(14)'x'(15)' Key 0 Index '(14)'x'(15)'   1 '(14)'x'(15)' Key 0 Index '(14)'x'(15)'   1 '(14)'x'(15)' Key 0 Index '(14)'x'(15)'   1 '(14)'x'(15)' Key 0 Index '(14)'x'(15)' ',
		CRLF,LOW_SHIFT,
'   '(14)'x'(15)'             '(14)'x'(15)'     '(14)'x'(15)'             '(14)'x'(15)'     '(14)'tqqqqqqqqqqqqqu'(15)'     '(14)'tqqqqqqqqqqqqqu'(15)' ',
		CRLF,LOW_SHIFT,
'   '(14)'x'(15)' Key n Data  '(14)'x'(15)'     '(14)'x'(15)' Key n Data  '(14)'x'(15)'   2 '(14)'x'(15)' Key n Data  '(14)'x'(15)'   2 '(14)'x'(15)' Key n Data  '(14)'x'(15)' ',
		CRLF,LOW_SHIFT,
'   '(14)'x'(15)'             '(14)'x'(15)'     '(14)'x'(15)'             '(14)'x'(15)'     '(14)'x'(15)'             '(14)'x'(15)'     '(14)'tqqqqqqqqqqqqqu'(15)' ',
		CRLF,LOW_SHIFT,
'   '(14)'x'(15)' Key n Index '(14)'x'(15)'     '(14)'x'(15)' Key n Index '(14)'x'(15)'     '(14)'x'(15)' Key n Index '(14)'x'(15)'   3 '(14)'x'(15)' Key n Index '(14)'x'(15)' ',
		CRLF,LOW_SHIFT,
'   '(14)'mqqqqqqqqqqqqqj'(15)'     '(14)'mqqqqqqqqqqqqqj'(15)'     '(14)'mqqqqqqqqqqqqqj'(15)'     '(14)'mqqqqqqqqqqqqqj'(15)' ',
		CRLF,LOW_SHIFT,
'       One (1)             Two (2)            Three (3)            Four (4)',
		CRLF)

		END	{ IF DEC_CRT }

		ELSE

		BEGIN

		WRITELN (CRLF,LOW_SHIFT,
'   +-------------+     +-------------+     +-------------+     +-------------+',
		CRLF,LOW_SHIFT,
' 0 | Key 0 Data  |   0 | Key 0 Data  |   0 | Key 0 Data  |   0 | Key 0 Data  |',
		CRLF,LOW_SHIFT,
'   |             |     +-------------+     +-------------+     +-------------+',
		CRLF,LOW_SHIFT,
'   | Key 0 Index |   1 | Key 0 Index |   1 | Key 0 Index |   1 | Key 0 Index |',
		CRLF,LOW_SHIFT,
'   |             |     |             |     +-------------+     +-------------+',
		CRLF,LOW_SHIFT,
'   | Key n Data  |     | Key n Data  |   2 | Key n Data  |   2 | Key n Data  |',
		CRLF,LOW_SHIFT,
'   |             |     |             |     |             |     +-------------+',
		CRLF,LOW_SHIFT,
'   | Key n Index |     | Key n Index |     | Key n Index |   3 | Key n Index |',
		CRLF,LOW_SHIFT,
'   +-------------+     +-------------+     +-------------+     +-------------+',
		CRLF,LOW_SHIFT,
'       One (1)             Two (2)            Three (3)            Four (4)',
		CRLF);

		END;	{ IF NOT DEC_CRT }

	    END

	    ELSE

	    BEGIN

		WRITELN (SHIFT,'(One Two Three Four Double)');

	    END;	{ IF FULL_PROMPT OR TEMP_FULL_PROMPT }

	    { +
	    Always ask the question, even for brief prompting.
	    - }
	    WRITELN (SHIFT,'(Type "Double" to allocate 2 areas per key)');
	    WRITE (SHIFT,
	    'Number of areas to allocate	(keyword)[Three] : ');

	END;	{ EDF$K_GRANULARITY }

	EDF$K_SET_FUNCTION :

	BEGIN

	    { +
	    See what char to set.
	    - }
	    CLEAR (IF_FULL_PROMPT);

	    IF FULL_PROMPT OR TEMP_FULL_PROMPT THEN

	    BEGIN

		WRITELN (
		SHIFT,
		'		',
		ANSI_REVERSE,
		' FDL Editor SET Function ',
		ANSI_RESET,
		CRLF,
		CRLF_SHIFT,
		'Analysis	filespec of FDL Analysis file',
		CRLF_SHIFT,
		'Display		type of graph to display',
		CRLF_SHIFT,
		'Emphasis	of default bucketsize calculations',
		CRLF_SHIFT,
		'Granularity	number of areas in Indexed files',
		CRLF_SHIFT,
		'Number_Keys	number of keys in Indexed files',
		CRLF_SHIFT,
		'Output		filespec of FDL Output file',
		CRLF_SHIFT,
		'Prompting	Full or Brief prompting of menus',
		CRLF_SHIFT,
		'Responses	usage of default responses in scripts',
		CRLF);

	    END

	    ELSE

	    BEGIN

		WRITELN (SHIFT,
		'(Analysis Display Emphasis Granularity',
		CRLF_SHIFT,' Number_Keys Output Prompting Responses)');

	    END;	{ IF FULL_PROMPT OR TEMP_FULL_PROMPT }

	    { +
	    Always ask the question, even for brief prompting.
	    - }
	    WRITE (SHIFT,
	    'Editor characteristic to set	(keyword)',
	    ANSI_REVERSE,'[-]',ANSI_RESET,'	: ');

	END;	{ EDF$K_SET_FUNCTION }

	EDF$K_MAX_RECORD_SIZE :

	BEGIN

	    WRITE (SHIFT,'Maximum Record Size		(');
    
	    IF IDATA[EDF$K_SCRIPT_OPTION] = EDF$K_REL_DESIGN_FDL THEN
    
	    BEGIN
    
		EXTRA	:= 0;
		WRITE (
		LOWMAX:NUM_LEN(LOWMAX),'-',
		CUR_MAX_REC:NUM_LEN(CUR_MAX_REC),')',
		ANSI_REVERSE,'[-]',ANSI_RESET);
		QTAB[QTAB_OFFSET].DEFAULT_OK	:= FALSE;
    
	    END
    
	    ELSE
    
	    BEGIN
    
		EXTRA	:= 2;
		WRITE ('0,',
		LOWMAX:NUM_LEN(LOWMAX),'-',CUR_MAX_REC:NUM_LEN(CUR_MAX_REC),
		')[0]');
		QTAB[QTAB_OFFSET].DEFAULT_OK	:= TRUE;
		QTAB[QTAB_OFFSET].DEFAULT	:= 0;
    
	    END;
    
	    IF (
	    ( EXTRA + NUM_LEN(LOWMAX) + NUM_LEN(CUR_MAX_REC) ) > 9
	    ) THEN
    
		WRITE (' : ')
    
	    ELSE
    
		WRITE ('	: ');

	END;	{ EDF$K_MAX_RECORD_SIZE }

	EDF$K_TEST_PRIMARY :

	BEGIN

	    CLEAR (IF_FULL_PROMPT);

	    IF FULL_CHOICE THEN

	    BEGIN

		IF FULL_PROMPT OR TEMP_FULL_PROMPT THEN

		BEGIN

WRITELN (SHIFT,'		',
ANSI_REVERSE,
' Legal Primary Attributes ',
ANSI_RESET,
CRLF,
CRLF_SHIFT,
'ACCESS	attributes set the run-time access mode of the file',
CRLF_SHIFT,
'AREA x	attributes define the characteristics of file area x',
CRLF_SHIFT,
'CONNECT	attributes set various RMS run-time options',
CRLF_SHIFT,
'DATE	attributes set the date parameters of the file',
CRLF_SHIFT,
'FILE	attributes affect the entire RMS data file',
CRLF_SHIFT,
'JOURNAL	attributes set the journaling parameters of the file',
CRLF_SHIFT,
'KEY y	attributes define the characteristics of key y',
CRLF_SHIFT,
'RECORD	attributes set the non-key aspects of each record',
CRLF_SHIFT,
'SHARING	attributes set the run-time sharing mode of the file',
CRLF_SHIFT,
'SYSTEM	attributes document operating system-specific items',
CRLF_SHIFT,
'TITLE	is the header line for the FDL file',
CRLF);

(* insert in above to handle ACLs
'ACL	entries specify the Access-Control-List of the file',
CRLF_SHIFT,
*)	

		END
	
		ELSE
		    WRITELN (SHIFT,
		    '(ACCESS AREA CONNECT DATE FILE JOURNAL',
		    CRLF_SHIFT,
		    ' KEY RECORD SHARING SYSTEM TITLE)');

(* ACL insert in above to handle ACLs *)	

	    END

	    ELSE

	    BEGIN

		IF FULL_PROMPT OR TEMP_FULL_PROMPT THEN

		BEGIN

		    WRITELN (
		    SHIFT,'		',
		    ANSI_REVERSE,
		    ' Current Primary Attributes ',
		    ANSI_RESET,
		    CRLF
		    );

		    { +
		    Setup to display definition on the terminal.
		    - }
		    OPEN	(FDL_DEST,SYS$OUTPUT_NAME,NEW,
				RECORD_LENGTH := 252);
		    REWRITE	(FDL_DEST);

		    SHOW_ALL_PRIMARIES;

		    CLOSE	(FDL_DEST);

		END

		ELSE

		    WRITELN (SHIFT,
		    '(Type "?" for a list of existing Primary Attributes)');

	    END;

	    { +
	    Pop the question.
	    - }
	    WRITE (SHIFT,'Enter Desired Primary		(Keyword)[',
	    DEFAULT_PRIMARY:PRIMARY_WIDTH[DEFAULT_PRIMARY]);

	    IF DEFAULT_PRIMARY IN [ AREA, KEY ] THEN

		WRITE (' ',DEFAULT_PRINUM:NUM_LEN(DEFAULT_PRINUM));

	    WRITE ('] : ');

	END;	{ EDF$K_TEST_PRIMARY }

    OTHERWISE

	{ NULL-STATEMENT } ;

    END;	{ CASE }

END;	{ WRITE_QUESTION }

{ ++

SPREAD_LOW_HIGH -- Routine to make sure high-bound is 5 away from low-bound.

This procedure adjusts Y_LOW,Y_HIGH until high-bound >= low-bound.

CALLING SEQUENCE:

SPREAD_LOW_HIGH (LO_LIM,HI_LIM);

INPUT PARAMETERS:

LO_LIM
HI_LIM

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


-- }

PROCEDURE SPREAD_LOW_HIGH ( LO_LIM, HI_LIM : INTEGER );

BEGIN

    { +
    Make sure the bounds are at least 5 apart.
    - }
    IF (IDATA[EDF$K_Y_HIGH] - IDATA[EDF$K_Y_LOW]) < 5 THEN

    BEGIN

	REPEAT

	    IF IDATA[EDF$K_Y_LOW] > LO_LIM THEN

		IDATA[EDF$K_Y_LOW]	:= IDATA[EDF$K_Y_LOW] - 1;

	    IF IDATA[EDF$K_Y_HIGH] < HI_LIM THEN

		IDATA[EDF$K_Y_HIGH]	:= IDATA[EDF$K_Y_HIGH] + 1;

	UNTIL (IDATA[EDF$K_Y_HIGH] - IDATA[EDF$K_Y_LOW]) > 4;

    END;

END;	{ SPREAD_LOW_HIGH }

{ ++

AUTO_SCALE -- Scale a surface plot.

This procedure adjusts Y_LOW,Y_HIGH,Y_INCR until the plot fits on the screen.

CALLING SEQUENCE:

AUTO_SCALE (LOW_LIMIT,HIGH_LIMIT);

INPUT PARAMETERS:

LOW_LIMIT
HIGH_LIMIT

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


-- }

PROCEDURE AUTO_SCALE ( LOW_LIMIT, HIGH_LIMIT : INTEGER );

BEGIN

    { +
    Figure out what the step between lines should be.
    We always have max_array_row steps.
    - }
    TEMP_INT2	:= IDATA[EDF$K_Y_HIGH];
    TEMP_REAL	:= (IDATA[EDF$K_Y_HIGH] - IDATA[EDF$K_Y_LOW]) / MAX_ARRAY_ROW;

    IDATA[EDF$K_Y_INCR]	:= TRUNC (TEMP_REAL);

    IF ((IDATA[EDF$K_Y_HIGH] - IDATA[EDF$K_Y_LOW]) MOD MAX_ARRAY_ROW) > 0 THEN

	IDATA[EDF$K_Y_INCR]	:= IDATA[EDF$K_Y_INCR] + 1;

    { +
    Juggle the margins and the step until we get it to fit.
    - }
    REPEAT

	IDATA[EDF$K_Y_HIGH]	:= IDATA[EDF$K_Y_LOW]
    					+ (MAX_ARRAY_ROW * IDATA[EDF$K_Y_INCR]);
    
	{ +
	Adjust down if too high.
	- }
	WHILE IDATA[EDF$K_Y_HIGH] > HIGH_LIMIT DO
    
	BEGIN
    
	    IDATA[EDF$K_Y_LOW]		:= IDATA[EDF$K_Y_LOW] - 1;
	    IDATA[EDF$K_Y_HIGH]		:= IDATA[EDF$K_Y_HIGH] - 1;
    
	END;

	{ +
	Adjust up if too low.
	- }
	WHILE IDATA[EDF$K_Y_LOW] < LOW_LIMIT DO

	BEGIN

	    IDATA[EDF$K_Y_LOW]		:= IDATA[EDF$K_Y_LOW] + 1;
	    IDATA[EDF$K_Y_HIGH]		:= IDATA[EDF$K_Y_HIGH] + 1;

	END;

	{ +
	Try a smaller step if this didn't work.
	- }
	IF (IDATA[EDF$K_Y_LOW] < LOW_LIMIT) OR (IDATA[EDF$K_Y_HIGH] > HIGH_LIMIT) THEN

	    IDATA[EDF$K_Y_INCR]		:= IDATA[EDF$K_Y_INCR] - 1;

    UNTIL (IDATA[EDF$K_Y_LOW] >= LOW_LIMIT) AND (IDATA[EDF$K_Y_HIGH] <= HIGH_LIMIT);

    { +
    Adjust the range up if we've squeezed it low.
    - }
    IF IDATA[EDF$K_Y_HIGH] < TEMP_INT2 THEN

    BEGIN

	IDATA[EDF$K_Y_LOW]	:= IDATA[EDF$K_Y_LOW]
    					+ (TEMP_INT2 - IDATA[EDF$K_Y_HIGH]);
	IDATA[EDF$K_Y_HIGH]	:= IDATA[EDF$K_Y_HIGH]
    					+ (TEMP_INT2 - IDATA[EDF$K_Y_HIGH]);

    END;

END;	{ AUTO_SCALE }

{ ++

ALT_SOURCE -- Look for the answer elsewhere.

This function can look in the definition linked list or the analysis linked
list, if it is determined that asking the user isn't appropriate.

CALLING SEQUENCE:

BOOLEAN_VAR := ALT_SOURCE (LINE_OBJECT_TYPE,PRIMARY,PRINUM,SECONDARY,SECNUM,AN_FLAG);

INPUT PARAMETERS:

OBJECT_TYPE
PRIMARY
PRINUM
SECONDARY
SECNUM
AN_FLAG

IMPLICIT INPUTS:

none

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

none

ROUTINES CALLED:

none

ROUTINE VALUE:

TRUE if the question should be asked, FALSE if it should be skipped.

SIGNALS:

none

SIDE EFFECTS:

none

-- }

FUNCTION ALT_SOURCE (
			OBJ_TYP		: LINE_OBJECT_TYPE;
			PRIM		: PRIMARY_TYPE;
			PRIMNUM		: INTEGER;
			SECO		: SECONDARY_TYPE;
			SECONUM		: INTEGER;
			AN_FLAG		: BOOLEAN
			) : BOOLEAN;

BEGIN

    { +
    Initial setup for GLOBAL_COUNT question.
    - }
    IF QTAB_OFFSET = EDF$K_GLOBAL_COUNT THEN

	GLOBAL_SET		:= FALSE;

    { +
    Should the question be visible?
    The questions asking compression percent are never visible and should
    always be found in the analysis file.
    - }
    IF (
    ((VISIBLE_QUESTION) OR (NOT OPTIMIZING))
    AND
    ( NOT (QTAB_OFFSET IN [ EDF$K_DATA_RECORD_COMP, EDF$K_DATA_KEY_COMP,
    				EDF$K_INDEX_RECORD_COMP ]))
    ) THEN

    BEGIN

	ALT_SOURCE	:= TRUE;

    END

    ELSE IF OPTIMIZING THEN

    BEGIN

	{ +
	Try to get the data from the alternate source.
	- }
	IF AN_FLAG THEN

	    POINT_AT_ANALYSIS;

	IF FIND_OBJECT (OBJ_TYP,PRIM,PRIMNUM,SECO,SECONUM) THEN

	BEGIN

	    ALT_SOURCE	:= FALSE;

	    CASE QTAB_OFFSET OF

		EDF$K_KEY_NAME,
		EDF$K_FDL_TITLE,
		EDF$K_DATA_FILE_NAME :

		BEGIN

		    LIB$SCOPY_DXDX (DEF_CURRENT^.STRING,SDATA[QTAB_OFFSET]);
		    BDATA[QTAB_OFFSET]	:= TRUE;

		END;

		EDF$K_NUMBER_DUPS,
		EDF$K_DESIRED_FILL,
		EDF$K_CONTROL_SIZE,
		EDF$K_MAX_RECORD_SIZE,
		EDF$K_MEAN_RECORD_SIZE,
		EDF$K_DATA_KEY_COMP,
		EDF$K_DATA_RECORD_COMP,
		EDF$K_CLUSTER_SIZE,
		EDF$K_PROLOGUE_VERSION,
		EDF$K_INDEX_RECORD_COMP :

		BEGIN

		    IDATA[QTAB_OFFSET]	:= DEF_CURRENT^.NUMBER;
		    INPUT_VALUE		:= IDATA[QTAB_OFFSET];

		END;

		EDF$K_KEY_TYPE,
		EDF$K_CARR_CTRL,
		EDF$K_RECORD_FORMAT :
    
		BEGIN

		    IDATA[QTAB_OFFSET]	:= DEF_CURRENT^.QUALIFIER;
		    INPUT_VALUE		:= IDATA[QTAB_OFFSET];

		END;

		EDF$K_KEY_POSITION :

		BEGIN

		    IDATA[QTAB_OFFSET]			:= DEF_CURRENT^.NUMBER;
		    INPUT_VALUE				:= IDATA[QTAB_OFFSET];
		    SEGMENT_POSITION[SEGMENT_NUMBER]	:= INPUT_VALUE;

		END;

		EDF$K_KEY_SIZE :

		BEGIN

		    IDATA[QTAB_OFFSET]			:= DEF_CURRENT^.NUMBER;
		    INPUT_VALUE				:= IDATA[QTAB_OFFSET];
		    SEGMENT_LENGTH[SEGMENT_NUMBER]	:= INPUT_VALUE;

		END;

		EDF$K_GLOBAL_COUNT :

		BEGIN

		    IDATA[QTAB_OFFSET]	:= DEF_CURRENT^.NUMBER;
		    INPUT_VALUE		:= IDATA[QTAB_OFFSET];
		    GLOBAL_SET		:= TRUE;

		END;	{ EDF$K_GLOBAL_COUNT }

		EDF$K_KEY_DUPS,
		EDF$K_KEY_CHANGES,
		EDF$K_KEY_COMP_WANTED,
		EDF$K_REC_COMP_WANTED,
		EDF$K_IDX_COMP_WANTED :

		BEGIN

		    BDATA[QTAB_OFFSET]	:= DEF_CURRENT^.SWITCH;

		    IF DEF_CURRENT^.SWITCH THEN

			INPUT_VALUE	:= EDF$K_YES

		    ELSE

			INPUT_VALUE	:= EDF$K_NO;

		END;	{ EDF$K_KEY_DUPS }

	    OTHERWISE

		{ NULL-STATEMENT } ;

	    END;	{ CASE }

	END	{ IF FOUND }

	ELSE

	BEGIN

	    { +
	    We couldn't find it - ask the user directly.
	    - }
	    ALT_SOURCE	:= TRUE;

	    { +
	    Unless we're in /NOINTERACTIVE, in which case,
	    exit with an error.
	    - }
	    IF (
	    (AUTO_TUNE)
	    AND
	    (QTAB_OFFSET IN [ EDF$K_INITIAL_COUNT, EDF$K_KEY_SIZE,
	     EDF$K_MEAN_RECORD_SIZE ])
	    ) THEN

		LIB$STOP (EDF$_INSFANL,0,0,0);

	    IF (QTAB_OFFSET IN [ EDF$K_DATA_RECORD_COMP, EDF$K_DATA_KEY_COMP,
    				EDF$K_INDEX_RECORD_COMP ]) THEN

	    BEGIN

		ALT_SOURCE		:= FALSE;
		RDATA[QTAB_OFFSET]	:= 0.0;

	    END;

	END;	{ IF NOT FOUND }

	POINT_AT_DEFINITION;

    END;	{ IF FALSE (VISIBLE_QUESTION) OR (NOT OPTIMIZING) }

END;	{ ALT_SOURCE }

{ ++

PRE_PROCESS -- Routine to setup question.

This function does any needed calculations before asking the question.

CALLING SEQUENCE:

status := PRE_PROCESS;

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

TRUE if we should continue, FALSE otherwise

SIGNALS:

none

SIDE EFFECTS:


-- }

FUNCTION PRE_PROCESS : BOOLEAN;

VAR
    RECORD_OVERHEAD	: INTEGER;
    TEMP_KEY_SIZE	: INTEGER;
    RESULT		: BOOLEAN;

BEGIN

    { +
    Assume success.
    - }
    PRE_PROCESS		:= TRUE;

    CASE QTAB_OFFSET OF

	EDF$K_SURFACE_OPTION :

	    IF (
	    (IDATA[EDF$K_ACTIVE_KEY] <> 0)
	    AND
	    ( NOT (QTAB[QTAB_OFFSET].DEFAULT IN [ EDF$K_LINE_SURFACE,
	    		EDF$K_FILL_SURFACE, EDF$K_KEY_SURFACE ]))
	    ) THEN

		QTAB[QTAB_OFFSET].DEFAULT	:= EDF$K_LINE_SURFACE;

	EDF$K_ADDED_COUNT_HIGH,
	EDF$K_INITIAL_COUNT_HIGH :

	    IF IDATA[EDF$K_Y_LOW] = 0 THEN

		DEF	:= 100000

	    ELSE

		DEF	:= 50 * IDATA[EDF$K_Y_LOW];

	EDF$K_KEY_LOW :

	BEGIN

	    { +
	    See how far we can go.
	    - }
	    IF (
	    (IDATA[EDF$K_MAX_RECORD_SIZE] = 0)
	    OR
	    (IDATA[EDF$K_MAX_RECORD_SIZE] > 255)
	    ) THEN
	
		MAX_KEY_SIZE	:= 255
	
	    ELSE
	
		MAX_KEY_SIZE	:= IDATA[EDF$K_MAX_RECORD_SIZE];

	    QTAB[QTAB_OFFSET].HIGH_BOUND	:= MAX_KEY_SIZE;
	    QTAB[QTAB_OFFSET+1].HIGH_BOUND	:= MAX_KEY_SIZE;
	    QTAB[QTAB_OFFSET+1].DEFAULT		:= MAX_KEY_SIZE;

	END;	{ EDF$K_KEY_LOW }

	EDF$K_DATA_KEY_COMP :

	BEGIN

	    PRE_PROCESS		:= FALSE;
	    IDATA[QTAB_OFFSET]	:= 0;

	    IF (
	    (VDATA[EDF$K_PROLOGUE_VERSION])
	    AND
	    (IDATA[EDF$K_PROLOGUE_VERSION] > 2)
	    ) THEN

		RESULT		:= ALT_SOURCE (SEC,ANALYSIS_OF_KEY,
			IDATA[EDF$K_ACTIVE_KEY],DATA_KEY_COMPRESSION$,0,TRUE);

	END;	{ EDF$K_DATA_KEY_COMP }

	EDF$K_DATA_RECORD_COMP :

	BEGIN

	    PRE_PROCESS		:= FALSE;
	    IDATA[QTAB_OFFSET]	:= 0;

	    IF (
	    (VDATA[EDF$K_PROLOGUE_VERSION])
	    AND
	    (IDATA[EDF$K_PROLOGUE_VERSION] > 2)
	    ) THEN

		RESULT		:= ALT_SOURCE (SEC,ANALYSIS_OF_KEY,
		       IDATA[EDF$K_ACTIVE_KEY],DATA_RECORD_COMPRESSION$,0,TRUE);

	END;	{ EDF$K_DATA_RECORD_COMP }

	EDF$K_INDEX_RECORD_COMP :

	BEGIN

	    PRE_PROCESS		:= FALSE;
	    IDATA[QTAB_OFFSET]	:= 0;

	    IF (
	    (VDATA[EDF$K_PROLOGUE_VERSION])
	    AND
	    (IDATA[EDF$K_PROLOGUE_VERSION] > 2)
	    ) THEN

		RESULT		:= ALT_SOURCE (SEC,ANALYSIS_OF_KEY,
			IDATA[EDF$K_ACTIVE_KEY],INDEX_COMPRESSION$,0,TRUE);

	END;	{ EDF$K_INDEX_RECORD_COMP }

	EDF$K_KEY_POSITION :

	BEGIN

	    { +
	    See how far we can go.
	    - }
	    IF BDATA[EDF$K_SEGMENTED] THEN

	    BEGIN

		TEMP_KEY_SIZE	:= 0;

		FOR TEMP_INT2 := 0 TO 7 DO

		BEGIN

		    IF SEGMENT_WANTED[TEMP_INT2] THEN

			TEMP_KEY_SIZE	:= TEMP_KEY_SIZE +
		    				SEGMENT_LENGTH[TEMP_INT2];

		END;

	    END

	    ELSE

		TEMP_KEY_SIZE	:= IDATA[EDF$K_KEY_SIZE];

	    IF IDATA[EDF$K_MAX_RECORD_SIZE] = 0 THEN
	
		MAX_KEY_POSITION	:= CUR_MAX_REC - TEMP_KEY_SIZE
	
	    ELSE
	
		MAX_KEY_POSITION	:= IDATA[EDF$K_MAX_RECORD_SIZE]
						- TEMP_KEY_SIZE;
	
	
	    QTAB[QTAB_OFFSET].HIGH_BOUND	:= MAX_KEY_POSITION;

	    PRE_PROCESS	:= ALT_SOURCE (SEC,KEY,IDATA[EDF$K_ACTIVE_KEY],
				SEG_POSITION,SEGMENT_NUMBER,FALSE);

	END;	{ EDF$K_KEY_POSITION }

	EDF$K_KEY_DIST :

	    IF (
	    (IDATA[EDF$K_ACTIVE_KEY] = 0)
	    OR
	    (NOT VDATA[EDF$K_KEY_DIST])
	    ) THEN

		IF IDATA[EDF$K_ADDED_COUNT] > 0 THEN

		    PRE_PROCESS		:= TRUE

		ELSE

		BEGIN

		    BDATA[QTAB_OFFSET]	:= TRUE;
		    PRE_PROCESS		:= FALSE;

		END

	    ELSE

		PRE_PROCESS		:= FALSE;

	EDF$K_KEY_CHANGES :

	    IF IDATA[EDF$K_ACTIVE_KEY] <> 0 THEN

		PRE_PROCESS	:= ALT_SOURCE (SEC,KEY,IDATA[EDF$K_ACTIVE_KEY],
				CHANGES,0,FALSE)

	    ELSE

	    BEGIN

		PRE_PROCESS		:= FALSE;
		BDATA[QTAB_OFFSET]	:= FALSE;

	    END;

	EDF$K_KEY_DUPS :

	BEGIN

	    IF IDATA[EDF$K_ACTIVE_KEY] = 0 THEN

		QTAB[QTAB_OFFSET].DEFAULT	:= EDF$K_NO

	    ELSE

		QTAB[QTAB_OFFSET].DEFAULT	:= EDF$K_YES;

	    PRE_PROCESS	:= ALT_SOURCE (SEC,KEY,IDATA[EDF$K_ACTIVE_KEY],
		    DUPLICATES,0,FALSE);

	END;	{ EDF$K_KEY_DUPS }

	EDF$K_NUMBER_KEYS :

	    PRE_PROCESS	:= (
				(VISIBLE_QUESTION)
				OR
				(NOT NUMBER_KEYS_SET)
			    );

	EDF$K_CLUSTER_SIZE :

	BEGIN

	    { +
	    This question shouldn't be asked for alternate keys,
	    unless it hasn't been asked yet. Or unless we're optimizing.
	    - }
	    IF OPTIMIZING THEN

		PRE_PROCESS	:= ALT_SOURCE (SEC,FILE$,0,CLUSTER_SIZE,0,TRUE)

	    ELSE

		PRE_PROCESS	:= (
			(IDATA[EDF$K_ACTIVE_KEY] = 0)
			OR
			(NOT VDATA[EDF$K_ADDED_COUNT])
			);

	END;	{ EDF$K_CLUSTER_SIZE }

	EDF$K_KEY_COMP_WANTED :

	BEGIN

	    PRE_PROCESS		:= FALSE;
	    BDATA[QTAB_OFFSET]	:= FALSE;

	    IF (
	    (VDATA[EDF$K_PROLOGUE_VERSION])
	    AND
	    (IDATA[EDF$K_PROLOGUE_VERSION] > 2)
	    AND
	    (IDATA[EDF$K_KEY_TYPE] = FDL$C_STG)
	    ) THEN

		PRE_PROCESS := ALT_SOURCE (SEC,KEY,
			IDATA[EDF$K_ACTIVE_KEY],DATA_KEY_COMPRESSION,0,FALSE);

	END;	{ EDF$K_DATA_RECORD_WANTED }

	EDF$K_REC_COMP_WANTED :

	BEGIN

	    PRE_PROCESS		:= FALSE;
	    BDATA[QTAB_OFFSET]	:= FALSE;

	    IF (
	    (VDATA[EDF$K_PROLOGUE_VERSION])
	    AND
	    (IDATA[EDF$K_PROLOGUE_VERSION] > 2)
	    AND
	    (IDATA[EDF$K_KEY_TYPE] = FDL$C_STG)
	    AND
	    (IDATA[EDF$K_ACTIVE_KEY] = 0)
	    ) THEN

		PRE_PROCESS := ALT_SOURCE (SEC,KEY,
		     IDATA[EDF$K_ACTIVE_KEY],DATA_RECORD_COMPRESSION,0,FALSE);

	END;	{ EDF$K_REC_COMP_WANTED }

	EDF$K_IDX_COMP_WANTED :

	BEGIN

	    PRE_PROCESS		:= FALSE;
	    BDATA[QTAB_OFFSET]	:= FALSE;

	    IF (
	    (VDATA[EDF$K_PROLOGUE_VERSION])
	    AND
	    (IDATA[EDF$K_PROLOGUE_VERSION] > 2)
	    AND
	    (IDATA[EDF$K_KEY_TYPE] = FDL$C_STG)
	    ) THEN

		PRE_PROCESS := ALT_SOURCE (SEC,KEY,
			IDATA[EDF$K_ACTIVE_KEY],INDEX_COMPRESSION,0,FALSE);

	END;	{ EDF$K_IDX_COMP_WANTED }

	EDF$K_NUMBER_DUPS :

	BEGIN

	    PRE_PROCESS			:= FALSE;
	    IDATA[EDF$K_NUMBER_DUPS]	:= 0;

	    RESULT	:= ALT_SOURCE (SEC,ANALYSIS_OF_KEY,
		    IDATA[EDF$K_ACTIVE_KEY],DUPLICATES_PER_SIDR,0,TRUE);

	END;

	EDF$K_SEGMENTED :

	BEGIN

	    FOR TEMP_INT2 := 0 TO 7 DO

	    BEGIN

		SEGMENT_WANTED[TEMP_INT2]	:= FALSE;
		SEGMENT_POSITION[TEMP_INT2]	:= 0;
		SEGMENT_LENGTH[TEMP_INT2]	:= 0;

	    END;

	    BDATA[QTAB_OFFSET]	:= FALSE;

	    IF IDATA[EDF$K_KEY_TYPE] <> FDL$C_STG THEN

		PRE_PROCESS	:= FALSE;

	END;

	EDF$K_GLOBAL_WANTED :

	BEGIN

	    { +
	    Set global_wanted by the presence or absence of a
	    global_buffer_count secondary in the list, when optimizing.
	    THIS DOESN'T USE ALT_SOURCE BECAUSE IT DOESN'T GET THE
	    CONTENTS OF THE SECONDARY IN THE LIST, BUT DECIDES ON THE
	    BASIS OF ITS EXISTENCE.
	    - }
	    IF OPTIMIZING THEN

	    BEGIN

		IF FIND_OBJECT (SEC,FILE$,0,GLOBAL_BUFFER_COUNT,0) THEN

		    INPUT_VALUE		:= EDF$K_YES

		ELSE

		    INPUT_VALUE		:= EDF$K_NO;

		PRE_PROCESS		:= FALSE;

	    END;

	END;	{ EDF$K_GLOBAL_WANTED }

	EDF$K_GLOBAL_COUNT :

	BEGIN

	    PRE_PROCESS	:= FALSE;
	    RESULT	:= ALT_SOURCE (SEC,FILE$,0,GLOBAL_BUFFER_COUNT,0,FALSE);

	END;

	EDF$K_INITIAL_COUNT :

	BEGIN

	    { +
	    This question shouldn't be asked for alternate keys,
	    unless it hasn't been asked yet.
	    - }
	    PRE_PROCESS	:= (
		    (IDATA[EDF$K_ACTIVE_KEY] = 0)
		    OR
		    (NOT VDATA[QTAB_OFFSET])
		    );

	    IF OPTIMIZING THEN

	    BEGIN

		POINT_AT_ANALYSIS;

		IF FIND_OBJECT (SEC,ANALYSIS_OF_KEY,0,DATA_RECORD_COUNT,0) THEN

		    OLD_COUNT	:= DEF_CURRENT^.NUMBER

		ELSE

		    OLD_COUNT	:= 0;

		POINT_AT_DEFINITION;

		QTAB[QTAB_OFFSET].DEFAULT_OK	:= TRUE;
		QTAB[QTAB_OFFSET].DEFAULT	:= OLD_COUNT;

	    END

	    ELSE

		QTAB[QTAB_OFFSET].DEFAULT_OK	:= FALSE;

	END;	{ EDF$K_INITIAL_COUNT }

	EDF$K_ASCENDING_LOAD :

	    { +
	    This question shouldn't be asked if we're doing a conv/fast,
	    or for alternate keys, unless it hasn't been asked yet.
	    - }
	    PRE_PROCESS	:= (
			(IDATA[EDF$K_INITIAL_COUNT] > 0)
		    AND
			(IDATA[EDF$K_LOAD_METHOD] <> EDF$K_FAST_CONVERT)
		    AND
			(
			(IDATA[EDF$K_ACTIVE_KEY] = 0)
			OR
			(NOT VDATA[EDF$K_ASCENDING_LOAD])
			)
		    );

	EDF$K_ADDED_COUNT :

	    { +
	    This question shouldn't be asked for alternate keys,
	    unless it hasn't been asked yet.
	    - }
	    PRE_PROCESS	:= (
		    (IDATA[EDF$K_ACTIVE_KEY] = 0)
		    OR
		    (NOT VDATA[EDF$K_ADDED_COUNT])
		    );

	EDF$K_LOAD_METHOD :

	BEGIN

	    IF IDATA[EDF$K_INITIAL_COUNT] > 0 THEN

		RESULT	:= (
			(IDATA[EDF$K_ACTIVE_KEY] = 0)
			OR
			(NOT VDATA[QTAB_OFFSET])
			)

	    ELSE

	    BEGIN

		{ +
		If we have no initial load, default it to rms puts
		- }
		IDATA[QTAB_OFFSET]	:= EDF$K_RMS_PUTS;
		RESULT			:= FALSE;

	    END;	{ IF FALSE IDATA[EDF$K_INITIAL_COUNT] > 0 }

	    IF NOT RESULT THEN

		INPUT_VALUE		:= IDATA[QTAB_OFFSET];

	    PRE_PROCESS			:= RESULT;

	END;	{ EDF$K_LOAD_METHOD }

	EDF$K_BLOCK_SPAN :

	BEGIN

	    IF IDATA[EDF$K_SCRIPT_OPTION] = EDF$K_SEQ_DESIGN_FDL THEN

		PRE_PROCESS	:= TRUE

	    ELSE

	    BEGIN

		PRE_PROCESS		:= FALSE;
		INPUT_VALUE		:= EDF$K_YES;

	    END;

	END;	{ EDF$K_BLOCK_SPAN }

	EDF$K_DATA_FILE_NAME :

	BEGIN

	    MAX_STRING_ANSWER_LENGTH	:= 126;
	    BDATA[QTAB_OFFSET]		:= FALSE;

	    IF OPTIMIZING THEN

		PRE_PROCESS	:=
		    ALT_SOURCE (SEC,FILE$,0,NAME,0,FALSE);

	END;	{ EDF$K_DATA_FILE_NAME }

	EDF$K_FDL_TITLE :

	BEGIN

	    MAX_STRING_ANSWER_LENGTH	:= 126;
	    BDATA[QTAB_OFFSET]		:= FALSE;

	    IF OPTIMIZING THEN

		PRE_PROCESS	:=
		    ALT_SOURCE (PRI,TITLE,0,DUMMY_SECONDARY$,0,FALSE);

	END;	{ EDF$K_FDL_TITLE }

	EDF$K_KEY_NAME :

	BEGIN

	    MAX_STRING_ANSWER_LENGTH	:= 32;
	    BDATA[QTAB_OFFSET]		:= FALSE;

	    IF OPTIMIZING THEN

		PRE_PROCESS	:=
		    ALT_SOURCE (SEC,KEY,IDATA[EDF$K_ACTIVE_KEY],NAME$,0,FALSE);

	END;

	EDF$K_ANALYSIS,
	EDF$K_OUTPUT :

	BEGIN

	    MAX_STRING_ANSWER_LENGTH	:= 126;
	    BDATA[QTAB_OFFSET]		:= FALSE;

	    IF OPTIMIZING THEN

		PRE_PROCESS		:= FALSE;

	END;

	EDF$K_ASCENDING_ADDED :

	    { +
	    This question shouldn't be asked for alternate keys,
	    unless it hasn't been asked yet.
	    - }
	    PRE_PROCESS	:= (
		    (IDATA[EDF$K_ADDED_COUNT] > 0)
		    AND
			((IDATA[EDF$K_ACTIVE_KEY] = 0)
			 OR
			(NOT VDATA[EDF$K_ASCENDING_ADDED]))
		    );

	EDF$K_BLOCKS_IN_BUCKET :

	BEGIN

	    QTAB[QTAB_OFFSET].DEFAULT	:= BUCKET_DEFAULT;

	    { +
	    Calculate the bucket overhead.
	    THIS QUESTION IS ONLY FOR INDEXED_DESIGN.
	    - }
	    BUCKET_OVERHEAD	:= CALC_BUC_OVERHEAD(0);

	    { +
	    See what the smallest allowable bucketsize is.
	    - }
	    IF IDATA[EDF$K_ACTIVE_KEY] = 0 THEN

		ENTRY_SIZE	:= IDATA[EDF$K_MAX_RECORD_SIZE]

	    ELSE

	    BEGIN

		IF BDATA[EDF$K_SEGMENTED] THEN

		BEGIN

		    ENTRY_SIZE	:= 0;

		    FOR TEMP_INT2 := 0 TO 7 DO

		    BEGIN

			IF SEGMENT_WANTED[TEMP_INT2] THEN

			    ENTRY_SIZE	:= ENTRY_SIZE +
						SEGMENT_LENGTH[TEMP_INT2];

		    END;

		END

		ELSE

		    ENTRY_SIZE	:= IDATA[EDF$K_KEY_SIZE];

	    END;

	    RECORD_OVERHEAD	:= CALC_REC_OVERHEAD(0);

	    MIN_BUCKET	:= (ENTRY_SIZE + BUCKET_OVERHEAD + RECORD_OVERHEAD)
	    			DIV 512;

	    IF (
	    (((ENTRY_SIZE + BUCKET_OVERHEAD + RECORD_OVERHEAD) MOD 512) <> 0)
	    OR
	    (MIN_BUCKET = 0)
	    ) THEN

		MIN_BUCKET	:= MIN_BUCKET + 1;

	    QTAB[QTAB_OFFSET].LOW_BOUND	:= MIN_BUCKET;

	    IF QTAB[QTAB_OFFSET].DEFAULT < QTAB[QTAB_OFFSET].LOW_BOUND THEN

		QTAB[QTAB_OFFSET].DEFAULT	:= QTAB[QTAB_OFFSET].LOW_BOUND;

	END;	{ EDF$K_BLOCKS_IN_BUCKET }

	EDF$K_KEY_SIZE :

	BEGIN

	    { +
	    Check according to key type.
	    - }
	    CASE IDATA[EDF$K_KEY_TYPE] OF

		FDL$C_BN2, FDL$C_IN2 :

		BEGIN

		    MAX_KEY_SIZE	:= 2;
		    MIN_KEY_SIZE	:= 2;

		END;

		FDL$C_BN4, FDL$C_IN4 :

		BEGIN

		    MAX_KEY_SIZE	:= 4;
		    MIN_KEY_SIZE	:= 4;

		END;

		FDL$C_BN8, FDL$C_IN8 :

		BEGIN

		    MAX_KEY_SIZE	:= 8;
		    MIN_KEY_SIZE	:= 8;

		END;

		FDL$C_PAC :

		BEGIN

		    MAX_KEY_SIZE	:= 16;
		    MIN_KEY_SIZE	:= 1;

		END;

		FDL$C_STG :

		BEGIN

		    MAX_KEY_SIZE	:= 255;
		    MIN_KEY_SIZE	:= 1;

		END;

	    OTHERWISE

		{ NULL-STATEMENT } ;

	    END;	{ CASE }

	    { +
	    See how far we can go.
	    - }
	    IF (
	    (IDATA[EDF$K_MAX_RECORD_SIZE] <> 0)
	    AND
	    (IDATA[EDF$K_MAX_RECORD_SIZE] < MAX_KEY_SIZE)
	    ) THEN

		MAX_KEY_SIZE	:= IDATA[EDF$K_MAX_RECORD_SIZE];

	    QTAB[QTAB_OFFSET].LOW_BOUND		:= MIN_KEY_SIZE;
	    QTAB[QTAB_OFFSET].HIGH_BOUND	:= MAX_KEY_SIZE;

	    RESULT	:=
	        ALT_SOURCE (SEC,KEY,IDATA[EDF$K_ACTIVE_KEY],SEG_LENGTH,
				SEGMENT_NUMBER,FALSE);
	    PRE_PROCESS := RESULT;

	    IF (
	    (RESULT)
	    AND
	    (QTAB[QTAB_OFFSET].LOW_BOUND = QTAB[QTAB_OFFSET].HIGH_BOUND)
	    ) THEN

	    BEGIN

		PRE_PROCESS			:= FALSE;
		INPUT_VALUE			:= QTAB[QTAB_OFFSET].LOW_BOUND;
		IDATA[QTAB_OFFSET]		:= INPUT_VALUE;
		SEGMENT_LENGTH[SEGMENT_NUMBER]	:= INPUT_VALUE;

	    END;

	END;	{ EDF$K_KEY_SIZE }

	EDF$K_PROLOGUE_VERSION :

	BEGIN

	    IF (
	    (IDATA[EDF$K_ACTIVE_KEY] = 0)
	    OR
	    (NOT VDATA[EDF$K_PROLOGUE_VERSION])
	    ) THEN

		PRE_PROCESS	:=
		ALT_SOURCE (SEC,KEY,IDATA[EDF$K_ACTIVE_KEY],PROLOGUE,0,FALSE)

	    ELSE

		PRE_PROCESS	:= FALSE;

	END;

	EDF$K_ACTIVE_KEY :

	BEGIN

	    { +
	    Find out the range of existing keys (assume contiguous).
	    - }
	    SCAN_DEFINITION (TRUE);

	    QTAB[QTAB_OFFSET].LOW_BOUND		:= LOW_KEY;
	    QTAB[QTAB_OFFSET].HIGH_BOUND	:= HIGH_KEY;

	    IF (
	    (QTAB[QTAB_OFFSET].LOW_BOUND = QTAB[QTAB_OFFSET].HIGH_BOUND)
	    ) THEN

	    BEGIN

		PRE_PROCESS	:= FALSE;
		INPUT_VALUE	:= QTAB[QTAB_OFFSET].LOW_BOUND;

	    END;

	END;	{ EDF$K_ACTIVE_KEY }

	EDF$K_CARR_CTRL :

	BEGIN

	    { +
	    Don't actually ask the question if the user is optimizing a key,
	    or if it's an alternate key - unless it hasn't been asked yet.
	    - }
	    IF (
	    (IDATA[EDF$K_ACTIVE_KEY] = 0)
	    OR
	    (NOT VDATA[EDF$K_CARR_CTRL])
	    ) THEN

		PRE_PROCESS	:=
			ALT_SOURCE (SEC,RECORD$,0,CARRIAGE_CONTROL,0,FALSE)

	    ELSE

		PRE_PROCESS	:= FALSE;

	END;	{ EDF$K_CARR_CTRL }

	EDF$K_CONTROL_SIZE :

	BEGIN

	    { +
	    The fixed portion of a record can't be larger than the record.
	    - }
	    IF IDATA[EDF$K_MEAN_RECORD_SIZE] < 256 THEN

		CUR_MAX_FIXED	:= IDATA[EDF$K_MEAN_RECORD_SIZE]

	    ELSE

		CUR_MAX_FIXED	:= 255;

	    QTAB[QTAB_OFFSET].HIGH_BOUND	:= CUR_MAX_FIXED;

	    PRE_PROCESS	:= ALT_SOURCE (SEC,RECORD$,0,CONTROL_FIELD_SIZE,0,FALSE);

	END;		{ EDF$K_CONTROL_SIZE }

	EDF$K_KEY_TYPE :

	BEGIN

	    PRE_PROCESS	:=
		ALT_SOURCE (SEC,KEY,IDATA[EDF$K_ACTIVE_KEY],SEG_TYPE,7,FALSE);

	END;		{ EDF$K_KEY_TYPE }

	EDF$K_DESIRED_FILL :

	BEGIN

	    { +
	    Fill doesn't mean anything if we don't have any records.
	    - }
	    IF IDATA[EDF$K_INITIAL_COUNT] > 0 THEN

	    BEGIN

		PRE_PROCESS	:=
			ALT_SOURCE (SEC,KEY,IDATA[EDF$K_ACTIVE_KEY],
			DATA_FILL,0,FALSE)

	    END		{ IF TRUE IDATA[EDF$K_INITIAL_COUNT > 0 }

	    ELSE

	    BEGIN

		IDATA[EDF$K_DESIRED_FILL]	:= 100;
		IDATA[EDF$K_FDL_FILL]		:= 100;
		PRE_PROCESS			:= FALSE;

	    END;

	END;	{ EDF$K_DESIRED_FILL }

	EDF$K_MAX_RECORD_SIZE :

	BEGIN

	    { +
	    Because mean_record_size includes fixed control area, and maximum
	    record size doesn't, it's possible to get a mean that's larger
	    than the max. Don't get confused by it.
	    - }
	    IF CUR_MAX_REC < IDATA[EDF$K_MEAN_RECORD_SIZE] THEN

		LOWMAX	:= CUR_MAX_REC

	    ELSE

		LOWMAX	:= IDATA[EDF$K_MEAN_RECORD_SIZE];

	    QTAB[QTAB_OFFSET].LOW_BOUND		:= LOWMAX;
	    QTAB[QTAB_OFFSET].HIGH_BOUND	:= CUR_MAX_REC;

	    PRE_PROCESS	:= ALT_SOURCE (SEC,RECORD$,0,SIZE,0,FALSE);

	END;	{ EDF$K_MAX_RECORD_SIZE }

	EDF$K_SIZE_LOW :

	    		CUR_MAX_REC := (BKT$C_MAXBKTSIZ * 512) -
	    			(CALC_BUC_OVERHEAD(0) + CALC_REC_OVERHEAD(0));

	EDF$K_MEAN_RECORD_SIZE :

	BEGIN

	    { +
	    Setup the max allowable record size.
	    - }
	    CASE IDATA[EDF$K_SCRIPT_OPTION] OF

		EDF$K_ADD_KEY_FDL,
		EDF$K_DELETE_KEY_FDL,
		EDF$K_IDX_DESIGN_FDL,
		EDF$K_REDESIGN_FDL,
		EDF$K_OPTIMIZE_FDL :
	    		CUR_MAX_REC := (BKT$C_MAXBKTSIZ * 512) -
	    			(CALC_BUC_OVERHEAD(0) + CALC_REC_OVERHEAD(0));
		EDF$K_SEQ_DESIGN_FDL :	CUR_MAX_REC	:= BIGGEST_SEQ_FIXED;
		EDF$K_REL_DESIGN_FDL :	IF VARIABLE_RECORDS THEN

					    CUR_MAX_REC	:= BIGGEST_REL_VAR

					ELSE

					    CUR_MAX_REC	:= BIGGEST_REL_FIXED;

	    OTHERWISE

		{ NULL-STATEMENT } ;

	    END;	{ CASE }

	    IF (
	    (IDATA[EDF$K_SCRIPT_OPTION] = EDF$K_SEQ_DESIGN_FDL)
	    AND
	    (NOT BDATA[EDF$K_BLOCK_SPAN])
	    ) THEN

		IF VARIABLE_RECORDS THEN

		    CUR_MAX_REC	:= 510

		ELSE

		    CUR_MAX_REC	:= 512;

	    QTAB[QTAB_OFFSET].HIGH_BOUND	:= CUR_MAX_REC;

	    IF VARIABLE_RECORDS THEN

		PRE_PROCESS	:=
		    ALT_SOURCE (SEC,ANALYSIS_OF_KEY,0,MEAN_DATA_LENGTH,0,TRUE)

	    ELSE

		PRE_PROCESS	:= ALT_SOURCE (SEC,RECORD$,0,SIZE,0,FALSE);

	END;	{ EDF$K_MEAN_RECORD_SIZE }

	EDF$K_RECORD_FORMAT :

	BEGIN

	    { +
	    This question shouldn't be asked for alternate keys,
	    unless it hasn't been asked before.
	    - }
	    IF (
	    (NOT ISAM_ORG)
	    OR
	    (IDATA[EDF$K_ACTIVE_KEY] = 0)
	    OR
	    (NOT VDATA[EDF$K_RECORD_FORMAT])
	    ) THEN
    
		PRE_PROCESS 	:= ALT_SOURCE (SEC,RECORD$,0,FORMAT,0,FALSE)

	    ELSE
    
		PRE_PROCESS	:= FALSE;

	END;	{ EDF$K_RECORD_FORMAT }

	EDF$K_DESIGN_CYCLE :

	BEGIN

	    IF NOT AUTO_TUNE THEN

	    BEGIN

		{ +
		Display the current value of the file parameters.
		- }
		CLEAR (LOWER_AREA);

		{ +
		Special support for the VT125. Turn on graphics mode, setup text.
		- }
		IF REGIS THEN

		BEGIN

		    WRITE (''(27)'Pp;');

		    IF IDATA[EDF$K_SURFACE_OPTION] <> EDF$K_LINE_SURFACE THEN

			WRITE (
'P[27,285];T(W(I3))'' Key:    Good   '';T(W(I2))''Fair   '';T(W(I1))''Poor'';');

		    WRITELN ('P[27,320];T(W(I3))''');

		END;	{ IF REGIS }

		WRITE (LOW_SHIFT,' ');

		WRITE ('PV-Prolog Version       ',IDATA[EDF$K_PROLOGUE_VERSION]:1,' ');
		WRITE ('KT-Key',
		IDATA[EDF$K_ACTIVE_KEY]:3,
		' Type    ');

		CASE IDATA[EDF$K_KEY_TYPE] OF

		    FDL$C_BN2 :		WRITE ('   Bin2 ');
		    FDL$C_BN4 :		WRITE ('   Bin4 ');
		    FDL$C_BN8 :		WRITE ('   Bin8 ');
		    FDL$C_PAC :		WRITE ('Decimal ');
		    FDL$C_IN2 :		WRITE ('   Int2 ');
		    FDL$C_IN4 :		WRITE ('   Int4 ');
		    FDL$C_IN8 :		WRITE ('   Int8 ');
		    FDL$C_STG :		WRITE (' String ');

		OTHERWISE

		    { NULL-STATEMENT } ;

		END;	{ CASE }

		WRITE ('EM-Emphasis  ');

		IF IDATA[EDF$K_SURFACE_OPTION] <> EDF$K_LINE_SURFACE THEN

		    WRITE ('     ');

		IF IDATA[EDF$K_BUCKET_WEIGHT] = EDF$K_SMALLER_BUFFERS THEN

		    WRITE ('Smaller')

		ELSE

		    WRITE ('Flatter');

		IF IDATA[EDF$K_SURFACE_OPTION] = EDF$K_LINE_SURFACE THEN

		BEGIN

		    BUCKET_DEFAULT	:= NATURAL_DEPTH;
		    WRITE (' (',BUCKET_DEFAULT:2,')');

		END;

		WRITELN;
		WRITE (LOW_SHIFT,' ');

		WRITE ('DK-Dup Key',
		IDATA[EDF$K_ACTIVE_KEY]:3,
		' Values  ');

		IF BDATA[EDF$K_KEY_DUPS] THEN

		    WRITE ('Yes ')

		ELSE

		    WRITE (' No ');

		IF (IDATA[EDF$K_SURFACE_OPTION] = EDF$K_LINE_SURFACE)
		    OR (IDATA[EDF$K_SURFACE_OPTION] <> EDF$K_KEY_SURFACE) THEN

		    WRITE ('KL-Key',IDATA[EDF$K_ACTIVE_KEY]:3,
		    ' Length      ',IDATA[EDF$K_KEY_SIZE]:3,' ');

		WRITE ('KP-Key',IDATA[EDF$K_ACTIVE_KEY]:3,
		' Position  ',IDATA[EDF$K_KEY_POSITION]:5,' ');

		WRITELN;
		WRITE (LOW_SHIFT,' ');

		IF IDATA[EDF$K_PROLOGUE_VERSION] > 2 THEN

		BEGIN

		    WRITE ('RC-Data Record Comp  ',
		    TRUNC(RDATA[EDF$K_DATA_RECORD_COMP]*100.0):3,'% ');
		    WRITE ('KC-Data Key Comp     ',
		    TRUNC(RDATA[EDF$K_DATA_KEY_COMP]*100.0):3,'% ');
		    WRITE ('IC-Index Record Comp ',
		    TRUNC(RDATA[EDF$K_INDEX_RECORD_COMP]*100.0):3,'% ');

		    WRITELN;
		    WRITE (LOW_SHIFT,' ');

		END;	{ IF IDATA[EDF$K_PROLOGUE_VERSION] > 2 }

		IF (IDATA[EDF$K_SURFACE_OPTION] = EDF$K_LINE_SURFACE)
		    OR (IDATA[EDF$K_SURFACE_OPTION] <> EDF$K_FILL_SURFACE) THEN

		    WRITE ('BF-Bucket Fill       ',IDATA[EDF$K_DESIRED_FILL]:3,'% ');

		WRITE ('RF-Record Format ');

		IF VARIABLE_RECORDS THEN

		    WRITE ('Variable ')

		ELSE

		    WRITE ('   Fixed ');

		IF (IDATA[EDF$K_SURFACE_OPTION] = EDF$K_LINE_SURFACE)
		    OR (IDATA[EDF$K_SURFACE_OPTION] <> EDF$K_SIZE_SURFACE) THEN

		BEGIN

		    WRITE ('RS-');

		    IF VARIABLE_RECORDS THEN

			WRITE ('Mean Record Size ')

		    ELSE

			WRITE ('Record Size      ');

		    WRITE (IDATA[EDF$K_MEAN_RECORD_SIZE]:5,' ');

		END;


		WRITELN;
		WRITE (LOW_SHIFT,' ');

		WRITE ('LM-Load Method ');

		CASE IDATA[EDF$K_LOAD_METHOD] OF

		    EDF$K_FAST_CONVERT :		WRITE (' Fast_Conv ');
		    EDF$K_NOFAST_CONVERT :		WRITE ('NoFast_Con ');
		    EDF$K_RMS_PUTS :		WRITE ('  RMS_Puts ');

		OTHERWISE

		    { NULL-STATEMENT } ;

		END;	{ CASE }

		IF (IDATA[EDF$K_SURFACE_OPTION] = EDF$K_LINE_SURFACE)
		    OR (IDATA[EDF$K_SURFACE_OPTION] <> EDF$K_INIT_SURFACE) THEN

		    WRITE ('IL-Initial Load ',IDATA[EDF$K_INITIAL_COUNT]:9,' ');

		IF (IDATA[EDF$K_SURFACE_OPTION] = EDF$K_LINE_SURFACE)
		    OR (IDATA[EDF$K_SURFACE_OPTION] <> EDF$K_ADDED_SURFACE) THEN

		    WRITE ('AR-Added Records',IDATA[EDF$K_ADDED_COUNT]:9,' ');

		{ +
		Done with display, now turn Graphics Mode off.
		- }
		IF REGIS THEN

		    WRITELN (''';'(27)'\',CRLF,CRLF);

		WRITELN;

		{ +
		Compensate for absent compression line.
		- }
		IF IDATA[EDF$K_PROLOGUE_VERSION] < 3 THEN

		    WRITELN;

	    END;	{ IF NOT AUTO_TUNE }

	END;	{ EDF$K_DESIGN_CYCLE }

    OTHERWISE

	{ NULL-STATEMENT } ;

    END;	{ CASE }

END;	{ PRE_PROCESS }

{ ++

VERIFY_PROCESS -- Routine to check answer during questioning.

This function makes sure the user is giving good answers.

CALLING SEQUENCE:

status := VERIFY_PROCESS;

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

TRUE if we should continue, FALSE otherwise

SIGNALS:

none

SIDE EFFECTS:


-- }

FUNCTION VERIFY_PROCESS : BOOLEAN;

BEGIN

    { +
    Assume success.
    - }
    VERIFY_PROCESS	:= TRUE;

    CASE QTAB_OFFSET OF

	EDF$K_KEY_NAME,
	EDF$K_FDL_TITLE,
	EDF$K_ANALYSIS,
	EDF$K_OUTPUT,
	EDF$K_DATA_FILE_NAME :

	BEGIN

	    IF SDATA[QTAB_OFFSET].DSC$W_LENGTH = 0 THEN

	    BEGIN

		BDATA[QTAB_OFFSET]	:= FALSE;

	    END

	    ELSE

	    BEGIN

		IF (
		SDATA[QTAB_OFFSET].DSC$W_LENGTH > MAX_STRING_ANSWER_LENGTH
		) THEN

		BEGIN

		    IF OPTIMIZING THEN

		    BEGIN

			SDATA[QTAB_OFFSET].DSC$W_LENGTH	:=
					MAX_STRING_ANSWER_LENGTH;
			BDATA[QTAB_OFFSET]		:= TRUE;

		    END

		    ELSE

		    BEGIN

			STR$FREE1_DX (SDATA[QTAB_OFFSET]);
			VERIFY_PROCESS	:= FALSE;

		    END;

		END

		ELSE

		    BDATA[QTAB_OFFSET]	:= TRUE;

	    END;	{ IF FALSE SDATA[QTAB_OFFSET].DSC$W_LENGTH = 0 }

	END;

	EDF$K_FILL_LOW,
	EDF$K_FILL_HIGH,
	EDF$K_DESIRED_FILL :

	    IF IDATA[QTAB_OFFSET] < 50 THEN

	    BEGIN

		IDATA[QTAB_OFFSET]	:= 50;

		IF NOT AUTO_TUNE THEN

		BEGIN

		    WRITELN (SHIFT,'Initial Fill of 50% assumed');
		    LIB$WAIT (3.0);

		END;

	    END;

	EDF$K_DESIGN_CYCLE :

	BEGIN

	    { +
	    Make sure he hasn't typed a temporarily disabled option.
	    - }
	    IF IDATA[EDF$K_SURFACE_OPTION] <> EDF$K_LINE_SURFACE THEN

		IF (
		((IDATA[EDF$K_SURFACE_OPTION] = EDF$K_FILL_SURFACE)
		    AND (INPUT_VALUE = EDF$K_BF))
		OR
		((IDATA[EDF$K_SURFACE_OPTION] = EDF$K_INIT_SURFACE)
		    AND (INPUT_VALUE = EDF$K_IL))
		OR
		((IDATA[EDF$K_SURFACE_OPTION] = EDF$K_ADDED_SURFACE)
		    AND (INPUT_VALUE = EDF$K_AR))
		OR
		((IDATA[EDF$K_SURFACE_OPTION] = EDF$K_SIZE_SURFACE)
		    AND (INPUT_VALUE = EDF$K_RS))
		OR
		((IDATA[EDF$K_SURFACE_OPTION] = EDF$K_KEY_SURFACE)
		    AND (INPUT_VALUE = EDF$K_KL))
		OR
		(
		( NOT (IDATA[EDF$K_KEY_TYPE] IN [ FDL$C_PAC, FDL$C_STG ]) )
		    AND (INPUT_VALUE = EDF$K_KL)
		)
		) THEN

		    VERIFY_PROCESS	:= FALSE;

	    { +
	    Make sure that he modifies only reasonable things.
	    The following options make sense only for the primary key.
	    - }
	    IF (
	    (IDATA[EDF$K_ACTIVE_KEY] <> 0) AND (INPUT_VALUE IN
	    [ EDF$K_RF, EDF$K_RS, EDF$K_IL, EDF$K_AR, EDF$K_PV, EDF$K_LM ])
	    ) THEN

		VERIFY_PROCESS		:= FALSE;

	    IF (
	    (IDATA[EDF$K_PROLOGUE_VERSION] < 3) AND (INPUT_VALUE IN
	    [ EDF$K_KC, EDF$K_RC, EDF$K_IC ])
	    ) THEN

		VERIFY_PROCESS		:= FALSE;

	    IF (IDATA[EDF$K_INITIAL_COUNT] < 1) AND
	    (INPUT_VALUE = EDF$K_LM) THEN

		VERIFY_PROCESS		:= FALSE;

	    IF (
	    (IDATA[EDF$K_INITIAL_COUNT] < 1)
	    AND
	    (INPUT_VALUE = EDF$K_BF)
	    AND
	    (NOT AUTO_TUNE)
	    ) THEN

	    BEGIN

		WRITELN (SHIFT,ANSI_REVERSE,
		' Fill Factor used is 100% when Initial Load is zero. ',
		ANSI_RESET);
		LIB$WAIT (3.0);

	    END;

	END;	{ EDF$K_DESIGN_CYCLE }

	EDF$K_SURFACE_OPTION :

	BEGIN

	    { +
	    Disallow queer options.
	    - }
	    IF (
		(IDATA[EDF$K_ACTIVE_KEY] <> 0)
	    AND
		(
		(INPUT_VALUE = EDF$K_SIZE_SURFACE)
		OR
		(INPUT_VALUE = EDF$K_INIT_SURFACE)
		OR
		(INPUT_VALUE = EDF$K_ADDED_SURFACE)
		)
	    ) THEN
    
		VERIFY_PROCESS	:= FALSE;

	END;	{ EDF$K_SURFACE_OPTION }

	EDF$K_RECORD_FORMAT :

	BEGIN

	    IDATA[EDF$K_RECORD_FORMAT]	:= INPUT_VALUE;

	    { +
	    Indexed files can have only fixed or variable record format.
	    Relative files can't be stream or undefined.
	    - }
	    IF (
		(
		(ISAM_ORG)
		AND
		(NOT (IDATA[EDF$K_RECORD_FORMAT] IN [ FDL$C_VAR, FDL$C_FIX ]))
		)
	    OR
		(
		(IDATA[EDF$K_SCRIPT_OPTION] = EDF$K_REL_DESIGN_FDL)
		AND
		(IDATA[EDF$K_RECORD_FORMAT] IN [ FDL$C_STM, FDL$C_STMCR, FDL$C_STMLF, FDL$C_UDF ])
		)
	    ) THEN

		VERIFY_PROCESS	:= FALSE;

	END;	{ EDF$K_RECORD_FORMAT }

	EDF$K_TEST_PRIMARY :

	BEGIN

	    TEST.OBJECT_TYPE		:= PRI;
	    TEST.PRIMARY		:= INPUT_VALUE::PRIMARY_TYPE;
	    TEST.PRINUM			:= INPUT_NUMBER;
	    DEFAULT_PRINUM		:= INPUT_NUMBER;
	    ACTIVE_PRIMARY		:= TEST.PRIMARY;
	    DEFAULT_PRIMARY		:= ACTIVE_PRIMARY;
	    QTAB[QTAB_OFFSET].DEFAULT	:= INPUT_VALUE;
    
	    IF (
	    (TEST.PRIMARY = AREA)
	    OR
	    (TEST.PRIMARY = KEY)
	    ) THEN
    
	    BEGIN
    
		IF TEST.PRINUM > 254 THEN
    
		    VERIFY_PROCESS	:= FALSE;
    
		SCAN_DEFINITION (TRUE);

		IF (
		(FOUND_AREA)
		AND
		(TEST.PRIMARY = AREA)
		AND
		((TEST.PRINUM - HIGH_AREA) > 1)
		) THEN
    
		    VERIFY_PROCESS	:= FALSE;
    
		IF (
		(FOUND_KEY)
		AND
		(TEST.PRIMARY = KEY)
		AND
		((TEST.PRINUM - HIGH_KEY) > 1)
		) THEN
    
		    VERIFY_PROCESS	:= FALSE;
    
		IF (
		(NOT FOUND_AREA)
		AND
		(TEST.PRIMARY = AREA)
		AND
		(TEST.PRINUM > 0)
		) THEN
    
		    VERIFY_PROCESS	:= FALSE;
    
		IF (
		(NOT FOUND_KEY)
		AND
		(TEST.PRIMARY = KEY)
		AND
		(TEST.PRINUM > 0)
		) THEN
    
		    VERIFY_PROCESS	:= FALSE;
    
	    END	{ IF TRUE (TEST.PRIMARY = AREA) OR (TEST.PRIMARY = KEY) }
    
	    ELSE
    
		TEST.PRINUM		:= 0;
    
	    { +
	    If we're asking for only ones that exist, make sure this one does.
	    - }
	    IF NOT FULL_CHOICE THEN
    
	    BEGIN
    
		DEF_CURRENT	:= DEF_HEAD;
    
		REPEAT
    
		    IF NOT CURRENT_EQ_TEST(TEST,FALSE) THEN
    
			INCR_CURRENT;
    
		UNTIL (CURRENT_EQ_TEST(TEST,FALSE) OR (DEF_CURRENT^.FORE = NIL));
    
		IF DEF_CURRENT <> NIL THEN
    
		BEGIN
    
		    IF NOT CURRENT_EQ_TEST(TEST,FALSE) THEN
    
			VERIFY_PROCESS	:= FALSE;
    
		END
    
		ELSE
    
		    VERIFY_PROCESS	:= FALSE;
    
	    END;

	END;	{ EDF$K_TEST_PRIMARY }

    OTHERWISE

	{ NULL-STATEMENT } ;

    END;	{ CASE }

END;	{ VERIFY_PROCESS }

{ ++

POST_PROCESS -- Routine to finish up a question.

This function does any calculations needed once a question is anwerred.

CALLING SEQUENCE:

status := POST_PROCESS;

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

TRUE if we should continue, FALSE otherwise

SIGNALS:

none

SIDE EFFECTS:


-- }

FUNCTION POST_PROCESS : BOOLEAN;

VAR
    I	: INTEGER;

BEGIN

    { +
    Assume success.
    - }
    POST_PROCESS	:= TRUE;

    CASE QTAB_OFFSET OF

	{ +
	These are boolean_answer questions.
	- }
	EDF$K_CONFIRM,
	EDF$K_KEY_DUPS,
	EDF$K_SEGMENTED,
	EDF$K_BLOCK_SPAN,
	EDF$K_GLOBAL_WANTED,
	EDF$K_ASCENDING_LOAD,
	EDF$K_ASCENDING_ADDED,
	EDF$K_KEY_COMP_WANTED,
	EDF$K_REC_COMP_WANTED,
	EDF$K_IDX_COMP_WANTED :

	BEGIN

	    QUERY_FLAG		:= (INPUT_VALUE = EDF$K_YES);
	    BDATA[QTAB_OFFSET]	:= QUERY_FLAG;

	END;	{ BOOLEAN_ANSWER }

	{ +
	Generalized answer storage for keyword answers.
	- }
	EDF$K_LOAD_METHOD,
	EDF$K_DESIGN_CYCLE,
	EDF$K_SET_FUNCTION,
	EDF$K_GRANULARITY,
	EDF$K_RESPONSES,
	EDF$K_KEY_TYPE,
	EDF$K_CARR_CTRL :

	    IDATA[QTAB_OFFSET]		:= INPUT_VALUE;

	{ +
	Make the new default whatever the user answers.
	- }
	EDF$K_NUMBER_KEYS,
	EDF$K_SURFACE_OPTION,
	EDF$K_BUCKET_WEIGHT :

	BEGIN

	    IDATA[QTAB_OFFSET]		:= INPUT_VALUE;
	    QTAB[QTAB_OFFSET].DEFAULT	:= INPUT_VALUE;

	END;

	EDF$K_ANALYSIS :

	BEGIN

	    ANALYSIS_FILENAME_DESC	:= NULL_STRING;
	    LIB$SCOPY_DXDX (SDATA[EDF$K_ANALYSIS],ANALYSIS_FILENAME_DESC);
	    ANALYSIS_SPECIFIED		:= TRUE;

	END;

	EDF$K_SET_OUTPUT :

	BEGIN

	    OUTPUT_FILENAME_DESC	:= NULL_STRING;
	    LIB$SCOPY_DXDX (SDATA[EDF$K_OUTPUT],OUTPUT_FILENAME_DESC);

	END;

	EDF$K_PROMPTING :

	BEGIN

	    IDATA[QTAB_OFFSET]		:= INPUT_VALUE;
	    FULL_PROMPT			:= (INPUT_VALUE = EDF$K_FULL);

	END;

	EDF$K_SCRIPT_OPTION :

	BEGIN

	    IDATA[QTAB_OFFSET]		:= INPUT_VALUE;

	    ISAM_ORG	:= (INPUT_VALUE IN [ EDF$K_IDX_DESIGN_FDL,
			    EDF$K_ADD_KEY_FDL, EDF$K_DELETE_KEY_FDL,
			    EDF$K_REDESIGN_FDL, EDF$K_OPTIMIZE_FDL ]);

	END;	{ SCRIPT_OPTION }

	{ +
	These are the real_answer questions.
	- }
	EDF$K_DATA_KEY_COMP,
	EDF$K_DATA_RECORD_COMP,
	EDF$K_INDEX_RECORD_COMP :

	BEGIN

	    { +
	    Make sure we aren't fooled.
	    - }
	    IF ABS (IDATA[QTAB_OFFSET]) > 99 THEN

		IDATA[QTAB_OFFSET]	:= 0;

	    RDATA[QTAB_OFFSET]	:= IDATA[QTAB_OFFSET];
	    RDATA[QTAB_OFFSET]	:= RDATA[QTAB_OFFSET] / 100.0;

	END;	{ EDF$K_DATA_KEY_COMP }

	EDF$K_RETURN :

	BEGIN

	    IF NOT AUTO_TUNE THEN

	    BEGIN

		{ +
		Now that he's answered, clear his screen.
		- }
		IF REGIS THEN

		    WRITELN (''(27)'Pp;S(E);'(27)'\');

		LIB$ERASE_PAGE (LINE_ONE,COL_ONE);

	    END;	{ IF NOT AUTO_TUNE }

	END;	{ EDF$K_RETURN }

	EDF$K_GLOBAL_COUNT :

	BEGIN

	    { +
	    GLOBAL_SET is true if GLOBAL_COUNT is set from the
	    definition linked list.
	    - }
	    IF NOT GLOBAL_SET THEN

	    BEGIN

		{ +
		See how many global buffers would map the entire key 0
		index, plus the roots of all the alternate
		keys, plus 5 data buckets. (why 5? it sounds good...)
		If a level has more than 512 buckets, only 512 are counted.
		(let's not get ridiculous here)
		- }
		PRIMARY_INDEX_BUCKETS	:= 0;

		FOR I := 1 TO 31 DO

		BEGIN

		    IF INIT_PRIMARY_BUCKETS [I] > 512 THEN

			INIT_PRIMARY_BUCKETS [I]	:= 512;

		    IF ADDED_PRIMARY_BUCKETS [I] > 512 THEN

			ADDED_PRIMARY_BUCKETS [I]	:= 512;

		    PRIMARY_INDEX_BUCKETS	:= PRIMARY_INDEX_BUCKETS
						    + INIT_PRIMARY_BUCKETS [I]
						    + ADDED_PRIMARY_BUCKETS [I];

		END;

		{ +
		4 is added instead of 5 so we don't have to use
		(idata[edf$K_number_keys]-1) for the number of alternate keys.
		- }
		IDATA[EDF$K_GLOBAL_COUNT]	:= PRIMARY_INDEX_BUCKETS +
						IDATA[EDF$K_NUMBER_KEYS] + 4;

	    END;

	    { +
	    Up to an RMS maximum.
	    - }
	    IF IDATA[EDF$K_GLOBAL_COUNT] > EDF$C_MAX_GBL_BUFS THEN

		IDATA[EDF$K_GLOBAL_COUNT]	:= EDF$C_MAX_GBL_BUFS;

	END;	{ EDF$K_GLOBAL_COUNT }

	EDF$K_NUMBER_RECORDS :

	    IDATA[EDF$K_INITIAL_COUNT]	:= IDATA[QTAB_OFFSET];

	EDF$K_KEY_POSITION :

	    SEGMENT_POSITION[SEGMENT_NUMBER] := IDATA[QTAB_OFFSET];

	EDF$K_KEY_SIZE :

	BEGIN

	    SEGMENT_WANTED[SEGMENT_NUMBER] := (IDATA[EDF$K_KEY_SIZE] > 0);
	    SEGMENT_LENGTH[SEGMENT_NUMBER] := IDATA[QTAB_OFFSET];

	END;

	EDF$K_CONTROL_SIZE :

	    CUR_MAX_REC		:= CUR_MAX_REC - IDATA[QTAB_OFFSET];

	EDF$K_NUMBER_DUPS :

	    IF IDATA[QTAB_OFFSET] < 0 THEN

		IDATA[QTAB_OFFSET]	:= 0;

	EDF$K_PROLOGUE_VERSION :

	BEGIN

	    IF IDATA[EDF$K_PROLOGUE_VERSION] < 3 THEN

	    BEGIN

		RDATA[EDF$K_DATA_RECORD_COMP]	:= 0.0;
		RDATA[EDF$K_DATA_KEY_COMP]	:= 0.0;
		RDATA[EDF$K_INDEX_RECORD_COMP]	:= 0.0;

	    END;

	END;	{ EDF$K_PROLOGUE_VERSION }

	EDF$K_KEY_LOW,
	EDF$K_ADDED_COUNT_LOW,
	EDF$K_INITIAL_COUNT_LOW,
	EDF$K_SIZE_LOW,
	EDF$K_FILL_LOW :

	BEGIN

	    IDATA[EDF$K_Y_LOW]			:= IDATA[QTAB_OFFSET];
	    QTAB[QTAB_OFFSET+1].LOW_BOUND	:= IDATA[QTAB_OFFSET];

	END;

	EDF$K_KEY_HIGH,
	EDF$K_FILL_HIGH,
	EDF$K_SIZE_HIGH,
	EDF$K_ADDED_COUNT_HIGH,
	EDF$K_INITIAL_COUNT_HIGH :

	BEGIN

	    IDATA[EDF$K_Y_HIGH]		:= IDATA[QTAB_OFFSET];

	    CASE QTAB_OFFSET OF

		EDF$K_FILL_HIGH :	SPREAD_LOW_HIGH (50,100);

		EDF$K_SIZE_HIGH :	SPREAD_LOW_HIGH (1,CUR_MAX_REC);

		EDF$K_KEY_HIGH,
		EDF$K_ADDED_COUNT_HIGH,
		EDF$K_INITIAL_COUNT_HIGH :	SPREAD_LOW_HIGH (1,MAXINT-1);

	    OTHERWISE

		{ NULL-STATEMENT } ;

	    END;	{ CASE }

	END;

	EDF$K_DESIRED_FILL :

	    IDATA[EDF$K_FDL_FILL]	:= IDATA[EDF$K_DESIRED_FILL];

	EDF$K_CURRENT_FUNCTION :

	BEGIN

	    IDATA[QTAB_OFFSET]		:= INPUT_VALUE;

	    { +
	    Reset the script pointer (only auto-invoke on 1st entry).
	    - }
	    IDATA[EDF$K_SCRIPT_OPTION]	:= EDF$K_ZERO_SCRIPT;

	    { +
	    Reset the ^Z flag.
	    - }
	    MAIN_LEVEL			:= FALSE;

	END;	{ EDF$K_CURRENT_FUNCTION }

	EDF$K_RECORD_FORMAT :

	BEGIN

	    { +
	    The IDATA[EDF$K_RECORD_FORMAT] variable was set in VERIFY_PROCESS.
	    - }

	    { +
	    Set a convenience boolean.
	    - }
	    VARIABLE_RECORDS	:= (
				    (IDATA[EDF$K_RECORD_FORMAT] <> FDL$C_FIX)
				    AND
				    (IDATA[EDF$K_RECORD_FORMAT] <> FDL$C_UDF)
				    );

	END;	{ EDF$K_RECORD_FORMAT }

	EDF$K_TEST_PRIMARY :

	BEGIN

	    IF ACTIVE_PRIMARY = AREA THEN

		ACTIVE_AREA		:= INPUT_NUMBER

	    ELSE IF ACTIVE_PRIMARY = KEY THEN

		IDATA[EDF$K_ACTIVE_KEY]	:= INPUT_NUMBER;

	END;	{ EDF$K_TEST_PRIMARY }

    OTHERWISE

	{ NULL-STATEMENT } ;

    END;	{ CASE }

END;	{ POST_PROCESS }

{ ++

QUERY -- Routine to control the asking of questions.

This function processes the QTAB table, and interacts with the user.

CALLING SEQUENCE:

status := QUERY (QTAB-OFFSET-VALUE);

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

none

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

SYS$OUTPUT:

ROUTINES CALLED:

WRITE_QUESTION
WRITE_HELP
PRE_PROCESS
VERIFY_PROCESS
POST_PROCESS

ROUTINE VALUE:

TRUE if answer was yes, FALSE otherwise

SIGNALS:

none

SIDE EFFECTS:


-- }

[GLOBAL] FUNCTION QUERY (OFFSET : INTEGER) : BOOLEAN;

    PROCEDURE THE_QUESTION;

    BEGIN

	{ +
	Special for top level query.
	- }
	IF QTAB_OFFSET = EDF$K_CURRENT_FUNCTION THEN

	BEGIN

	    MAIN_LEVEL		:= TRUE;
	    MAIN_CTRLZ		:= FALSE;
	    CONTROL_ZEE_TYPED	:= FALSE;

	END;	{ IF TRUE QTAB_OFFSET = EDF$K_CURRENT_FUNCTION }

	{ +
	Setup to catch bad user input.
	- }
	SYS$INPUT_ERROR	:= FALSE;
	ESTABLISH (SYS$INPUT_COND_HANDLER);

	IF NOT AUTO_TUNE THEN

	BEGIN

	    IF TEMP_FULL_PROMPT THEN

		WRITE_HELP;

	    WRITE_QUESTION;

	END;

	CASE QTAB[QTAB_OFFSET].ANSWER_CLASS OF

	    STRING_ANSWER :

	    BEGIN

		SDATA[QTAB_OFFSET]	:= NULL_STRING;

		IF (
		(
		(TAKE_DEFAULTS)
		AND
		(IDATA[EDF$K_RESPONSES] = EDF$K_AUTO)
		)
		OR
		(AUTO_TUNE)
		) THEN

		BEGIN

		    IF NOT AUTO_TUNE THEN

			LIB$WAIT (0.7);

		END

		ELSE

		BEGIN

		    IF EOF (INPUT) THEN

		    BEGIN

			RESET (INPUT);
			LIB$SIGNAL (EDF$_CTRLZ,0,0,0);

		    END;

		    READLN (TEMP_STRING255);
		    STR$TRIM (SDATA[QTAB_OFFSET],TEMP_STRING255);
		    LIB$SCOPY_DXDX (SDATA[QTAB_OFFSET],INPUT_DESC);
		    PARAM_BLOCK.TPA$L_TOKENPTR	:= INPUT_DESC.DSC$A_POINTER::UNSIGNED;
		    PARAM_BLOCK.TPA$L_TOKENCNT	:= INPUT_DESC.DSC$W_LENGTH;

		END;

		IF NOT AUTO_TUNE THEN

		    WRITELN (CRLF);

		{ +
		If we're journaling our input, save a copy of it to the
		journal file.
		- }
		IF JOURNAL_ENABLED THEN

		    IF SDATA[QTAB_OFFSET].DSC$W_LENGTH > 0 THEN

			WRITELN (
			    JOURNAL_FILE,
			    SDATA[QTAB_OFFSET].DSC$A_POINTER^:
			    	SDATA[QTAB_OFFSET].DSC$W_LENGTH
			    )

		    ELSE

			WRITELN (JOURNAL_FILE);

	    END;	{ STRING_ANSWER }

	    REAL_ANSWER,	{ Actually, real_answer = integer percentage }
	    INTEGER_ANSWER :

	    BEGIN

		NUMBER_INPUT (
			IDATA[QTAB_OFFSET],
			QTAB[QTAB_OFFSET].DEFAULT_OK,
			QTAB[QTAB_OFFSET].DEFAULT);

		{ +
		Max record size of 0 is one case where it's OK to
		specify an answer that's out of the low-high range.
		- }
		IF (
		(
		    (QTAB_OFFSET = EDF$K_MAX_RECORD_SIZE)
		    AND
		    (IDATA[EDF$K_SCRIPT_OPTION] <> EDF$K_REL_DESIGN_FDL)
		    AND
		    (IDATA[QTAB_OFFSET] = 0)
		)
		OR
		(
		    (BDATA[EDF$K_SEGMENTED])
		    AND
		    (SEGMENT_NUMBER <> 0)
		    AND
		    (QTAB_OFFSET = EDF$K_KEY_SIZE)
		    AND
		    (IDATA[QTAB_OFFSET] = 0)
		)
		) THEN

		BEGIN

		    { NULL-STATEMENT } ;

		END

		ELSE

		BEGIN

		    IF (
		    (IDATA[QTAB_OFFSET] < QTAB[QTAB_OFFSET].LOW_BOUND)
		    OR
		    (IDATA[QTAB_OFFSET] > QTAB[QTAB_OFFSET].HIGH_BOUND)
		    ) THEN
		
			LIB$SIGNAL (EDF$_BADVALUE,0,0,0);

		END;

	    END;	{ REAL_ANSWER,INTEGER_ANSWER }

	    BOOLEAN_ANSWER,
	    KEYWORD_ANSWER :

	    BEGIN

		PARSE_INPUT (
			QTAB[QTAB_OFFSET].KEY_TABLE,
			QTAB[QTAB_OFFSET].STATE_TABLE,
			QTAB[QTAB_OFFSET].DEFAULT_OK,
			QTAB[QTAB_OFFSET].DEFAULT);

	    END;	{ BOOLEAN_ANSWER, KEYWORD_ANSWER }

	    NO_ANSWER :

	    BEGIN

		{ +
		When the user just types <CR>, then accept anything.
		- }
		IF AUTO_TUNE THEN

		BEGIN

		    { NULL-STATEMENT } ;

		END

		ELSE

		BEGIN

		    IF EOF (INPUT) THEN

		    BEGIN

			RESET (INPUT);
			LIB$SIGNAL (EDF$_CTRLZ,0,0,0);

		    END;

		    READLN;

		    IF JOURNAL_ENABLED THEN

			WRITELN (JOURNAL_FILE);

		END;

	    END;	{ NO_ANSWER }

	    OBJECT_ANSWER :

		{ T.B.S. } ;

	OTHERWISE

	    { NULL-STATEMENT } ;

	END;	{ CASE }

	{ +
	Do some initial checking of the answer.
	- }
	IF NOT VERIFY_PROCESS THEN

	    LIB$SIGNAL (EDF$_BADVALUE,0,0,0);

	{ +
	Make sure this is true for only one cycle.
	- }
	TEMP_FULL_PROMPT	:= FALSE;

    END;	{ THE_QUESTION }

BEGIN

    { +
    Make which question we're on widely known.
    - }
    QTAB_OFFSET		:= OFFSET;

    IF PRE_PROCESS THEN

    BEGIN

	{ +
	Keep at it until the user gets it right.
	- }
	REPEAT

	    THE_QUESTION;

	UNTIL NOT SYS$INPUT_ERROR;

	STR$FREE1_DX (INPUT_DESC);

    END;	{ IF TRUE PRE_PROCESS }

    { +
    If this question has a valid answer, flag it so.
    - }
    IF POST_PROCESS THEN

	VDATA[QTAB_OFFSET]	:= TRUE;

    { +
    Set the output function value.
    - }
    QUERY	:= QUERY_FLAG;

END;	{ QUERY }

{ ++

ASK_KEY_DUPS -- Query the user.

This routine asks the user if he wants duplicates on his key.
If he does, then it asks him how many.

CALLING SEQUENCE:

ASK_KEY_DUPS;

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

SYS$INPUT_ERROR
SYS$INPUT:

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

BDATA[EDF$K_NUMBER_DUPS]
BDATA[EDF$K_KEY_DUPS]

ROUTINES CALLED:

none

ROUTINE VALUE:

none

SIGNALS:

none

SIDE EFFECTS:

none

-- }

PROCEDURE ASK_KEY_DUPS;

BEGIN

    IF QUERY (EDF$K_KEY_DUPS) THEN

	QUERY (EDF$K_NUMBER_DUPS)

    ELSE

	IDATA[EDF$K_NUMBER_DUPS]	:= 0;

END;	{ ASK_KEY_DUPS }

{ ++

ASK_GLOBAL_WANTED -- Query the user.

This routine asks the user if he wants Global Buffers, and if he does, then
it asks him how many.

CALLING SEQUENCE:

ASK_GLOBAL_WANTED;

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

SYS$INPUT_ERROR

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

IDATA[EDF$K_GLOBAL_COUNT]
BDATA[EDF$K_GLOBAL_WANTED]

ROUTINES CALLED:

QUERY (EDF$K_GLOBAL_WANTED)
QUERY (EDF$K_GLOBAL_COUNT)

ROUTINE VALUE:

none

SIGNALS:

none

SIDE EFFECTS:

none

-- }

PROCEDURE ASK_GLOBAL_WANTED;

BEGIN

    { +
    If we want Global Buffers, see how many.
    - }
    IF QUERY (EDF$K_GLOBAL_WANTED) THEN

	QUERY (EDF$K_GLOBAL_COUNT)

    ELSE

	IDATA[EDF$K_GLOBAL_COUNT]	:= 0;

END;	{ ASK_GLOBAL_WANTED }

{ ++

ASK_KEY_COMP -- Query the user.

This routine asks the user if he wants key compression and if he does, then
it finds out what the compression was.

CALLING SEQUENCE:

ASK_KEY_COMP;

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

SYS$INPUT_ERROR

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

RDATA[EDF$K_DATA_KEY_COMP]
BDATA[EDF$K_KEY_COMP_WANTED]

ROUTINES CALLED:

QUERY (EDF$K_KEY_COMP_WANTED)
QUERY (EDF$K_DATA_KEY_COMP)

ROUTINE VALUE:

none

SIGNALS:

none

SIDE EFFECTS:

none

-- }

PROCEDURE ASK_KEY_COMP;

BEGIN

    { +
    If we want compression. See what it is.
    - }
    IF QUERY (EDF$K_KEY_COMP_WANTED) THEN

	QUERY (EDF$K_DATA_KEY_COMP)

    ELSE

	RDATA[EDF$K_DATA_KEY_COMP]	:= 0.0;

END;	{ ASK_KEY_COMP }

{ ++

ASK_REC_COMP -- Query the user.

This routine asks the user if he wants record compression, and if he does, then
it finds out how much there is.

CALLING SEQUENCE:

ASK_REC_COMP;

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

SYS$INPUT_ERROR

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

RDATA[EDF$K_DATA_RECORD_COMP]
BDATA[EDF$K_REC_COMP_WANTED]

ROUTINES CALLED:

QUERY (EDF$K_REC_COMP_WANTED)
QUERY (EDF$K_DATA_RECORD_COMP)

ROUTINE VALUE:

none

SIGNALS:

none

SIDE EFFECTS:

none

-- }

PROCEDURE ASK_REC_COMP;

BEGIN

    { +
    If we want compression. See what it is.
    - }
    IF QUERY (EDF$K_REC_COMP_WANTED) THEN

	QUERY (EDF$K_DATA_RECORD_COMP)

    ELSE

	RDATA[EDF$K_DATA_RECORD_COMP]	:= 0.0;

END;	{ ASK_REC_COMP }

{ ++

ASK_IDX_COMP -- Query the user.

This routine asks the user if he wants index compression and if he does, then
it finds out how much there is.

CALLING SEQUENCE:

ASK_IDX_COMP;

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

SYS$INPUT_ERROR

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

RDATA[EDF$K_INDEX_RECORD_COMP]
BDATA[EDF$K_IDX_COMP_WANTED]

ROUTINES CALLED:

QUERY (EDF$K_IDX_COMP_WANTED)
QUERY (EDF$K_INDEX_RECORD_COMP)

ROUTINE VALUE:

none

SIGNALS:

none

SIDE EFFECTS:

none

-- }

PROCEDURE ASK_IDX_COMP;

BEGIN

    { +
    If we want compression. See what it is.
    - }
    IF QUERY (EDF$K_IDX_COMP_WANTED) THEN

	QUERY (EDF$K_INDEX_RECORD_COMP)

    ELSE

	RDATA[EDF$K_INDEX_RECORD_COMP]	:= 0.0;

END;	{ ASK_IDX_COMP }

{ ++

ASK_MEAN_RECORD_SIZE -- Query the user.

This routine asks about the user's record size. (plus max_rec, and control_size)

CALLING SEQUENCE:

ASK_MEAN_RECORD_SIZE;

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

SYS$INPUT_ERROR

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

IDATA[EDF$K_MEAN_RECORD_SIZE]
SYS$INPUT_ERROR

ROUTINES CALLED:

ESTABLISH

ROUTINE VALUE:

none

SIGNALS:

none

SIDE EFFECTS:

none

-- }

PROCEDURE ASK_MEAN_RECORD_SIZE;

BEGIN

    { +
    This question shouldn't be asked for alternate keys. Unless redesigning,
    and we don't already have a value for it.
    - }
    IF (
    (NOT ISAM_ORG)
    OR
    (ISAM_ORG AND (IDATA[EDF$K_ACTIVE_KEY] = 0))
    OR
    (NOT VDATA[EDF$K_MEAN_RECORD_SIZE])
    ) THEN

    BEGIN

	{ +
	Ask the question we're here for.
	- }
	QUERY (EDF$K_MEAN_RECORD_SIZE);

	{ +
	Get (or set) the other record size parameter.

	THE CONTROL_SIZE QUESTION MUST COME BEFORE THE MAX_RECORD_SIZE
	QUESTION!

	- }
	IF IDATA[EDF$K_RECORD_FORMAT] = FDL$C_VFC THEN

	    QUERY (EDF$K_CONTROL_SIZE);

	IF VARIABLE_RECORDS THEN
    
	    QUERY (EDF$K_MAX_RECORD_SIZE)
    
	ELSE
    
	    IDATA[EDF$K_MAX_RECORD_SIZE] := IDATA[EDF$K_MEAN_RECORD_SIZE];

    END;

END;	{ ASK_MEAN_RECORD_SIZE }

{ ++

ASK_KEY_SIZE -- Query the user.

This routine asks about the user's key size.

CALLING SEQUENCE:

ASK_KEY_SIZE;

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

SYS$INPUT_ERROR

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

IDATA[EDF$K_KEY_SIZE]
SEGMENT_LENGTH[0..7]
SYS$INPUT_ERROR

ROUTINES CALLED:

ESTABLISH

ROUTINE VALUE:

none

SIGNALS:

none

SIDE EFFECTS:

none

-- }

PROCEDURE ASK_KEY_SIZE;

VAR
    I	: INTEGER;

BEGIN

    IF BDATA[EDF$K_SEGMENTED] THEN

    BEGIN

	SEGMENT_NUMBER	:= 0;

	REPEAT

	    QUERY (EDF$K_KEY_SIZE);

	    SEGMENT_NUMBER	:= SEGMENT_NUMBER + 1;

	UNTIL (IDATA[EDF$K_KEY_SIZE] = 0) OR (SEGMENT_NUMBER > 7);

	IF IDATA[EDF$K_KEY_SIZE] = 0 THEN

	BEGIN

	    FOR I := SEGMENT_NUMBER TO 7 DO

		SEGMENT_WANTED[I]	:= FALSE;

	END;

	IDATA[EDF$K_KEY_SIZE]	:= SEGMENT_LENGTH[0];

    END

    ELSE

	QUERY (EDF$K_KEY_SIZE);

END;	{ ASK_KEY_SIZE }

{ ++

ASK_KEY_POSITION -- Query the user.

This routine asks about the user's key position.

CALLING SEQUENCE:

ASK_KEY_POSITION;

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

SYS$INPUT_ERROR

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

IDATA[EDF$K_KEY_POSITION]
SEGMENT_POSITION[0..7]
SYS$INPUT_ERROR

ROUTINES CALLED:

ESTABLISH

ROUTINE VALUE:

none

SIGNALS:

none

SIDE EFFECTS:

none

-- }

PROCEDURE ASK_KEY_POSITION;

BEGIN

    IF BDATA[EDF$K_SEGMENTED] THEN

    BEGIN

	FOR SEGMENT_NUMBER := 0 TO 7 DO

	BEGIN

	    IF SEGMENT_WANTED[SEGMENT_NUMBER] THEN

		QUERY (EDF$K_KEY_POSITION);

	END;

	IDATA[EDF$K_KEY_POSITION]	:= SEGMENT_POSITION[0];

    END

    ELSE

	QUERY (EDF$K_KEY_POSITION);

END;	{ ASK_KEY_POSITION }

{ ++

ASK_TEST_SECONDARY -- Get the user's choice of secondary.

This routine queries the user.

CALLING SEQUENCE:

ASK_TEST_SECONDARY

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

CRLF
TAB
SYS$INPUT_ERROR
SYS$INPUT:

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

SYS$OUTPUT:

ROUTINES CALLED:

ESTABLISH

ROUTINE VALUE:

none

SIGNALS:

none

SIDE EFFECTS:

none

-- }

PROCEDURE ASK_TEST_SECONDARY;

    PROCEDURE THE_QUESTION;

    BEGIN

	{ +
	Set up to catch bad user input.
	- }
	EDF$GL_SECNUM	:= 0;
	SYS$INPUT_ERROR	:= FALSE;
	ESTABLISH (SYS$INPUT_COND_HANDLER);

	CASE ACTIVE_PRIMARY OF

	    IDENT :

		INPUT_VALUE	:= 0;	{ DUMMY_SECONDARY$ }

	    TITLE :

		INPUT_VALUE	:= 0;	{ DUMMY_SECONDARY$ }

	    ACCESS :

	    BEGIN

		    IF FULL_CHOICE THEN

			BEGIN

			    CLEAR (IF_FULL_PROMPT);

			    IF FULL_PROMPT OR TEMP_FULL_PROMPT THEN

			    BEGIN

				WRITELN (SHIFT,'		',ANSI_REVERSE,
				' Legal ACCESS',SEC_ATTR,
				ANSI_RESET,CRLF,
				CRLF_SHIFT,
				'BLOCK_IO		yes/no',
				CRLF_SHIFT,
				'DELETE			yes/no',
				CRLF_SHIFT,
				'GET			yes/no',
				CRLF_SHIFT,
				'PUT			yes/no',
				CRLF_SHIFT,
				'RECORD_IO		yes/no',
				CRLF_SHIFT,
				'TRUNCATE		yes/no',
				CRLF_SHIFT,
				'UPDATE			yes/no',
				CRLF);

			    END	{ IF FULL_PROMPT OR TEMP_FULL_PROMPT TRUE }

			    ELSE

				WRITELN (SHIFT,QUES_HINT);

			END

		ELSE

			BEGIN

			    CLEAR (IF_FULL_PROMPT);

			    IF FULL_PROMPT OR TEMP_FULL_PROMPT THEN

			    BEGIN

				WRITELN (SHIFT,'		',ANSI_REVERSE,
				' Current ACCESS',SEC_ATTR,
				ANSI_RESET,CRLF);

				{ +
				Setup to display definition on the terminal.
				- }
				OPEN	(FDL_DEST,SYS$OUTPUT_NAME,NEW,
					RECORD_LENGTH := 252);
				REWRITE	(FDL_DEST);

				SHOW_PRIMARY_SECTION (TEST);

				CLOSE (FDL_DEST);

			    END	{ IF FULL_PROMPT OR TEMP_FULL_PROMPT TRUE }

			    ELSE

				WRITELN (SHIFT,QUES_HINT);

			END;	{ EXTANT_ONLY }

		WRITE (SHIFT,'Enter ACCESS Attribute		(Keyword)',
		ANSI_REVERSE,'[-]',ANSI_RESET,'	: ');
		PARSE_INPUT (
			    IADDRESS (EDF$AB_ACCESS_TABLE_KEY),
			    IADDRESS (EDF$AB_ACCESS_TABLE_STA),
			    FALSE,
			    0
			    );

	    END;	{ ACCESS }

(* Here starts the comment to exclude ACLS *)
(*	    ACL :

	    BEGIN

		    IF FULL_CHOICE THEN

			BEGIN

			    CLEAR (IF_FULL_PROMPT);

			    IF FULL_PROMPT OR TEMP_FULL_PROMPT THEN

			    BEGIN

				WRITELN (SHIFT,'		',ANSI_REVERSE,
				' Legal ACL',SEC_ATTR,
				ANSI_RESET,CRLF,
				CRLF_SHIFT,
				'ENTRY			string',
				CRLF);
*)
(*			    END*){ IF FULL_PROMPT OR TEMP_FULL_PROMPT TRUE }
(*
			    ELSE

				WRITELN (SHIFT,QUES_HINT);

			END

		ELSE

			BEGIN
	
			    CLEAR (IF_FULL_PROMPT);

			    IF FULL_PROMPT OR TEMP_FULL_PROMPT THEN

			    BEGIN

				WRITELN (SHIFT,'		',ANSI_REVERSE,
				' Current ACL',SEC_ATTR,
				ANSI_RESET,CRLF);
*)
				{ +
				Setup to display definition on the terminal.
				- }
(*				OPEN	(FDL_DEST,SYS$OUTPUT_NAME,NEW,
					RECORD_LENGTH := 252);
				REWRITE	(FDL_DEST);

				SHOW_PRIMARY_SECTION (TEST);

				CLOSE (FDL_DEST);
*)	
(*			    END*){ IF FULL_PROMPT OR TEMP_FULL_PROMPT TRUE }
(*
			    ELSE

				WRITELN (SHIFT,QUES_HINT);

			END;*)	{ EXTANT_ONLY }
	
{ +
    THIS CAN BE OPTIMIZED IN THE FUTURE - GIVEN THAT THE ACL PRIMARY HAS ONLY
    ONE KIND OF SECONDARY:   "ENTRY"  
- }
(*
		WRITE (SHIFT,'Enter ACL Attribute		(Keyword)',
		ANSI_REVERSE,'[-]',ANSI_RESET,'	: ');
		PARSE_INPUT (
			    IADDRESS (EDF$AB_ACL_TABLE_KEY),
			    IADDRESS (EDF$AB_ACL_TABLE_STA),
			    FALSE,
			    0
			    );

	    END;*)	{ ACL }


	    ANALYSIS_OF_AREA :

		INPUT_VALUE	:= 0;	{ DUMMY_SECONDARY$ }

	    ANALYSIS_OF_KEY :

		INPUT_VALUE	:= 0;	{ DUMMY_SECONDARY$ }

	    AREA :

	    BEGIN

		    IF FULL_CHOICE THEN

			BEGIN

			    CLEAR (IF_FULL_PROMPT);

			    IF FULL_PROMPT OR TEMP_FULL_PROMPT THEN

			    BEGIN

				WRITELN (SHIFT,'		',ANSI_REVERSE,
				' Legal AREA ',ACTIVE_AREA:NUM_LEN(ACTIVE_AREA),
				SEC_ATTR,
				ANSI_RESET,CRLF,
				CRLF_SHIFT,
				'ALLOCATION		number',
				CRLF_SHIFT,
				'BEST_TRY_CONTIGUOUS	yes/no',
				CRLF_SHIFT,
				'BUCKET_SIZE		number',
				CRLF_SHIFT,
				'CONTIGUOUS		yes/no',
				CRLF_SHIFT,
				'EXACT_POSITIONING	yes/no',
				CRLF_SHIFT,
				'EXTENSION		number',
				CRLF_SHIFT,
				'POSITION    qualifier	number',
				CRLF_SHIFT,
				'VOLUME			number',
				CRLF);

			    END	{ IF FULL_PROMPT OR TEMP_FULL_PROMPT TRUE }

			    ELSE

				WRITELN (SHIFT,QUES_HINT);

			END

		ELSE

			BEGIN
	
			    CLEAR (IF_FULL_PROMPT);

			    IF FULL_PROMPT OR TEMP_FULL_PROMPT THEN

			    BEGIN

				WRITELN (SHIFT,'		',ANSI_REVERSE,
				' Current AREA ',
				ACTIVE_AREA:NUM_LEN(ACTIVE_AREA),
				SEC_ATTR,
				ANSI_RESET,CRLF);

				{ +
				Setup to display definition on the terminal.
				- }
				OPEN	(FDL_DEST,SYS$OUTPUT_NAME,NEW,
					RECORD_LENGTH := 252);
				REWRITE	(FDL_DEST);

				SHOW_PRIMARY_SECTION (TEST);

				CLOSE (FDL_DEST);
	
			    END	{ IF FULL_PROMPT OR TEMP_FULL_PROMPT TRUE }

			    ELSE

				WRITELN (SHIFT,QUES_HINT);

			END;	{ EXTANT_ONLY }
	
		WRITE (SHIFT,'Enter AREA ',ACTIVE_AREA:NUM_LEN(ACTIVE_AREA),
		' Attribute		(Keyword)',
		ANSI_REVERSE,'[-]',ANSI_RESET,'	: ');
		PARSE_INPUT (
			    IADDRESS (EDF$AB_AREA_TABLE_KEY),
			    IADDRESS (EDF$AB_AREA_TABLE_STA),
			    FALSE,
			    0
			    );

	    END;	{ AREA }

	    CONNECT :

	    BEGIN

		    IF FULL_CHOICE THEN

			BEGIN

			    CLEAR (IF_FULL_PROMPT);

			    IF FULL_PROMPT OR TEMP_FULL_PROMPT THEN

			    BEGIN

WRITELN (SHIFT,'		',ANSI_REVERSE,
' Legal CONNECT',SEC_ATTR,
ANSI_RESET,CRLF,
CRLF_SHIFT,
'ASYNCHRONOUS		yes/no	NOLOCK			yes/no',
CRLF_SHIFT,
'BLOCK_IO		yes/no	NONEXISTENT_RECORD	yes/no',
CRLF_SHIFT,
'BUCKET_CODE		number	READ_AHEAD		yes/no',
CRLF_SHIFT,
'CONTEXT			number	READ_REGARDLESS		yes/no',
CRLF_SHIFT,
'END_OF_FILE		yes/no	TIMEOUT_ENABLE		yes/no',
CRLF_SHIFT,
'FAST_DELETE		yes/no	TIMEOUT_PERIOD		number',
CRLF_SHIFT,
'FILL_BUCKETS		yes/no	TRUNCATE_ON_PUT		yes/no',
CRLF_SHIFT,
'KEY_GREATER_EQUAL	yes/no	TT_CANCEL_CONTROL_O	yes/no',
CRLF_SHIFT,
'KEY_GREATER_THAN	yes/no	TT_PROMPT		yes/no',
CRLF_SHIFT,
'KEY_LIMIT		yes/no	TT_PURGE_TYPE_AHEAD	yes/no',
CRLF_SHIFT,
'KEY_OF_REFERENCE	number	TT_READ_NOECHO		yes/no',
CRLF_SHIFT,
'LOCATE_MODE		yes/no	TT_READ_NOFILTER	yes/no',
CRLF_SHIFT,
'LOCK_ON_READ		yes/no	TT_UPCASE_INPUT		yes/no',
CRLF_SHIFT,
'LOCK_ON_WRITE		yes/no	UPDATE_IF		yes/no',
CRLF_SHIFT,
'MANUAL_UNLOCKING	yes/no	WAIT_FOR_RECORD		yes/no',
CRLF_SHIFT,
'MULTIBLOCK_COUNT	number	WRITE_BEHIND		yes/no',
CRLF_SHIFT,
'MULTIBUFFER_COUNT	number',
CRLF
);

			    END	{ IF FULL_PROMPT OR TEMP_FULL_PROMPT TRUE }

			    ELSE

				WRITELN (SHIFT,QUES_HINT);

			END

		ELSE

			BEGIN

			    CLEAR (IF_FULL_PROMPT);

			    IF FULL_PROMPT OR TEMP_FULL_PROMPT THEN

			    BEGIN

				WRITELN (SHIFT,'		',ANSI_REVERSE,
				' Current CONNECT',SEC_ATTR,
				ANSI_RESET,CRLF);

				{ +
				Setup to display definition on the terminal.
				- }
				OPEN	(FDL_DEST,SYS$OUTPUT_NAME,NEW,
					RECORD_LENGTH := 252);
				REWRITE	(FDL_DEST);

				SHOW_PRIMARY_SECTION (TEST);

				CLOSE (FDL_DEST);

			    END	{ IF FULL_PROMPT OR TEMP_FULL_PROMPT TRUE }

			    ELSE

				WRITELN (SHIFT,QUES_HINT);

			END;	{ EXTANT_ONLY }

		WRITE (SHIFT,'Enter CONNECT Attribute		(Keyword)',
		ANSI_REVERSE,'[-]',ANSI_RESET,'	: ');
		PARSE_INPUT (
			    IADDRESS (EDF$AB_CONNECT_TABLE_KEY),
			    IADDRESS (EDF$AB_CONNECT_TABLE_STA),
			    FALSE,
			    0
			    );

	    END;	{ CONNECT }

	    DATE :

	    BEGIN

		    IF FULL_CHOICE THEN

			BEGIN

			    CLEAR (IF_FULL_PROMPT);
	    
			    IF FULL_PROMPT OR TEMP_FULL_PROMPT THEN
	    
			    BEGIN
	    
				WRITELN (SHIFT,'		',ANSI_REVERSE,
				' Legal DATE',SEC_ATTR,
				ANSI_RESET,CRLF,
				CRLF_SHIFT,
				'BACKUP			string',
				CRLF_SHIFT,
				'CREATION		string',
				CRLF_SHIFT,
				'EXPIRATION		string',
				CRLF_SHIFT,
				'REVISION		string',
				CRLF);
	    
			    END	{ IF FULL_PROMPT OR TEMP_FULL_PROMPT TRUE }
	    
			    ELSE
	    
				WRITELN (SHIFT,QUES_HINT);

			END

		ELSE

			BEGIN
	
			    CLEAR (IF_FULL_PROMPT);

			    IF FULL_PROMPT OR TEMP_FULL_PROMPT THEN

			    BEGIN

				WRITELN (SHIFT,'		',ANSI_REVERSE,
				' Current DATE',SEC_ATTR,
				ANSI_RESET,CRLF);

				{ +
				Setup to display definition on the terminal.
				- }
				OPEN	(FDL_DEST,SYS$OUTPUT_NAME,NEW,
					RECORD_LENGTH := 252);
				REWRITE	(FDL_DEST);

				SHOW_PRIMARY_SECTION (TEST);

				CLOSE (FDL_DEST);
	
			    END	{ IF FULL_PROMPT OR TEMP_FULL_PROMPT TRUE }

			    ELSE

				WRITELN (SHIFT,QUES_HINT);

			END;	{ EXTANT_ONLY }

		WRITE (SHIFT,'Enter DATE Attribute		(Keyword)',
		ANSI_REVERSE,'[-]',ANSI_RESET,'	: ');
		PARSE_INPUT (
			    IADDRESS (EDF$AB_DATE_TABLE_KEY),
			    IADDRESS (EDF$AB_DATE_TABLE_STA),
			    FALSE,
			    0
			    );

	    END;	{ DATE }

	    FILE$ :

	    BEGIN

		    IF FULL_CHOICE THEN

			BEGIN

			    CLEAR (IF_FULL_PROMPT);

			    IF FULL_PROMPT OR TEMP_FULL_PROMPT THEN
	    
			    BEGIN
	    
WRITELN (SHIFT,'		',ANSI_REVERSE,
' Legal FILE',SEC_ATTR,
ANSI_RESET,CRLF,CRLF_SHIFT,
'ALLOCATION		number	MT_PROTECTION		char/num',
CRLF_SHIFT,
'BEST_TRY_CONTIGUOUS	yes/no	NAME			string',
CRLF_SHIFT,
'BUCKET_SIZE		number	NOBACKUP		yes/no',
CRLF_SHIFT,
'CLUSTER_SIZE		number	NON_FILE_STRUCTURED	yes/no',
CRLF_SHIFT,
'CONTEXT			number	ORGANIZATION		keyword',
CRLF_SHIFT,
'CONTIGUOUS		yes/no	OUTPUT_FILE_PARSE	yes/no',
CRLF_SHIFT,
'CREATE_IF		yes/no	OWNER			uic',
CRLF_SHIFT,
'DEFAULT_NAME		string	PRINT_ON_CLOSE		yes/no',
CRLF_SHIFT,
'DEFERRED_WRITE		yes/no	PROTECTION		yes/no',
CRLF_SHIFT,
'DELETE_ON_CLOSE		yes/no	READ_CHECK		yes/no',
CRLF_SHIFT,
'DIRECTORY_ENTRY		yes/no	REVISION		number',
CRLF_SHIFT,
'EXTENSION		number	SEQUENTIAL_ONLY		yes/no',
CRLF_SHIFT,
'GLOBAL_BUFFER_COUNT	number	SUBMIT_ON_CLOSE		yes/no',
CRLF_SHIFT,
'MAX_RECORD_NUMBER	number	SUPERSEDE		yes/no',
CRLF_SHIFT,
'MAXIMIZE_VERSION	yes/no	TEMPORARY		yes/no',
CRLF_SHIFT,
'MT_BLOCK_SIZE		number	TRUNCATE_ON_CLOSE	yes/no',
CRLF_SHIFT,
'MT_CLOSE_REWIND		yes/no	USER_FILE_OPEN		yes/no',
CRLF_SHIFT,
'MT_CURRENT_POSITION	yes/no	WINDOW_SIZE		number',
CRLF_SHIFT,
'MT_NOT_EOF		yes/no	WRITE_CHECK		yes/no',
CRLF
);
	    
			    END	{ IF FULL_PROMPT OR TEMP_FULL_PROMPT TRUE }
	    
			    ELSE
	    
				WRITELN (SHIFT,QUES_HINT);

			END

		    ELSE

			BEGIN
	
			    CLEAR (IF_FULL_PROMPT);

			    IF FULL_PROMPT OR TEMP_FULL_PROMPT THEN

			    BEGIN

				WRITELN (SHIFT,'		',ANSI_REVERSE,
				' Current FILE',SEC_ATTR,
				ANSI_RESET,CRLF);

				{ +
				Setup to display definition on the terminal.
				- }
				OPEN	(FDL_DEST,SYS$OUTPUT_NAME,NEW,
					RECORD_LENGTH := 252);
				REWRITE	(FDL_DEST);

				SHOW_PRIMARY_SECTION (TEST);

				CLOSE (FDL_DEST);
	
			    END	{ IF FULL_PROMPT OR TEMP_FULL_PROMPT TRUE }

			    ELSE

				WRITELN (SHIFT,QUES_HINT);

			END;	{ EXTANT_ONLY }

		WRITE (SHIFT,'Enter FILE Attribute		(Keyword)',
		ANSI_REVERSE,'[-]',ANSI_RESET,'	: ');
		PARSE_INPUT (
			    IADDRESS (EDF$AB_FILE_TABLE_KEY),
			    IADDRESS (EDF$AB_FILE_TABLE_STA),
			    FALSE,
			    0
			    );

	    END;	{ FILE }

	    JOURNAL :

	    BEGIN

		    IF FULL_CHOICE THEN

			BEGIN

			    CLEAR (IF_FULL_PROMPT);

			    IF FULL_PROMPT OR TEMP_FULL_PROMPT THEN
	    
			    BEGIN
	    
				WRITELN (SHIFT,'		',ANSI_REVERSE,
				' Legal JOURNAL',SEC_ATTR,
				ANSI_RESET,CRLF,
				CRLF_SHIFT,
				'AFTER_IMAGE		yes/no',
				CRLF_SHIFT,
				'AFTER_NAME		string',
				CRLF_SHIFT,
				'AUDIT_TRAIL		yes/no',
				CRLF_SHIFT,
				'AUDIT_NAME		string',
				CRLF_SHIFT,
				'BEFORE_IMAGE		yes/no',
				CRLF_SHIFT,
				'BEFORE_NAME		string',
				CRLF_SHIFT,
				'RECOVERY_UNIT		keyword',
				CRLF);
	    
			    END	{ IF FULL_PROMPT OR TEMP_FULL_PROMPT TRUE }
	    
			    ELSE
	    
			    BEGIN

				WRITELN (SHIFT,QUES_HINT);

			    END;

			END

		    ELSE

			BEGIN
	
			    CLEAR (IF_FULL_PROMPT);

			    IF FULL_PROMPT OR TEMP_FULL_PROMPT THEN

			    BEGIN

				WRITELN (SHIFT,'		',ANSI_REVERSE,
				' Current JOURNAL',SEC_ATTR,
				ANSI_RESET,CRLF);

				{ +
				Setup to display definition on the terminal.
				- }
				OPEN	(FDL_DEST,SYS$OUTPUT_NAME,NEW,
					RECORD_LENGTH := 252);
				REWRITE	(FDL_DEST);

				SHOW_PRIMARY_SECTION (TEST);

				CLOSE (FDL_DEST);
	
			    END	{ IF FULL_PROMPT OR TEMP_FULL_PROMPT TRUE }

			    ELSE

				WRITELN (SHIFT,QUES_HINT);

			END;	{ EXTANT_ONLY }

		WRITE (SHIFT,'Enter JOURNAL Attribute		(Keyword)',
		ANSI_REVERSE,'[-]',ANSI_RESET,'	: ');
		PARSE_INPUT (
			    IADDRESS (EDF$AB_JOURNAL_TABLE_KEY),
			    IADDRESS (EDF$AB_JOURNAL_TABLE_STA),
			    FALSE,
			    0
			    );

	    END;	{ JOURNAL }

	    KEY :

	    BEGIN

		    IF FULL_CHOICE THEN

			BEGIN

			    CLEAR (IF_FULL_PROMPT);

			    IF FULL_PROMPT OR TEMP_FULL_PROMPT THEN
	    
			    BEGIN
	    
WRITELN (SHIFT,'		',ANSI_REVERSE,
' Legal KEY',
IDATA[EDF$K_ACTIVE_KEY]:3,
SEC_ATTR,
ANSI_RESET,CRLF,
CRLF_SHIFT,
'CHANGES			yes/no	LEVEL1_INDEX_AREA	number',
CRLF_SHIFT,
'DATA_AREA		number	NAME			string',
CRLF_SHIFT,
'DATA_FILL		number	NULL_KEY		yes/no',
CRLF_SHIFT,
'DATA_KEY_COMPRESSION	yes/no	NULL_VALUE		char/num',
CRLF_SHIFT,
'DATA_RECORD_COMPRESSION	yes/no	POSITION		number',
CRLF_SHIFT,
'DUPLICATES		yes/no	PROLOG			number',
CRLF_SHIFT,
'INDEX_AREA		number	TYPE			keyword',
CRLF_SHIFT,
'INDEX_COMPRESSION	yes/no	SEGn_LENGTH		number',
CRLF_SHIFT,
'INDEX_FILL		number	SEGn_POSITION		number',
CRLF_SHIFT,
'LENGTH			number'{	SEGn_TYPE	keyword},
CRLF);
	    
			    END	{ IF FULL_PROMPT OR TEMP_FULL_PROMPT TRUE }
	    
			    ELSE
	    
				WRITELN (SHIFT,QUES_HINT);

			END

		    ELSE

			BEGIN
	
			    CLEAR (IF_FULL_PROMPT);

			    IF FULL_PROMPT OR TEMP_FULL_PROMPT THEN

			    BEGIN

				WRITELN (SHIFT,'		',ANSI_REVERSE,
				' Current KEY',
				IDATA[EDF$K_ACTIVE_KEY]:3,
				SEC_ATTR,
				ANSI_RESET,CRLF);

				{ +
				Setup to display definition on the terminal.
				- }
				OPEN	(FDL_DEST,SYS$OUTPUT_NAME,NEW,
					RECORD_LENGTH := 252);
				REWRITE	(FDL_DEST);

				SHOW_PRIMARY_SECTION (TEST);

				CLOSE (FDL_DEST);
	
			    END	{ IF FULL_PROMPT OR TEMP_FULL_PROMPT TRUE }

			    ELSE

				WRITELN (SHIFT,QUES_HINT);

			END;	{ EXTANT_ONLY }

		WRITE (SHIFT,'Enter KEY',
		IDATA[EDF$K_ACTIVE_KEY]:3,
		' Attribute		(Keyword)',
		ANSI_REVERSE,'[-]',ANSI_RESET,'	: ');
		PARSE_INPUT (
			    IADDRESS (EDF$AB_KEY_TABLE_KEY),
			    IADDRESS (EDF$AB_KEY_TABLE_STA),
			    FALSE,
			    0
			    );

	    END;	{ KEY }

	    RECORD$ :

	    BEGIN

		    IF FULL_CHOICE THEN

			BEGIN

			    CLEAR (IF_FULL_PROMPT);

			    IF FULL_PROMPT OR TEMP_FULL_PROMPT THEN
	    
			    BEGIN
	    
				WRITELN (SHIFT,'		',ANSI_REVERSE,
				' Legal RECORD',SEC_ATTR,
				ANSI_RESET,CRLF,
				CRLF_SHIFT,
				'BLOCK_SPAN		yes/no',
				CRLF_SHIFT,
				'CARRIAGE_CONTROL	keyword',
				CRLF_SHIFT,
				'CONTROL_FIELD_SIZE	number',
				CRLF_SHIFT,
				'FORMAT			keyword',
				CRLF_SHIFT,
				'SIZE			number',
				CRLF);
	    
			    END	{ IF FULL_PROMPT OR TEMP_FULL_PROMPT TRUE }
	    
			    ELSE
	    
			    BEGIN

				WRITELN (SHIFT,QUES_HINT);

			    END;

			END

		    ELSE

			BEGIN
	
			    CLEAR (IF_FULL_PROMPT);

			    IF FULL_PROMPT OR TEMP_FULL_PROMPT THEN

			    BEGIN

				WRITELN (SHIFT,'		',ANSI_REVERSE,
				' Current RECORD',SEC_ATTR,
				ANSI_RESET,CRLF);

				{ +
				Setup to display definition on the terminal.
				- }
				OPEN	(FDL_DEST,SYS$OUTPUT_NAME,NEW,
					RECORD_LENGTH := 252);
				REWRITE	(FDL_DEST);

				SHOW_PRIMARY_SECTION (TEST);

				CLOSE (FDL_DEST);
	
			    END	{ IF FULL_PROMPT OR TEMP_FULL_PROMPT TRUE }

			    ELSE

				WRITELN (SHIFT,QUES_HINT);

			END;	{ EXTANT_ONLY }

		WRITE (SHIFT,'Enter RECORD Attribute		(Keyword)',
		ANSI_REVERSE,'[-]',ANSI_RESET,'	: ');
		PARSE_INPUT (
			    IADDRESS (EDF$AB_RECORD_TABLE_KEY),
			    IADDRESS (EDF$AB_RECORD_TABLE_STA),
			    FALSE,
			    0
			    );

	    END;	{ RECORD }

	    SHARING :

	    BEGIN

		    IF FULL_CHOICE THEN

			BEGIN

			    CLEAR (IF_FULL_PROMPT);

			    IF FULL_PROMPT OR TEMP_FULL_PROMPT THEN

			    BEGIN

				WRITELN (SHIFT,'		',ANSI_REVERSE,
				' Legal SHARING',SEC_ATTR,
				ANSI_RESET,CRLF,
				CRLF_SHIFT,
				'DELETE			yes/no',
				CRLF_SHIFT,
				'GET			yes/no',
				CRLF_SHIFT,
				'MULTISTREAM		yes/no',
				CRLF_SHIFT,
				'PROHIBIT		yes/no',
				CRLF_SHIFT,
				'PUT			yes/no',
				CRLF_SHIFT,
				'UPDATE			yes/no',
				CRLF_SHIFT,
				'USER_INTERLOCK		yes/no',
				CRLF);

			    END	{ IF FULL_PROMPT OR TEMP_FULL_PROMPT TRUE }

			    ELSE

				WRITELN (SHIFT,QUES_HINT);

			END

		ELSE

			BEGIN

			    CLEAR (IF_FULL_PROMPT);

			    IF FULL_PROMPT OR TEMP_FULL_PROMPT THEN

			    BEGIN

				WRITELN (SHIFT,'		',ANSI_REVERSE,
				' Current SHARING',SEC_ATTR,
				ANSI_RESET,CRLF);

				{ +
				Setup to display definition on the terminal.
				- }
				OPEN	(FDL_DEST,SYS$OUTPUT_NAME,NEW,
					RECORD_LENGTH := 252);
				REWRITE	(FDL_DEST);

				SHOW_PRIMARY_SECTION (TEST);

				CLOSE (FDL_DEST);

			    END	{ IF FULL_PROMPT OR TEMP_FULL_PROMPT TRUE }

			    ELSE

				WRITELN (SHIFT,QUES_HINT);

			END;	{ EXTANT_ONLY }

		WRITE (SHIFT,'Enter SHARING Attribute		(Keyword)',
		ANSI_REVERSE,'[-]',ANSI_RESET,'	: ');
		PARSE_INPUT (
			    IADDRESS (EDF$AB_SHARING_TABLE_KEY),
			    IADDRESS (EDF$AB_SHARING_TABLE_STA),
			    FALSE,
			    0
			    );

	    END;	{ SHARING }

	    SYSTEM :

	    BEGIN

		    IF FULL_CHOICE THEN

			BEGIN

			    CLEAR (IF_FULL_PROMPT);

			    IF FULL_PROMPT OR TEMP_FULL_PROMPT THEN
	    
			    BEGIN
	    
				WRITELN (SHIFT,'		',ANSI_REVERSE,
				' Legal SYSTEM',SEC_ATTR,
				ANSI_RESET,CRLF,
				CRLF_SHIFT,
				'DEVICE			string',
				CRLF_SHIFT,
				'SOURCE			keyword',
				CRLF_SHIFT,
				'TARGET			keyword',
				CRLF);
	    
			    END	{ IF FULL_PROMPT OR TEMP_FULL_PROMPT TRUE }
	    
			    ELSE
	    
				WRITELN (SHIFT,QUES_HINT);

			END

		    ELSE

			BEGIN
	
			    CLEAR (IF_FULL_PROMPT);

			    IF FULL_PROMPT OR TEMP_FULL_PROMPT THEN

			    BEGIN

				WRITELN (SHIFT,'		',ANSI_REVERSE,
				' Current SYSTEM',SEC_ATTR,
				ANSI_RESET,CRLF);

				{ +
				Setup to display definition on the terminal.
				- }
				OPEN	(FDL_DEST,SYS$OUTPUT_NAME,NEW,
					RECORD_LENGTH := 252);
				REWRITE	(FDL_DEST);

				SHOW_PRIMARY_SECTION (TEST);

				CLOSE (FDL_DEST);
	
			    END	{ IF FULL_PROMPT OR TEMP_FULL_PROMPT TRUE }

			    ELSE

				WRITELN (SHIFT,QUES_HINT);

			END;	{ EXTANT_ONLY }

		WRITE (SHIFT,'Enter SYSTEM Attribute		(Keyword)',
		ANSI_REVERSE,'[-]',ANSI_RESET,'	: ');
		PARSE_INPUT (
			    IADDRESS (EDF$AB_SYSTEM_TABLE_KEY),
			    IADDRESS (EDF$AB_SYSTEM_TABLE_STA),
			    FALSE,
			    0
			    );

	    END;	{ SYSTEM }

	OTHERWISE

	    { NULL-STATEMENT } ;

	END;	{ CASE }

	IF TEST.PRIMARY <> TITLE THEN

	    TEST.OBJECT_TYPE	:= SEC;

	TEST.SECONDARY	:= INPUT_VALUE::SECONDARY_TYPE;

	{ +
	Get the secondary number if there was one, it's inited to 0;
	only SEGn_LENGTH,_POSITION,_TYPE set it.
	Force seg_type to be last.
	- }
	IF TEST.SECONDARY = SEG_TYPE THEN

	    TEST.SECNUM	:= 7

	ELSE

	    TEST.SECNUM	:= EDF$GL_SECNUM;

	IF (
	(TEST.SECNUM < 0)
	OR
	(TEST.SECNUM > 7)
	) THEN
    
	    LIB$SIGNAL (EDF$_BADVALUE,0,0,0);

	{ +
	If we're only to ask for what exists, then make sure this does.
	- }
	IF NOT FULL_CHOICE THEN

	BEGIN

	    DEF_CURRENT		:= DEF_HEAD;

	    REPEAT

		IF NOT CURRENT_EQ_TEST(TEST,TRUE) THEN

		    INCR_CURRENT;

	    UNTIL (CURRENT_EQ_TEST(TEST,TRUE) OR (DEF_CURRENT^.FORE = NIL));

	    IF DEF_CURRENT <> NIL THEN

	    BEGIN

		IF NOT CURRENT_EQ_TEST(TEST,TRUE) THEN

		    LIB$SIGNAL (EDF$_BADVALUE,0,0,0);

	    END

	    ELSE

		    LIB$SIGNAL (EDF$_BADVALUE,0,0,0);

	END;	{ IF DISPLAY = EXTANT_ONLY }

	{ +
	Make sure this is true for only one cycle.
	- }
	TEMP_FULL_PROMPT	:= FALSE;

    END;	{ THE_QUESTION }

BEGIN

    { +
    Keep at it until the user gets it right.
    - }
    REPEAT

	THE_QUESTION;

    UNTIL NOT SYS$INPUT_ERROR;

    STR$FREE1_DX (INPUT_DESC);

END;	{ ASK_TEST_SECONDARY }

{ ++

ASK_TEST_SECONDARY_VALUE -- Input the user's value for the secondary.

This routine queries the user about his secondary.

CALLING SEQUENCE:

ASK_TEST_SECONDARY_VALUE;

INPUT PARAMETERS:

none

IMPLICIT INPUTS:

SYS$INPUT:

OUTPUT PARAMETERS:

none

IMPLICIT OUTPUTS:

SYS$INPUT_ERROR
SYS$OUTPUT:

ROUTINES CALLED:

ESTABLISH

ROUTINE VALUE:

none

SIGNALS:

none

SIDE EFFECTS:

none

-- }

PROCEDURE ASK_TEST_SECONDARY_VALUE;

VAR
    I			: INTEGER;
    TEMP_INT		: INTEGER;
    TEMP_DESC		: DESCRIPTOR;
    TEMP_MAX		: INTEGER;
    TEMP_STRING255	: STRING255;

    PROCEDURE THE_QUESTION;

    BEGIN

	{ +
	Set up the condition handler to catch typing errors.
	- }
	SYS$INPUT_ERROR	:= FALSE;
	ESTABLISH (SYS$INPUT_COND_HANDLER);

	IF TEMP_FULL_PROMPT THEN

	    WRITELN (SHIFT,
	    'The value entered will be put into the Definition.');

	{ +
	Pop the question.
	- }
	IF TEST.PRIMARY = DATE THEN

	    WRITE (CRLF_SHIFT,
	    '(dd-mmm-yyyy hh:mm:ss.cc)');

	IF TEST.SECONDARY = POSITION$ THEN

	    WRITE (CRLF_SHIFT,
	    '(Any_cylinder Cylinder File_ID File_name',
	    CRLF_SHIFT,' Logical None Virtual)',CRLF_SHIFT,
	    'Enter POSITION qualifier	(')

	ELSE IF NOT SEC_TYPE[TEST.SECONDARY].QUAL THEN

	    WRITE (CRLF_SHIFT,'Enter value for this Secondary	(');

	IF SEC_TYPE[TEST.SECONDARY].QUAL THEN

	BEGIN

	    CASE TEST.SECONDARY OF

		ORGANIZATION :

		    WRITE (CRLF_SHIFT,
		    '(Indexed Relative Sequential)');

		SOURCE,
		TARGET :

		    WRITE (CRLF_SHIFT,
		    '(IAS RSTS/E RSX-11M RSX-11M-PLUS RT-11 VAX/VMS)');

		RECOVERY_UNIT :

		    WRITE (CRLF_SHIFT,
	      '(If_in_recovery_unit Necessary_to_write Never_RU_journal None)');

		CARRIAGE_CONTROL :

		    WRITE (CRLF_SHIFT,
		    '(Carriage_return FORTRAN None Print)');

		FORMAT :

		    WRITE (CRLF_SHIFT,
		    '(Fixed Stream Stream_CR Stream_LF',CRLF_SHIFT,
		    ' Undefined Variable VFC)');

		SEG_TYPE :

		    WRITE (CRLF_SHIFT,
		    '(Bin2 Bin4 Bin8 Decimal Int2 Int4 Int8 String)');

	    OTHERWISE

		{ NULL-STATEMENT } ;

	    END;	{ CASE }

	    WRITE (CRLF_SHIFT,'Enter value for this Secondary	(Keyword)',
	    ANSI_REVERSE,'[-]',ANSI_RESET,'	: ');

	    CASE TEST.SECONDARY OF

		ORGANIZATION :

		PARSE_INPUT (
			    IADDRESS (EDF$AB_ORG_TABLE_KEY),
			    IADDRESS (EDF$AB_ORG_TABLE_STA),
			    FALSE,
			    0
			    );

		SOURCE,
		TARGET :

		PARSE_INPUT (
			    IADDRESS (EDF$AB_SOURCE_TABLE_KEY),
			    IADDRESS (EDF$AB_SOURCE_TABLE_STA),
			    FALSE,
			    0
			    );

		RECOVERY_UNIT :

		PARSE_INPUT (
			    IADDRESS (EDF$AB_RU_TABLE_KEY),
			    IADDRESS (EDF$AB_RU_TABLE_STA),
			    FALSE,
			    0
			    );

		CARRIAGE_CONTROL :

		PARSE_INPUT (
			    IADDRESS (EDF$AB_CARR_TABLE_KEY),
			    IADDRESS (EDF$AB_CARR_TABLE_STA),
			    FALSE,
			    0
			    );

		FORMAT :

		PARSE_INPUT (
			    IADDRESS (EDF$AB_FORMAT_TABLE_KEY),
			    IADDRESS (EDF$AB_FORMAT_TABLE_STA),
			    FALSE,
			    0
			    );

		SEG_TYPE :

		PARSE_INPUT (
			    IADDRESS (EDF$AB_TYPE_TABLE_KEY),
			    IADDRESS (EDF$AB_TYPE_TABLE_STA),
			    FALSE,
			    0
			    );

	    OTHERWISE

		{ NULL-STATEMENT } ;

	    END;	{ CASE }

	    TEST.QUALIFIER	:= INPUT_VALUE;

	END;	{ IF QUALIFIER_VALUED }

	IF SEC_TYPE[TEST.SECONDARY].NUM THEN

	BEGIN

	    TEMP_MAX	:= SECONDARY_MAX[TEST.SECONDARY];

	    IF (TEST.SECONDARY IN

	    [ DATA_KEY_COMPRESSION,
	    DATA_RECORD_COMPRESSION,
	    INDEX_COMPRESSION ]

	    ) THEN

		WRITE ('Abs<100)')

	    ELSE IF TEMP_MAX = EDF$C_1GIGA THEN

		WRITE ('0-1Giga)')

	    ELSE

		WRITE ('0-',TEMP_MAX:NUM_LEN(TEMP_MAX),')');

	    WRITE (ANSI_REVERSE,'[-]',ANSI_RESET);

	    IF (
	    (NUM_LEN(TEMP_MAX) > 8)
	    AND
	    (TEMP_MAX <> EDF$C_1GIGA)
	    ) THEN

		WRITE (' : ')

	    ELSE

		WRITE ('	: ');

	    NUMBER_INPUT (TEST.NUMBER,FALSE,0);

	    IF (TEST.SECONDARY IN

	    [ DATA_KEY_COMPRESSION,
	    DATA_RECORD_COMPRESSION,
	    INDEX_COMPRESSION ]

	    ) THEN

	    BEGIN

		IF (
		((VDATA[EDF$K_PROLOGUE_VERSION])
		AND (IDATA[EDF$K_PROLOGUE_VERSION] < 3))
		AND
		(TEST.NUMBER <> 0)
		) THEN

		    LIB$SIGNAL (EDF$_BADVALUE,0,0,0);

		IF (
		(TEST.NUMBER < -TEMP_MAX)
		OR
		(TEST.NUMBER > TEMP_MAX)
		) THEN

		    LIB$SIGNAL (EDF$_BADVALUE,0,0,0);

	    END

	    ELSE IF TEST.SECONDARY = CONTROL_FIELD_SIZE THEN

	    BEGIN

		IF (
		(TEST.NUMBER < 1)
		OR
		(TEST.NUMBER > TEMP_MAX)
		) THEN

		    LIB$SIGNAL (EDF$_BADVALUE,0,0,0);

	    END

	    ELSE

	    BEGIN

		IF (
		(TEST.NUMBER < 0)
		OR
		(TEST.NUMBER > TEMP_MAX)
		) THEN

		    LIB$SIGNAL (EDF$_BADVALUE,0,0,0);

	    END;

	    IF (
	    (TEST.SECONDARY = MT_BLOCK_SIZE)
	    AND
	    (TEST.NUMBER > 0)
	    AND
	    (TEST.NUMBER < 20)
	    ) THEN

		LIB$SIGNAL (EDF$_BADVALUE,0,0,0);

	END;	{ IF NUMBER_VALUED }

	IF (
	(SEC_TYPE[TEST.SECONDARY].STR)
	OR
	(TEST.PRIMARY = TITLE)
	) THEN

	BEGIN

	    IF TEST.PRIMARY = DATE THEN

		WRITE ('Date-str)',ANSI_REVERSE,'[-]',ANSI_RESET,'	: ')

	    ELSE IF TEST.SECONDARY = NAME$ THEN

		WRITE ('1-32 chars)[null]	: ')

	    ELSE

		WRITE ('1-126 chars)[null]',CRLF_SHIFT,': ');

	    IF EOF (INPUT) THEN

	    BEGIN

		RESET (INPUT);
		LIB$SIGNAL (EDF$_CTRLZ,0,0,0);

	    END;

	    READLN (TEMP_STRING255);
	    WRITELN (CRLF);

	    TEST.STRING	:= NULL_STRING;
	    STR$TRIM (TEST.STRING,TEMP_STRING255);
	    LIB$SCOPY_DXDX (TEST.STRING,INPUT_DESC);
	    PARAM_BLOCK.TPA$L_TOKENPTR	:= INPUT_DESC.DSC$A_POINTER::UNSIGNED;
	    PARAM_BLOCK.TPA$L_TOKENCNT	:= INPUT_DESC.DSC$W_LENGTH;

	    { +
	    If we're journaling our input, save a copy of it to the
	    journal file.
	    - }
	    IF JOURNAL_ENABLED THEN

		IF TEST.STRING.DSC$W_LENGTH > 0 THEN

		    WRITELN (
			JOURNAL_FILE,
			TEST.STRING.DSC$A_POINTER^:
			    TEST.STRING.DSC$W_LENGTH
			)

		ELSE

		    WRITELN (JOURNAL_FILE);

	    IF TEST.PRIMARY = DATE THEN

	    BEGIN

		STR$UPCASE (TEST.STRING,TEST.STRING);

		IF TEST.STRING.DSC$W_LENGTH = 0 THEN

		BEGIN

		    STR$FREE1_DX (TEST.STRING);
		    LIB$SIGNAL (EDF$_NODEFAULT,0,0,0);

		END;

		{ +
		Copy the upcased string back into the temp_string255
		for the test.	
		- }
		FOR I := 1 TO TEST.STRING.DSC$W_LENGTH DO

		    TEMP_STRING255[I]	:= TEST.STRING.DSC$A_POINTER^[I];

		IF (
		NOT ODD ( $BINTIM (TEMP_STRING255,QUAD_TIME) )
		) THEN

		BEGIN

		    STR$FREE1_DX (TEST.STRING);
		    LIB$SIGNAL (EDF$_BADSYNTAX,0,0,0);

		END;

	    END;	{ IF TEST.PRIMARY = DATE }

	    IF (
	    (
	    (TEST.SECONDARY = NAME$)
	    AND
	    (TEST.STRING.DSC$W_LENGTH > 32)
	    )
	    OR
	    (TEST.STRING.DSC$W_LENGTH > 126)
	    ) THEN

	    BEGIN

		STR$FREE1_DX (TEST.STRING);
		LIB$SIGNAL (EDF$_BADSYNTAX,0,0,0);

	    END;

	END;	{ IF STRING_VALUED }

	IF SEC_TYPE[TEST.SECONDARY].SW THEN

	BEGIN

	    WRITE ('Yes/No)',ANSI_REVERSE,'[-]',ANSI_RESET,'	: ');
	    PARSE_INPUT (
			IADDRESS (EDF$AB_YES_NO_TABLE_KEY),
			IADDRESS (EDF$AB_YES_NO_TABLE_STA),
			FALSE,
			0
			);

	    TEST.SWITCH	:= (INPUT_VALUE = EDF$K_YES);

	    IF (
	    (TEST.PRIMARY = KEY)
	    AND
	    (TEST.PRINUM = 0)
	    AND
	    (TEST.SECONDARY = CHANGES)
	    AND
	    (TEST.SWITCH = TRUE)
	    ) THEN

		LIB$SIGNAL (EDF$_BADVALUE,0,0,0);

	    IF (
	    (TEST.PRIMARY = RECORD$)
	    AND
	    (TEST.SECONDARY = BLOCK_SPAN)
	    AND
	    (TEST.SWITCH = TRUE)
	    ) THEN

	    BEGIN

		IF FIND_OBJECT (SEC,FILE$,0,ORGANIZATION,0) THEN

		BEGIN

		    IF DEF_CURRENT^.QUALIFIER <> FDL$C_SEQ THEN

			LIB$SIGNAL (EDF$_BADVALUE,0,0,0);

		END;

	    END;

	END;	{ IF SWITCH_VALUED }

	IF TEST.SECONDARY = OWNER THEN

	BEGIN

	    EDF$GL_OWNER_UIC	:= 0;

	    WRITE ('UIC-str)',ANSI_REVERSE,'[-]',ANSI_RESET,'	: ');
	    PARSE_INPUT (
			IADDRESS (EDF$AB_UIC_TABLE_KEY),
			IADDRESS (EDF$AB_UIC_TABLE_STA),
			FALSE,
			0
			);

	    TEST.OWNER_UIC	:= EDF$GL_OWNER_UIC;

	END;	{ IF TEST.SECONDARY = OWNER }

	IF TEST.SECONDARY = PROTECTION THEN

	BEGIN

	    FOR I := 0 TO 31 DO

		EDF$GL_PROT_MASK[I]	:= FALSE;

	    WRITE ('Prot-str)',ANSI_REVERSE,'[-]',ANSI_RESET,CRLF_SHIFT,': ');
	    PARSE_INPUT (
			IADDRESS (EDF$AB_PROT_TABLE_KEY),
			IADDRESS (EDF$AB_PROT_TABLE_STA),
			FALSE,
			0
			);

	    TEST.PROT_MASK	:= EDF$GL_PROT_MASK;

	END;	{ IF TEST.SECONDARY = PROTECTION }

	IF TEST.SECONDARY = POSITION$ THEN

	BEGIN

	    WRITE ('Keyword)',ANSI_REVERSE,'[-]',ANSI_RESET,'	: ');
	    PARSE_INPUT (
			IADDRESS (EDF$AB_POSIT_TABLE_KEY),
			IADDRESS (EDF$AB_POSIT_TABLE_STA),
			FALSE,
			0
			);

	    TEST.QUALIFIER	:= INPUT_VALUE;

	    IF NOT (TEST.QUALIFIER IN [ FDL$C_NOPOS, FDL$C_ANYPOS ]) THEN

	    BEGIN

		WRITE (CRLF_SHIFT,'Enter POSITION value		(');

		CASE TEST.QUALIFIER OF

		    FDL$C_CLUSPOS, FDL$C_CYLPOS, FDL$C_LOGPOS, FDL$C_VIRPOS :

		    BEGIN

			WRITE ('0-1Giga)',ANSI_REVERSE,'[-]',ANSI_RESET,'	: ');
			NUMBER_INPUT (TEST.NUMBER,FALSE,0);

		    END;

		    FDL$C_FIDPOS :

		    BEGIN

			EDF$GL_FID1	:= 0;
			EDF$GL_FID2	:= 0;
			EDF$GL_FID3	:= 0;

			WRITE ('FID-str)',ANSI_REVERSE,'[-]',ANSI_RESET,'	: ');
			PARSE_INPUT (
				    IADDRESS (EDF$AB_FID_TABLE_KEY),
				    IADDRESS (EDF$AB_FID_TABLE_STA),
				    FALSE,
				    0
				    );

			TEST.FID1		:= EDF$GL_FID1;
			TEST.FID2		:= EDF$GL_FID2;
			TEST.FID3		:= EDF$GL_FID3;

		    END;

		    FDL$C_FNMPOS :

		    BEGIN

			WRITE ('1-109 chars)[null]',CRLF_SHIFT,': ');

			IF EOF (INPUT) THEN

			BEGIN

			    RESET (INPUT);
			    LIB$SIGNAL (EDF$_CTRLZ,0,0,0);

			END;

			READLN (TEMP_STRING255);
			WRITELN (CRLF);

			TEST.STRING	:= NULL_STRING;
			STR$TRIM (TEST.STRING,TEMP_STRING255);
			LIB$SCOPY_DXDX (TEST.STRING,INPUT_DESC);
			PARAM_BLOCK.TPA$L_TOKENPTR	:= INPUT_DESC.DSC$A_POINTER::UNSIGNED;
			PARAM_BLOCK.TPA$L_TOKENCNT	:= INPUT_DESC.DSC$W_LENGTH;

			{ +
			If we're journaling our input, save a copy of it to the
			journal file.
			- }
			IF JOURNAL_ENABLED THEN

			    IF TEST.STRING.DSC$W_LENGTH > 0 THEN

				WRITELN (
				    JOURNAL_FILE,
				    TEST.STRING.DSC$A_POINTER^:
					TEST.STRING.DSC$W_LENGTH
				    )

			    ELSE

				WRITELN (JOURNAL_FILE);

			IF TEST.STRING.DSC$W_LENGTH > 109 THEN

			    LIB$SIGNAL (EDF$_BADSYNTAX,0,0,0);

		    END;

		OTHERWISE

		    { NULL-STATEMENT } ;

		END;	{ CASE }

	    END;	{ IF NOT (TEST.QUALIFIER IN [ FDL$C_NOPOS, FDL$C_ANYPOS ]) }

	END;	{ IF TEST.SECONDARY = POSITION$ }

	IF (
	(TEST.SECONDARY = NULL_VALUE)
	OR
	(TEST.SECONDARY = MT_PROTECTION)
	) THEN

	BEGIN

	    WRITE ('''char''/num)',ANSI_REVERSE,'[-]',ANSI_RESET,'	: ');


	    IF EOF (INPUT) THEN

	    BEGIN

		RESET (INPUT);
		LIB$SIGNAL (EDF$_CTRLZ,0,0,0);

	    END;

	    READLN (TEMP_STRING255);
	    WRITELN (CRLF);

	    TEMP_DESC	:= NULL_STRING;
	    STR$TRIM (TEMP_DESC,TEMP_STRING255);
	    LIB$SCOPY_DXDX (TEMP_DESC,INPUT_DESC);
	    PARAM_BLOCK.TPA$L_TOKENPTR	:= INPUT_DESC.DSC$A_POINTER::UNSIGNED;
	    PARAM_BLOCK.TPA$L_TOKENCNT	:= INPUT_DESC.DSC$W_LENGTH;

	    { +
	    If we're journaling our input, save a copy of it to the
	    journal file.
	    - }
	    IF JOURNAL_ENABLED THEN

		IF TEMP_DESC.DSC$W_LENGTH > 0 THEN

		    WRITELN (
			JOURNAL_FILE,
			TEMP_DESC.DSC$A_POINTER^:
			    TEMP_DESC.DSC$W_LENGTH
			)

		ELSE

		    WRITELN (JOURNAL_FILE);

	    IF TEMP_DESC.DSC$W_LENGTH = 0 THEN

	    BEGIN

		STR$FREE1_DX (TEMP_DESC);
		LIB$SIGNAL (EDF$_NODEFAULT,0,0,0);

	    END;

	    ISTATUS		:= OTS$CVT_TI_L (TEMP_DESC,TEMP_INT);

	    IF ODD (ISTATUS) THEN

		TEST.NUMBER	:= TEMP_INT

	    ELSE IF (
	    (TEMP_DESC.DSC$A_POINTER^[1] <> APOSTROPHE)
	    OR
	    (TEMP_DESC.DSC$A_POINTER^[3] <> APOSTROPHE)
	    ) THEN

	    BEGIN

		STR$FREE1_DX (TEMP_DESC);
		LIB$SIGNAL (EDF$_BADSYNTAX,0,0,0);

	    END

	    ELSE

		TEST.NUMBER	:= ORD (TEMP_DESC.DSC$A_POINTER^[2]);

	    IF TEST.SECONDARY = MT_PROTECTION THEN

	    BEGIN

		{ +
		Make sure it's a legal ANSI-a character.
		- }
		IF (
		(TEST.NUMBER < %X20)	{ SPACE }
		OR
		(TEST.NUMBER > %X5A)	{ CAPITAL Z }
		OR
		(TEST.NUMBER = %X23)	{ # }
		OR
		(TEST.NUMBER = %X24)	{ $ }
		OR
		(TEST.NUMBER = %X40)	{ @ }
		) THEN		

		BEGIN

		    STR$FREE1_DX (TEMP_DESC);
		    LIB$SIGNAL (EDF$_BADVALUE,0,0,0);

		END;

	    END; { IF TEST.SECONDARY = MT_PROTECTION }

	END;	{ IF TEST.SECONDARY = NULL_VALUE OR MT_PROTECTION }

	{ +
	Make sure this is true only for one cycle.
	- }
	TEMP_FULL_PROMPT	:= FALSE;

    END;	{ THE_QUESTION }

BEGIN

    IF TEST.PRIMARY = TITLE THEN

	TEST.OBJECT_TYPE	:= PRI

    ELSE

	TEST.OBJECT_TYPE	:= SEC;

    { +
    Keep at it until the user gets it right.
    - }
    REPEAT

	THE_QUESTION;

    UNTIL NOT SYS$INPUT_ERROR;

    STR$FREE1_DX (INPUT_DESC);

END;		{ ASK_TEST_SECONDARY_VALUE }

END.
    { End of file: SRC$:EDFASK.PAS }
