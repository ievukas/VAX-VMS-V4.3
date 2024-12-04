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

c	Author	Brian Porter			Creation date	10-FEB-1982

c++
c	Functional description:
c
c	This module displays entries logged by pudriver and dudriver.
c
c	Modified by:
c
C	V03-016	SAR0291		Sharon A. Reynolds	7-Aug-1984
C		Fixed a bug in the starting buffer location for the
C		call the dumpreg in SDI_STI_ERRORS routine.
C
C	V03-015	SAR0287		Sharon A. Reynolds	6-Jul-1984
C		Added call for TU81 device dependent information.
C
C	V03-014	SAR0277		Sharon A. Reynolds	20-Jun-1984
C		Added TMSCP support.
C
C	V03-013	SAR0211		Sharon A. Reynolds,	21-Mar-1984
C		Fixed a bug in the conversion of the volume serial 
C		number in the MSLG$$L_VOL_SER routine.
C
C	V03-012	SAR0200		Sharon A. Reynolds,	20-Feb-1984
C		Added an SYE update that:
C		- Corrected formatting problems in AZTEC host access
C		errors.
C		- Added mscp 1.2 ECO. This added controller support for
C		?????????????????????????????.
C
C	V03-011	SAR0156		Sharon A. Reynolds,	11-Oct-1983
C		Added an SYE update that:
C		- Corrects the failure code output.
C		- Adds extra controllers to 'last fail' dispatching.
C		- Adds unknown device/controller specific code
C		  extensions.
C		- Adds AZTEC extensions.
C
C	V03-010	SAR0087		Sharon A. Reynolds,	20-Jun-1983
C		Changed the carriage control in the 'format' statements
C		for use with ERF.
C
c	v03-009	BP0009		Brian Porter,		28-FEB-1983
c		Added ra60 byte 15 descriptions.
c
c	v03-008	BP0008		Brian Porter,		03-JAN-1982
c		Corrected spelling error which resulted in the first
c		longword of the sdi status being displayed as zero's.
c
c	v03-007	BP0007		Brian Porter,		15-DEC-1982
c		Corrected symbol error value for data errors and
c		sdi data being incorrectly reported.
c
c	v03-006	BP0006		Brian Porter,		15-NOV-1982
c		Added ra60 etc.  Added sdi stuff to disk transfer error.
c
c	v03-005	BP0005		Brian Porter,		08-NOV-1982
c		Corrected symbol error value for data errors.
c
c	v03-004	BP0004		Brian Porter,		20-AUG-1982
c		Corrected fortran error.
c
c	v03-003	BP0003		Brian Porter,		04-MAY-1982
c		Corrected group bug.
c
c	v03-002	BP0002		Brian Porter,		22-APR-1982
c		Modified invalid command.
c
c	v03-001	BP0001		Brian Porter,		12-APR-1982
c		Added unit available, duplicate unit and invalid command
c		message support.
c**
c--

	Subroutine MSCP$$K_OP_AVATN (lun,expand)

	include 'src$:msghdr.for /nolist'


	byte		lun

	logical*1	expand

	integer*4	reserved1

	integer*2	mscp$w_unit
	integer*2	reserved2

	byte		mscp$b_opcode
	byte		reserved3

	integer*2	reserved4
	integer*2	mscp$w_mult_unt
	integer*2	mscp$w_unt_flags

	integer*4	undefined
	integer*4	mscp$l_unit_id1
	integer*4	mscp$l_unit_id2
	integer*4	mscp$l_media_id

	equivalence	(emb(38),reserved1)
	equivalence	(emb(42),mscp$w_unit)
	equivalence	(emb(44),reserved2)
	equivalence	(emb(46),mscp$b_opcode)
	equivalence	(emb(47),reserved3)
	equivalence	(emb(48),reserved4)
	equivalence	(emb(50),mscp$w_mult_unt)
	equivalence	(emb(52),mscp$w_unt_flags)
	equivalence	(emb(54),undefined)
	equivalence	(emb(58),mscp$l_unit_id1)
	equivalence	(emb(62),mscp$l_unit_id2)
	equivalence	(emb(66),mscp$l_media_id)



	call linchk (lun,1)

	write(lun,10)
10	format(' ',:)

	call mscp_first_twelve_bytes2 (lun,expand)



	Entry INVALID_MSCP$$K_OP_AVATN (lun,expand)



	call mscp$$w_mult_unt (lun,mscp$w_mult_unt)

	call mscp$$w_unt_flgs (lun,mscp$w_unt_flgs,expand)

	call linchk (lun,1)

	write(lun,15) undefined
15	format(' ',t8,'UNDEFINED',t24,z8.8)

	call mscp$$q_unit_id (lun,mscp$l_unit_id1,mscp$l_unit_id2,expand)

	call mscp$$l_media_id (lun,mscp$l_media_id,expand)

	return

	end



	Subroutine MSCP$$K_OP_ACPTH (lun,expand)


	include 'src$:msghdr.for /nolist'


	byte		lun

	logical*1	expand

	integer*4	reserved1

	integer*2	mscp$w_unit
	integer*2	reserved2

	byte		mscp$b_opcode
	byte		reserved3

	integer*2	reserved4

	equivalence	(emb(38),reserved1)
	equivalence	(emb(42),mscp$w_unit)
	equivalence	(emb(44),reserved2)
	equivalence	(emb(46),mscp$b_opcode)
	equivalence	(emb(47),reserved3)
	equivalence	(emb(48),reserved4)



	Entry MSCP$$K_OP_DUPUN (lun,expand)

	call linchk (lun,1)

	write(lun,10)
10	format(' ',:)

	call mscp_first_twelve_bytes2 (lun,expand)



	Entry INVALID_MSCP$$K_OP_ACPTH (lun,expand)

	Entry INVALID_MSCP$$K_OP_DUPUN (lun,expand)


	return

	end



	Subroutine MSLG$K_CNT_ERR (lun,packet_length)


	include 'src$:msghdr.for /nolist'
	include 'src$:emblmdef.for /nolist'


	byte		lun

	Integer*4	packet_length
	integer*4	mslg$l_cmd_ref

	integer*2	reserved
	integer*2	mslg$w_seq_num

	byte		mslg$b_format
	byte		mslg$b_flags

	integer*2	mslg$w_event

	integer*4	mslg$l_cnt_id1
	integer*4	mslg$l_cnt_id2

	byte		mslg$b_cnt_svr
	byte		mslg$b_cnt_hvr

	integer*2	lastfail_code

	equivalence	(emb(38),mslg$l_cmd_ref)
	equivalence	(emb(42),reserved)
	equivalence	(emb(44),mslg$w_seq_num)
	equivalence	(emb(46),mslg$b_format)
	equivalence	(emb(47),mslg$b_flags)
	equivalence	(emb(48),mslg$w_event)
	equivalence	(emb(50),mslg$l_cnt_id1)
	equivalence	(emb(54),mslg$l_cnt_id2)
	equivalence	(emb(58),mslg$b_cnt_svr)
	equivalence	(emb(59),mslg$b_cnt_hvr)
	equivalence	(emb(60),lastfail_code)


	call linchk (lun,1)

	write(lun,10)
10	format(' ',:)

	call mslg$$l_cmd_ref (lun,mslg$l_cmd_ref)
	call mslg$$w_seq_num (lun,mslg$w_seq_num)
	call mslg$$b_format (lun,mslg$b_format)

	call mslg$$b_flags (lun,mslg$b_flags)
	call mslg$$w_event (lun,mslg$w_event)
	call mslg$$q_cnt_id (lun,mslg$l_cnt_id1,mslg$l_cnt_id2)

	call mslg$$b_cnt_svr (lun,mslg$b_cnt_svr)
	call mslg$$b_cnt_hvr (lun,mslg$b_cnt_hvr)

C
C	Device dependent extensions...
C
	If (packet_length .GT. 22) then

	If (
	1 (emb$b_lm_class .EQ. '80'X)		! Bus device class
	1 .AND.
	1 (emb$b_lm_type .EQ. 3			! UDA50, UQPORT
	1 .OR.
	1 emb$b_lm_type .EQ. 4			! UDA50A
	1 .OR.
	1 emb$b_lm_type .EQ. 6)			! TU81P port
	1 ) then

	Call UDA_LASTFAIL_ERROR (lun,lastfail_code)
	Else

	Call LINCHK (lun,3)
	Write (lun,15) 'CONTROLLER DEPENDENT INFORMATION'
15	Format (/' ',a,/)

	Call DUMPREG (lun,(((packet_length - 22) +3)/4),emb(60))
	Endif
	Endif

	return
	end




	Subroutine MSLG$K_BUS_ADDR (lun,packet_length)


	include 'src$:msghdr.for /nolist'
	include 'src$:emblmdef.for /nolist'


	byte		lun

	Integer*4	packet_length
	integer*4	mslg$l_cmd_ref

	integer*2	reserved1
	integer*2	mslg$w_seq_num

	byte		mslg$b_format
	byte		mslg$b_flags

	integer*2	mslg$w_event

	integer*4	mslg$l_cnt_id1
	integer*4	mslg$l_cnt_id2

	byte		mslg$b_cnt_svr
	byte		mslg$b_cnt_hvr

	integer*2	reserved2

	integer*4	mslg$l_bus_addr

	equivalence	(emb(38),mslg$l_cmd_ref)
	equivalence	(emb(42),reserved1)
	equivalence	(emb(44),mslg$w_seq_num)
	equivalence	(emb(46),mslg$b_format)
	equivalence	(emb(47),mslg$b_flags)
	equivalence	(emb(48),mslg$w_event)
	equivalence	(emb(50),mslg$l_cnt_id1)
	equivalence	(emb(54),mslg$l_cnt_id2)
	equivalence	(emb(58),mslg$b_cnt_svr)
	equivalence	(emb(59),mslg$b_cnt_hvr)
	equivalence	(emb(60),reserved2)
	equivalence	(emb(62),mslg$l_bus_addr)


	call linchk (lun,1)

	write(lun,10)
10	format(' ',:)

	call mslg$$l_cmd_ref (lun,mslg$l_cmd_ref)
	call mslg$$w_seq_num (lun,mslg$w_seq_num)
	call mslg$$b_format (lun,mslg$b_format)

	call mslg$$b_flags (lun,mslg$b_flags)
	call mslg$$w_event (lun,mslg$w_event)
	call mslg$$q_cnt_id (lun,mslg$l_cnt_id1,mslg$l_cnt_id2)

	call mslg$$b_cnt_svr (lun,mslg$b_cnt_svr)
	call mslg$$b_cnt_hvr (lun,mslg$b_cnt_hvr)
	call mslg$$l_bus_addr (lun,mslg$l_bus_addr)

C
C	Device dependent extensions...
C
	If (packet_length .GT. 28) then

	Call LINCHK (lun,3)
	Write (lun,150) 'CONTROLLER DEPENDENT INFORMATION'
150	Format (/' ',a,/)

	If (
	1 (emb$b_lm_class .EQ. 1)		! Disk device class
	1 .AND.
	1 (emb$b_lm_type .EQ. 23		! AZTEC removable
	1 .OR.
	1 emb$b_lm_type .EQ. 24)		! AZTEC fixed
	1 ) then

	Call MSLG$K_BUS_ADDR_AZTEC (lun)

C
C	The IF-THEN-ELSE should be expanded at this point to
C	include additional "type" support.
C
	Else

	Call DUMPREG (lun,(((packet_length - 28) +3)/4),emb(66))
	Endif
	Endif

200	Continue

	return
	end



	Subroutine DISK_TAPE_TRANSFER_ERRORS (lun,packet_length)

	include 'src$:msghdr.for /nolist'
	include 'src$:emblmdef.for /nolist'


	byte		lun

	Integer*4	packet_length
	integer*4	mslg$l_cmd_ref

	integer*2	mslg$w_unit
	integer*2	mslg$w_seq_num

	byte		mslg$b_format
	byte		mslg$b_flags

	integer*2	mslg$w_event

	integer*4	mslg$l_cnt_id1
	integer*4	mslg$l_cnt_id2

	byte		mslg$b_cnt_svr
	byte		mslg$b_cnt_hvr

	integer*2	mslg$w_mult_unt

	integer*4	mslg$l_unit_id1
	integer*4	mslg$l_unit_id2

	byte		mslg$b_unit_svr
	byte		mslg$b_unit_hvr
	byte		mslg$b_level
	byte		mslg$b_retry

	integer*4	mslg$l_vol_ser
	integer*4	mslg$l_header

	equivalence	(emb(38),mslg$l_cmd_ref)
	equivalence	(emb(42),mslg$w_unit)
	equivalence	(emb(44),mslg$w_seq_num)
	equivalence	(emb(46),mslg$b_format)
	equivalence	(emb(47),mslg$b_flags)
	equivalence	(emb(48),mslg$w_event)
	equivalence	(emb(50),mslg$l_cnt_id1)
	equivalence	(emb(54),mslg$l_cnt_id2)
	equivalence	(emb(58),mslg$b_cnt_svr)
	equivalence	(emb(59),mslg$b_cnt_hvr)
	equivalence	(emb(60),mslg$w_mult_unt)
	equivalence	(emb(62),mslg$l_unit_id1)
	equivalence	(emb(66),mslg$l_unit_id2)
	equivalence	(emb(70),mslg$b_unit_svr)
	equivalence	(emb(71),mslg$b_unit_hvr)
	equivalence	(emb(72),mslg$b_level)
	equivalence	(emb(73),mslg$b_retry)
	equivalence	(emb(74),mslg$l_vol_ser)
	equivalence	(emb(78),mslg$l_header)


	call linchk (lun,1)

	write(lun,10)
10	format(' ',:)

	call mslg$$l_cmd_ref (lun,mslg$l_cmd_ref)
	call mslg$$w_unit (lun,mslg$w_unit,.true.)
	call mslg$$w_seq_num (lun,mslg$w_seq_num)

	call mslg$$b_format (lun,mslg$b_format)
	call mslg$$b_flags (lun,mslg$b_flags)
	call mslg$$w_event (lun,mslg$w_event)

	call mslg$$q_cnt_id (lun,mslg$l_cnt_id1,mslg$l_cnt_id2)
	call mslg$$b_cnt_svr (lun,mslg$b_cnt_svr)
	call mslg$$b_cnt_hvr (lun,mslg$b_cnt_hvr)

	call mslg$$w_mult_unt (lun,mslg$w_mult_unt)
	call mslg$$q_unit_id (lun,mslg$l_unit_id1,mslg$l_unit_id2,.true.)
	call mslg$$b_unit_svr (lun,mslg$b_unit_svr)

	call mslg$$b_unit_hvr (lun,mslg$b_unit_hvr)
	call mslg$$b_level (lun,mslg$b_level)
	call mslg$$b_retry (lun,mslg$b_retry)

C
C At this point the disk and tape transfer error entries differ,
C determine whether outputting a disk or tape transfer error and
C call the appropriate routines.
C
	If (mslg$b_format .EQ. 2) then			! Disk transfer error
	  call mslg$$l_vol_ser (lun,mslg$l_vol_ser)
	  call mslg$$l_header (lun,mslg$l_header)

	Else if (mslg$b_format .EQ. 5) then		! Tape transfer error
	  Call MSLG$$L_GAP_CNT (lun,emb(74))
	  Call FORMATTER_VERSIONS (lun,emb(78),emb(79))
	Endif


C
C	Device dependent extensions...
C
	If (packet_length .GT. 44) then

C
C Determine whether this entry applies to a TU81 transfer and 
C call the appropriate routine to decode/output the device 
C dependent information.
C
	If (
	1 (mslg$b_format .EQ. 5) 		! Tape transfer error
	1 .AND. 
	1 (emb$b_lm_type .EQ. 8)		! TU81 device
	1 ) then
	  Call TU81_SENSE_BYTES_DECODE (lun)
	  Return
	Endif

C
C Output the controller or device dependent information in a 
C hex longword format.
C
	Call LINCHK (lun,3)
	Write (lun,15) 'CONTROLLER OR DEVICE DEPENDENT INFORMATION'
