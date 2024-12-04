	Subroutine ERFRTINI ( Array_addr, Array_size )

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
C++
C	Author:	Sharon Reynolds		Creation date:	29-Mar-1983
C
C	Functional Description:
C
C	This module initializes data structures that contain the
C	device class, type, version number, and the transfer vector
C	offsets for the devices supported by the ERFRLTIM image.
C
C	Modified By:
C
C	V03-001	SAR0127		Sharon A. Reynolds,	7-Sep-1983
C		Added initialization of a common text area for 
C		device registers used by both the DR750/DR780 modules.
C
C**
C--

C
C	Include files
C
	Include 'SRC$:DR32COM.FOR /nolist'

! 
!  REALTIME DEVICE CLASS AND TYPES
! 
	Parameter DC$_REALTIME = '00000060'X

	PARAMETER DT$_LPA11 = '00000001'X	!  LPA-11 
	PARAMETER DT$_DR780 = '00000002'X	!  DR780 
	PARAMETER DT$_DR750 = '00000003'X	!  DR750 
	PARAMETER DT$_DR11W = '00000004'X	!  DR11W 
	PARAMETER DT$_PCL11R = '00000005'X	!  PCL11 RECEIVER (CSS) 
	PARAMETER DT$_PCL11T = '00000006'X	!  PCL11 TRANSMTTER (CSS) 
!	PARAMETER DT$_DR11C = '00000007'X	!  DR11C PARALLEL INTERFACE 
	PARAMETER DT$_BS_DT07 = '00000008'X	!  PARALLEL INTERFACE ON DMF-32 
!	PARAMETER DT$_XP_PCL11B = '00000009'X	!  PCL-11B (DECNET and NONDECNET mode CSS)
!	PARAMETER DT$_XI_DR11C = '0000000A'X	!  PARALLEL INTERFACE ON DMF-32 

	Parameter V1 = 1			! device module version number

	Parameter	Maxtypes = 7

	Integer*4	Array_addr, Array_size

	Integer*2	Real_time_codes ( 4 * Maxtypes )

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

	Data		Real_time_codes /
	1 DT$_LPA11,     DC$_REALTIME, V1, 1,	!  LPA-11 
	2 DT$_DR780,     DC$_REALTIME, V1, 2,	!  DR780 
	3 DT$_DR750,     DC$_REALTIME, V1, 3,	!  DR750 
	4 DT$_DR11W,     DC$_REALTIME, V1, 4,	!  DR11W 
	5 DT$_PCL11R,    DC$_REALTIME, V1, 5,	!  PCL11 RECEIVER (CSS) 
	6 DT$_PCL11T,    DC$_REALTIME, V1, 6,	!  PCL11 TRANSMTTER (CSS) 
!	7 DT$_DR11C,     DC$_REALTIME, V1, 0,	!  DR11C PARALLEL INTERFACE 
	8 DT$_BS_DT07,   DC$_REALTIME, V1, 7/	!  UNIBUS SWITCH
!	8 DT$_XI_DR11C,  DC$_REALTIME, V1, 1	!  PARALLEL INTERFACE ON DMF-32 
!	9 DT$_XP_PCL11B, DC$_REALTIME, V1, 1	!  PCL-11B (DECNET and NONDECNET mode CSS)

	Array_addr = %LOC (Real_time_codes(1))
	Array_size = Maxtypes

C
C Initialize the DR32 common.
C
	V1DR_SL(0) = 'SUCCESSFUL COMPLETION*'
	V1DR_SL(1) = 'COMMAND STARTED*'
	V1DR_SL(2) = 'INVALID PTE*'
	V1DR_SL(3) = 'COMMAND IN*'
	V1DR_SL(4) = 'FAR-END DISABLED*'
	V1DR_SL(5) = 'SELF TEST*'
	V1DR_SL(6) = 'RANGE ERROR*'
	V1DR_SL(7) = 'UNALIGNED QUEUE ERROR*'
	V1DR_SL(8) = 'INVALID COMMAND PACKET*'
	V1DR_SL(9) = 'FREE QUEUE EMPTY*'
	V1DR_SL(10) = 'RANDOM ENABLE*'
	V1DR_SL(11) = 'INVALID DDI COMMAND*'
	V1DR_SL(12) = 'LENGTH ERROR*'
	V1DR_SL(13) = 'DRIVER ABORT*'
	V1DR_SL(14) = 'DDI PARITY ERROR*'

	V2DR_SL(21) = 'NON-EXISTENT REGISTER*'
	V2DR_SL(22) = 'LOG FAR-END REGISTERS*'
	V2DR_SL(23) = 'FAR-END ERROR*'

	V1DR_CB(1) = 'BASE VA OF COMMAND BLOCK*'
	V1DR_CB(2) = 'LENGTH OF COMMAND BLOCK (BYTES)*'
	V1DR_CB(3) = 'SVAPTE OF COMMAND BLOCK BASE VA*'

	V1DR_BB(1) = 'BASE VA OF BUFFER BLOCK*'
	V1DR_BB(2) = 'LENGTH OF BUFFER BLOCK (BYTES)*'
	V1DR_BB(3) = 'SVAPTE OF BUFFER BLOCK BASE VA*'

	Return
	End
