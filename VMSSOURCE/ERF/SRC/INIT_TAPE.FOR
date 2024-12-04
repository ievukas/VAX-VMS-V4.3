	Subroutine ERFTAPINI ( Array_addr, Array_size )

C
C Version:	'V04-000'
C
C****************************************************************************
C*									    *
C*  COPYRIGHT (c) 1978, 1980, 1982, 1984 BY				    *
C*  DIGITAL EQUIPMENT CORPORATION, MAYNARD, MASSACHUSETTS.		    *
C*  ALL RIGHTS RESERVED.						    *
C* 									    *
C*  THIS SOFTWARE IS FURNISHED UNDER A LICENSE AND MAY BE USED AND COPIED   *
C*  ONLY IN  ACCORDANCE WITH  THE  TERMS  OF  SUCH  LICENSE  AND WITH THE   *
C*  INCLUSION OF THE ABOVE COPYRIGHT NOTICE. THIS SOFTWARE OR  ANY  OTHER   *
C*  COPIES THEREOF MAY NOT BE PROVIDED OR OTHERWISE MADE AVAILABLE TO ANY   *
C*  OTHER PERSON.  NO TITLE TO AND OWNERSHIP OF  THE  SOFTWARE IS  HEREBY   *
C*  TRANSFERRED.							    *
C* 									    *
C*  THE INFORMATION IN THIS SOFTWARE IS  SUBJECT TO CHANGE WITHOUT NOTICE   *
C*  AND  SHOULD  NOT  BE  CONSTRUED AS  A COMMITMENT BY DIGITAL EQUIPMENT   *
C*  CORPORATION.							    *
C* 									    *
C*  DIGITAL ASSUMES NO RESPONSIBILITY FOR THE USE  OR  RELIABILITY OF ITS   *
C*  SOFTWARE ON EQUIPMENT WHICH IS NOT SUPPLIED BY DIGITAL.		    *
C* 									    *
C*									    *
C****************************************************************************
C
C
C
C	AUTHOR: Elliott A. Drayton		CREATION DATE: 27-Jan-1983
C
C	Functional description:

C	This is the initialization module for the loadable image ERFTAPE.EXE.
C	After ERFTAPE has been loaded this routine is called to return
C	the information from it tables. These tables specifiy which error
C	log packets this loadable image will process. The tables consist of:

C       ENTRY TYPE, DEVICE CLASS, MODULE VERSION, TRANSFER VECTOR OFFSET
C
C	The ENTRY TYPE value is the packet type identifier for the packets that
C	this loadable image will process.

C	The DEVICE CLASS value specifies the class of the packet that will
C	be process by this loadable image.

C	The MODULE VERSION is used to determine if the module in this image
C	is the one to use. This is accomplished by the root image comparing
C	this value against the value in the master tables in the root image.

C	The TRANSFER VECTOR OFFSET is the index to the transfer vector to
C	be used for a specific device or entry type. For example, the transfer
C	vectors for the disk image are ordered as:
C
C	INITDISK 0	! a routine similar to this one
C	MASSDISK 1	! a device specific routine
C	RKDISK   2
C	RLDISK   3
C	ECT.
C
C	Modified by:
C
C**

	Parameter DC$_TAPE = '00000002'X
! 
!  TAPE DEVICES
! 
	PARAMETER DT$_TE16 = '00000001'X	! TE16 MAGTAPE 
	PARAMETER DT$_TU45 = '00000002'X	! TU45 MAGTAPE 
	PARAMETER DT$_TU77 = '00000003'X	! TU77 MAGTAPE 
	PARAMETER DT$_TS11 = '00000004'X	! TS11 MAGTAPE 
	PARAMETER DT$_TU78 = '00000005'X	! TU78 MAGTAPE 
	PARAMETER DT$_TA78 = '00000006'X	! TA78 MAGTAPE 
	PARAMETER DT$_TU80 = '00000007'X	! TU80 MAGTAPE 
	PARAMETER DT$_TU81 = '00000008'X	! TU81 MAGTAPE 
	PARAMETER DT$_TA81 = '00000009'X	! TA81 MAGTAPE 

	Parameter V1 = 1			! device module version number

	Parameter	Maxtypes = 5

	Integer*4	Array_addr, Array_size

	Integer*2	Tape_codes ( 4 * Maxtypes )

	Data		Tape_codes /
	1 DT$_TE16, DC$_TAPE, V1, 1,	! TE16 MAGTAPE 
	2 DT$_TU45, DC$_TAPE, V1, 1,	! TU45 MAGTAPE 
	3 DT$_TU77, DC$_TAPE, V1, 1,	! TU77 MAGTAPE 
	4 DT$_TS11, DC$_TAPE, V1, 2,	! TS11 MAGTAPE 
	5 DT$_TU78, DC$_TAPE, V1, 3/	! TU78 MAGTAPE 

! The following devices are handled by ERFPROC1.EXE:
!	6 DT$_TA78, DC$_TAPE, V1, 0	! TA78 MAGTAPE 
!	7 DT$_TU80, DC$_TAPE, V1, 0	! TU80 MAGTAPE 
!	8 DT$_TU81, DC$_TAPE, V1, 0	! TU81 MAGTAPE 
!	9 DT$_TA81, DC$_TAPE, V1, 0	! TA81 MAGTAPE 

	Array_addr = %LOC (Tape_codes(1))
	Array_size = Maxtypes

	Return
	End