15	Format (/' ',a,/)

	Call DUMPREG (lun,(((packet_length - 44) +3)/4),emb(82))
	Endif

	return
	end



	Subroutine SDI_STI_ERRORS (lun,packet_length)


	include 'src$:msghdr.for /nolist'
	include 'src$:emblmdef.for /nolist'


	byte		lun

	Integer*4	packet_length
	integer*4	mslg$l_cmd_ref

	integer*2	mslg$w_unit
	integer*2	mslg$w_seq_num

	byte		mslg$b_format
	byte		mslg$b_flags

	integer*2	mslg$w_event

	integer*4	mslg$l_cnt_id1
	integer*4	mslg$l_cnt_id2

	byte		mslg$b_cnt_svr
	byte		mslg$b_cnt_hvr

	integer*2	mslg$w_mult_unt

	integer*4	mslg$l_unit_id1
	integer*4	mslg$l_unit_id2

	byte		mslg$b_unit_svr
	byte		mslg$b_unit_hvr

	integer*2	reserved

	integer*4	mslg$l_vol_ser
	integer*4	mslg$l_header
	integer*4	mslg$l_sdi1
	integer*4	mslg$l_sdi2
	integer*4	mslg$l_sdi3

	equivalence	(emb(38),mslg$l_cmd_ref)
	equivalence	(emb(42),mslg$w_unit)
	equivalence	(emb(44),mslg$w_seq_num)
	equivalence	(emb(46),mslg$b_format)
	equivalence	(emb(47),mslg$b_flags)
	equivalence	(emb(48),mslg$w_event)
	equivalence	(emb(50),mslg$l_cnt_id1)
	equivalence	(emb(54),mslg$l_cnt_id2)
	equivalence	(emb(58),mslg$b_cnt_svr)
	equivalence	(emb(59),mslg$b_cnt_hvr)
	equivalence	(emb(60),mslg$w_mult_unt)
	equivalence	(emb(62),mslg$l_unit_id1)
	equivalence	(emb(66),mslg$l_unit_id2)
	equivalence	(emb(70),mslg$b_unit_svr)
	equivalence	(emb(71),mslg$b_unit_hvr)
	equivalence	(emb(72),reserved)
	equivalence	(emb(74),mslg$l_vol_ser)
	equivalence	(emb(78),mslg$l_header)
	equivalence	(emb(82),mslg$l_sdi1)
	equivalence	(emb(86),mslg$l_sdi2)
	equivalence	(emb(90),mslg$l_sdi3)


	call linchk (lun,1)
	write(lun,10)
10	format(' ',:)

	call mslg$$l_cmd_ref (lun,mslg$l_cmd_ref)
	call mslg$$w_unit (lun,mslg$w_unit,.true.)
	call mslg$$w_seq_num (lun,mslg$w_seq_num)

	call mslg$$b_format (lun,mslg$b_format)
	call mslg$$b_flags (lun,mslg$b_flags)
	call mslg$$w_event (lun,mslg$w_event)

	call mslg$$q_cnt_id (lun,mslg$l_cnt_id1,mslg$l_cnt_id2)
	call mslg$$b_cnt_svr (lun,mslg$b_cnt_svr)
	call mslg$$b_cnt_hvr (lun,mslg$b_cnt_hvr)

	call mslg$$w_mult_unt (lun,mslg$w_mult_unt)
	call mslg$$q_unit_id (lun,mslg$l_unit_id1,mslg$l_unit_id2,.true.)
	call mslg$$b_unit_svr (lun,mslg$b_unit_svr)
	call mslg$$b_unit_hvr (lun,mslg$b_unit_hvr)

	If (mslg$b_format .EQ. 3) then	! SDI comm error - mslg$k_sdi
	call mslg$$l_vol_ser (lun,mslg$l_vol_ser)
	call mslg$$l_header (lun,mslg$l_header)
	call mslg$$z_sdi (lun,mslg$l_sdi1,mslg$l_sdi2,mslg$l_sdi3)

	Else if (
	1 mslg$b_format .EQ. 6		! STI comm error - mslg$k_sti_err
	1 .OR.
	1 mslg$b_format .EQ. 7		! STI drive error - mslg$k_sti_del
	1 .OR.
	1 mslg$b_format .EQ. 8		! STI formatter error - mslg$k_sti_fel
	1 ) then
	  Call MSLG$$L_GAP_CNT (lun,emb(74))
	  Call FORMATTER_VERSIONS (lun,emb(78),emb(79))
	Endif

C
C	Device dependent extensions...
C
	If (packet_length .GT. 42) then

!	If (
!	1 emb$b_lm_class .EQ. 2		! Tape device class
!	1 .OR.
!	1 emb$b_lm_type .EQ. 6		! TA78 device
!	1 ) then
!
!	  If (mslg$b_format .EQ. 6) then	! STI comm or cmd failure
!	    Call TA78_UNSUCCESSFUL_RESPONSE (lun)
!
!	  Else if (mslg$b_format .EQ. 7) then	! STI drive error
!	    Call TA78_EXTENDED_DRIVE_STS (lun)
!
!	  Else if (mslg$b_format .EQ. 8) then	! STI formatter error
!	    Call TA78_EXTENDED_FORMATTER_STS (lun)
!	  Endif
!	Endif

	Call LINCHK (lun,3)
	Write (lun,15) 'DEVICE DEPENDENT INFORMATION'
15	Format (/' ',a,/)

	I = 94
	If ((mslg$b_format .GE. 6)  .AND.  (mslg$b_format .LE. 8)) then
	  I = 82
	Endif

	Call DUMPREG (lun,(((packet_length - 42) +3)/4),emb(I))
	Endif

	return
	end



	Subroutine MSLG$K_SML_DSK (lun,packet_length)


	include 'src$:msghdr.for /nolist'
	include 'src$:emblmdef.for /nolist'


	byte		lun

	Integer*4	packet_length
	integer*4	mslg$l_cmd_ref

	integer*2	mslg$w_unit
	integer*2	mslg$w_seq_num

	byte		mslg$b_format
	byte		mslg$b_flags

	integer*2	mslg$w_event

	integer*4	mslg$l_cnt_id1
	integer*4	mslg$l_cnt_id2

	byte		mslg$b_cnt_svr
	byte		mslg$b_cnt_hvr

	integer*2	mslg$w_mult_unt

	integer*4	mslg$l_unit_id1
	integer*4	mslg$l_unit_id2

	byte		mslg$b_unit_svr
	byte		mslg$b_unit_hvr

	integer*2	mslg$w_sde_cyl

	integer*4	mslg$l_vol_ser

	equivalence	(emb(38),mslg$l_cmd_ref)
	equivalence	(emb(42),mslg$w_unit)
	equivalence	(emb(44),mslg$w_seq_num)
	equivalence	(emb(46),mslg$b_format)
	equivalence	(emb(47),mslg$b_flags)
	equivalence	(emb(48),mslg$w_event)
	equivalence	(emb(50),mslg$l_cnt_id1)
	equivalence	(emb(54),mslg$l_cnt_id2)
	equivalence	(emb(58),mslg$b_cnt_svr)
	equivalence	(emb(59),mslg$b_cnt_hvr)
	equivalence	(emb(60),mslg$w_mult_unt)
	equivalence	(emb(62),mslg$l_unit_id1)
	equivalence	(emb(66),mslg$l_unit_id2)
	equivalence	(emb(70),mslg$b_unit_svr)
	equivalence	(emb(71),mslg$b_unit_hvr)
	equivalence	(emb(72),mslg$w_sde_cyl)
	equivalence	(emb(74),mslg$l_vol_ser)


	call linchk (lun,1)

	write(lun,10)
10	format(' ',:)

	call mslg$$l_cmd_ref (lun,mslg$l_cmd_ref)

	call mslg$$w_unit (lun,mslg$w_unit,.true.)

	call mslg$$w_seq_num (lun,mslg$w_seq_num)

	call mslg$$b_format (lun,mslg$b_format)

	call mslg$$b_flags (lun,mslg$b_flags)

	call mslg$$w_event (lun,mslg$w_event)

	call mslg$$q_cnt_id (lun,mslg$l_cnt_id1,mslg$l_cnt_id2)

	call mslg$$b_cnt_svr (lun,mslg$b_cnt_svr)

	call mslg$$b_cnt_hvr (lun,mslg$b_cnt_hvr)

	call mslg$$w_mult_unt (lun,mslg$w_mult_unt)

	call mslg$$q_unit_id (lun,mslg$l_unit_id1,mslg$l_unit_id2,.true.)

	call mslg$$b_unit_svr (lun,mslg$b_unit_svr)

	call mslg$$b_unit_hvr (lun,mslg$b_unit_hvr)

	call mslg$$w_sde_cyl (lun,mslg$w_sde_cyl)

	call mslg$$l_vol_ser (lun,mslg$l_vol_ser)

C
C	Device dependent extensions...
C	
	If (packet_length .GT. 40) then

	Call LINCHK (lun,3)
	Write (lun,15) 'CONTROLLER OR DEVICE DEPENDENT INFORMATION'
15	Format (/' ',a,/)

	If (
	1 emb$b_lm_type .EQ. 23
	1 .OR.
	1 emb$b_lm_type .EQ. 24
	1 ) then

	Call MSLG$K_SML_DSK_AZTEC (lun)

C
C	The IF-THEN-ELSE should be expanded at this point to
C	include additional "type" support.
C
	Else

	Call DUMPREG (lun,(((packet_length - 40) +3)/4),emb(78))
	Endif
	Endif

	return
	end



	Subroutine MSCP$$K_OP_ABORT (lun,expand)


	include 'src$:msghdr.for /nolist'


	byte		lun

	logical*1	expand

	integer*4	mscp$l_cmd_ref

	integer*2	mscp$w_unit
	integer*2	reserved1

	byte		mscp$b_opcode
	byte		reserved2

	integer*2	mscp$w_modifier

	integer*4	mscp$l_out_ref

	equivalence	(emb(38),mscp$l_cmd_ref)
	equivalence	(emb(42),mscp$w_unit)
	equivalence	(emb(44),reserved1)
	equivalence	(emb(46),mscp$b_opcode)
	equivalence	(emb(47),reserved2)
	equivalence	(emb(48),mscp$w_modifier)
	equivalence	(emb(50),mscp$l_out_ref)



	Entry MSCP$$K_OP_GTCMD (lun,expand)

	Entry MSCP$$K_OP_GTUNT (lun,expand)



	call linchk (lun,1)

	write(lun,5)
5	format(' ',:)

	call mscp_first_twelve_bytes1 (lun,expand)



	Entry INVALID_MSCP$$K_OP_ABORT (lun,expand)

	Entry INVALID_MSCP$$K_OP_GTCMD (lun,expand)

	Entry INVALID_MSCP$$K_OP_GTUNT (lun,expand)



	if (mscp$b_opcode .eq. 3) goto 15

	call linchk (lun,1)

	write(lun,10) mscp$l_out_ref
10	format(' ',t8,'MSCP$L_OUT_REF',t24,z8.8)

15	return

	end



	Subroutine MSCP$$K_OP_ACCES (lun,expand)


	include 'src$:msghdr.for /nolist'


	byte		lun

	logical*1	expand

	integer*4	mscp$l_cmd_ref

	integer*2	mscp$w_unit
	integer*2	reserved1

	byte		mscp$b_opcode
	byte		reserved2

	integer*2	mscp$w_modifier

	integer*4	mscp$l_byte_cnt
	integer*4	mscp$l_rbn
	integer*4	reserved3(3)
	integer*4	mscp$z_buffer(3)
	integer*4	mscp$l_lbn

	equivalence	(emb(38),mscp$l_cmd_ref)
	equivalence	(emb(42),mscp$w_unit)
	equivalence	(emb(44),reserved1)
	equivalence	(emb(46),mscp$b_opcode)
	equivalence	(emb(47),reserved2)
	equivalence	(emb(48),mscp$w_modifier)

	equivalence	(emb(50),mscp$l_byte_cnt)
	equivalence	(emb(50),mscp$l_rbn)

	equivalence	(emb(54),reserved3)
	equivalence	(emb(54),mscp$z_buffer)
	equivalence	(emb(66),mscp$l_lbn)

	integer*4	compress4


	Entry MSCP$$K_OP_CMPCD (lun,expand)

	Entry MSCP$$K_OP_COMP (lun,expand)

	Entry MSCP$$K_OP_ERASE (lun,expand)

	Entry MSCP$$K_OP_FLUSH (lun,expand)

	Entry MSCP$$K_OP_READ (lun,expand)

	Entry MSCP$$K_OP_REPLC (lun,expand)

	Entry MSCP$$K_OP_WRITE (lun,expand)


	call linchk (lun,1)

	write(lun,5)
5	format(' ',:)

	call mscp_first_twelve_bytes1 (lun,expand)



	Entry INVALID_MSCP$$K_OP_ACCES (lun,expand)

	Entry INVALID_MSCP$$K_OP_CMPCD (lun,expand)

	Entry INVALID_MSCP$$K_OP_COMP (lun,expand)

	Entry INVALID_MSCP$$K_OP_ERASE (lun,expand)

	Entry INVALID_MSCP$$K_OP_FLUSH (lun,expand)

	Entry INVALID_MSCP$$K_OP_READ (lun,expand)

	Entry INVALID_MSCP$$K_OP_REPLC (lun,expand)

	Entry INVALID_MSCP$$K_OP_WRITE (lun,expand)


	call linchk (lun,1)

	if (mscp$b_opcode .eq. 20) then

	write(lun,7) mscp$l_rbn
7	format(' ',t8,'MSCP$L_RBN',t24,z8.8)

	if (expand) then

	call linchk (lun,1)

	write(lun,8) mscp$l_rbn
8	format(' ',t40,'REPLACEMENT BLOCK #',i<compress4 (mscp$l_rbn)>,'.')
	endif
	else

	write(lun,10) mscp$l_byte_cnt
10	format(' ',t8,'MSCP$L_BYTE_CNT',t24,z8.8)

	if (expand) then

	call linchk (lun,1)

	write(lun,11) mscp$l_byte_cnt
11	format(' ',t40,'BYTE COUNT, ',i<compress4 (mscp$l_byte_cnt)>,
	1 '. BYTE(S)')
	endif
	endif

	if (
	1 mscp$b_opcode .eq. 32
	1 .or.
	1 mscp$b_opcode .eq. 33
	1 .or.
	1 mscp$b_opcode .eq. 34
	1 ) then

	call mscp$$z_buffer (lun,mscp$z_buffer)
	else

	call mscp_reservedq (lun,reserved3)

	call linchk (lun,4)

	write(lun,15) reserved3(3)
15	format(' ',t24,z8.8)
	endif

	call linchk (lun,1)

	write(lun,20) mscp$l_lbn
20	format(' ',t8,'MSCP$L_LBN',t24,z8.8)

	if (expand) then

	If (LIB$EXTZV(6,2,mscp$b_opcode) .EQ. 0) then

	call linchk (lun,1)

	write(lun,22) mscp$l_lbn
22	format(' ',t40,'LOGICAL BLOCK #',i<compress4 (mscp$l_lbn)>,'.')
	endif
	Endif

	return
	end



	Subroutine MSCP$$K_OP_AVAIL (lun,expand)


	include 'src$:msghdr.for /nolist'


	byte		lun

	logical*1	expand

	integer*4	mscp$l_cmd_ref

	integer*2	mscp$w_unit
	integer*2	reserved1

	byte		mscp$b_opcode
	byte		reserved2

	integer*2	mscp$w_modifier

	equivalence	(emb(38),mscp$l_cmd_ref)
	equivalence	(emb(42),mscp$w_unit)
	equivalence	(emb(44),reserved1)
	equivalence	(emb(46),mscp$b_opcode)
	equivalence	(emb(47),reserved2)
	equivalence	(emb(48),mscp$w_modifier)


	Entry MSCP$$K_OP_DTACP (lun,expand)

	Entry MSCP$$K_OP_SEREX (lun,expand)


	call linchk (lun,1)

	write(lun,5)
5	format(' ',:)

	call mscp_first_twelve_bytes1 (lun,expand)


	Entry INVALID_MSCP$$K_OP_AVAIL (lun,expand)

	Entry INVALID_MSCP$$K_OP_DTACP (lun,expand)


	return
	end



	Subroutine MSCP$$K_OP_ONLIN (lun,expand)


	include 'src$:msghdr.for /nolist'


	byte		lun

	logical*1	expand

	integer*4	mscp$l_cmd_ref

	integer*2	mscp$w_unit
	integer*2	reserved1

	byte		mscp$b_opcode
	byte		reserved2

	integer*2	mscp$w_modifier
	integer*2	reserved3
	integer*2	mscp$w_unt_flgs

	integer*4	reserved4(3)
	integer*4	mscp$l_dev_parm

	integer*2	mscp$w_shdw_unt
	integer*2	mscp$w_copy_spd

	equivalence	(emb(38),mscp$l_cmd_ref)
	equivalence	(emb(42),mscp$w_unit)
	equivalence	(emb(44),reserved1)
	equivalence	(emb(46),mscp$b_opcode)
	equivalence	(emb(47),reserved2)
	equivalence	(emb(48),mscp$w_modifier)
	equivalence	(emb(50),reserved3)
	equivalence	(emb(52),mscp$w_unt_flgs)
	equivalence	(emb(54),reserved4)
	equivalence	(emb(66),mscp$l_dev_parm)
	equivalence	(emb(70),mscp$w_shdw_unt)
	equivalence	(emb(72),mscp$w_copy_spd)


	Entry MSCP$$K_OP_STUNT (lun,expand)


	call linchk (lun,1)

	write(lun,5)
5	format(' ',:)

	call mscp_first_twelve_bytes1 (lun,expand)


	Entry INVALID_MSCP$$K_OP_ONLIN (lun,expand)

	Entry INVALID_MSCP$$K_OP_STUNT (lun,expand)


	call mscp$$w_unt_flgs (lun,mscp$w_unt_flgs,expand)

	call mscp_reservedq (lun,reserved4)

	call linchk (lun,1)

	write(lun,10) reserved4(3)
