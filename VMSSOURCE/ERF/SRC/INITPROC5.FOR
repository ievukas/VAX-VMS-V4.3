	Subroutine ERFPRC5INI ( Array_addr, Array_size )

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

C	This is the initialization module for the loadable image ERFPROC5.EXE.
C	After ERFPROC5 has been loaded this routine is called to return
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
C		SR0001		Sharon Reynolds			17-Mar-1983
C		Change tables to support system power fail, system startup,
C		new errlog.sys file, time stamps, snderr, operator, and
C		network messages.
C**

!
!  DEFINE ENTRY TYPES
! 
! 
						! MESSAGE module
	Parameter EMB$K_SS = 39			! $Snderr message entry %X27
	Parameter EMB$K_OM = 41			! Operator message entry %X29
	Parameter EMB$K_NM = 42			! Network message entry %X2a

						! SYSPWRFAIL module
	Parameter EMB$K_PF = 34			! System power fail %X22

						! SYSTARTUP module
	Parameter EMB$K_CS = 32			! System startup entry %X20
						!  (cold start)
	Parameter EMB$K_WS = 36			! System powerfail recovery %x24
						!  (warm start)

						! NEWFILE module
	Parameter EMB$K_NF = 35			! New errlog file created entry%X23
	Parameter EMB$K_TS = 38			! Time stamp entry %X26




	Parameter Zero = 0
	Parameter V1 = 1			! Device module version number

	Parameter	Maxtypes = 8

	Integer*4	Array_addr, Array_size

	Integer*2	Proc5_codes ( 4 * Maxtypes )

	Data		Proc5_codes /
	1 EMB$K_SS, zero, V1, 1,		! $Snderr message entry
	2 EMB$K_OM, zero, V1, 1,		! Operator message entry
	3 EMB$K_NM, zero, V1, 1,		! Network message entry
	4 EMB$K_PF, zero, V1, 2,		! System power-fail
	5 EMB$K_CS, zero, V1, 3,		! System restart (cold)
	6 EMB$K_WS, zero, V1, 3,		! System power-fail reocvery
	7 EMB$K_NF, zero, V1, 4,		! New file created entry
	8 EMB$K_TS, zero, V1, 4/		! Time stamp entry
						

	Array_addr = %LOC (proc5_codes(1))
	Array_size = Maxtypes

	Return
	End

