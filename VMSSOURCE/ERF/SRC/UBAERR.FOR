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
C	Author	Brian Porter		Creation date	06-MAY-1981
C

c++
c	Functional description:
c
c	This module displays uba entries for the 11/730.
c
c	Modified by:
c
C	V03-003	SAR0159		Sharon A. Reynolds,	13-Oct-1983
C		Added an SYE update that makes register heralds
C		generic.
C
C	V03-002	SAR0102		Sharon A. Reynolds,	20-Jun-1983
C		Changed the carriage control in the 'format' statements
C		for use with ERF.
C
C	V03-001	SAR0053		Sharon A. Reynolds,	13-Jun-1983
C		Removed brief/cryptic support.
C
c	v02-003	BP0003		Brian Porter,		19-NOV-1981
c		Added dispatching.
c
c	v02-002	BP0002		Brian Porter,		11-NOV-1981
c		Changed register herald.
c
c	v02-001	BP0001		Brian Porter,		01-JUL-1981
c		Added call to LOGGER.
c**
c--



	subroutine uba_errors (lun,option)



	include 'src$:msghdr.for /nolist'



	byte		lun

	character*1	option



	if (lib$extzv(24,8,emb$l_hd_sid) .eq. 3) then

	if (option .eq. 'S') then

	call dw730_error (lun)
	endif
c
c	for future expansion the IF-THEN-ELSE should be expanded
c	at this point.
c
	endif

	return
	end



	subroutine dw730_error (lun)



	include	'src$:msghdr.for /nolist'


	byte		lun

	integer*4	uba_csr

	equivalence	(emb(16),uba_csr)

	character*20	v1uba_csr(14:16)

	data		v1uba_csr(14)	/'WRITE ERROR*'/

	data		v1uba_csr(15)	/'MAP PARITY ERROR*'/

	data		v1uba_csr(16)	/'NON-EXISTENT MEMORY*'/

	character*21	v2uba_csr(31:31)

	data		v2uba_csr(31)	/'READ DATA SUBSTITUTE*'/



	call frctof (lun)

	call header (lun)

	call logger (lun,'"DW" ERROR')

	call linchk (lun,2)

	write(lun,10) uba_csr
10	format(/' ',t8,'"DW" CSR',t24,z8.8)

	call output (lun,uba_csr,v1uba_csr,14,14,16,'0')

	call output (lun,uba_csr,v2uba_csr,31,31,31,'0')

	Return
	End