10	format(' ',t24,z8.8)

	call mscp$$l_dev_parm (lun,mscp$l_dev_parm)

	call mscp$$w_shdw_unt (lun,mscp$w_shdw_unt,expand)

	call mscp$$w_copy_spd (lun,mscp$w_copy_spd)

	return
	end



	Subroutine MSCP$$K_OP_STCON (lun,expand)


	include 'src$:msghdr.for /nolist'


	byte		lun

	logical*1	expand

	integer*4	mscp$l_cmd_ref

	integer*2	mscp$w_unit
	integer*2	reserved1

	byte		mscp$b_opcode
	byte		reserved2

	integer*2	mscp$w_modifier
	integer*2	mscp$w_version
	integer*2	mscp$w_cnt_flgs
	integer*2	mscp$w_hst_tmo
	integer*2	reserved3

	integer*4	mscp$l_time1
	integer*4	mscp$l_time2

	equivalence	(emb(38),mscp$l_cmd_ref)
	equivalence	(emb(42),mscp$w_unit)
	equivalence	(emb(44),reserved1)
	equivalence	(emb(46),mscp$b_opcode)
	equivalence	(emb(47),reserved2)
	equivalence	(emb(48),mscp$w_modifier)
	equivalence	(emb(50),mscp$w_version)
	equivalence	(emb(52),mscp$w_cnt_flgs)
	equivalence	(emb(54),mscp$w_hst_tmo)
	equivalence	(emb(56),reserved3)
	equivalence	(emb(58),mscp$l_time1)
	equivalence	(emb(60),mscp$l_time2)


	call linchk (lun,1)

	write(lun,5)
5	format(' ',:)

	call mscp_first_twelve_bytes1 (lun,expand)


	Entry INVALID_MSCP$$K_OP_STCON (lun,expand)


	call mscp$$w_version (lun,mscp$w_version)

	call mscp$$w_cnt_flgs (lun,mscp$w_cnt_flgs,expand)

	call mscp$$w_hst_tmo (lun,mscp$w_hst_tmo,expand)

	call mscp_reservedw (lun,reserved3)

	call mscp$$q_time (lun,mscp$l_time1,expand)

	return
	end



	Subroutine MSLG$$L_CMD_REF (lun,command_reference_number)


	byte		lun

	integer*4	command_reference_number


	call linchk (lun,1)

	write(lun,10) command_reference_number
10	format(' ',t8,'MSLG$L_CMD_REF',t24,z8.8)

	return



	Entry MSCP$$L_CMD_REF (lun,command_reference_number)


	call linchk (lun,1)

	write(lun,15) command_reference_number
15	format(' ',t8,'MSCP$L_CMD_REF',t24,z8.8)

	return
	end



	Subroutine MSLG$$W_UNIT (lun,unit_number,expand)


	byte		lun

	integer*2	unit_number

	logical*1	expand

	integer*4	unit
	integer*4	compress4


	call linchk (lun,2)

	write(lun,10) 'MSLG$W_UNIT',unit_number
10	format(' ',t8,a,t28,z4.4)

15	if (expand) then

	unit = lib$extzv(0,16,unit_number)

	write(lun,20) unit
20	format(' ',t40,'UNIT #',i<compress4 (unit)>,'.')
	endif

	return



	Entry MSCP$$W_UNIT (lun,unit_number,expand)


	call linchk (lun,2)

	write(lun,10) 'MSCP$W_UNIT',unit_number

	goto 15

	end



	Subroutine MSLG$$W_SEQ_NUM (lun,sequence_number)


	byte		lun

	integer*2	sequence_number

	integer*4	sequence
	integer*4	compress4


	call linchk (lun,2)

	write(lun,10) sequence_number
10	format(' ',t8,'MSLG$W_SEQ_NUM',t28,z4.4)

	sequence = lib$extzv(0,16,sequence_number)

	write(lun,20) sequence
20	format(' ',t40,'SEQUENCE #',i<compress4 (sequence)>,'.')

	return
	end



	Subroutine MSLG$$B_FORMAT (lun,format)

	byte		lun
	byte		format

	integer*4	message_format
	integer*4	compress4


	call linchk (lun,2)
	write(lun,10) format
10	format(' ',t8,'MSLG$B_FORMAT',t30,z2.2)

	message_format = lib$extzv(0,8,format)

	if (message_format .eq. 0) then
	write(lun,20) 'CONTROLLER ERROR'
20	format(' ',t40,a)

	else if (message_format .eq. 1) then
	write(lun,20) 'HOST MEMORY ACCESS ERROR'

	else if (message_format .eq. 2) then
	write(lun,20) 'DISK TRANSFER ERROR'

	else if (message_format .eq. 3) then
	write(lun,20) '"SDI" ERROR'

	else if (message_format .eq. 4) then
	write(lun,20) '"SMALL DISK" ERROR'

	Else if (message_format .EQ. 5) then
	Write (lun,20) 'TAPE TRANSFER ERROR'

	Else if (message_format .EQ. 6) then
	Write (lun,20) '"STI" ERROR'

	Else if (message_format .EQ. 7) then
	Write (lun,20) '"STI" DRIVE ERROR'

	Else if (message_format .EQ. 8) then
	Write (lun,20) '"STI" FORMATTER ERROR'

	else
C
C Unknown message format, output it decimal.
C
	write(lun,25) message_format
25	format(' ',t40,'FORMAT #',i<compress4 (message_format)>,'.')
	endif

	return
	end



	Subroutine MSLG$$B_FLAGS (lun,error_log_message_flags)


	byte		lun
	byte		error_log_message_flags

	character*22	v1error_log_message_flags(0:0)
	data		v1error_log_message_flags(0) /'SEQUENCE NUMBER RESET*'/

	character*21	v2error_log_message_flags(6:7)
	data		v2error_log_message_flags(6) /'OPERATION CONTINUING*'/
	data		v2error_log_message_flags(7) /'OPERATION SUCCESSFUL*'/


	call linchk (lun,1)

	write(lun,10) error_log_message_flags
10	format(' ',t8,'MSLG$B_FLAGS',t30,z2.2)

	call output (lun,lib$extzv(0,8,error_log_message_flags),
	1 v1error_log_message_flags,0,0,0,'0')

	call output (lun,lib$extzv(0,8,error_log_message_flags),
	1 v2error_log_message_flags,6,6,7,'0')

	return
	end



	Subroutine MSCP$$B_FLAGS (lun,end_message_flags,expand)


	byte		lun
	byte		end_message_flags

	logical*1	expand

	character*21	v1end_message_flags(4:7)
	data		v1end_message_flags(4)	/'SERIOUS EXCEPTION*'/
	data		v1end_message_flags(5)	/'ERROR LOG GENERATED*'/
	data		v1end_message_flags(6)	/'BAD BLOCK UNREPORTED*'/
	data		v1end_message_flags(7)	/'BAD BLOCK REPORTED*'/


	call linchk (lun,1)

	write(lun,10) end_message_flags
10	format(' ',t8,'MSCP$B_FLAGS',t30,z2.2)

	if (expand) then

	call output (lun,end_message_flags,v1end_message_flags,4,4,7,'0')
	endif

	return
	end



	Subroutine MSLG$$W_EVENT (lun,event_code)


	byte		lun

	integer*2	event_code

	integer*4	code
	integer*4	sub_code
	integer*4	compress4

	logical*1	valid_subcode


	call linchk (lun,1)

	write(lun,10) event_code
10	format(' ',t8,'MSLG$W_EVENT',t28,z4.4)


	Entry AZTEC_FULL_ERROR_CODE1 (lun,event_code)

	Call STATUS_AND_EVENT_CODES (lun)

	Return
	End 



	Subroutine MSLG$$Q_CNT_ID (lun,controller_id1,controller_id2)


	byte		lun

	integer*4	controller_id1
	integer*4	controller_id2
	integer*4	unique_identifier_high
	integer*4	class
	integer*4	model

	character*24	subsystem_class(3)
	data		subsystem_class(1)	/'MASS STORAGE CONTROLLER*'/
	data		subsystem_class(2)	/'DISK CLASS DEVICE*'/
	data		subsystem_class(3)	/'TAPE CLASS DEVICE*'/

	character*27	class_model(11)
	data		class_model(1)		/'HSC50*'/
	data		class_model(2)		/'UDA50*'/
	data		class_model(3)		/'RC25*'/
	data		class_model(4)		/'VMS (SOFTWARE MSCP SERVER*'/
	data		class_model(5)		/'TU81P*'/
	data		class_model(6)		/'UDA50A*'/
	data		class_model(7)		/'RD51*'/
	data		class_model(8)		/'TOPS 10/20 MSCP SERVER*'/
	data		class_model(9)		/'TK50*'/
	data		class_model(10)		/'RUX50*'/
	data		class_model(11)		/'RC26*'/

	integer*4	compressc



	call linchk (lun,2)

	write(lun,10) controller_id1,controller_id2
10	format(' ',t8,'MSLG$Q_CNT_ID',t24,z8.8,/,t24,z8.8)



	Entry CDDB$Q_CNTRLID (lun,controller_id1,controller_id2)


	unique_identifier_high = lib$extzv (0,16,controller_id2)

	call linchk (lun,1)

	write(lun,15) unique_identifier_high,controller_id1
15	format(' ',t40,'UNIQUE IDENTIFIER, ',z4.4,z8.8)

	class = lib$extzv(24,8,controller_id2)
	model = lib$extzv(16,8,controller_id2)

	if (
	1 class .gt. 0
	1 .and.
	1 class .le. 3
	1 ) then

	call linchk (lun,1)

	write(lun,20) subsystem_class(class)
20	format(' ',t40,a<compressc (subsystem_class(class))>)
	endif

	if (
	1 model .gt. 0
	1 .and.
	1 model .le. 7
	1 ) then

	call linchk (lun,1)

	write(lun,25) class_model(model)
25	format(' ',t40,a<compressc (class_model(model))>)
	endif

	return
	end


	Subroutine MSLG$$B_CNT_SVR (lun,controller_software_version)


	byte		lun
	byte		controller_software_version

	integer*4	software_version
	integer*4	compress4


	software_version = lib$extzv(0,8,controller_software_version)

	call linchk (lun,2)

	write(lun,10) controller_software_version,software_version
10	format(' ',t8,'MSLG$B_CNT_SVR',t30,z2.2,/,
	1 t40,'CONTROLLER SOFTWARE VERSION #',
	1 i<compress4 (software_version)>,'.')

	return
	end



	Subroutine MSLG$$B_CNT_HVR (lun,controller_hardware_version)


	byte		lun
	byte		controller_hardware_version

	integer*4	hardware_version
	integer*4	compress4


	hardware_version = lib$extzv(0,8,controller_hardware_version)

	call linchk (lun,2)

	write(lun,10) controller_hardware_version,hardware_version
10	format(' ',t8,'MSLG$B_CNT_HVR',t30,z2.2,/,
	1 t40,'CONTROLLER HARDWARE REVISION #',
	1 i<compress4 (hardware_version)>,'.')

	return
	end



	Subroutine MSLG$$W_MULT_UNT (lun,multi_unit_code)


	byte		lun

	integer*2	multi_unit_code


	call linchk (lun,1)

	write(lun,10) 'MSLG$W_MULT_UNT',multi_unit_code
10	format(' ',t8,a,t28,z4.4)

	return



	Entry MSCP$$W_MULT_UNT (lun,multi_unit_code)


	call linchk (lun,1)

	write(lun,10) 'MSCP$W_MULT_UNT',multi_unit_code

	return
	end



	Subroutine MSLG$$Q_UNIT_ID (lun,unit_id1,unit_id2,expand)


	byte		lun

	integer*4	unit_id1
	integer*4	unit_id2

	logical*1	expand

	integer*4	class
	integer*4	model
	integer*4	unique_identifier_high
	integer*4	compressc

	character*24	subsystem_class(4)
	data		subsystem_class(1)	/'MASS STORAGE CONTROLLER*'/
	data		subsystem_class(2)	/'DISK CLASS DEVICE*'/
	data		subsystem_class(3)	/'TAPE CLASS DEVICE*'/
	data		subsystem_class(4)	/'DISK CLASS DEVICE*'/


	call linchk (lun,2)

	write(lun,5) 'MSLG$Q_UNIT_ID',unit_id1,unit_id2
5	format(' ',t8,a,t24,z8.8,/,t24,z8.8)

10	continue

	if (expand) then

	unique_identifier_high = lib$extzv (0,16,unit_id2)

	call linchk (lun,1)

	write(lun,15) unique_identifier_high,unit_id1
15	format(' ',t40,'UNIQUE IDENTIFIER, ',z4.4,z8.8)

	class = lib$extzv(24,8,unit_id2)
	model = lib$extzv(16,8,unit_id2)

	if (
	1 class .gt. 0
	1 .and.
	1 class .le. 4
	1 ) then

	call linchk (lun,1)

	write(lun,20) subsystem_class(class)
20	format(' ',t40,a<compressc (subsystem_class(class))>)
	endif

	if (class .eq. 2) then

	if (model .eq. 1) then

	call linchk (lun,1)
	write(lun,25) 'RA80'
25	format(' ',t40,a)

	else if (model .eq. 2) then

	call linchk (lun,1)
	write(lun,25) 'RC25'

	else if (model .eq. 3) then

	call linchk (lun,1)
	write(lun,25) 'RCF25'

	else if (model .eq. 4) then

	call linchk (lun,1)
	write(lun,25) 'RA60'

	else if (model .eq. 5) then

	call linchk (lun,1)
	write(lun,25) 'RA81'

	else if (model .eq. 6) then

	call linchk (lun,1)
	write(lun,25) 'RD51'

	else if (model .eq. 7) then

	call linchk (lun,1)
	write(lun,25) 'RX50'

	else if (model .eq. 8) then

	call linchk (lun,1)
	write(lun,25) 'RD52'

	else if (model .eq. 9) then

	call linchk (lun,1)
	write(lun,25) 'RD53'

	else if (model .eq. 10) then

	call linchk (lun,1)
	write(lun,25) 'RD26'

	else if (model .eq. 11) then

	call linchk (lun,1)
	write(lun,25) 'RA82'

	else if (model .eq. 12) then

	call linchk (lun,1)
	write(lun,25) 'RC26'

	else if (model .eq. 13) then

	call linchk (lun,1)
	write(lun,25) 'RCF26'
	endif

	else if (class .eq. 3) then

	if (model .eq. 1) then

	call linchk (lun,1)
	write(lun,25) 'TU78'

	else if (model .eq. 2) then

	call linchk (lun,1)
	write(lun,25) 'TU81'
	endif
	endif
	endif

	return


	Entry MSCP$$Q_UNIT_ID (lun,unit_id1,unit_id2,expand)


	call linchk (lun,2)

	write(lun,5) 'MSCP$Q_UNIT_ID',unit_id1,unit_id2

	goto 10

	end



	Subroutine MSLG$$B_UNIT_SVR (lun,unit_software_version)


	byte		lun
	byte		unit_software_version

	integer*4	software_version
	integer*4	compress4


	software_version = lib$extzv(0,8,unit_software_version)

	call linchk (lun,2)

	write(lun,10) unit_software_version,software_version
10	format(' ',t8,'MSLG$B_UNIT_SVR',t30,z2.2,/,
	1 t40,'UNIT SOFTWARE VERSION #',
	1 i<compress4 (software_version)>,'.')

	return
	end


	Subroutine MSLG$$B_UNIT_HVR (lun,unit_hardware_version)


	byte		lun
	byte		unit_hardware_version

	integer*4	hardware_version
	integer*4	compress4


	hardware_version = lib$extzv(0,8,unit_hardware_version)

	call linchk (lun,2)

	write(lun,10) unit_hardware_version,hardware_version
10	format(' ',t8,'MSLG$B_UNIT_HVR',t30,z2.2,/,
	1 t40,'UNIT HARDWARE REVISION #',i<compress4 (hardware_version)>,'.')

	return
	end



	Subroutine MSLG$$L_VOL_SER (lun,volume_serial_number)

	byte		lun

	External	Sys$fao

	Logical*4	Sys$fao
	Logical*1	Status

	Character*10	cnvrted_serial_number

	integer*4	volume_serial_number
	integer*4	compress4


	call linchk (lun,2)

	Status = SYS$FAO( '!ZL',,cnvrted_serial_number,
	1			%VAL(volume_serial_number) )

	If (.NOT. status) then
	Call LIB$SIGNAL (status)
	Endif

	write(lun,10) volume_serial_number,cnvrted_serial_number
10	format(' ',t8,'MSLG$L_VOL_SER',t24,z8.8,/,
	1 t40,'VOLUME SERIAL #',A10,'.')

	return
	end



	Subroutine MSLG$$L_GAP_CNT (lun,gap_cnt)

	Byte		lun

	Integer*4	gap_cnt, COMPRESS4, count

	Count = LIB$EXTZV (0,16,gap_cnt)

	Call LINCHK (lun,1)
	Write (lun,10) 'MSLG$L_GAP_CNT',gap_cnt,count
