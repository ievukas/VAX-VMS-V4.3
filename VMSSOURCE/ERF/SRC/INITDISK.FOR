	Subroutine ERFDSKINI ( Array_addr, Array_size )

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

C	This is the initialization module for the loadable image ERFDISK.EXE.
C	After ERFDISK has been loaded this routine is called to return
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

!  DEFINE DEVICE TYPES
! 
!  DISK DEVICES
! 
	Parameter DC$_DISK = 1		!  DISK 

	Parameter DT$_RK06 =  1		! RK06 DISK 
	Parameter DT$_RK07 =  2		! RK07 DISK 
	Parameter DT$_RP04 =  3		! RP04 DISK 
	Parameter DT$_RP05 =  4		! RP05 DISK 
	Parameter DT$_RP06 =  5		! RP06 DISK 
	Parameter DT$_RM03 =  6		! RM03 DISK 
	Parameter DT$_RP07 =  7		! RP07 DISK 
	Parameter DT$_RP07HT =  8	! RP07 DISK WITH HEAD/TRACK 
	Parameter DT$_RL01 =  9		! RL01 DISK 
	Parameter DT$_RL02 =  10	! RL02 DISK 
	Parameter DT$_RX02 =  11	! RX02 DISK 
	Parameter DT$_RX04 =  12	! RX04 DISK 
	Parameter DT$_RM80 =  13	! RM80 DISK 
	Parameter DT$_TU58 =  14	! TU58 
	Parameter DT$_RM05 =  15	! RM05 DISK 
	Parameter DT$_RX01 =  16	! RX01 DISK 
	Parameter DT$_ML11 =  17	! ML11 disk 
	Parameter DT$_RB02 =  18	! R02 ON RB730 
	Parameter DT$_RB80 =  19	! R80 ON RB730 
	Parameter DT$_RA80 =  20	! R80 ON INTELLIGENT CONTROLLER 
	Parameter DT$_RA81 =  21	! R81 ON INTELLIGENT CONTROLLER 
	Parameter DT$_RA60 =  22	! PINON ON INTELLIGENT CONTROLLER 
	Parameter DT$_RZ01 =  23	! AZTEC REMOVABLE 
	Parameter DT$_RZF01 = 24	! AZTEC FIXED 

	Parameter V1 = 1			! device module version number

	Parameter	Maxtypes = 17

	Integer*4	Array_addr, Array_size

	Integer*2	Disk_codes ( 4 * Maxtypes )

	Data		Disk_codes /
	1 DT$_RK06, DC$_DISK, V1, 2,		! DM 1
	2 DT$_RK07, DC$_DISK, V1, 2,		! DM 2
	3 DT$_RP04, DC$_DISK, V1, 1,		! DB 3
	4 DT$_RP05, DC$_DISK, V1, 1,		! DB 4
	5 DT$_RP06, DC$_DISK, V1, 1,		! DB 5
	6 DT$_RM03, DC$_DISK, V1, 1,		! DR 6
	7 DT$_RP07, DC$_DISK, V1, 1,		! DR 7
!	8 DT$_RP07, DC$_DISK, V1, 1,		! DR
	9 DT$_RL01, DC$_DISK, V1, 3,		! DL 8
	1 DT$_RL02, DC$_DISK, V1, 3,		! DL 9
	2 DT$_RX02, DC$_DISK, V1, 4,		! DY 10
	3 DT$_RX04, DC$_DISK, V1, 4,		! D? 11
	4 DT$_RM80, DC$_DISK, V1, 1,		! DR 12
	5 DT$_TU58, DC$_DISK, V1, 6,		! DD 13
	6 DT$_RM05, DC$_DISK, V1, 1,		! DR 14
!	7 DT$_RX01, DC$_DISK, V1, 0,		! DX
	8 DT$_ML11, DC$_DISK, V1, 7,		! EM 15
	9 DT$_RB02, DC$_DISK, V1, 5,		! DQ 16
	1 DT$_RB80, DC$_DISK, V1, 5/		! DQ 17

!	2 DT$_RA80, DC$_DISK, V1, 0,
!	3 DT$_RA81, DC$_DISK, V1, 0,
!	4 DT$_RA60, DC$_DISK, V1, 0,
!	5 DT$_RZ01, DC$_DISK, V1, 0,
!	6 DT$_RZF01,DC$_DISK, V1, 0/

	Array_addr = %LOC (disk_codes(1))
	Array_size = Maxtypes

	Return
	End
