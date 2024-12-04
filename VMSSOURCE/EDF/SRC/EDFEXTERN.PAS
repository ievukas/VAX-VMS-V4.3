	[ IDENT ('V04-000'),
{ ++
 ****************************************************************************
 *									    *
 *  COPYRIGHT (c) 1978, 1980, 1982, 1984 BY				    *
 *  DIGITAL EQUIPMENT CORPORATION, MAYNARD, MASSACHUSETTS.		    *
 *  ALL RIGHTS RESERVED.						    *
 * 									    *
 *  THIS SOFTWARE IS FURNISHED UNDER A LICENSE AND MAY BE USED AND COPIED   *
 *  ONLY IN  ACCORDANCE WITH  THE  TERMS  OF  SUCH  LICENSE  AND WITH THE   *
 *  INCLUSION OF THE ABOVE COPYRIGHT NOTICE. THIS SOFTWARE OR  ANY  OTHER   *
 *  COPIES THEREOF MAY NOT BE PROVIDED OR OTHERWISE MADE AVAILABLE TO ANY   *
 *  OTHER PERSON.  NO TITLE TO AND OWNERSHIP OF  THE  SOFTWARE IS  HEREBY   *
 *  TRANSFERRED.							    *
 * 									    *
 *  THE INFORMATION IN THIS SOFTWARE IS  SUBJECT TO CHANGE WITHOUT NOTICE   *
 *  AND  SHOULD  NOT  BE  CONSTRUED AS  A COMMITMENT BY DIGITAL EQUIPMENT   *
 *  CORPORATION.							    *
 * 									    *
 *  DIGITAL ASSUMES NO RESPONSIBILITY FOR THE USE  OR  RELIABILITY OF ITS   *
 *  SOFTWARE ON EQUIPMENT WHICH IS NOT SUPPLIED BY DIGITAL.		    *
 * 									    *
 *									    *
 ****************************************************************************





FACILITY:	VAX/VMS EDF (EDIT/FDL) UTILITY

ABSTRACT:	This facility is used to create, modify, and optimize
		FDL specification files.

ENVIRONMENT:	NATIVE/USER MODE

AUTHOR:		Ken F. Henderson Jr.

CREATION DATE:	27-Mar-1981

MODIFIED BY:

		V03-008	KFH0008		Ken Henderson		 8 Aug 1983
			Changes for seperate compilation.

		V03-007	KFH0007		Ken Henderson		14 Apr 1983
			Changed EDF$TERM_SETUP function
			value from BYTE to INTEGER.

		V03-006	KFH0006		Ken Henderson		22 Nov 1982
			Removed obsolete SYS$routine
			definitions. (now from starlet.pen)

		V03-005	KFH0005		Ken Henderson		11 Oct 1982
			Added support for Access, ACL,
			Connect, Journal, Sharing primaries.
			Changed FDL$$PARSE to FDL$PARSE.
			Modified FDL$CREATE.

		V03-004	KFH0004		Ken Henderson		22 Sept 1982
			Added definition of LIB$WAIT;
			Removed definition of FOR$SECNDS.

		V03-003	KFH0003		Ken Henderson		11 August 1982
			Removed reference to CLI$END_PARSE.

		V03-002	KFH0002		Ken Henderson		2 April 1982
			Added ISECNUM_PTR to call to
			FDL$GLOBAL.

		V03-001	KFH0001		Ken Henderson		23-Mar-1982
			Modified LIB$OUTPUT_HELP to fix
			FT2 QAR 381

-- }

ENVIRONMENT ('LIB$:EDFEXTERN'),

INHERIT (

'SYS$LIBRARY:STARLET',
'SHRLIB$:FDLPARDEF',
'LIB$:EDFSTRUCT',
'LIB$:EDFCONST',
'LIB$:EDFTYPE',
'LIB$:EDFVAR'

)]

MODULE EDFEXTERN;

{ ++
EXTERNAL ROUTINE DECLARATIONS:

The following functions and procedures are part of the VMS RunTimeLibrary.
They are documented in the RTL Reference Manual and the Utilities Reference
Manual.
-- }

{ +
These are the 'Terminal Independent Screen Procedures'.
- }

[ASYNCHRONOUS] FUNCTION LIB$PUT_LINE (

	%DESCR      TEXTX	: [VOLATILE] VARYING [A] OF CHAR;
		VAR LINE_ADV	: [VOLATILE] INTEGER;
		    FLAGS	: [VOLATILE] INTEGER

		    ) : INTEGER; EXTERNAL;

FUNCTION LIB$ERASE_LINE (

		VAR LINE,
		    COLUMN	: INTEGER

		    ) : INTEGER; EXTERN;

FUNCTION LIB$ERASE_PAGE (

     		VAR LINE,
     		    COLUMN	: [VOLATILE] INTEGER

		    ) : INTEGER; EXTERN;