10	Format (' ',T8,A,T24,Z8.8,/,
	1 T40,'GAP COUNT = ',I<COMPRESS4 (count)>,'.')

	Return
	End


	Subroutine FORMATTER_VERSIONS (lun,s_vers,h_vers)

	Byte		lun, h_vers, s_vers

	Integer*4	COMPRESS4, version 


	Version = LIB$EXTZV (0,8,s_vers)

	Call LINCHK (lun,4)

	Write (lun,10) 'MSLG$B_FMTR_SVR',s_vers,version
10	Format (' ',T8,A,T30,Z2.2,/,T40,
	1 'FORMATTER SOFTWARE VERSION #',I<COMPRESS4 (version)>,'.')

	Version = LIB$EXTZV (0,8,h_vers)

	Write (lun,15) 'MSLG$B_FMTR_HVR',h_vers,version
15	Format (' ',T8,A,T30,Z2.2,/,T40,
	1 'FORMATTER HARDWARE VERSION #',I<COMPRESS4 (version)>,'.')

	Return
	End



	Subroutine MSLG$$L_BUS_ADDR (lun,bus_address)


	byte		lun

	integer*4	bus_address


	call linchk (lun,1)

	write(lun,10) bus_address
10	format(' ',t8,'MSLG$L_BUS_ADDR',t24,z8.8)

	call calc_map (lun,16,bus_address,bus_address)

	return
	end



	Subroutine MSLG$$B_LEVEL (lun,level)


	byte		lun
	byte		level


	call linchk (lun,1)

	write(lun,10) level
10	format(' ',t8,'MSLG$B_LEVEL',t30,z2.2)

	return
	end



	Subroutine MSLG$$B_RETRY (lun,retry)


	byte		lun
	byte		retry


	call linchk (lun,1)

	write(lun,10) retry
10	format(' ',t8,'MSLG$B_RETRY',t30,z2.2)

	return
	end



	Subroutine MSLG$$Z_SDI (lun,sdi1,sdi2,sdi3)


	include 'src$:msghdr.for /nolist'
	include 'src$:emblmdef.for /nolist'


	byte		lun

	integer*4	sdi1
	integer*4	sdi2
	integer*4	sdi3
	integer*4	c_flags
	integer*4	retry_count

	logical*1	init_diagnostic_failure

	integer*4	previous_command
	integer*4	cylinder_low
	integer*4	cylinder_high
	integer*4	cylinder
	integer*4	current_group
	integer*4	led_display_code


	call linchk (lun,3)

	write(lun,10) sdi1,sdi2,sdi3
10	format(' ',t8,'MSLG$Z_SDI',t24,z8.8,/,t24,z8.8,/,t24,z8.8)

	call generic_sdi (lun,sdi1,sdi2,sdi3)

	If (LIB$EXTZV(3,1,sdi1) .EQ. 1) then

	if (
	1 emb$b_lm_type .eq. 20
	1 .or.
	1 emb$b_lm_type .eq. 21
	1 ) then

	call ra8x_status (lun,sdi1,sdi2,sdi3)
	endif

	if (emb$b_lm_type .eq. 20) then

	call ra80_status (lun,sdi1,sdi2,sdi3)

	else if (emb$b_lm_type .eq. 21) then

	call ra81_status (lun,sdi1,sdi2,sdi3)

	else if (emb$b_lm_type .eq. 22) then

	call ra60_status (lun,sdi1,sdi2,sdi3)
	endif
	endif

	return
	end



	Subroutine MSLG$$W_SDE_CYL (lun,small_disk_cylinder)


	byte		lun

	integer*2	small_disk_cylinder


	call linchk (lun,1)

	write(lun,10) small_disk_cylinder
10	format(' ',t8,'MSLG$W_SDE_CYL',t28,z4.4)

	return
	end



	Subroutine MSLG$$L_HEADER (lun,header)


	byte		lun

	integer*4	header
	integer*4	lbn
	integer*4	code
	integer*4	compress4


	call linchk (lun,1)

	write(lun,5) header
5	format(' ',t8,'MSLG$L_HEADER',t24,z8.8)


	Entry DISK_HEADER (lun,header)


	lbn = lib$extzv(0,28,header)
	code = lib$extzv(28,4,header)

	call linchk (lun,2)

	if (code .eq. 0) then

	write(lun,10) lbn,'GOOD LOGICAL SECTOR'
10	format(' ',t40,'LBN #',i<compress4 (lbn)>,'.',/,t40,a)

	else if (code .eq. 3) then

	write(lun,10) lbn,'BAD REVECTORED LOG. SECTOR'

	else if (code .eq. 5) then

	write(lun,10) lbn,'BAD PRIMARY REVECT. LOG. SECTOR'

	else if (code .eq. 6) then

	write(lun,11) lbn,'BAD REPLACEMENT SECTOR'
11	format(' ',t40,'RBN #',i<compress4 (lbn)>,'.',/,t40,a)

	else if (code .eq. 11) then

	write(lun,12) 'BAD SECTOR #',lbn
12	format(' ',t40,a,i<compress4 (lbn)>,'.')

	else if (code .eq. 12) then

	write(lun,13) lbn,'GOOD EXTERNAL SECTOR'
13	format(' ',t40,'XBN #',i<compress4 (lbn)>,'.',/,t40,a)

	else if (code .eq. 14) then

	write(lun,14) lbn,'GOOD DIAGNOSTIC SECTOR'
14	format(' ',t40,'DBN #',i<compress4 (lbn)>,'.',/,t40,a)
	else

	write(lun,15) 'HEADER #',lbn,'.','RESERVED HEADER CODE, #',code,'.'
15	format(' ',t40,a,i<compress4 (lbn)>,a,/,t40,a,i<compress4 (code)>,a)
	endif

	return
	end



	Subroutine MSCP_RESERVEDB (lun,reservedb)


	byte		lun
	byte		reservedb


	call linchk (lun,1)

	write(lun,10) 'RESERVED',reservedb
10	format(' ',t8,a,t30,z2.2)

	return
	end



	subroutine MSCP_RESERVEDW (lun,reservedw)


	byte		lun

	integer*2	reservedw


	call linchk (lun,1)

	write(lun,10) 'RESERVED',reservedw
10	format(' ',t8,a,t28,z4.4)

	return
	end



	subroutine MSCP_RESERVEDL (lun,reservedl)


	byte		lun

	integer*4	reservedl


	call linchk (lun,1)

	write(lun,10) 'RESERVED',reservedl
10	format(' ',t8,a,t24,z8.8)

	return
	end



	Subroutine MSCP_RESERVEDQ (lun,reservedq)


	byte		lun

	integer*4	reservedq(2)


	call linchk (lun,2)

	write(lun,10) 'RESERVED',(reservedq(i),i = 1,2)
10	format(' ',t8,a,t24,z8.8,/,t24,z8.8)

	return
	end



	Subroutine MSCP$$W_UNT_FLGS (lun,unit_flags,expand)


	byte		lun

	integer*2	unit_flags

	logical*1	expand

	character*17	v1unit_flags(0:2)
	data		v1unit_flags(0)	/'COMPARE READS*'/
	data		v1unit_flags(1)	/'COMPARE WRITES*'/
	data		v1unit_flags(2)	/'576 BYTE SECTORS*'/

	character*26	v2unit_flags(6:7)
	data		v2unit_flags(6)	/'WRITE BACK (NON-VOLATILE)*'/
	data		v2unit_flags(7)	/'REMOVABLE MEDIA*'/

	character*35	v3unit_flags(10:15)
	data		v3unit_flags(10)/'SUPPRESS CACHING (LOW SPEED)*'/
	data		v3unit_flags(11)/'SUPPRESS CACHING (HIGH SPEED*'/
	data		v3unit_flags(12)/'WRITE PROTECT (SOFTWARE OR VOLUME)*'/
	data		v3unit_flags(13)/'WRITE PROTECT (HARDWARE)*'/
	data		v3unit_flags(14)/'INACTIVE SHADOW SET UNIT*'/
	data		v3unit_flags(15)/'CONTROLLER BAD BLOCK REPLACEMENT*'/


	call linchk (lun,1)

	write(lun,10) unit_flags
10	format(' ',t8,'MSCP$W_UNT_FLGS',t28,z4.4)

	if (expand) then

	call output (lun,unit_flags,v1unit_flags,0,0,2,'0')

	call output (lun,unit_flags,v2unit_flags,6,6,7,'0')

	call output (lun,unit_flags,v3unit_flags,10,10,15,'0')
	endif

	return
	end



	Subroutine MSCP$$L_MEDIA_ID (lun,media_id,expand)


	byte		lun

	integer*4	media_id

	logical*1	expand

	character*2		letter(31)
	data		letter(1)	/'A*'/
	data		letter(2)	/'B*'/
	data		letter(3)	/'C*'/
	data		letter(4)	/'D*'/
	data		letter(5)	/'E*'/
	data		letter(6)	/'F*'/
	data		letter(7)	/'G*'/
	data		letter(8)	/'H*'/
	data		letter(9)	/'I*'/
	data		letter(10)	/'J*'/
	data		letter(11)	/'K*'/
	data		letter(12)	/'L*'/
	data		letter(13)	/'M*'/
	data		letter(14)	/'N*'/
	data		letter(15)	/'O*'/
	data		letter(16)	/'P*'/
	data		letter(17)	/'Q*'/
	data		letter(18)	/'R*'/
	data		letter(19)	/'S*'/
	data		letter(20)	/'T*'/
	data		letter(21)	/'U*'/
	data		letter(22)	/'V*'/
	data		letter(23)	/'W*'/
	data		letter(24)	/'X*'/
	data		letter(25)	/'Y*'/
	data		letter(26)	/'Z*'/
	data		letter(27)	/'.*'/
	data		letter(28)	/'.*'/
	data		letter(29)	/'.*'/
	data		letter(30)	/'.*'/
	data		letter(31)	/'.*'/

	integer*4	d(0:1)
	integer*4	a(0:2)
	integer*4	n
	integer*4	compress4

	character*2	d_string
	character*3	a_string


	call linchk (lun,1)

	write(lun,5) 'MSCP$L_MEDIA_ID',media_id
5	format(' ',t8,a,t24,z8.8)

	if (expand) then

	d(0) = lib$extzv(27,5,media_id)

	d(1) = lib$extzv(22,5,media_id)

	a(0) = lib$extzv(17,5,media_id)

	a(1) = lib$extzv(12,5,media_id)

	a(2) = lib$extzv(7,5,media_id)

	n = lib$extzv(0,7,media_id)

	do 10,i = 0,1

	if (d(i) .eq. 0) then

	d_string(i+1:i+1) = char(0)
	else

	d_string(i+1:i+1) = letter(d(i))
	endif

10	continue

	do 15,i = 0,2

	if (a(i) .eq. 0) then

	a_string(i+1:i+1) = char(0)
	else

	a_string(i+1:i+1) = letter(a(i))
	endif

15	continue

	call linchk (lun,2)

	write(lun,20) 'DEVICE TYPE, /',d_string,'/'
20	format(' ',t40,3(a))

	write(lun,25) 'MEDIA TYPE, /',a_string,n,'/'
25	format(' ',t40,a,a,i<compress4 (n)>,a)
	endif

	return
	end



	Subroutine MSCP$$B_OPCODE (lun,opcode,expand)


	byte		lun
	byte		opcode

	logical*1	expand

	integer*4	control_message_type
	integer*4	compress4


	call linchk (lun,1)

	If (LIB$EXTZV(6,2,opcode) .EQ. 0) then

	write(lun,10) 'MSCP$B_OPCODE',opcode
10	format(' ',t8,a,t30,z2.2)

	Else if (LIB$EXTZV(6,2,opcode) .EQ. 1) then

	Write (lun,10) 'MSCP$B_ATNCODE',opcode

	Else if (LIB$EXTZV(6,2,opcode) .EQ. 2) then

	Write (lun,10) 'MSCP$B_ENDCODE',opcode
	Else

	Write (lun,12) opcode
12	Format (' ',T30,Z2.2)
	Endif

	if (expand) then

	call linchk (lun,1)

	control_message_type = lib$extzv(0,8,opcode)

	if (control_message_type .eq. 1) then

	write(lun,15) 'ABORT'
15	format(' ',t40,a)

	else if (control_message_type .eq. 2) then

	write(lun,15) 'GET COMMAND STATUS'

	else if (control_message_type .eq. 3) then

	write(lun,15) 'GET UNIT STATUS'

	else if (control_message_type .eq. 4) then

	write(lun,15) 'SET CONTROLLER CHARACTERISTICS'

	else if (control_message_type .eq. 8) then

	write(lun,15) 'AVAILABLE'

	else if (control_message_type .eq. 9) then

	write(lun,15) 'ONLINE'

	else if (control_message_type .eq. 10) then

	write(lun,15) 'SET UNIT CHARACTERISTICS'

	else if (control_message_type .eq. 11) then

	write(lun,15) 'DETERMINE ACCESS PATH(S)'

	else if (control_message_type .eq. 16) then

	write(lun,15) 'ACCESS'

	else if (control_message_type .eq. 17) then

	write(lun,15) 'COMPARE CONTROLLER DATA'

	else if (control_message_type .eq. 18) then

	write(lun,15) 'ERASE'

	else if (control_message_type .eq. 19) then

	write(lun,15) 'FLUSH'

	else if (control_message_type .eq. 20) then

	write(lun,15) 'REPLACE'

	else if (control_message_type .eq. 32) then

	write(lun,15) 'COMPARE HOST DATA'

	else if (control_message_type .eq. 33) then

	write(lun,15) 'READ'

	else if (control_message_type .eq. 34) then

	write(lun,15) 'WRITE'

	else if (control_message_type .eq. 64) then

	write(lun,15) 'AVAILABLE'

	else if (control_message_type .eq. 65) then

	write(lun,15) 'DUPLICATE UNIT NUMBER'

	else if (control_message_type .eq. 66) then

	write(lun,15) 'ACCESS PATH'
	else

	write(lun,20) control_message_type
20	format(' ',t40,'CONTROL MESSAGE TYPE, #',
	1 i<compress4 (control_message_type)>,'.')
	endif
	endif

	return
	end



	Subroutine MSCP$$W_MODIFIER (lun,opcode,command_modifier,expand)


	byte		lun
	byte		opcode

	integer*2	command_modifier

	logical*1	expand

	integer*4	control_message_type

	character*33	v1modifier(4:15)
	data		v1modifier(4)	/'WRITE SHADOW SET, SINGLE UNIT(S)*'/
	data		v1modifier(5)	/'WRITE BACK (VOLATILE)*'/
	data		v1modifier(6)	/'WRITE BACK (NON-VOLATILE)*'/
	data		v1modifier(7)	/'SUPPRESS SHADOWING*'/
	data		v1modifier(8)	/'SUPRESS ERROR RECOVERY*'/
	data		v1modifier(9)	/'SUPRESS ERROR CORRECTION*'/
	data		v1modifier(10)	/'SUPRESS CACHING (LOW SPEED)*'/
	data		v1modifier(11)	/'SUPPRESS CACHING (HIGH SPEED)*'/
	data		v1modifier(12)	/'FORCE ERROR*'/
	data		v1modifier(13)	/'CLEAR SERIOUS EXCEPTION*'/
	data		v1modifier(14)	/'COMPARE*'/
	data		v1modifier(15)	/'EXPRESS REQUEST*'/

	character*10	v1gus_modifier(0:0)
	data		v1gus_modifier(0)	/'NEXT UNIT*'/

	character*18	v1available_modifier(0:1)
	data		v1available_modifier(0)	/'ALL CLASS DRIVERS*'/
	data		v1available_modifier(1)	/'SPIN-DOWN*'/

	character*27	v1online_modifier(0:4)
	data		v1online_modifier(0)	/'ALLOW SELF DESTRUCTION*'/
	data		v1online_modifier(1)	/'IGNORE MEDIA FORMAT ERROR*'/
	data		v1online_modifier(2)	/'ENABLE SET WRITE PROTECT*'/
	data		v1online_modifier(3)	/'CLEAR WRITE-BACK DATA LOST*'/
	data		v1online_modifier(4)	/'SHADOW UNIT SPECIFIED*'/

	character*27	v1suc_modifier(2:4)

	equivalence	(v1suc_modifier(2),v1online_modifier(2))

	character*18	v1flush_modifier(0:1)
	data		v1flush_modifier(0)	/'FLUSH ENTIRE UNIT*'/
	data		v1flush_modifier(1)	/'VOLATILE ONLY*'/

	character*26	v1replace_modifier(0:0)
	data		v1replace_modifier(0)	/'PRIMARY REPLACEMENT BLOCK*'/


	call linchk (lun,1)

	write(lun,10) command_modifier
