	Subroutine SYS_STARTUP (lun)
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
C Modified By:
C
C	V03-001	SAR0098		Sharon A. Reynolds,	20-Jun-1983
C		Changed the carriage control in the 'format' statements
C		for use with ERF.
C
C--

C
C	Require files
C
	Include 'src$:msghdr.for /nolist'


	Byte		Lun

C
C	Call the 'header' routine to output the first two lines of the
C	header portion of the report.
C
	Call HEADER (lun)

C
C	Determine if this is a 'system start-up' or a 'power fail restart'
C	entry. Call the 'logger' routine with the appropriate heading
C	to output for the header portion of the report. (System start up
C	and power fail restart entries consist of header and time of day 
C	clock only, as they are indicators that the event occurred).
C
	If (EMB$W_HD_ENTRY .EQ. '20'X) Then		! System start-up
	Call LOGGER (lun,'SYSTEM START-UP')

	Else if (EMB$W_HD_ENTRY .EQ. '24'X) Then	! Power-fail restart
	Call LOGGER (lun,'POWER-FAIL RESTART')
	Endif


C
C	Call the 'linchk' routine to count the number of lines output.
C	And output the information.
C
	Call LINCHK (LUN,2)

	Write (lun,2111) (emb(16 + i),i = 3,0,-1)
2111	Format(/' ','TIME OF DAY CLOCK',T24,4Z2.2)

	Return
	End	! Module
