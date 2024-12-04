	Subroutine ERFPRC3INI ( Array_addr, Array_size )

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

C	This is the initialization module for the loadable image ERFPROC3.EXE.
C	After ERFPROC3 has been loaded this routine is called to return
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
C	V03-002	SAR0206		Sharon A. Reynolds		27-Feb-1984
C		Added bus errors and asynchronous write entry support (SBI).
C
C		SR0001		Sharon Reynolds			17-Mar-1983
C		Change tables to support SBI alert, soft and hard ECC's,
C		and volume mounts and dismounts.
C**

!
!  DEFINE ENTRY TYPES
! 
! 
	Parameter EMB$K_SA = 5			! SBI alert
	Parameter EMB$K_SE = 6			! Soft ECC error 
	Parameter EMB$K_HE = 8			! Hard ECC error 
	Parameter EMB$K_VM = 64			! Volume mount entries %x40
	Parameter EMB$K_VD = 65			! Volume dismount entries %x41
	Parameter EMB$K_BE = 4			! Bus errors 
	Parameter EMB$K_AW = 7			! Async write errors

	Parameter Zero = 0
	Parameter V1 = 1			! Device module version number

	Parameter	Maxtypes = 7

	Integer*4	Array_addr, Array_size

	Integer*2	Proc3_codes ( 4 * Maxtypes )

	Data		Proc3_codes /
	1 EMB$K_SA, zero, V1, 1,		! SBI alert entries
	2 EMB$K_SE, zero, V1, 1,		! Soft ECC error 
	3 EMB$K_HE, zero, V1, 1,		! Hard ECC error
	4 EMB$K_VM, zero, V1, 2,		! Volume mount entries
	5 EMB$K_VD, zero, V1, 2,		! Volume dismount entries
	6 EMB$K_BE,  zero, V1, 3,		! Bus error entries
	7 EMB$K_AW,  zero, V1, 3/		! Asynchronous write error 
						!  entries

	Array_addr = %LOC (proc3_codes(1))
	Array_size = Maxtypes

	Return
	End