10	format(' ',t8,'MSCP$W_MODIFIER',t28,z4.4)

	if (expand) then

	control_message_type = lib$extzv(0,8,opcode)

	if (control_message_type .eq. 3) then

	call output (lun,command_modifier,v1gus_modifier,0,0,0,'0')
	call output (lun,command_modifier,v1modifier,4,13,13,'0')

	else if (control_message_type .eq. 8) then

	call output (lun,command_modifier,v1available_modifier,0,0,1,'0')
	call output (lun,command_modifier,v1modifier,4,13,13,'0')

	else if (control_message_type .eq. 9) then

	call output (lun,command_modifier,v1online_modifier,0,0,4,'0')
	call output (lun,command_modifier,v1modifier,4,13,13,'0')

	else if (control_message_type .eq. 10) then

	call output (lun,command_modifier,v1suc_modifier,2,2,4,'0')
	call output (lun,command_modifier,v1modifier,4,13,13,'0')

	else if (
	1 control_message_type .eq. 16
	1 .or.
	1 control_message_type .eq. 17
	1 .or.
	1 control_message_type .eq. 32
	1 ) then

	call output (lun,command_modifier,v1modifier,4,7,11,'0')
	call output (lun,command_modifier,v1modifier,4,13,13,'0')
	call output (lun,command_modifier,v1modifier,4,15,15,'0')

	else if (control_message_type .eq. 18) then

	call output (lun,command_modifier,v1modifier,4,4,8,'0')
	call output (lun,command_modifier,v1modifier,4,12,13,'0')
	call output (lun,command_modifier,v1modifier,4,15,15,'0')

	else if (control_message_type .eq. 19) then

	call output (lun,command_modifier,v1flush_modifier,0,0,1,'0')
	call output (lun,command_modifier,v1modifier,4,7,9,'0')
	call output (lun,command_modifier,v1modifier,4,13,13,'0')
	call output (lun,command_modifier,v1modifier,4,15,15,'0')

	else if (control_message_type .eq. 20) then

	call output (lun,command_modifier,v1replace_modifier,0,0,0,'0')
	call output (lun,command_modifier,v1modifier,4,13,13,'0')
	call output (lun,command_modifier,v1modifier,4,15,15,'0')

	else if (control_message_type .eq. 33) then

	call output (lun,command_modifier,v1modifier,4,7,11,'0')
	call output (lun,command_modifier,v1modifier,4,13,15,'0')

	else if (control_message_type .eq. 34) then

	call output (lun,command_modifier,v1modifier,4,4,9,'0')
	call output (lun,command_modifier,v1modifier,4,12,15,'0')
	endif
	endif

	return
	end



	Subroutine MSCP$$Z_BUFFER (lun,buffer)


	include 'src$:msghdr.for /nolist'


	byte		lun

	integer*4	buffer(3)


	call linchk (lun,3)

	write(lun,10) (buffer(i),i = 1,3)
10	format(' ',t8,'MSCP$Z_BUFFER',t24,z8.8,/,t24,z8.8,/,t24,z8.8)

	return
	end



	Subroutine MSCP$$L_DEV_PARM (lun,device_dependant_parameters)


	byte		lun

	integer*4	device_dependant_parameters


	call linchk (lun,1)

	write(lun,10) device_dependant_parameters
10	format(' ',t8,'MSCP$L_DEV_PARM',t24,z8.8)

	return
	end



	Subroutine MSCP$$W_SHDW_UNT (lun,shadow_unit,expand)


	byte		lun

	integer*2	shadow_unit

	logical*1	expand

	integer*4	compress4



	call linchk (lun,1)

	write(lun,10) shadow_unit
10	format(' ',t8,'MSCP$W_SHDW_UNT',t28,z4.4)

	if (expand) then

	call linchk (lun,1)

	write(lun,15) shadow_unit
15	format(' ',t40,'SHADOW UNIT #',i<compress4 (shadow_unit)>,'.')
	endif

	return
	end



	Subroutine MSCP$$W_COPY_SPD (lun,copy_speed)


	byte		lun

	integer*2	copy_speed


	call linchk (lun,1)

	write(lun,10) copy_speed
10	format(' ',t8,'MSCP$W_COPY_SPD',t28,z4.4)

	return
	end



	Subroutine MSCP$$W_VERSION (lun,mscp_version)


	byte		lun

	integer*2	mscp_version


	call linchk (lun,1)

	write(lun,10) mscp_version
10	format(' ',t8,'MSCP$W_VERSION',t28,z4.4)

	return
	end



	Subroutine MSCP$$W_CNT_FLGS (lun,controller_flags,expand)


	byte		lun

	integer*2	controller_flags

	logical*1	expand

	character*17	v1controller_flags(0:1)
	data		v1controller_flags(0)	/'576 BYTE SECTORS*'/
	data		v1controller_flags(1)	/'SHADOWING*'/

	character*34	v2controller_flags(4:7)

	data		v2controller_flags(4)
	1 /'ENABLE ERROR LOG MSG., THIS HOST*'/

	data		v2controller_flags(5)
	1 /'ENABLE ERROR LOG MSG., OTHER HOST*'/

	data		v2controller_flags(6)
	1 /'ENABLE MISC. ERROR LOG MESSAGES*'/

	data		v2controller_flags(7)
	1 /'ENABLE "ATTENTION" MESSAGES*'/

	character*33	v3controller_flags(15:15)

	data		v3controller_flags(15)
	1 /'CONTROLLER BAD BLOCK REPLACEMENT*'/



	call linchk (lun,1)

	write(lun,10) controller_flags
10	format(' ',t8,'MSCP$W_CNT_FLGS',t28,z4.4)

	if (expand) then

	call output (lun,controller_flags,v1controller_flags,0,0,1,'0')
	call output (lun,controller_flags,v2controller_flags,4,4,7,'0')
	call output (lun,controller_flags,v3controller_flags,15,15,15,'0')
	endif

	return
	end



	Subroutine MSCP$$W_HST_TMO (lun,host_timeout,expand)


	byte		lun

	integer*2	host_timeout

	logical*1	expand

	integer*4	compress4


	call linchk (lun,1)

	write(lun,10) host_timeout
10	format(' ',t8,'MSCP$W_HST_TMO',t28,z4.4)

	if (expand) then

	call linchk (lun,1)

	write(lun,15) host_timeout
15	format(' ',t40,'HOST TIMEOUT, ',i<compress4 (host_timeout)>,
	1 '. SECONDS')
	endif

	return
	end



	Subroutine MSCP$$Q_TIME (lun,vms_time,expand)


	byte		lun

	integer*4	vms_time(2)

	logical*1	expand

	logical*4	sys$asctim

	character*23	timbuf


	call linchk (lun,2)

	write(lun,10) vms_time(1)
10	format(' ',t8,'MSCP$Q_TIME',t24,z8.8)

	if (expand) then

	if (sys$asctim (,timbuf,vms_time,%val(0))) then

	write(lun,15) vms_time(2),timbuf
15	format(' ',t24,z8.8,:t40,:a)

	goto 20
	endif
	endif

	write(lun,15) vms_time(2)

20	return
	end



	Subroutine MSCP$$W_STATUS (lun,end_message_status_code,expand)



	byte		lun

	integer*2	end_message_status_code

	logical*1	expand

	integer*4	status_code
	integer*4	compress4



	call linchk (lun,1)

	write(lun,10) end_message_status_code
10	format(' ',t8,'MSCP$W_STATUS',t28,z4.4)

	if (expand) then

	Call STATUS_AND_EVENT_CODES (lun)
	Endif

	return
	end



	Subroutine MSCP_FIRST_TWELVE_BYTES1 (lun,expand)


	include 'src$:msghdr.for /nolist'


	byte		lun

	logical*1	expand

	integer*4	mscp$l_cmd_ref

	integer*2	mscp$w_unit
	integer*2	reserved1

	byte		mscp$b_opcode
	byte		reserved2

	integer*2	mscp$w_modifier

	integer*4	mscp$l_out_ref

	equivalence	(emb(38),mscp$l_cmd_ref)
	equivalence	(emb(42),mscp$w_unit)
	equivalence	(emb(44),reserved1)
	equivalence	(emb(46),mscp$b_opcode)
	equivalence	(emb(47),reserved2)
	equivalence	(emb(48),mscp$w_modifier)

	Logical*1	End_message

	End_message = .false.

	If (LIB$EXTZV(7,1,mscp$b_opcode) .EQ. 1) then

	End_message = .true.
	Endif

	call mscp$$l_cmd_ref (lun,mscp$l_cmd_ref)

	call mscp$$w_unit (lun,mscp$w_unit,expand)

	call mscp_reservedw (lun,reserved1)

	call mscp$$b_opcode (lun,mscp$b_opcode,expand)

	If (.NOT. end_message) then

	call mscp_reservedb (lun,reserved2)
	Else

	Call MSCP$$B_FLAGS (lun,reserved2,expand)
	Endif

	If (.NOT. end_message) then

	call mscp$$w_modifier (lun,mscp$b_opcode,mscp$w_modifier,expand)
	Else

	Call MSCP$$W_STATUS (lun,mscp$w_modifier,expand)
	Endif

	return
	end



	Subroutine MSCP_FIRST_TWELVE_BYTES2 (lun,expand)


	include 'src$:msghdr.for /nolist'


	byte		lun

	logical*1	expand

	integer*4	reserved1

	integer*2	mscp$w_unit
	integer*2	reserved2

	byte		mscp$b_opcode
	byte		reserved3

	integer*2	reserved4

	equivalence	(emb(38),reserved1)
	equivalence	(emb(42),mscp$w_unit)
	equivalence	(emb(44),reserved2)
	equivalence	(emb(46),mscp$b_opcode)
	equivalence	(emb(47),reserved3)
	equivalence	(emb(48),reserved4)


	call mscp_reservedl (lun,reserved1)

	call mscp$$w_unit (lun,mscp$w_unit,expand)

	call mscp_reservedw (lun,reserved2)

	call mscp$$b_opcode (lun,mscp$b_opcode,expand)

	call mscp_reservedb (lun,reserved3)

	call mscp_reservedw (lun,reserved4)

	return
	end



	subroutine MSCP_INVALID_COMMAND_END_MESAGE (lun)


	include 'src$:msghdr.for /nolist'


	byte		lun

	integer*4	mscp$l_cmd_ref

	integer*2	mscp$w_unit
	integer*2	reserved1

	byte		mscp$b_endcode
	byte		mscp$b_flags

	integer*2	mscp$w_status

	byte		manufactured_mscp$b_opcode

	equivalence	(emb(38),mscp$l_cmd_ref)
	equivalence	(emb(42),mscp$w_unit)
	equivalence	(emb(44),reserved1)
	equivalence	(emb(46),mscp$b_endcode)
	equivalence	(emb(47),mscp$b_flags)
	equivalence	(emb(48),mscp$w_status)
	equivalence	(emb(94),manufactured_mscp$b_opcode)


	call linchk (lun,1)

	write(lun,10)
10	format(' ',:)

	call mscp$$l_cmd_ref (lun,mscp$l_cmd_ref)

	call mscp$$w_unit (lun,mscp$w_unit,.true.)

	call mscp_reservedw (lun,reserved1)

	Call MSCP$$B_OPCODE (lun,mscp$b_endcode, .true.)

	Call MSCP$$B_FLAGS (lun,mscp$b_flags, .true.)

	Call MSCP$$W_STATUS (lun,mscp$w_status, .true.)

	Call MSCP$B_OPCODE_DISPATCHER (lun,manufactured_mscp$b_opcode,
	1 .false., .true.)

	call linchk (lun,1)

	write(lun,25)
25	format(/' ','RE-MANUFACTURED "MSCP" CONTROL MESSAGE')

	call movc3 (%val(36),emb(86),emb(38))

	call mscp$b_opcode_dispatcher (lun,manufactured_mscp$b_opcode,.true.,
	1 .false.)

	return
	end



	Subroutine MSCP$B_OPCODE_DISPATCHER (lun,mscp$b_opcode,expand,invalid)


	include 'src$:msghdr.for /nolist'


	byte		lun
	byte		mscp$b_opcode

	logical*1	expand
	logical*1	invalid

	integer*4	mscp$l_opcode


	mscp$l_opcode = lib$extzv(0,7,mscp$b_opcode)

	if (.not. invalid) then

	if (mscp$l_opcode .eq. 1) then

	call mscp$$k_op_abort (lun,expand)

	else if (mscp$l_opcode .eq. 2) then
	call mscp$$k_op_gtcmd (lun,expand)

	else if (mscp$l_opcode .eq. 3) then
	call mscp$$k_op_gtunt (lun,expand)

	else if (mscp$l_opcode .eq. 4) then
	call mscp$$k_op_stcon (lun,expand)

	Else if (mscp$l_opcode .EQ. 7) then
	Call MSCP$$K_OP_SEREX (lun,expand)

	else if (mscp$l_opcode .eq. 8) then
	call mscp$$k_op_avail (lun,expand)

	else if (mscp$l_opcode .eq. 9) then
	call mscp$$k_op_onlin (lun,expand)

	else if (mscp$l_opcode .eq. 10) then
	call mscp$$k_op_stunt (lun,expand)

	else if (mscp$l_opcode .eq. 11) then
	call mscp$$k_op_dtacp (lun,expand)

	else if (mscp$l_opcode .eq. 16) then
	call mscp$$k_op_acces (lun,expand)

	else if (mscp$l_opcode .eq. 17) then
	call mscp$$k_op_cmpcd (lun,expand)

	else if (mscp$l_opcode .eq. 18) then
	call mscp$$k_op_erase (lun,expand)

	else if (mscp$l_opcode .eq. 19) then
	call mscp$$k_op_flush (lun,expand)

	else if (mscp$l_opcode .eq. 20) then
	call mscp$$k_op_replc (lun,expand)

	else if (mscp$l_opcode .eq. 32) then
	call mscp$$k_op_comp (lun,expand)

	else if (mscp$l_opcode .eq. 33) then
	call mscp$$k_op_read (lun,expand)

	else if (mscp$l_opcode .eq. 34) then
	call mscp$$k_op_write (lun,expand)

	else if (mscp$l_opcode .eq. 64) then
	call mscp$$k_op_avatn (lun,expand)

	else if (mscp$l_opcode .eq. 65) then
	call mscp$$k_op_dupun (lun,expand)

	else if (mscp$l_opcode .eq. 66) then
	call mscp$$k_op_acpth (lun,expand)

	else
	call linchk (lun,1)

	write(lun,5)
5	format(' ',:)

	Call DUMPREG (lun,9,emb(38))
	endif

	else if (invalid) then
	if (mscp$l_opcode .eq. 1) then

	call invalid_mscp$$k_op_abort (lun,expand)

	else if (mscp$l_opcode .eq. 2) then
	call invalid_mscp$$k_op_gtcmd (lun,expand)

	else if (mscp$l_opcode .eq. 3) then
	call invalid_mscp$$k_op_gtunt (lun,expand)

	else if (mscp$l_opcode .eq. 4) then
	call invalid_mscp$$k_op_stcon (lun,expand)

	else if (mscp$l_opcode .eq. 8) then
	call invalid_mscp$$k_op_avail (lun,expand)

	else if (mscp$l_opcode .eq. 9) then
	call invalid_mscp$$k_op_onlin (lun,expand)

	else if (mscp$l_opcode .eq. 10) then
	call invalid_mscp$$k_op_stunt (lun,expand)

	else if (mscp$l_opcode .eq. 11) then
	call invalid_mscp$$k_op_dtacp (lun,expand)

	else if (mscp$l_opcode .eq. 16) then
	call invalid_mscp$$k_op_acces (lun,expand)

	else if (mscp$l_opcode .eq. 17) then
	call invalid_mscp$$k_op_cmpcd (lun,expand)

	else if (mscp$l_opcode .eq. 18) then
	call invalid_mscp$$k_op_erase (lun,expand)

	else if (mscp$l_opcode .eq. 19) then
	call invalid_mscp$$k_op_flush (lun,expand)

	else if (mscp$l_opcode .eq. 20) then
	call invalid_mscp$$k_op_replc (lun,expand)

	else if (mscp$l_opcode .eq. 32) then
	call invalid_mscp$$k_op_comp (lun,expand)

	else if (mscp$l_opcode .eq. 33) then
	call invalid_mscp$$k_op_read (lun,expand)

	else if (mscp$l_opcode .eq. 34) then
	call invalid_mscp$$k_op_write (lun,expand)

	else if (mscp$l_opcode .eq. 64) then
	call invalid_mscp$$k_op_avatn (lun,expand)

	else if (mscp$l_opcode .eq. 65) then
	call invalid_mscp$$k_op_dupun (lun,expand)

	else if (mscp$l_opcode .eq. 66) then
	call invalid_mscp$$k_op_acpth (lun,expand)

	else
	call linchk (lun,1)

	write(lun,5)

	Call DUMPREG (lun,9,emb(38))
	endif
	endif

	return
	end



	Subroutine RA60_STATUS (lun,sdi1,sdi2,sdi3)


	byte		lun

	integer*4	sdi1
	integer*4	sdi2
	integer*4	sdi3
	integer*4	previous_cylinder
	integer*4	previous_head
	integer*4	current_cylinder
	integer*4	current_head
	integer*4	error_code
	integer*4	compress4


	previous_cylinder = lib$extzv(8,16,sdi2)

	call linchk (lun,1)

	write(lun,10) 'PREVIOUS CYLINDER, #',previous_cylinder
