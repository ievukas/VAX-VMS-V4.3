c
c Version:	'V04-000'
c
c****************************************************************************
c*									    *
c*  COPYRIGHT (c) 1978, 1980, 1982, 1984 BY				    *
c*  DIGITAL EQUIPMENT CORPORATION, MAYNARD, MASSACHUSETTS.		    *
c*  ALL RIGHTS RESERVED.						    *
c* 									    *
c*  THIS SOFTWARE IS FURNISHED UNDER A LICENSE AND MAY BE USED AND COPIED   *
c*  ONLY IN  ACCORDANCE WITH  THE  TERMS  OF  SUCH  LICENSE  AND WITH THE   *
c*  INCLUSION OF THE ABOVE COPYRIGHT NOTICE. THIS SOFTWARE OR  ANY  OTHER   *
c*  COPIES THEREOF MAY NOT BE PROVIDED OR OTHERWISE MADE AVAILABLE TO ANY   *
c*  OTHER PERSON.  NO TITLE TO AND OWNERSHIP OF  THE  SOFTWARE IS  HEREBY   *
c*  TRANSFERRED.							    *
c* 									    *
c*  THE INFORMATION IN THIS SOFTWARE IS  SUBJECT TO CHANGE WITHOUT NOTICE   *
c*  AND  SHOULD  NOT  BE  CONSTRUED AS  A COMMITMENT BY DIGITAL EQUIPMENT   *
c*  CORPORATION.							    *
c* 									    *
c*  DIGITAL ASSUMES NO RESPONSIBILITY FOR THE USE  OR  RELIABILITY OF ITS   *
c*  SOFTWARE ON EQUIPMENT WHICH IS NOT SUPPLIED BY DIGITAL.		    *
c* 									    *
c*									    *
c****************************************************************************
c
c
c
c	Author	Brian Porter		Creation date	03-AUG-1983
c

c++
c	Functional description:
c
c	Modified by:
c
C	V03-004	EAD0197		Elliott A. Drayton		21-Jun-1984
C		Changed code to use LSTLUN and RECORD_SIZE from SYECOM.
C
C	V03-003	SAR0278		Sharon A. Reynolds	21-Jun-1984
C		Added TMSCP support.
C
C	V03-002	SAR0171		Sharon A. Reynolds,	11-Nov-1983
C		- Removed the 'b_logmscp' routine.
C		- Changed the carriage control for use with ERF.
C
c	v03-001	BP0001		Brian Porter,		07-SEP-1983
c		Added 'no-unit' code.
c**
c--


	Subroutine LOGMSCP (lun,record_length)


	include		'src$:msghdr.for/nolist'
	include		'src$:emblmdef.for/nolist'
	include		'src$:syecom.for/nolist'

	byte		lun
	integer*4	record_length

	integer*2	logmscp_type
	equivalence	(emb(16),logmscp_type)

	byte		mscp_packet(476)
	equivalence	(emb(36),mscp_packet(1))

	integer*4	mscp$$b_opcode
	integer*4	mscp$$b_endcode
	integer*4	mslg$$b_format
	integer*4	packet_length
	integer*4	compress4


	call FRCTOF (lstlun)
	call HEADER (lstlun)
	call LOGGER (lstlun,'ERL$LOGMSCP ENTRY')

	call LOGMSCP_HEADER ()

	packet_length = record_size - 36

	call LINCHK (lstlun,1)

	write(lstlun,10)
10	format(' ',:)

	if (logmscp_type .eq. 9) then

	mscp$$b_opcode = lib$extzv(0,7,emb(44))
	mscp$$b_endcode = lib$extzv(0,8,emb(44))

	call LINCHK (lstlun,1)

	write(lstlun,15) 'UNEXPECTED END MESSAGE "MSCP$W_STATUS"'
15	format(' ',t8,a)

	call MOVC3 (%val(packet_length),emb(36),emb(38))
	call MSCP$B_OPCODE_DISPATCHER (lstlun,mscp$$b_endcode,.true.,.false.)

	else if (logmscp_type .eq. 10) then

	mscp$$b_opcode = lib$extzv(0,7,emb(44))
	mscp$$b_endcode = lib$extzv(0,8,emb(44))

	call LINCHK (lstlun,1)
	write(lstlun,15) 'UNEXPECTED ATTENTION CONTROL MESSAGE'

	call MOVC3 (%val(packet_length),emb(36),emb(38))

	call LINCHK (lstlun,1)
	write(lstlun,10)

	call MSCP_FIRST_TWELVE_BYTES2 (lstlun,.true.)

	if (packet_length .gt. 12) then

	call LINCHK (lstlun,1)
	write(lstlun,10)

	call DUMPREG (lstlun,(((packet_length - 12) + 3)/4),emb(50))
	endif

	else if (logmscp_type .eq. 11) then

	mslg$$b_format = lib$extzv(0,7,emb(44))

	call LINCHK (lstlun,1)

	if (
	1 mslg$$b_format .eq. 0
	1 .or.
	1 mslg$$b_format .eq. 1
	1 ) then

	write(lstlun,15) 'NO-UNIT DATAGRAM'
	else

	write(lstlun,15) 'DATAGRAM FOR NON-EXISTING "UCB"'
	endif

