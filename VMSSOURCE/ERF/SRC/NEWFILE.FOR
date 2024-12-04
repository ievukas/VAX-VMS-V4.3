	Subroutine NEWFILE_AND_TIME_STAMP (lun)
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
C	Required files
C
	Include 'src$:msghdr.for /nolist'


	Byte		Lun

C
C	Call the 'header' routine to output the first two lines of the 
C	header portion of the report.
C
	Call HEADER (lun)

C
C	Determine if this is a 'new file created' or a 'time stamp'
C	entry. Call the 'logger' routine with the appropriate heading
C	to output for the header portion of the report. (New file creation
C	and time stamp entries consist of headers only, as they are just
C	indicators that the event occurred).
C
	If (EMB$W_HD_ENTRY .EQ. '23'X) Then		! New file entry
	Call LOGGER (lun,'ERRLOG.SYS CREATED')

	Else if (EMB$W_HD_ENTRY .EQ. '26'X) Then	! Time stamp entry
	Call LOGGER (lun,'TIME STAMP')

	Endif

	Return
	End	! Module