10	format(' ',t40,a,i<compress4 (previous_cylinder)>,'.')

	previous_head = lib$extzv(24,8,sdi2)

	call linchk (lun,1)

	write(lun,15) 'PREVIOUS HEAD, #',previous_head
15	format(' ',t40,a,i<compress4 (previous_head)>,'.')

	current_cylinder = lib$extzv(0,16,sdi3)

	call linchk (lun,1)

	write(lun,20) 'CURRENT CYLINDER, #',current_cylinder
20	format(' ',t40,a,i<compress4 (current_cylinder)>,'.')

	current_head = lib$extzv(16,8,sdi3)

	call linchk (lun,1)

	write(lun,25) 'CURRENT HEAD, #',current_head
25	format(' ',t40,a,i<compress4 (current_head)>,'.')

	error_code = lib$extzv(24,8,sdi3)

	call linchk (lun,1)

	write(lun,30) 'ERROR CODE ',error_code
30	format(' ',t40,a,z2.2,' (HEX)')

	call linchk (lun,1)

	if (error_code .eq. '01'x) then

	call linchk (lun,1)

	write(lun,35) 'COMMAND CANNOT BE EXECUTED',
	1 ' - WITH DRIVE IN CURRENT STATE'
35	format(' ',t40,a,/,t40,a)

	else if (error_code .eq. '02'x) then

	call linchk (lun,1)

	write(lun,35) 'SEEK REQUESTED NON-EXISTENT',
	1 ' - HEAD OR CYLINDER'

	else if (error_code .eq. '03'x) then

	write(lun,40) 'NOT A VALID OPCODE'
40	format(' ',t40,a)

	else if (error_code .eq. '04'x) then

	call linchk (lun,1)

	write(lun,35) 'COVER NOT CLOSED',
	1 ' - WHEN "RUN" ISSUED'

	else if (error_code .eq. '05'x) then

	write(lun,40) 'LID NOT LOCKED WHEN "RUN" ISSUED'

	else if (error_code .eq. '06'x) then

	write(lun,40) 'PROGRAM ERROR DURING HEAD LOAD'

	else if (error_code .eq. '08'x) then

	write(lun,40) 'HEADS NOT HOME WHEN "RUN" ISSUED'

	else if (error_code .eq. '09'x) then

	call linchk (lun,1)

	write(lun,35) 'HEADS HOME SWITCH OPEN',
	1 ' - DURING SPIN-UP'

	else if (error_code .eq. '0a'x) then

	call linchk (lun,1)

	write(lun,35) 'HEADS HOME SWITCH WOULD NOT CLOSE',
	1 ' - DURING UNLOAD'

	else if (error_code .eq. '0b'x) then

	call linchk (lun,1)

	write(lun,35) 'COVER OR LID LOCK OPENED',
	1 ' - DURING HEAD LOAD'

	else if (error_code .eq. '10'x) then

	write(lun,40) 'LID LOCK OPEN DURING SPIN-UP'

	else if (error_code .eq. '11'x) then

	write(lun,40) 'COVER OPEN DURING SPIN-UP'

	else if (error_code .eq. '18'x) then

	write(lun,40) 'SPIN-UP TIME TOO LONG'

	else if (error_code .eq. '19'x) then

	call linchk (lun,1)

	write(lun,35) 'NO MOTOR SAMPLE CHANGE',
	1 ' - DURING SPIN-UP'

	else if (error_code .eq. '20'x) then

	write(lun,40) 'SPIN-UP TIME TOO SHORT'

	else if (error_code .eq. '28'x) then

	call linchk (lun,1)

	write(lun,35) 'TOO MANY BAD SERVO SAMPLES',
	1 ' - DURING "RTZ"'

	else if (error_code .eq. '29'x) then

	call linchk (lun,1)

	write(lun,35) 'TOO LONG TO AQUIRE GOOD SAMPLES',
	1 ' - ON HEAD LOAD'

	else if (error_code .eq. '2a'x) then

	call linchk (lun,1)

	write(lun,35) 'HEAD LOAD SEEK DID NOT RETURN',
	1 ' - TO TRACK ZERO'

	else if (error_code .eq. '2b'x) then

	call linchk (lun,1)

	write(lun,35) 'BAD SERVO SAMPLES WHEN BUMPING',
	1 ' - GUARD BAND ON HEAD LOAD'

	else if (error_code .eq. '2c'x) then

	call linchk (lun,1)

	write(lun,35) 'BAD SERVO SAMPLES DURING "RTZ"',
	1 ' - ON HEAD LOAD'

	else if (error_code .eq. '2d'x) then

	write(lun,40) 'BAD SAMPLES DURING LINEAR MODE'

	else if (error_code .eq. '2e'x) then

	write(lun,40) 'OFF SPEED WHEN IN LINEAR STATE'

	else if (error_code .eq. '30'x) then

	call linchk (lun,1)

	write(lun,35) 'VELOCITY TOO HIGH DURING "RTZ"',
	1 ' - ON HEAD LOAD'

	else if (error_code .eq. '31'x) then

	call linchk (lun,1)

	write(lun,35) 'VELOCITY TOO LOW DURING "RTZ"',
	1 ' - ON HEAD LOAD'

	else if (error_code .eq. '32'x) then

	write(lun,40) 'BAD VELOCITY ON SEEK'

	else if (error_code .eq. '38'x) then

	call linchk (lun,1)

	write(lun,35) 'TOO LONG TO GET ON TRACK',
	1 ' - IN LINEAR MODE'

	else if (error_code .eq. '40'x) then

	write(lun,40) 'RETRY ON SEEK, BAD SERVO SAMPLES'

	else if (error_code .eq. '41'x) then

	call linchk (lun,1)

	write(lun,35) 'RETRY ON SEEK,',
	1 ' - BAD SERVO SAMPLES FAILED'

	else if (error_code .eq. '42'x) then

	call linchk (lun,1)

	write(lun,35) 'RETRY ON SEEK,',
	1 ' - BAD GUARD BAND FLAGS'

	else if (error_code .eq. '43'x) then

	call linchk (lun,1)

	write(lun,35) 'RETRY ON SEEK,',
	1 ' - BAD GUARD BAND FLAGS FAILED'

	else if (error_code .eq. '44'x) then

	write(lun,40) 'RETRY ON SEEK, SEEK TIMEOUT'

	else if (error_code .eq. '45'x) then

	call linchk (lun,1)

	write(lun,35) 'RETRY ON SEEK,',
	1 ' - SEEK TIMEOUT FAILED'

	else if (error_code .eq. '48'x) then

	write(lun,40) 'LOST SERVO SAMPLES'

	else if (error_code .eq. '50'x) then

	call linchk (lun,1)

	write(lun,35) 'TOO LONG FOR HEADS HOME SWITCH',
	1 ' - TO OPEN ON HEAD LOAD'

	else if (error_code .eq. '81'x) then

	write(lun,40) 'INITS AND TESTS, CONTROL PANEL'

	else if (error_code .eq. '82'x) then

	write(lun,40) 'CHECKS, PROCESSOR REGISTERS'

	else if (error_code .eq. '83'x) then

	write(lun,40) 'TESTS, RAM #0'

	else if (error_code .eq. '84'x) then

	write(lun,40) 'TESTS, ROM #0'

	else if (error_code .eq. '85'x) then

	write(lun,40) 'TESTS, ROM #1'

	else if (error_code .eq. '86'x) then

	write(lun,40) 'TESTS, ROM #2'

	else if (error_code .eq. '87'x) then

	write(lun,40) 'VERIFY ROM VERSION NUMBERS'

	else if (error_code .eq. '88'x) then

	write(lun,40) 'TESTS, "SDI" CLEAR INTERFACE BIT'

	else if (error_code .eq. '89'x) then

	call linchk (lun,1)

	write(lun,35) 'TESTS,',
	1 ' - "SDI" CONTROL/STATUS REGISTER'

	else if (error_code .eq. '8a'x) then

	call linchk (lun,1)

	write(lun,35) 'TESTS,',
	1 ' - FRONT PANEL AND SERIAL # ROM'

	else if (error_code .eq. '8b'x) then

	write(lun,40) 'INITS, "UART"'

	else if (error_code .eq. '8c'x) then

	write(lun,40) 'TESTS, ERROR REGISTERS'

	else if (error_code .eq. '8d'x) then

	write(lun,40) 'TESTS, "8155" TIMER'

	else if (error_code .eq. '8e'x) then

	write(lun,40) 'TESTS, SLAVE CONTROL PORT'

	else if (error_code .eq. '8f'x) then

	write(lun,40) 'SLAVE DIAGNOSTICS'

	else if (error_code .eq. '90'x) then

	call linchk (lun,2)

	write(lun,45) '"CMD" AVAILABLE OR',
	1 ' - SLAVE ALREADY SET WHEN ISSUING',
	1 ' - A NEW SLAVE COMMAND'
45	format(' ',t40,a,/,t40,a,/,t40,a)

	else if (error_code .eq. '91'x) then

	call linchk (lun,1)

	write(lun,35) 'SLAVE COMMAND RECEIVED',
	1 ' - TIMEOUT ON OPCODE'

	else if (error_code .eq. '92'x) then

	write(lun,40) 'SLAVE ATTENTION TIMEOUT'

	else if (error_code .eq. '93'x) then

	write(lun,40) 'SLAVE DONE TIMEOUT, "TOSTP"'

	else if (error_code .eq. '94'x) then

	call linchk (lun,1)

	write(lun,35) 'SLAVE DONE TIMEOUT,',
	1 ' - STATUS (1MS)'

	else if (error_code .eq. '95'x) then

	write(lun,40) 'SLAVE DONE TIMEOUT'

	else if (error_code .eq. '96'x) then

	write(lun,40) 'SLAVE ATTENTION TIMEOUT'

	else if (error_code .eq. '97'x) then

	write(lun,40) 'SOLENOID RELEASE TIMEOUT'

	else if (error_code .eq. '98'x) then

	write(lun,40) 'WATCHDOG TIMER, MASTER INSANE'

	else if (error_code .eq. '99'x) then

	write(lun,40) 'WATCHDOG TIMER, SLAVE INSANE'

	else if (error_code .eq. '9a'x) then

	call linchk (lun,1)

	write(lun,35) 'RUN SWITCH OR COVER INVALID',
	1 ' - AT SPIN-UP'

	else if (error_code .eq. '9b'x) then

	call linchk (lun,1)

	write(lun,35) 'SPINDLE NOT READY DURING',
	1 ' - RECALIBRATE COMMAND'

	else if (error_code .eq. '9c'x) then

	call linchk (lun,1)

	write(lun,35) '"SDI" TRANSFER ERROR',
	1 ' - FROM "DC703"'

	else if (error_code .eq. '9d'x) then

	call linchk (lun,1)

	write(lun,35) 'WRITE OR FORMAT WHILE',
	1 ' - WRITE PROTECTED'

	else if (error_code .eq. '9e'x) then

	write(lun,40) 'FORMAT WHILE FORMAT DISABLED'

	else if (error_code .eq. '9f'x) then

	call linchk (lun,1)

	write(lun,35) 'TRANSFER COMMAND',
	1 ' - WHILE DRIVE ERROR'

	else if (error_code .eq. 'a0'x) then

	write(lun,40) 'SECTOR READ/WRITE OVERRUN ERROR'

	else if (error_code .eq. 'a1'x) then

	write(lun,40) 'TRANSFER COMMAND WHILE R/W ERROR'

	else if (errror_code .eq. 'a2'x) then

	write(lun,40) '"SDI" COMMAND CHECKSUM ERROR'

	else if (error_code .eq. 'a3'x) then

	write(lun,40) '"SDI" FRAME ERROR'

	else if (error_code .eq. 'a4'x) then

	write(lun,40) '"SDI" COMMAND PARITY ERROR'

	else if (error_code .eq. 'a5'x) then

	write(lun,40) '"SDI" COMMAND OUT OF RANGE'

	else if (error_code .eq. 'a6'x) then

	write(lun,40) '"SDI" COMMAND LENGTH ERROR'

	else if (error_code .eq. 'a7'x) then

	write(lun,40) '"SDI" ERROR STATUS BYTE NON-ZERO'

	else if (error_code .eq. 'a8'x) then

	write(lun,40) 'SLAVE DONE TIMEOUT, SEEK COMMAND'

	else if (error_code .eq. 'a9'x) then

	call linchk (lun,1)

	write(lun,35) 'SLAVE DONE TIMEOUT,',
	1 ' - "RTZ" COMMAND'

	else if (error_code .eq. 'aa'x) then

	call linchk (lun,1)

	write(lun,35) 'SLAVE RESPONSE ERROR,',
	1 ' - "RTZ COMMAND'

	else if (error_code .eq. 'ab'x) then

	write(lun,40) 'SLAVE DONE TIMEOUT, FIRST PASS'

	else if (error_code .eq. 'ac'x) then

	call linchk (lun,2)

	write(lun,45) 'COMMAND RECEIVED TIMEOUT DURING',
	1 ' - STOP OR ASCII PORT COMMAND,',
	1 ' - TIME = "TODGN2"'

	else if (error_code .eq. 'ad'x) then

	call linchk (lun,2)

	write(lun,45) 'COMMAND RECEIVED TIMEOUT DURING',
	1 ' - STOP OR ASCII PORT COMMAND,',
	1 ' - TIME = 1MS'

	else if (error_code .eq. 'ae'x) then

	write(lun,40) 'DRIVE NOT ON-LINE'

	else if (error_code .eq. 'af'x) then

	write(lun,40) 'COMMAND BYTES 4 AND 5 NON-ZERO'

	else if (error_code .eq. 'b0'x) then

	write(lun,40) 'INVALID GROUP NUMBER'

	else if (error_code .eq. 'b1'x) then

	write(lun,40) 'INVALID HEAD SELECT NUMBER'

	else if (error_code .eq. 'b2'x) then

	write(lun,40) 'INVALID CYLINDER RANGE'

	else if (error_code .eq. 'b3'x) then

	write(lun,40) 'SPINDLE NOT READY'

	else if (error_code .eq. 'b4'x) then

	write(lun,40) 'CONTROLLER TIMEOUT = 0'

	else if (error_code .eq. 'b5'x) then

	write(lun,40) 'SPINDLE NOT READY'

	else if (error_code .eq. 'b6'x) then

	write(lun,40) 'ILLEGAL MEMORY REGION'

	else if (error_code .eq. 'b7'x) then

	write(lun,40) '"DD" BIT SET'

	else if (error_code .eq. 'b8'x) then

	write(lun,40) 'TRIED TO CLEAR HARD FAULT'

	else if (error_code .eq. 'b9'x) then

	write(lun,40) 'SLAVE DONE TIMEOUT, GET STATUS'

	else if (error_code .eq. 'ba'x) then

	write(lun,40) 'NON-ZERO LEVEL'

	else if (error_code .eq. 'bb'x) then

	write(lun,40) 'WRONG SUB-UNIT ERROR'

	else if (error_code .eq. 'bc'x) then

	call linchk (lun,1)

	write(lun,35) 'DIAGNOSTIC COMMAND,',
	1 ' - MEMORY REGION "HI" NON-ZERO'

	else if (error_code .eq. 'bd'x) then

	call linchk (lun,1)

	write(lun,35) 'DIAGNOSTIC COMMAND,',
	1 ' - INVALID PARAMETERS'

	else if (error_code .eq. 'be'x) then

	call linchk (lun,1)

	write(lun,35) 'WRITE ENABLE',
	1 ' - TO WRITE PROTECTED DRIVE'

	else if (error_code .eq. 'bf'x) then

	write(lun,40) 'SETTING "S7" = 1'

	else if (error_code .eq. 'c0'x) then

	call linchk (lun,1)

	write(lun,35) 'SLAVE DONE TIMEOUT,',
	1 ' - FROM GET STATUS COMMAND'

	else if (error_code .eq. 'c1'x) then

	call linchk (lun,1)

	write(lun,35) 'ERROR RESPONSE,',
	1 ' - GET STATUS COMMAND'

	else if (error_code .eq. 'c2'x) then

	write(lun,40) 'INVALID GROUP NUMBER'

	else if (error_code .eq. 'c3'x) then

	write(lun,40) 'MICRO-CODE FAULT ERROR'

	else if (error_code .eq. 'c4'x) then

	write(lun,40) 'NO WATCHDOG INTERRUPT'

	else if (error_code .eq. 'c5'x) then

	call linchk (lun,1)

	write(lun,35) 'SLAVE DONE TIMEOUT,',
	1 ' - ASCII PORT'

	else if (error_code .eq. 'c6'x) then

	call linchk (lun,1)

	write(lun,35) 'SLAVE COMMAND ERROR,',
	1 ' - ASCII PORT'
	endif

	return
	end



	Subroutine RA80_STATUS (lun,sdi1,sdi2,sdi3)


	byte		lun

	integer*4	sdi1
	integer*4	sdi2
	integer*4	sdi3
	integer*4	front_panel_fault_code
	integer*4	compress4


	front_panel_fault_code = lib$extzv (24,8,sdi3)

	if (front_panel_fault_code .eq. '14'x) then

	write(lun,55) 'R/W DIAGNOSTIC ERROR (SPIN-UP)'
