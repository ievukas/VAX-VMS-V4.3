	Subroutine ERFBUSINI ( Array_addr, Array_size )

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
C Modified by:
C
C	V03-002	SAR0238		Sharon A. Reynolds	28-Mar-1984
C		Added KMS3271 support.
C
C	V03-001	SAR0207		Sharon A. Reynolds	1-Mar-1984
C		Added the UDA50A and TU81P.
C
C--



	Parameter DC$_BUS = '00000080'X
	Parameter DC$_SCOM = '00000020'X
! 
!  BUS CLASS DEVICES
! 
	PARAMETER DT$_CI780 = '00000001'X	!  CI780 
	PARAMETER DT$_CI750 = '00000002'X	!  CI750 
	PARAMETER DT$_UDA50 = '00000003'X	!  UDA50 
	PARAMETER DT$_UDA50A = '00000003'X	!  UDA50A
	PARAMETER DT$_LESI = '00000005'X	!  LESI
	PARAMETER DT$_TU81P = '00000006'X	!  TU81P
	PARAMETER DT$_RDRX = '00000007'X	!  RDRX

	PARAMETER DT$_XK_3271 = '00000003'X	!  DUP-11 FOR 3271 PROTOCOL EMULATOR 
	PARAMETER DT$_SB_ISB11 = '00000007'X	!  ISB-11 DEC dataway 
	Parameter DT$_YQ_3271 = '00000012'X	!  KMS3271

	Parameter V1 = 1			! device module version number

	Parameter	Maxtypes = 10

	Integer*4	Array_addr, Array_size

	Integer*2	Bus_codes ( 4 * Maxtypes )

C
C The following table consist of:
C  DEVICE TYPE, DEVICE CLASS, MODULE VERSION, TRANSFER VECTOR OFFSET
C
C The MODULE VERSION is used to determine if the module in this image
C is the one to use. This is accomplished the root image comparing
C this value against the value in the master tables in the root image.
C
C The TRANSFER VECTOR OFFSET is the index to the transfer vector to
C be used for a specific device type. For example, the transfer
C vectors for the disk image are ordered as:
C	INITDISK 0
C	MASSDISK 1
C	RKDISK   2
C	RLDISK   3
C	ECT.

	Data		Bus_codes /
	1 DT$_CI780,	DC$_BUS, V1, 1,	!  CI780 
	2 DT$_CI750,	DC$_BUS, V1, 2,	!  CI750 
	3 DT$_UDA50,	DC$_BUS, V1, 3,	!  UDA50 
	4 DT$_UDA50A,	DC$_BUS, V1, 3,	!  UDA50A
	5 DT$_TU81P,	DC$_BUS, V1, 3,	!  TU81P
	5 DT$_LESI,	DC$_BUS, V1, 3, !  LESI
	5 DT$_RDRX,	DC$_BUS, V1, 3, !  RDRX
	
C The following two entries should be in a module for sync. communications
C devices. But since only these two devices log errors, it was frugal
C to create a loadable image just for them.

	6 DT$_XK_3271, DC$_SCOM, V1, 4,	!  DUP-11 FOR 3271 PROTOCOL EMULATOR 
	7 DT$_SB_ISB11, DC$_SCOM, V1, 5,!  ISB-11 DEC dataway 
	8 DT$_YQ_3271, DC$_SCOM, V1, 6/	!  KMS3271

	Array_addr = %LOC (Bus_codes(1))
	Array_size = Maxtypes

	Return
	End

