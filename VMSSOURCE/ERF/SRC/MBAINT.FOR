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

c	Author	Brian Porter			Creation date	18-NOV-1981

c++
c	Functional description:
c
c	This module displays massbus adapter interrupts which occur
c	on behalf of itself.
c
c	Modified by:
C
C	V03-003	SAR0147		Sharon A. Reynolds,	5-Oct-1983
C		Added an SYE update that makes the register heralds
C		generic and adds support for 11/7xx.
C
C	V03-002	SAR0081		Sharon A. Reynolds,	20-Jun-1983
C		Changed the carriage control in the 'format' statements
C		for use with ERF.
C
C	V03-001	SAR0055		Sharon A. Reynolds,	13-Jun-1983
C		Removed brief/cryptic support.
C
c**
c--



	Subroutine MBA_INTERRUPTS (lun,option)


	include 'src$:msghdr.for /nolist'


	byte		lun

	character*1	option


	if (
	1 lib$extzv(24,8,emb$l_hd_sid) .eq. 255
	1 .or.
	1 lib$extzv(24,8,emb$l_hd_sid) .eq. 1
	1 .or.
	1 LIB$EXTZV(24,8,emb$l_hd_sid) .EQ. 4
	1 ) then

	if (option .eq. 'S') then

	call rh780_interrupt (lun)
	endif
c
c	For future expansion the IF-THEN-ELSE should be
c	extended here.
c

	endif

	return

	end



c++
c	This routine displays the massbus interrupt error log entry for the
c	11/780.  The format of the error log record is as
c	follows.
c
c	+---------------------------------+
c	|      configuration register     |
c	+---------------------------------+
c	|         control register        |
c	+---------------------------------+
c	|          status register        |
c	+---------------------------------+
c	|     virtual address register    |
c	+---------------------------------+
c	|       byte count register       |
c	+---------------------------------+
c	|      diagnostic register        |
c	+---------------------------------+
c	|      selected map register      |
c	+---------------------------------+
c	|    command address register     |
c	+---------------------------------+
c--




	Subroutine RH780_INTERRUPT (lun)


	include 'src$:msghdr.for /nolist'


	byte		lun

	integer*4	rh780_control_register(6)
	integer*4	diagnostic_register
	integer*4	interrupt_pc
	integer*4	interrupt_psl
	integer*4	adapter_tr
	integer*4	dummy_variable
	integer*4	compress4

	logical*1	diagnostic_mode

	equivalence	(emb(16),rh780_control_register)
	equivalence	(emb(36),diagnostic_register)
	equivalence	(emb(40),adapter_tr)
	equivalence	(emb(44),interrupt_pc)
	equivalence	(emb(48),interrupt_psl)


	call frctof (lun)

	call header (lun)

	call logger (lun,'"RH" INTERRUPT')

	diagnostic_mode = .false.

	if (lib$extzv(3,1,rh780_control_register(2)) .eq. 1)
	1 diagnostic_mode = .true.

	if (lib$extzv(0,4,diagnostic_register) .ne. 0) diagnostic_mode = .true.

	call linchk (lun,2)

	write(lun,5) interrupt_pc
5	format(/' ',t8,'ERROR PC',t24,z8.8)

	if (.not. diagnostic_mode) then

	call vaxpsl (lun,interrupt_psl)

	call linchk (lun,2)

	write(lun,10) adapter_tr
10	format(/' ',t8,'ADAPTER TR# ',i<compress4 (adapter_tr)>,'.')

	call rh780_control_registers (lun,rh780_control_register,
	1 dummy_variable)
	else

	call linchk (lun,11)

	write(lun,15) interrupt_psl,adapter_tr,
	1 (rh780_control_register(i),i = 1,2)
15	format(/' ',t8,'ERROR PSL',t24,z8.8,//,
	1 t8,'ADAPTER TR# ',i<compress4 (adapter_tr)>,'.',//,
	1 t8,'"RH" CSR',t24,z8.8,/,
	1 t8,'"RH" CR',t24,z8.8)

	if (lib$extzv(3,1,rh780_control_register(2)) .eq. 1) then

	call linchk (lun,1)

	write(lun,30)
	endif

	write(lun,20) (rh780_control_register(i),i = 3,5)
20	format(' ',t8,'"RH" SR',t24,z8.8,/,
	1 t8,'"RH" VAR',t24,z8.8,/,
	1 t8,'"RH" BCR',t24,z8.8)
	endif

	call linchk (lun,1)

	write(lun,25) diagnostic_register
25	format(' ',t8,'"RH" DR',t24,z8.8)

	if (lib$extzv(0,4,diagnostic_register) .ne. 0) then

	call linchk (lun,1)

	write(lun,30)
30	format(' ',t40,'DIAGNOSTIC MODE')
	endif

	return
	end