55	format(' ',t40,a)

	else if (front_panel_fault_code .eq. '16'x) then

	write(lun,55) 'SPINDLE MOTOR INTERLOCK'

	else if (front_panel_fault_code .eq. '18'x) then

	write(lun,55) 'SPIN-UP ERROR'

	else if (front_panel_fault_code .eq. '1c'x) then

	write(lun,55) 'R/W UNSAFE'

	else if (front_panel_fault_code .eq. '1e'x) then

	write(lun,55) 'SPINDLE MOTOR SPEED ERROR'

	else if (front_panel_fault_code .eq. '34'x) then

	write(lun,55) 'HDA OR SERVO BOARD OVER-TEMP'

	else if (front_panel_fault_code .eq. '36'x) then

	write(lun,55) 'INITIAL RECAL FAILURE'

	else if (front_panel_fault_code .eq. '38'x) then

	write(lun,55) 'DRIVE DISABLED BY "DD" BIT'

	else if (front_panel_fault_code .eq. '3a'x) then

	write(lun,55) 'SERVO DIAGNOSTIC ERROR (SPIN-UP)'
	else

	write(lun,60) 'FRONT PANEL FAULT CODE, ',front_panel_fault_code,
	1 ' (HEX)'
60	format(' ',t40,a,z2.2,a)
	endif

	return
	end



	Subroutine RA8X_STATUS (lun,sdi1,sdi2,sdi3)


	byte		lun

	integer*4	sdi1
	integer*4	sdi2
	integer*4	sdi3
	integer*4	compress4

	logical*1	init_diagnostic_failure

	integer*4	retry_count
	integer*4	previous_command
	integer*4	cylinder
	integer*4	current_group
	integer*4	led_display_code

	character*33	v1ra8x_interface_error_status(3:5)

	data		v1ra8x_interface_error_status(3)
	1 /'OVERRUN ERROR*'/

	data		v1ra8x_interface_error_status(4)
	1 /'CONTROL R/T STATUS, PARITY ERROR*'/

	data		v1ra8x_interface_error_status(5)
	1 /'CONTROL PULSE ERROR*'/

	character*17	v2ra8x_interface_error_status(7:7)

	data		v2ra8x_interface_error_status(7)
	1 /'DATA PULSE ERROR*'/




	if (lib$extzv (20,1,sdi1) .eq. 1) then

	init_diagnostic_failure = .true.
	else

	init_diagnostic_failure = .false.
	endif

	retry_count = lib$extzv (0,8,sdi2)

	if (.not. init_diagnostic_failure) then

	if (retry_count .ne. 0) then

	previous_command = lib$extzv (8,8,sdi2)

	if (previous_command .eq. '8e'x) then

	call linchk (lun,1)

	write(lun,34) 'RECALIBRATE'
34	format(' ',t40,a)

	else if (previous_command .eq. '0a'x) then

	call linchk (lun,1)

	write(lun,34) 'SEEK'
	endif
	endif
	endif

	call output (lun,sdi2,v1ra8x_interface_error_status,3,3,5,'0')

	call output (lun,sdi2,v2ra8x_interface_error_status,7,7,7,'0')

	if (
	1 .not. init_diagnostic_failure
	1 .and.
	1 retry_count .ne. 0
	1 .and.
	1 (previous_command .eq. '8e'x
	1 .or.
	1 previous_command .eq. '0a'x)
	1 ) then

	cylinder = lib$extzv (24,16,sdi2)

	call linchk (lun,1)

	write(lun,40) cylinder
40	format(' ',t40,'CYLINDER #',i<compress4 (cylinder)>,'.')

	current_group = lib$extzv (8,8,sdi3)

	call linchk (lun,1)

	write(lun,45) current_group
45	format(' ',t40,'CURRENT GROUP #',i<compress4 (current_group)>,'.')
	endif

	led_display_code = lib$extzv (16,8,sdi3)

	call linchk (lun,1)

	write(lun,50) led_display_code
50	format(' ',t40,'"LED" DISPLAY CODE, ',z2.2,' (HEX)')

	return
	end



	Subroutine GENERIC_SDI (lun,sdi1,sdi2,sdi3)


	byte		lun

	integer*4	sdi1
	integer*4	sdi2
	integer*4	sdi3
	integer*4	compress4
	integer*4	c_flags
	integer*4	retry_count

	character*19	v1generic_sdi_status(0:1)

	data		v1generic_sdi_status(0)
	1 /'RUN/STOP SWITCH IN*'/

	data		v1generic_sdi_status(1)
	1 /'PORT SWITCH IN*'/

	character*33	v2generic_sdi_status(3:15)

	data		v2generic_sdi_status(3)
	1 /'LOG INFORMATION IN EXTENDED AREA*'/

	data		v2generic_sdi_status(4)
	1 /'SPINDLE READY*'/

	data		v2generic_sdi_status(5)
	1 /'DIAGNOSTIC LOAD REQUEST*'/

	data		v2generic_sdi_status(6)
	1 /'RE-ADJUSTMENT REQUESTED*'/

	data		v2generic_sdi_status(7)
	1 /'DRIVE UNAVAILABLE, BUT ONLINE*'/

	data		v2generic_sdi_status(8)
	1 /'576 BYTE SECTOR*'/

	data		v2generic_sdi_status(9)
	1 /'DIAG. CYLINDER ACCESS ENABLED*'/

	data		v2generic_sdi_status(10)
	1 /'FORMATTING OPERATIONS ENABLED*'/

	data		v2generic_sdi_status(11)
	1 /'FAULT*'/

	data		v2generic_sdi_status(12)
	1 /'WRITE PROTECT, UNIT #0.*'/

	data		v2generic_sdi_status(13)
	1 /'WRITE PROTECT, UNIT #1.*'/

	data		v2generic_sdi_status(14)
	1 /'WRITE PROTECT, UNIT #2.*'/

	data		v2generic_sdi_status(15)
	1 /'WRITE PROTECT, UNIT #3.*'/

	character*34	v3generic_sdi_status(19:23)

	data		v3generic_sdi_status(19)
	1 /'WRITE LOCK ERROR*'/

	data		v3generic_sdi_status(20)
	1 /'INITIALIZATION DIAGNOSTIC FAILURE*'/

	data		v3generic_sdi_status(21)
	1 /'LEVEL 2 PROTOCOL ERROR*'/

	data		v3generic_sdi_status(22)
	1 /'TRANSMISSION ERROR*'/

	data		v3generic_sdi_status(23)
	1 /'DRIVE ERROR*'/



	call output (lun,sdi1,v1generic_sdi_status,0,0,1,'0')

	call output (lun,sdi1,v2generic_sdi_status,3,3,15,'0')

	call output (lun,sdi1,v3generic_sdi_status,19,19,23,'0')

	c_flags = lib$extzv(24,4,sdi1)

	if (c_flags .eq. 8) then

	call linchk (lun,1)

	write(lun,15) '"DIAGNOSTICS"'
15	format(' ',t40,'DRIVE-OFFLINE, ',a)

	else if (c_flags .eq. 9) then

	call linchk (lun,1)

	write(lun,15) 'DUPLICATE UNIT IDENT'
	endif

	do 25,i = 28,31

	if (lib$extzv(i,1,sdi1) .eq. 1) then

	call linchk (lun,1)

	write(lun,20) 'SEND "MSCP" AVAILABLE SUB-UNIT #',28-i,'.'
20	format(' ',t40,a,i<compress4 (28-i)>,a)
	endif

25	continue

	retry_count = lib$extzv (0,8,sdi2)

	if (lib$extzv(20,1,sdi1) .eq. 0) then

	if (retry_count .ne. 0) then

	call linchk (lun,1)

	write(lun,30) 'RETRY COUNT ',retry_count
30	format(' ',t40,a,i<compress4 (retry_count)>,'.')
	endif
	else

	write(lun,35) 'FAILURE CODE ',retry_count,' (HEX)'
35	format(' ',t40,a,z2.2,a)
	endif

	return
	end



	Subroutine RA81_STATUS (lun,sdi1,sdi2,sdi3)


	byte		lun

	integer*4	sdi1
	integer*4	sdi2
	integer*4	sdi3
	integer*4	front_panel_fault_code
	integer*4	compress4


	front_panel_fault_code = lib$extzv (24,8,sdi3)

	if (front_panel_fault_code .eq. '18'x) then

	write(lun,55) 'SPIN-UP ERROR'
55	format(' ',t40,a)

	else if (front_panel_fault_code .eq. '14'x) then

	write(lun,55) 'UPROC FAULT'

	else if (front_panel_fault_code .eq. '1c'x) then

	write(lun,55) 'SDI ERROR'

	else if (front_panel_fault_code .eq. '12'x) then

	write(lun,55) 'MASTER/SLAVE ERROR'

	else if (front_panel_fault_code .eq. '1a'x) then

	write(lun,55) 'SERVO FINE POSITIONING ERROR'

	else if (front_panel_fault_code .eq. '16'x) then

	write(lun,55) 'SERVO COARSE POSITIONING ERROR'

	else if (front_panel_fault_code .eq. '1e'x) then

	write(lun,55) 'SPINDLE MOTOR INTERLOCK'

	else if (front_panel_fault_code .eq. '30'x) then

	write(lun,55) 'HDA OR SERVO BOARD OVER-TEMP'

	else if (front_panel_fault_code .eq. '38'x) then

	write(lun,55) 'R/W UNSAFE'

	else if (front_panel_fault_code .eq. '34'x) then

	write(lun,55) 'R/W COMMAND ERROR'

	else if (front_panel_fault_code .eq. '3c'x) then

	write(lun,55) 'SERVO/HDA INTERLOCK'

	else if (front_panel_fault_code .eq. '32'x) then

	write(lun,55) 'SERVO/MICRO INTERLOCK'

	else if (front_panel_fault_code .eq. '3a'x) then

	write(lun,55) 'RW/MICRO INTERLOCK'

	else if (front_panel_fault_code .eq. '36'x) then

	write(lun,55) 'CTL PAN/MICRO INTERLOCK'

	else if (front_panel_fault_code .eq. '3e'x) then

	write(lun,55) 'PER/MICRO INTERLOCK'

	else if (front_panel_fault_code .eq. '11'x) then

	write(lun,55) 'INDEX ERROR'

	else if (front_panel_fault_code .eq. '19'x) then

	write(lun,55) 'WRITE AND BAD IMBEDDED'

	else if (front_panel_fault_code .eq. '15'x) then

	write(lun,55) 'DRIVE DISABLED BY "DD" BIT'

	else if (front_panel_fault_code .eq. '1d'x) then

	write(lun,55) 'WRITE AND WRITE PROTECT'

	else if (front_panel_fault_code .eq. '13'x) then

	write(lun,55) 'SERVO DIAGNOSTICS FAILED'

	else if (front_panel_fault_code .eq. '1b'x) then

	write(lun,55) 'R/W DIAGNOSTICS FAILED'

	else if (front_panel_fault_code .eq. '17'x) then

	write(lun,55) 'IDLE LOOP DIAGNOSTICS FAILED'

	else if (front_panel_fault_code .eq. '3f'x) then

	write(lun,55) 'HARDCORE FAILURE'
	else

	write(lun,60) 'FRONT PANEL FAULT CODE, ',front_panel_fault_code,
	1 ' (HEX)'
60	format(' ',t40,a,z2.2,a)
	endif

	return
	end



	Subroutine MSLG$K_SML_DSK_AZTEC (lun)


	include 'src$:msghdr.for /nolist'


	byte		lun

	integer*4	mslg$l_cmd_ref

	integer*2	mslg$w_event
	integer*2	full_error_code
	integer*2	front_panel

	byte		l5b
	byte		pl5b

	integer*2	track_in_error
	integer*2	servo_state
	integer*2	spindle_state
	integer*2	distance_travelled

	integer*4	last_header_read

	integer*2	desired_track
	integer*2	starting_track
	integer*2	dsts
	integer*2	track_error_value

	byte		sel
	byte		sector

	integer*4	compress4
	integer*4	lib$extzv
	integer*4	selected_head
	integer*4	base_unit

	logical*1	drive_positioner_error

	equivalence	(emb(38),mslg$l_cmd_ref)
	equivalence	(emb(48),mslg$w_event)
	equivalence	(emb(78),full_error_code)
	equivalence	(emb(80),front_panel,l5b)
	equivalence	(emb(81),pl5b)
	equivalence	(emb(82),track_in_error,servo_state)
	equivalence	(emb(84),spindle_state,distance_travelled)
	equivalence	(emb(86),last_header_read,desired_track)
	equivalence	(emb(88),starting_track)
	equivalence	(emb(90),dsts,track_error_value)
	equivalence	(emb(92),sel)
	equivalence	(emb(93),sector)

	character*25	v1aztec_dsts(0:6)

	data		v1aztec_dsts(0)
	1 /'DISABLE WRITE*'/

	data		v1aztec_dsts(1)
	1 /'CARTRIDGE OR DOOR NOT OK*'/

	data		v1aztec_dsts(2)
	1 /'OVER TEMPERATURE*'/

	data		v1aztec_dsts(3)
	1 /'HEADS HOME*'/

	data		v1aztec_dsts(4)
	1 /'SPINDLE STOPPED*'/

	data		v1aztec_dsts(5)
	1 /'SPEED ERROR*'/

	data		v1aztec_dsts(6)
	1 /'SERVO TIMEOUT*'/


	character*27	v2aztec_dsts(15:15)

	data		v2aztec_dsts(15)
	1 /'FRONT PANEL SERIAL DATA IN*'/


	character*31	v1aztec_sel(0:4)

	data		v1aztec_sel(0)
	1 /'PEAK DETECTED READ THRESHOLDS*'/

	data		v1aztec_sel(1)
	1 /'EARLY-LATE INTEGRALS*'/

	data		v1aztec_sel(2)
	1 /'DAC MODE*'/

	data		v1aztec_sel(3)
	1 /'TACH. VELOCITY FEEDBACK TO A/D*'/

	data		v1aztec_sel(4)
	1 /'ACTUATOR CURRENT TO A/D*'/


	character*21	v2aztec_sel(7:7)

	data		v2aztec_sel(7)
	1 /'START A/D CONVERSION*'/


	character*6	v1front_panel(0:0)

	data		v1front_panel(0)
	1 /'FAULT*'/


	character*26	v2front_panel(8:10)

	data		v2front_panel(8)
	1 /'WRITE PROTECT, FIXED*'/

	data		v2front_panel(9)
	1 /'WRITE PROTECT, REMOVEABLE*'/

	data		v2front_panel(10)
	1 /'RUN*'/



	drive_positioner_error = .false.

	if (
	1 lib$extzv(0,5,mslg$w_event) .eq. 11
	1 .and.
	1 lib$extzv(5,11,mslg$w_event) .eq. 3
	1 ) then

	drive_positioner_error = .true.
	endif

	call linchk (lun,2)

	write(lun,15) 'FULL ERROR CODE',full_error_code
