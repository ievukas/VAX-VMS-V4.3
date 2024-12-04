	Subroutine ERFPRC4INI ( Array_addr, Array_size )

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

C	This is the initialization module for the loadable image ERFPROC4.EXE.
C	After ERFPROC4 has been loaded this routine is called to return
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
C		Change tables to support UBA interrupts and errors,
c		MBA interrupts, and undefined interrupts.
C**

!
!  DEFINE ENTRY TYPES
! 
! 
						! UBAINT module
	Parameter EMB$K_UBA = 9			! 11/780 unibus adapter error

						! UBAERR module
	Parameter EMB$K_UE = 11			! 11/730 unibus error %XB

						! MBAINT module
	Parameter EMB$K_MBA = 12		! 11/780 massbus adapter error %XC

						! UNDEFINED module
	Parameter EMB$K_UI = 97			! Undefined interrupt %X61

	Parameter Zero = 0
	Parameter V1 = 1			! Device module version number

	Parameter	Maxtypes = 4

	Integer*4	Array_addr, Array_size

	Integer*2	Proc4_codes ( 4 * Maxtypes )

	Data		Proc4_codes /
	1 EMB$K_UBA, zero, V1, 1,		! 11/780 unibus adapter error
	2 EMB$K_UE, zero, V1, 2,		! 11/730 unibus error
	3 EMB$K_MBA, zero, V1, 3,		! 11/780 massbus adapter error
	4 EMB$K_UI, zero, V1, 4/		! Undefined interrupt

	Array_addr = %LOC (proc4_codes(1))
	Array_size = Maxtypes

	Return
	End
