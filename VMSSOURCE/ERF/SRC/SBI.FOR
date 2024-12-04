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

	SUBROUTINE SBI (LUN)

C
C	AUTHOR	BRIAN PORTER		CREATION DATE	27-AUG-1979
C
C++
C	Functional desciption:
C
C	Modified by:
C
C	V03-003 EAD0001		Elliott A. Drayton	18-Feb-1984
C		Add UVAX-1 support.
C
C	V03-002	SAR0096		Sharon A. Reynolds,	20-Jun-1983
C		Changed the carriage control in the 'format' statements
C		for use with ERF.
C
C	v03-001	BP0001		Brian Porter,		05-APR-1982
C		Corrected sbi alert bug.
C**
C--


	INCLUDE 'SRC$:MSGHDR.FOR /NOLIST'
	INCLUDE 'SRC$:SYECOM.FOR /NOLIST'





	BYTE		LUN

	INTEGER*4	SBI_FAULT

	INTEGER*4	SBI_COMP

	INTEGER*4	SBI_MAINT

	INTEGER*4	SBI_ERR

	INTEGER*4	SBI_TO

	INTEGER*4	SILO(0:15)

	INTEGER*4	SBI_REGA(0:15)

	INTEGER*4	ERROR_PC_780

	INTEGER*4	ERROR_PSL_780

	integer*4	error_pc_750

	integer*4	error_psl_750

	INTEGER*4	FIELD

	EQUIVALENCE	(SBI_FAULT,EMB(16))

	EQUIVALENCE	(SBI_COMP,EMB(20))

	EQUIVALENCE	(SBI_MAINT,EMB(24))

	EQUIVALENCE	(SBI_ERR,EMB(28))

	EQUIVALENCE	(SBI_TO,EMB(32))

	EQUIVALENCE	(SILO,EMB(36))

	EQUIVALENCE	(SBI_REGA,EMB(100))

	EQUIVALENCE	(ERROR_PC_780,EMB(164))

	EQUIVALENCE	(ERROR_PSL_780,EMB(168))

	equivalence	(error_pc_750,emb(16))

	equivalence	(error_psl_750,emb(20))

	integer*4	memory_registers_uv1(0:4)

	equivalence	(memory_registers_uv1(0),emb(16))

	PARAMETER	ASYNC_WRITE = 7

	integer*4	compress4

	logical*1	diagnostic_mode


	CALL FRCTOF (LUN)

	call header (lun)

c
c	11/780, 782, 785 support
c

	if (
	1 lib$extzv(24,8,emb$l_hd_sid) .eq. 255
	1 .or.
	1 lib$extzv(24,8,emb$l_hd_sid) .eq. 1
	1 ) then

	if (emb$w_hd_entry .eq. '07'x) then

	call logger (lun,'ASYNCHRONOUS WRITE')
	else

	call logger (lun,'SBI FAULT')
	endif

	call linchk (lun,2)

	write(lun,10) error_pc_780
10	format(/' ',t8,'ERROR PC',t24,z8.8)

	call vaxpsl (lun,error_psl_780)

	diagnostic_mode = .false.

	if (iand(sbi_maint,'f05ff900'x) .ne. 0) diagnostic_mode = .true.

	if (.not. diagnostic_mode) then

	CALL SBI_FAULTREG (LUN,SBI_FAULT)

	CALL SBI_COMPARATOR (LUN,SBI_COMP)

	CALL SBI_MAINTENANCE (LUN,SBI_MAINT)

	CALL SBI_ERROR (LUN,SBI_ERR)

	CALL SBI_TIMEOUT (LUN,SBI_TO)
	else

	call linchk (lun,6)

	write(lun,28) sbi_fault,sbi_comp,sbi_maint,sbi_err,sbi_to
28	format(' ',t8,'SBIFS',t24,z8.8,/,
	1 t8,'SBISC',t24,z8.8,/,
	1 t8,'SBIMT',t24,z8.8,/,
	1 t40,'DIAGNOSTIC MODE',/,
	1 t8,'SBIER',t24,z8.8,/,
	1 t8,'SBITA',t24,z8.8)
	endif

	IF (JIAND(SBI_COMP,'A0000000'X) .NE. 0
	1 .OR.
	2 JIAND(SBI_FAULT,'10000'X) .NE. 0) THEN

	if (.not. diagnostic_mode) then

	CALL LINCHK (LUN,3)

	WRITE(LUN,30)
30	FORMAT(/' ','SBI SILO LOCKED, DETAILED SUMMARY',/)

	DO 50,I = 0,15

	CALL SBI_SILO (LUN,SILO(I))

50	CONTINUE
	else

	CALL LINCHK (LUN,3)

	WRITE(LUN,52)
52	FORMAT(/' ','SBI SILO LOCKED',/)

	do 54,i = 0,15

	call linchk (lun,1)

	write(lun,53) silo(i)
53	format(' ',t24,z8.8)

54	continue
	endif
	ENDIF

	DO 80,I = 0,15

	IF (SBI_REGA(I) .NE. 0) THEN

	CALL LINCHK (LUN,2)

	WRITE(LUN,55) I
55	FORMAT(/' ','ADAPTER TR# ',I<compress4 (i)>,'.')

	CALL CLASSIFY (LUN,SBI_REGA(I))
	ENDIF

80	CONTINUE

c
c	11/750 support
c

	else if (lib$extzv(24,8,emb$l_hd_sid) .eq. 2) then

	if (emb$w_hd_entry .eq. '07'x) then

	call logger (lun,'WRITE BUS ERROR')
	endif

	write(lun,10) error_pc_750

	call vaxpsl (lun,error_psl_750)

c
c	UVAX-1 support
c

	else if (lib$extzv(24,8,emb$l_hd_sid) .eq. 7) then

	if (emb$w_hd_entry .eq. 7) then

	call logger (lun,'ASYNCHRONOUS WRITE')

	do 85,i = 1,16

	if (lib$extzv(15,1,memory_registers_uv1(i)) .eq. 1) then

	call memory_register_uv1 (lun,memory_registers_uv1)
	endif

85	continue

	endif

c
c	The IF-THEN-ELSE must be expanded at this point
c	to provide additional CPU "ASYNCHRONOUS WRITE
c	ERROR" support.
c

	endif

	RETURN



	ENTRY B_SBI (LUN)



	call header (lun)

	if (
	1 lib$extzv(24,8,emb$l_hd_sid) .eq. 255
	1 .or.
	1 lib$extzv(24,8,emb$l_hd_sid) .eq. 1
	1 ) then

	if (emb$w_hd_entry .eq. '07'x) then

	call logger (lun,'ASYNCHRONOUS WRITE')
	ELSE

	call logger (lun,'SBI FAULT')
	ENDIF

	else if (lib$extzv(24,8,emb$l_hd_sid) .eq. 2) then

	if (emb$w_hd_entry .eq. '07'x) then

	call logger (lun,'WRITE BUS ERROR')
	endif
	endif

	RETURN

	END