15	format(' ',t8,a,t28,z4.4)

	if (lib$extzv(0,5,full_error_code) .eq. '13'o) then

	minor_code = lib$extzv(5,11,full_error_code)

	if (minor_code .eq. '10'o) then

	write(lun,35) 'SEEK INTO GUARDBAND'

	else if (minor_code .eq. '20'o) then

	write(lun,35) 'NEGATIVE TRACK DIFFERENCE'

	else if (minor_code .eq. '30'o) then

	write(lun,35) 'DISTANCE TRAVELLED'

	else if (minor_code .eq. '40'o) then

	write(lun,35) 'NOT ONE TRACK AWAY'

	else if (minor_code .eq. '50'o) then

	write(lun,35) 'NOT ZERO TRACKS AWAY'

	else if (minor_code .eq. '60'o) then

	write(lun,35) 'DRIVE OFF TRACK'

	else if (minor_code .eq. '70'o) then

	write(lun,35) 'SERVO SAMPLE PARITY ERROR'

	else if (minor_code .eq. '100'o) then

	write(lun,35) 'HEAD SWITCH DEAD BAND'

	else if (minor_code .eq. '120'o) then

	write(lun,35) 'SERVO SAMPLE ERROR'

	else if (minor_code .eq. '130'o) then

	write(lun,35) 'A/D CONVERSION ERROR'

	else if (minor_code .eq. '140'o) then

	write(lun,35) 'HEAD SWITCH SSR TIMEOUT'

	else if (minor_code .eq. '150'o) then

	write(lun,35) 'HEAD SWITCH SSE ERROR'

	else if (minor_code .eq. '160'o) then

	write(lun,35) 'HEAD SWITCH L5B ERROR'

	else if (minor_code .eq. '170'o) then

	write(lun,35) 'ANL OR SCB.KT SERVO TIMEOUT'

	else if (minor_code .eq. '11'o) then

	write(lun,35) 'DSTS DISABLE WRITE ERROR'

	else if (minor_code .eq. '21'o) then

	write(lun,35) 'DSTS ANL SERVO TIMEOUT'

	else if (minor_code .eq. '31'o) then

	write(lun,35) 'D PROCESSOR SSR TIMEOUT'

	else if (minor_code .eq. '41'o) then

	write(lun,35) 'D PROCESSOR FOUND SSE'

	else if (minor_code .eq. '51'o) then

	write(lun,35) 'D PROCESSOR INDEX TIMEOUT'

	else if (minor_code .eq. '61'o) then

	write(lun,35) 'SERDES PARALLEL READY TIMEOUT'

	else if (minor_code .eq. '71'o) then

	write(lun,35) 'RESIDUE READY TIMEOUT'

	else if (minor_code .eq. '101'o) then

	write(lun,35) 'HEADER WORD RATE CLOCK TIMEOUT'

	else if (minor_code .eq. '111'o) then

	write(lun,35) 'DATA WORD RATE CLOCK TIMEOUT'

	else if (minor_code .eq. '121'o) then

	write(lun,35) 'REPLACE FOUND POSITIONER ERROR'

	else if (minor_code .eq. '131'o) then

	write(lun,35) 'ATTEMPT TO REVECTOR NON-LBN'

	else if (minor_code .eq. '141'o) then

	write(lun,35) 'RCT SEEK, READ OR EDC FAILED'

	else if (minor_code .eq. '151'o) then

	write(lun,35) 'RBN NOT FOUND IN RCT'

	else if (minor_code .eq. '161'o) then

	write(lun,35) 'SEEK TO RBN FAILED'

	else if (minor_code .eq. '171'o) then

	write(lun,35) 'SEEK BACK TO ORIGONAL FAILED'

	else if (minor_code .eq. '231'o) then

	write(lun,35) 'DRIVE ACLO ASSERTED'

	else if (minor_code .eq. '241'o) then

	write(lun,35) 'DRIVE OVER TEMPERATURE'

	else if (minor_code .eq. '251'o) then

	write(lun,35) 'DUPLICATE UNIT DETECTED'

	else if (minor_code .eq. '261'o) then

	write(lun,35) 'FRONT PANEL LOOP-BACK FAILED'

	else if (minor_code .eq. '271'o) then

	write(lun,35) 'WRONG STOPPED STATE (DS.STP)'

	else if (minor_code .eq. '301'o) then

	write(lun,35) 'SPIN DOWN TIMEOUT (DS.STP)'

	else if (minor_code .eq. '311'o) then

	write(lun,35) 'WRONG SPEED STATE (DS.STE)'

	else if (minor_code .eq. '321'o) then

	write(lun,35) 'SPIN UP TIMEOUT (DS.STE)'

	else if (minor_code .eq. '331'o) then

	write(lun,35) 'HEADS NOT OVER DISK (DS.HDH)'

	else if (minor_code .eq. '341'o) then

	write(lun,35) 'HEADS HOME TIMEOUT (DS.HDH)'

	else if (minor_code .eq. '351'o) then

	write(lun,35) 'HEADS HOME NEVER WENT AWAY'

	else if (minor_code .eq. '361'o) then

	write(lun,35) 'UNSAFE ATTEMPT TO UNLOCK DOOR'

	else if (minor_code .eq. '371'o) then

	write(lun,35) 'CARTRIDGE OR DOOR ERROR (DS.COD)'

	else if (minor_code .eq. '401'o) then

	write(lun,35) 'ARCS SEEK HARD ERROR'

	else if (minor_code .eq. '411'o) then

	write(lun,35) 'ARCS SECTOR HARD ERROR'

	else if (minor_code .eq. '421'o) then

	write(lun,35) 'ARCS DETENT HARD ERROR'

	else if (minor_code .eq. '431'o) then

	write(lun,35) 'SERVO ERROR RATE TOO HIGH'

	else if (minor_code .eq. '441'o) then

	write(lun,35) 'SPINDLE MACH. FAILED TO INIT SERVO'

	else if (minor_code .eq. '501'o) then

	write(lun,35) 'TPD DIAGNOSTICS FAILED'

	else if (minor_code .eq. '511'o) then

	write(lun,35) 'TPD DATA BUS CHECK FAILED'

	else if (minor_code .eq. '521'o) then

	write(lun,35) 'A/D OFFSET/TIMING FAILED'

	else if (minor_code .eq. '531'o) then

	write(lun,35) 'D/A OFFSET/TIMING FAILED'

	else if (minor_code .eq. '541'o) then

	write(lun,35) 'A/D - D/A LINEARITY FAILED'

	else if (minor_code .eq. '551'o) then

	write(lun,35) 'INTEGRATOR OFFSET FAILED'

	else if (minor_code .eq. '561'o) then

	write(lun,35) 'DRIVE CARD FAILED INIT TEST'

	else if (minor_code .eq. '571'o) then

	write(lun,35) 'DRIVE CABLE NOT IN PLACE'
	else

	write(lun,17) 'ERROR CODE #',minor_code
17	format(' ',t40,a,o5.5,' (OCTAL)')
	endif
	endif

c
c	other than drive, positioner error
c

	if (.not. drive_positioner_error) then

	call linchk (lun,1)

	write(lun,20) 'FRONT PANEL',front_panel
20	format(' ',t8,a,t28,z4.4)

	call output (lun,front_panel,v1front_panel,0,0,0,'1')

	base_unit = lib$extzv(1,7,front_panel) * 2

	call linchk (lun,1)

	write(lun,22) 'BASE UNIT #',base_unit
22	format(' ',t40,a,i<compress4 (base_unit)>,'.')

	call output (lun,front_panel,v2front_panel,8,8,10,'1')

	call linchk (lun,2)

	write(lun,25) 'TRACK IN ERROR',track_in_error,
	1 'TRACK #',lib$extzv(0,16,track_in_error),'. AT ERROR'
25	format(' ',t8,a,t28,z4.4,/,
	1 t40,a,i<compress4 (lib$extzv(0,16,track_in_error))>,a)

	call linchk (lun,2)

	write(lun,30) 'SPINDLE STATE',spindle_state
30	format(' ',t8,a,t28,z4.4)

	if (spindle_state .eq. 0) then

	write(lun,35) 'ONLINE'
35	format(' ',t40,a)

	else if (spindle_state .eq. 2) then

	write(lun,35) 'I/O RUNDOWN'

	else if (spindle_state .eq. 3) then

	write(lun,35) 'BEGIN UNLOAD'
	else if (spindle_state .eq. 4) then

	write(lun,35) 'HEADS HOME WAIT'

	else if (spindle_state .eq. 5) then

	write(lun,35) 'END UNLOAD'

	else if (spindle_state .eq. 6) then

	write(lun,35) 'SPIN DOWN WAIT'

	else if (spindle_state .eq. 7) then

	write(lun,35) 'STOPPED'

	else if (spindle_state .eq. 8) then

	write(lun,35) 'CHECK DOOR'

	else if (spindle_state .eq. 9) then

	write(lun,35) 'SPIN UP WAIT'

	else if (spindle_state .eq. 10) then

	write(lun,35) 'PURGE WAIT'

	else if (spindle_state .eq. 11) then

	write(lun,35) 'BEGIN LOAD'

	else if (spindle_state .eq. 12) then

	write(lun,35) 'LOAD WAIT'

	else if (spindle_state .eq. 13) then

	write(lun,35) 'INIT SERVO'

	else if (spindle_state .eq. 14) then

	write(lun,35) 'OFFLINE'

	else if (spindle_state .eq. 15) then

	write(lun,35) 'INITIAL SPIN-UP'
	else

	write(lun,40) lib$extzv(0,16,spindle_state)
40	format(' ',t40,'ERROR CODE #',
	1 i<compress4 (lib$extzv(0,16,spindle_state))>,'.')
	endif

	call linchk (lun,1)

	write(lun,45) 'HEADER/LBN',last_header_read
45	format(' ',t8,a,t24,z8.8)

	last_header_read = lib$extzv(0,27,last_header_read)

	if (mslg$l_cmd_ref .ne. 0) then

	call linchk (lun,1)

	write(lun,50) last_header_read
50	format(' ',t40,'LOGICAL BLOCK #',i<compress4 (last_header_read)>,'.')
	else

	call linchk (lun,1)

	if (lib$extzv(27,1,last_header_read) .eq. 1) then

	write(lun,52) 'FIXED MEDIA'
52	format(' ',t40,a)
	else

	write(lun,52) 'REMOVEABLE MEDIA'
	endif

	call disk_header (lun,last_header_read)
	endif

	call linchk (lun,1)

	write(lun,55) 'DSTS',dsts
55	format(' ',t8,a,t28,z4.4)

	call output (lun,dsts,v1aztec_dsts,0,0,6,'0')

	call output (lun,dsts,v2aztec_dsts,15,15,15,'0')
	else

c
c	drive, positioner error
c

	call linchk (lun,2)

	write(lun,60) 'L5B',l5b,'PL5B',pl5b
60	format(' ',t8,a,t30,z2.2,/,
	1 t8,a,t30,z2.2)

	call linchk (lun,2)

	write(lun,65) 'SERVO STATE',servo_state
65	format(' ',t8,a,t28,z4.4)

	if (servo_state .eq. 0) then

	write(lun,70) 'FAST SEEK'
70	format(' ',t40,a,:i<compress4 (lib$extzv(0,16,servo_state))>,:a)

	else if (servo_state .eq. 1) then

	write(lun,70) 'MEDIUM SEEK'

	else if (servo_state .eq. 2) then

	write(lun,70) 'SLOW SEEK'

	else if (servo_state .eq. 3) THEN

	write(lun,70) 'ONE TRACK AWAY'

	else if (servo_state .eq. 4) then

	write(lun,70) 'ZERO TRACKS AWAY'

	else if (servo_state .eq. 5) then

	write(lun,70) 'DETENT'

	else if (servo_state .eq. 6) then

	write(lun,70) 'RTZ IN PROGRESS'

	else if (servo_state .eq. 7) then

	write(lun,70) 'ERROR STATE'

	else if (servo_state .eq. 8) then

	write(lun,70) 'FAKE SAMPLES (HEAD LOAD/UNLOAD'
	else

	write(lun,70) 'STATE #',lib$extzv(0,16,servo_state),'.'
	endif

	call linchk (lun,2)

	write(lun,75) 'DISTANCE TRAVELLED',
	1 (lib$extzv(0,16,distance_travelled),i = 1,2),
	1 '. TRACK(S)'
75	format(' ',t8,a,t28,z4.4,/,
	1 t40,i<compress4 (lib$extzv(0,16,distance_travelled))>,a)

	call linchk (lun,2)

	write(lun,80) 'DESIRED TRACK',desired_track,
	1 'TRACK #',lib$extzv(0,16,desired_track),'.'
80	format(' ',t8,a,t28,z4.4,/,
	1 t40,a,i<compress4 (lib$extzv(0,16,desired_track))>,a)

	call linchk (lun,2)

	write(lun,82) 'STARTING TRACK',starting_track,
	1 'TRACK #',lib$extzv(0,16,starting_track),'.'
82	format(' ',t8,a,t28,z4.4,/,
	1 t40,a,i<compress4 (lib$extzv(0,16,starting_track))>,a)

	call linchk (lun,1)

	write(lun,84) 'TRACK ERROR VALUE',track_error_value
84	format(' ',t8,a,t28,z4.4)
	endif

	call linchk (lun,1)

	write(lun,85) 'SEL',sel
85	format(' ',t8,a,t30,z2.2)

	call output (lun,sel,v1aztec_sel,0,0,4,'1')

	selected_head = lib$extzv(5,2,sel)

	call linchk (lun,1)

	if (selected_head .eq. 0) then

	write(lun,90) selected_head,'(REMOVEABLE, TOP)'
90	format(' ',t40,'HEAD #',i<compress4 (selected_head)>,'. ',a)

	else if (selected_head .eq. 1) then

	write(lun,90) selected_head,'(REMOVEABLE, BOTTOM)'

	else if (selected_head .eq. 2) then

	write(lun,90) selected_head,'(FIXED, TOP)'

	else if (selected_head .eq. 3) then

	write(lun,90) selected_head,'(FIXED, BOTTOM)'
	endif

	call output (lun,sel,v2aztec_sel,7,7,7,'1')

	call linchk (lun,2)

	write(lun,95) 'SECTOR IN ERROR',sector
95	format(' ',t8,a,t30,z2.2)

	if (sector .ne. '255'o) then

	write(lun,100) lib$extzv(0,8,sector)
100	format(' ',t40,'SECTOR #',i<compress4 (lib$extzv(0,8,sector))>,'.')
	endif

	return
	end



	Subroutine MSLG$K_BUS_ADDR_AZTEC (lun)


	include 'src$:msghdr.for /nolist'


	byte		lun

	integer*2	full_error_code
	integer*2	start_word_count
	integer*2	base_ram_address
	integer*2	acs

	equivalence	(emb(66),full_error_code)
	equivalence	(emb(68),start_word_count)
	equivalence	(emb(70),base_ram_address)
	equivalence	(emb(72),lesi)

	character*34	v1acs(3:7)

	data		v1acs(3)
	1 /'HOST HAS READ POLL REGISTER*'/

	data		v1acs(4)
	1 /'PURGE COMPLETE*'/

	data		v1acs(5)
	1 /'HOST BUS DATA PARITY ERROR*'/

	data		v1acs(6)
	1 /'CABLE PARITY ERROR ON WRITE*'/

	data		v1acs(7)
	1 /'LAST TRANSFER NON-EXISTENT MEMORY*'/

	integer*4	start_byte_count
	integer*4	host_bus_type
	integer*4	compress4
	integer*4	lib$extzv


	call linchk (lun,1)

	write(lun,15) 'FULL ERROR CODE',full_error_code
15	format(' ',t8,a,t28,z4.4)

	call aztec_full_error_code1 (lun,full_error_code)

	start_byte_count = start_word_count * 2

	call linchk (lun,2)

	write(lun,20) 'START BYTE COUNT',start_word_count,
	1 start_byte_count,'. BYTES'
20	format(' ',t8,a,t28,z4.4,/,
	1 T40,i<compress4 (start_byte_count)>,a)

	call linchk (lun,2)

	write(lun,25) 'BASE RAM ADDRESS',(base_ram_address,i = 1,2),' (OCTAL)'
25	format(' ',t8,a,T28,z4.4,/,
	1 t40,o6.6,a)

	call linchk (lun,1)

	write(lun,30) ACS,acs
30	format(' ',t8,a,z4.4)

	host_bus_type = lib$extzv(0,3,acs)

	call linchk (lun,1)

	if (host_bus_type .eq. 1) then

	write(lun,35) 'UNIBUS'
35	format(' ',t40,'HOST BUS IS A ',a,:i<compress4 (host_bus_type)>,:a)

	else if (host_bus_type .eq. 2) then

	write(lun,35) 'Q-BUS'
	else

	write(lun,35) 'TYPE #',host_bus_type,'.'
	endif

	call output (lun,acs,v1acs,3,3,7,'0')

	return
	end


	Subroutine STATUS_AND_EVENT_CODES (lun)

	Include  'SRC$:MSGHDR.FOR /nolist' 


	Byte		lun

	Integer*2	str_len

	Integer*4	value_1, compress4, code, sub_code

	Character*25	Msg_part1
	Character*33	Msg_part2


C
C Decode the status and event codes. 
C
	Call STATUS_AND_EVENT_DECODE (msg_part1,msg_part2,value_1)

C
C Determine whether it was decoded and output the text.
C

	Call LINCHK (lun,2)

	Str_len = LIB$EXTZV (0,16,msg_part1) 

	If (str_len .NE. 1) then
	  Write (lun,15) msg_part1
15	  Format (' ',T40,A<str_len>)

	Else 
C Not decoded due to unknown code, extract the status/event code
C and output the it in decimal.
C
	  Code = LIB$EXTZV(0,5,emb(48))

	  Write (lun,20) 'UNKNOWN CODE #', code
20	  Format (' ',T40,A,Z2.2,'(X)')

	Endif

C
C Determine whether it was decoded and output the text.
C
	Str_len = LIB$EXTZV (0,16,msg_part2)

	Call LINCHK (lun,1)

	If (
	1 (str_len .NE. 1)
	1 .AND.
	1 (value_1 .NE. -1)
	1 ) then

	  Write (lun,17) value_1, msg_part2
17	  Format (' ',T40,I<COMPRESS4 (value_1)>,A<str_len>)


	Else if (
	1 (str_len .NE. 1) 
	1 .AND.
	1 (value_1 .EQ. -1) 
	1 ) then

	  Write (lun,15) msg_part2


C Not decoded due to unknown subcode, extract the status/event subcode and
C output the it in decimal.
C
	Else if (str_len .EQ. 1) then

	  Sub_code = LIB$EXTZV(5,11,emb(48))

	  Write (lun,25) 'UNKNOWN SUBCODE #', sub_code
25	  Format (' ',T40,A17,Z4.4,'(X)')

	Endif


	return

	end
