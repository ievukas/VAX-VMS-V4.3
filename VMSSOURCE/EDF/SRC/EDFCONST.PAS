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

		V03-007	KFH0007		Ken Henderson		 8 Aug 1983
			Changes for seperate compilation.

		V03-006	KFH0006		Ken Henderson		27 Jul 1983
			Added BKT$C and IRC$C constants.

		V03-005	KFH0005		Ken Henderson		14 Apr 1983
			Added BKT$C_MAXBKTSIZ.

		V03-004	KFH0004		Ken Henderson		31 Jan 1983
			Added XAB$C_BN8 and XAB$C_IN8 until
			new Starlet.pen is made online.

		V03-003	KFH0003		Ken Henderson		8 Sept 1982
			Removed some definitions and added
			output from EDFSTRUCT.SDL (until PasV2)

		V03-002	KFH0002		Ken Henderson		23-Mar-1982
			Added RMS$_FNF to fix FT2 QAR 694.

		V03-001	KFH0001		Ken Henderson		17-Mar-1982
			Added BIGGEST_REL_VAR to support VFC better.

-- }

ENVIRONMENT ('LIB$:EDFCONST')]

MODULE EDFCONST;

CONST

%INCLUDE	'SYS$LIBRARY:PASDEF.PAS'

%INCLUDE	'SYS$LIBRARY:PASSTATUS.PAS'

    { +
    The following are for manipulating string descriptors.
    - }
    DSC$K_CLASS_S	= 1;		{ String descriptor class }
    DSC$K_CLASS_D	= 2;		{ Dynamic string descriptor class }
    DSC$K_DTYPE_T	= 14;		{ Text data type }

    { +
    The following are for condition handling.
    - }
    STS$V_SEVERITY	= 0;
    STS$S_SEVERITY	= 3;

    { +
    The following are general constants used by EDF.
    - }
    EDF$C_HEADROOM	= 3;		{ Margin of lines left on screen }
    EDF$C_SHIFTPOINT	= 100;		{ For shifting the Menus }
    EDF$C_1GIGA		= 999999999;	{ 10**9 minus 1 }

    { +
    The following are used to display and parse file protection codes.
    In a line_object's PROT_MASK field.

    THE PROTECTION WORD IS:

    (MSF in word) WORLD | GROUP | OWNER | SYSTEM  (LSF in word)

    EACH 4 BIT FIELD IS:

    (MSB in field) NODEL | NOEXE | NOWRITE | NOREAD (LSB in field)

    FALSE = DENY ACCESS		NOTE: THIS IS THE TRUE/FALSE SENSE OF JUST
    TRUE = ALLOW ACCESS		FDL$GL_PROTECTION AND EDF$GL_PROT_MASK.
    				THE ACTUAL XABPRO BITS ARE (1=DENY/0=ALLOW)

    - }
    EDF$V_SYS		= 0;
    EDF$V_OWN		= 4;
    EDF$V_GRP		= 8;
    EDF$V_WLD		= 12;
    EDF$V_NOREAD	= 0;
    EDF$V_NOWRITE	= 1;
    EDF$V_NOEXE		= 2;
    EDF$V_NODEL		= 3;

    { +
    The following define RMS Prologue 2 and 3 structure constants.
    - }
    P2_BUCKET_OVERHEAD		= 15;
    BIGGEST_P2_FIX_RECORD	= 16362;
    BIGGEST_P2_VAR_RECORD	= 16360;
    BIGGEST_SEQ_FIXED		= 32767;
    BIGGEST_REL_FIXED		= 16383;
    BIGGEST_REL_VAR		= 16381;
    BIGGEST_ANSI_TAPE		= 9995;

    BKT$C_MAXBKTSIZ		= 63;
    BKT$C_OVERHDSZ		= 14;
    BKT$C_ENDOVHD		= 4;
    BKT$C_DATBKTOVH		= 2;
    BKT$C_DUPBKTOVH		= 4;
    IRC$C_MAXVBNSZ		= 4;
    IRC$C_DATPTRBS3		= 4;
    IRC$C_DATOVHSZ3		= 3;
    IRC$C_FIXOVHSZ3		= 9;
    IRC$C_VAROVHSZ3		= 11;
    IRC$C_RRVOVHSZ3		= 9;
    IRC$C_SDROVHSZ3		= 2;
    IRC$C_KEYCMPOVH		= 2;
    IRC$C_DATCMPOVH		= 3;

    EDF$K_MAXRECSIZ		= ((BKT$C_MAXBKTSIZ*512) -
		(IRC$C_KEYCMPOVH+IRC$C_VAROVHSZ3+IRC$C_DATCMPOVH));

    EDF$C_MAX_GBL_BUFS		= 32767; { RMS field is a word; pos values only }
    EDF$K_TEMP_VARYING_SIZE	= 255;	{ Number of characters in scratch string }

    BUCKET_LEFT_WEIGHT		= 0.10;	{ These are used to help find the }
    BUFFER_SPACE_FACTOR		= 3;	{ 'Right' bucketsize }

    MAX_ARRAY_ROW		= 12;	{ this value affects EDFGRF.B32 }

(*+                                                                         *)
(* FDL CALL INTERFACE CONTROL FLAGS                                         *)
(*-                                                                         *)
 
CONST	FDL$M_SIGNAL = 1;
	FDL$M_FDL_STRING = 2;
	FDL$M_DEFAULT_STRING = 4;
	FDL$M_FULL_OUTPUT = 8;
	FDL$M_$CALLBACK = 16;

{ +
DEFINE 8-BYTE KEY DATA TYPES
- }

CONST	XAB$C_IN8	= 6;
	XAB$C_BN8	= 7;
 
{      End of file SRC$:EDFCONST.PAS      }

END.
