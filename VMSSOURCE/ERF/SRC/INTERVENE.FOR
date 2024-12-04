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
c	Author	Brian Porter		Creation date	22-JUL-1983
c

c++
c	Functional description:
c
c
c	Modified by:
C
C	V03-002	SAR0168		Sharon A. Reynolds	1-Nov-1983
C		Fixed a problem with negative numbers being output
C		in the intervening record message.
C
C	V03-001	SAR0135		Sharon A. Reynolds	9-Sep-1983
C		Changed carriage control so that this routine can
C		be used for ERF.
C
c**
c--

	Subroutine INTERVENE_INCREMENT (lun)


	implicit		none

	byte		lun

	integer*4	intervening_records
	integer*4	lib$extzv
	integer*4	compress4
	integer*4	repeat_count


	Intervening_records = intervening_records + 1

	Return



	Entry INTERVENE_OUTPUT (lun)


5	if (intervening_records .GT. 0) then

	call linchk (lun,3)

	write(lun,10) ('*',repeat_count = 1,72)
10	format(' ',72a1)

	write(lun,15) intervening_records
15	format(/' ',t8,i<compress4 (intervening_records)>,
	1 '. INTERVENING RECORD(S) WILL BE PRINTED AT INPUT FILE "<EOF>"')

	intervening_records = 0
	endif

	Return



	Entry INTERVENE_DECREMENT (lun)


	intervening_records = intervening_records - 1

	goto 5

	end
