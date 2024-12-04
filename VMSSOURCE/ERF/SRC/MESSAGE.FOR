	Subroutine MESSAGE_HANDLING (lun)
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
C Modified By:
C
C	V03-001	SAR0084		Sharon A. Reynolds,	20-Jun-1983
C		Changed the carriage control in the 'format' statements
C		for use with ERF.
C
c--


C
C	Required files.
C
	Include 'src$:msghdr.for /nolist'
	Include 'src$:ssmessage.for /nolist'

	Byte		Lun

C
C	Call the 'header' routine to output the first two lines of the 
C	header portion of the report.
C
	Call HEADER (lun)

C
C	Determine if this is a '$snderr message', 'operator message', or 
C	a 'network message' entry. Call the 'logger' routine with the 
C	appropriate heading to output for the header portion of the report. 
C
	If (EMB$W_HD_ENTRY .EQ. '27'X) Then		! $Snderr message
	Call LOGGER (lun,'$SNDERR MESSAGE')

	Else if (EMB$W_HD_ENTRY .EQ. '29'X) Then	! Operator message
	Call LOGGER (lun,'OPERATOR MESSAGE')

	Else if (EMB$W_HD_ENTRY .EQ. '2A'X) Then	! Network message
	Call LOGGER (lun,'NETWORK MESSAGE')
	Endif

C
C	Call the 'linchk' routine to count the number of lines output.
C	Output the message text header.
C
	Call LINCHK (LUN,3)

	Write (lun,2605)
2605	Format(/' ','MESSAGE TEXT',/)

C
C	Ensure that there really was a message included, and output
C	it.
C
	If (EMB$W_SS_MSGSZ .NE. 0) Then
	Do 2615,I = 0,(EMB$W_SS_MSGSZ/56)

	J = I*56

	Call LINCHK (lun,1)

	Write (lun,2610) EMB$T_SS_MSGTXT(MAX(1,J):
	1 (J + MIN(55,EMB$W_SS_MSGSZ - J)))
2610	Format(' ',T8,A)
 
2615	Continue	! Do

	Else
C
C	Indicate that no message was actually in the entry.
C
	Call LINCHK (lun,1)

	Write (lun,2620)
2620	Format(' ',T8,'[NONE]')
	Endif

	Return
	End	! Module