FUNCTION LIB$SET_CURSOR (

     		VAR LINE,
     		    COLUMN	: [VOLATILE] INTEGER

		    ) : INTEGER; EXTERN;

[ASYNCHRONOUS] FUNCTION LIB$SET_SCROLL (

     		VAR START_LINE,
     		    END_LINE	: [VOLATILE] INTEGER

		    ) : INTEGER; EXTERN;

FUNCTION LIB$PUT_SCREEN (

	   %STDESCR TEXTX	: PACKED ARRAY [L..U:INTEGER] OF CHAR;
		VAR LINE,
		    COLUMN	: INTEGER

		    ) : INTEGER; EXTERN;

[UNBOUND,EXTERNAL] FUNCTION LIB$PUT_OUTPUT (

	   %STDESCR TEXTX	: PACKED ARRAY [L..U:INTEGER] OF CHAR

		    ) : INTEGER; EXTERNAL;

[UNBOUND,EXTERNAL] FUNCTION LIB$GET_INPUT (

	   %DESCR   INPUT_TEXT	: VARYING [A] OF CHAR;
	   %DESCR   PROMPT_STR	: VARYING [B] OF CHAR;
		VAR LENGTH	: INTEGER

		    ) : INTEGER; EXTERNAL;

FUNCTION LIB$GET_SCREEN (

	   %DESCR   INPUT_TEXT	: VARYING [A] OF CHAR;
	   %DESCR   PROMPT_STR	: VARYING [B] OF CHAR;
		VAR LENGTH	: INTEGER

		    ) : INTEGER; EXTERN;

FUNCTION LIB$SCREEN_INFO (

		    FLAGS		: SCR1$TYPE;
		    DEV_TYPE		: INTEGER;
		    LINE_WIDTH		: INTEGER;
		    LINES_PER_PAGE	: INTEGER

		    ) : INTEGER; EXTERN;

FUNCTION LIB$DOWN_SCROLL : INTEGER; EXTERN;

{ +
The following is the famed "TPARSE" table-driven parsing routine.
- }
FUNCTION LIB$TPARSE (

		VAR PARAM_BLK	: [VOLATILE] TPA$TYPE;
	     %IMMED STATE_TBL	: INTEGER;
	     %IMMED KEY_TBL	: INTEGER

		    ) : INTEGER; EXTERN;

{ +
The following are general string handling routines.
- }

PROCEDURE STR$UPCASE (

	   	VAR DST		: [VOLATILE] DESCRIPTOR;
	   	VAR SRC		: [VOLATILE] DESCRIPTOR

		    ); EXTERN;

PROCEDURE STR$TRIM (

	   	VAR DST		: [VOLATILE] DESCRIPTOR;
	   %STDESCR SRC		: PACKED ARRAY [L..U:INTEGER] OF CHAR

		    ); EXTERN;

[ASYNCHRONOUS] PROCEDURE STR$FREE1_DX (

    		VAR DSC		: [VOLATILE] DESCRIPTOR

    		    ); EXTERN;

[ASYNCHRONOUS] FUNCTION LIB$SCOPY_DXDX	(

		    SRC		: DESCRIPTOR;
		    DST		: DESCRIPTOR

		    ) : INTEGER; EXTERN;

FUNCTION OTS$SCOPY_DXDX	(

	   %STDESCR SRC		: PACKED ARRAY [L..U:INTEGER] OF CHAR;
		    DST		: DESCRIPTOR

		    ) : INTEGER; EXTERN;

FUNCTION OTS$CVT_TI_L (

		    STR		: DESCRIPTOR;
		VAR NUM		: INTEGER

		    ) : INTEGER; EXTERN;

FUNCTION LIB$DATE_TIME (

	   %STDESCR DST		: PACKED ARRAY [L..U:INTEGER] OF CHAR

		    ) : INTEGER; EXTERN;

{ +
This routine will set a bit field (SRC) in a location (BASE).
- }
[ASYNCHRONOUS] PROCEDURE LIB$INSV (

		    SRC,
		    POS		: LONG;
		    SIZE	: BYTE;
		VAR BASE	: LONG

		    ); EXTERN;

{ +
This routine will get a bit field from a location.
- }
[ASYNCHRONOUS] FUNCTION LIB$EXTZV (

		    POS,
		    SIZE,
		    BASE	: LONG

		    ) : INTEGER; EXTERN;

{ +
This routine does a schdwk/hiber to wait a specified length of time.
- }
[ASYNCHRONOUS] PROCEDURE LIB$WAIT (

		    SECONDS	: REAL

		    ); EXTERN;