c
c	Although the 'emblmdef' format is not part of this kind of error log
c	entry it is necessary, because of the implementation chosen, to zero
c	the equivalent 'emb$b_lm_type' field and re-position the "mscp" portion
c	of the entry for the output routines.
c

	call MOVC3 (%val(packet_length),emb(36),emb(38))

	emb$b_lm_type  = 0

	if (mslg$$b_format .eq. 0) then
	call MSLG$K_CNT_ERR (lstlun,packet_length)

	else if (mslg$$b_format .eq. 1) then
	call MSLG$K_BUS_ADDR (lstlun,packet_length)

	else if (
	1 mslg$$b_format .eq. 2		! Disk transfer error
	1 .OR.
	1 mslg$$b_format .EQ. 5		! Tape transfer error
	1) then
	call DISK_TAPE_TRANSFER_ERRORS (lstlun,packet_length)

	else if (
	1 mslg$$b_format .eq. 3		! SDI error
	1 .OR.
	1 mslg$$b_format .eq. 6		! STI error
	1 .OR.
	1 mslg$$b_format .eq. 7		! STI drive error
	1 .OR.
	1 mslg$$b_format .eq. 8		! STI formatter error
	1 ) then
	call SDI_STI_ERRORS (lstlun,packet_length)

	else if (mslg$$b_format .eq. 4) then 	! Small disk error
	call MSLG$K_SML_DSK (lstlun,packet_length)
	else

	call LINCHK (lstlun,1)

	write(lstlun,10)

	call DUMPREG (lstlun,(((packet_length) + 3)/4),emb(38))
	endif

c
c	The IF-THEN-ELSE should be extended at this point to add
c	additional "logmscp_type" formats.
c

	else

	call LINCHK (lstlun,1)

	write(lstlun,20) logmscp_type
20	format(' ',t8,'ENTRY TYPE #',
	1 i<compress4 (lib$extzv(0,16,logmscp_type))>,'.')

	call LINCHK (lstlun,1)

	write(lstlun,10)

	call DUMPREG (lstlun,(((packet_length) + 3)/4),emb(36))
	endif

	return
	end




	Subroutine LOGMSCP_HEADER ()


	include		'src$:msghdr.for/nolist'
	include		'src$:syecom.for/nolist'

	byte		class_driver_array(4)
	integer*4	class_driver
	character*4	class_driver_string
	equivalence	(emb(18),class_driver_array(1),class_driver_string,
	1 class_driver)

	integer*4	cddb$q_cntrlid_array(2)
	integer*4	cddb$q_cntrlid1
	equivalence	(cddb$q_cntrlid_array(1),cddb$q_cntrlid1)
	integer*4	cddb$q_cntrlid2
	equivalence	(cddb$q_cntrlid_array(2),cddb$q_cntrlid2)
	equivalence	(emb(22),cddb$q_cntrlid_array(1))

	byte		cddb$b_systemid_array(6)
	integer*4	cddb$b_systemid1
	equivalence	(cddb$b_systemid_array(1),cddb$b_systemid1)
	integer*2	cddb$b_systemid2
	equivalence	(cddb$b_systemid_array(5),cddb$b_systemid2)
	equivalence	(emb(30),cddb$b_systemid_array(1))

	byte		fao_array(4)
	character*4	fao_string
	equivalence	(fao_array(1),fao_string)

	external	sys$fao
	logical*4	sys$fao



	call LINCHK (lstlun,2)

	write(lstlun,10) 'CLASS DRIVER',class_driver
10	format(/' ',t8,a,t24,z8.8)

	if (sys$fao('!AF',,fao_string,%val(4),class_driver_array(1))) then

	call LINCHK (lstlun,1)

	write(lstlun,15) fao_string
15	format(' ',t40,'/',a,'/')
	endif

	call LINCHK (lstlun,2)

	write(lstlun,20) cddb$q_cntrlid1,cddb$q_cntrlid2
20	format(' ',t8,'CDDB$Q_CNTRLID',t24,z8.8,/,
	1 t24,z8.8)

	call CDDB$Q_CNTRLID (lstlun,cddb$q_cntlrid1,cddb$q_cntrlid2)

	call LINCHK (lstlun,2)

	write(lstlun,25) cddb$b_systemid1,cddb$b_systemid2
25	format(/' ',t8,'CDDB$B_SYSTEMID',t24,z8.8,/,
	1 t28,z4.4)

	return

	end