{ +
This routine does our help processing for us.
- }
FUNCTION LBR$OUTPUT_HELP (

	     %IMMED PUT_PTR	 	: INTEGER;
		    WIDTH		: LONG;
	     %IMMED LINE		: LONG;
	   %STDESCR LIBRARY		: PACKED ARRAY [L..U:INTEGER] OF CHAR;
	     %IMMED FLAGS		: LONG;
	     %IMMED GET_PTR		: INTEGER

		    ) : INTEGER; EXTERNAL;

{ +
These are used in error handling.
- }

[ASYNCHRONOUS] FUNCTION LIB$MATCH_COND (

		    CONDVAL,
		    COMPVAL	: INTEGER

		    ) : BOOLEAN; EXTERN;

PROCEDURE LIB$SIGNAL (

	     %IMMED CONDITION	: INTEGER;
	     %IMMED NUMARGS	: INTEGER;
	     %IMMED ARG1	: INTEGER;
	     %IMMED ARG2	: INTEGER

		    ); EXTERN;

PROCEDURE LIB$STOP (

	     %IMMED CONDITION	: INTEGER;
	     %IMMED NUMARGS	: INTEGER;
	     %IMMED ARG1	: INTEGER;
	     %IMMED ARG2	: INTEGER

		    ); EXTERN;

{ +
These are used to process the DCL command string.
- }

FUNCTION CLI$GET_VALUE (

	   %STDESCR SELECT	: PACKED ARRAY [L..U:INTEGER] OF CHAR;
	   	VAR RETURNED	: DESCRIPTOR

		    ) : INTEGER; EXTERN;

FUNCTION CLI$PRESENT (

	   %STDESCR TEXTX	: PACKED ARRAY [L..U:INTEGER] OF CHAR

		    ) : INTEGER; EXTERN;


{ +
The following is used to plot graphs on the terminal.
- }
PROCEDURE EDF$GRAPH (

		    GRAPH_TYPE	: INTEGER;
	     %DESCR XY_ARRAY	: XY_PLOT_TYPE;
		    CURRENT_INDEX,
		    LAST_INDEX,
		    Y_HIGH,
		    Y_LOW,
		    Y_INCR	: INTEGER;
	   %STDESCR Y_LABEL	: PACKED ARRAY [L..U:INTEGER] OF CHAR;
	     %DESCR COLOR_ARRAY	: XY_PLOT_TYPE

		    ) ; EXTERN;

{ +
The following is used to parse the input FDL file for storage into the
database.
- }
FUNCTION FDL$PARSE (

	   	    FNM		: DESCRIPTOR;
		VAR FAB		: FAB_PTR;
		VAR RAB		: FAB_PTR;
	       %REF FLG		: FDL2$TYPE

		    ) : INTEGER; EXTERN;

{ +
The following is used to deallocate the memory used by the RMS blocks
which are allocated by FDL$PARSE.
- }
FUNCTION FDL$RELEASE (

		    FAB		: FAB_PTR;
		    RAB		: FAB_PTR

		    ) : INTEGER; EXTERN;

{ +
The following is used to first parse an input FDL file and then create the
RMS file specified by it.
- }
FUNCTION FDL$CREATE (

		    FDLNAM	: DESCRIPTOR;
		    OUTNAM	: DESCRIPTOR;
		    DFTNAM	: DESCRIPTOR;
     		VAR RESNAM	: [VOLATILE] DESCRIPTOR;
		VAR FIDBLK	: [VOLATILE] FID;
	       %REF FLAGS	: FDL2$TYPE

		    ) : INTEGER; EXTERN;

{ +
The following routines are used to interface to TTDRV.
- }
FUNCTION  EDF$TERM_SETUP : INTEGER; EXTERN;

PROCEDURE EDF$RESET_TERM; EXTERN;

PROCEDURE EDF$CTRLCAST; EXTERN;

{ +
The following routines are in other modules of EDF.
They were FORWARD declared before seperate compilation (Pascal V2) was used.
- }
[EXTERNAL] FUNCTION QUERY (OFFSET : INTEGER) : BOOLEAN; EXTERN;

[EXTERNAL] PROCEDURE POINT_AT_DEFINITION; EXTERN;

[ASYNCHRONOUS,EXTERNAL] PROCEDURE EDF$RESET_SCROLL; EXTERN;

[EXTERNAL] PROCEDURE INPUT_ANALYSIS_FILE; EXTERN;

[EXTERNAL] PROCEDURE SHOW_ALL_PRIMARIES; EXTERN;

[EXTERNAL] PROCEDURE SHOW_PRIMARY_SECTION (TEST : LINE_OBJECT); EXTERN;

[EXTERNAL] PROCEDURE SHOW_CUR_PRI_SEC (PLUS_VALUE : BOOLEAN); EXTERN;

[EXTERNAL] FUNCTION NATURAL_DEPTH : INTEGER; EXTERN;

END.
{      End of file SRC$:EDFEXTERN.PAS      }
