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
C
C	AUTHOR:	Elliott A. Drayton		CREATION DATE: 15-Dec-1982
C
C	Functional description:
C
C
C	This module opens the file specified by OUTPUT_FILE_STRING.
C	If the open is successful then we returns to the caller,
C	else we signal the error and stop the image.
C
C
C	Modified by:
C
C	V03-005	EAD0189		Elliott	A. Drayton		 6-Jul-1984
C		Remove LSTLUN from the parmeter list, it is in SYECOM.
C
C	V03-004	EAD0131		Elliott	A. Drayton		 9-Apr-1984
C		Changed the carriage control from fortran to list.
C
C	V03-003 EAD0003		Elliott A. Drayton		23-Aug-1983
C		Add an assignment for FORMS when SYS$OUTPUT is not uesed.
C
C	V03-002	EAD0002		Elliott A. Drayton		23-Jun-1983
C		Changed the default for FORMS to true.
C
C	V03-001	EAD0001		Elliott A. Drayton		20-Jun-1983
C		Changed error message from SYE to ERF.
C
C**


	Subroutine Open_out_file ( output_file_string )


	Include 'SRC$:SYECOM.FOR/NOLIST'

	Character*(*)	output_file_string
	Integer*4	output_file_string_length

	Integer*4	fnum,rmssts,rmsstv,iunit,condval

	Integer*4	Term_dev
	
	Integer		sys$output

	External	sys$output_open
	External	lstlun_open

   	Forms = .FALSE.

	Printer = .FALSE.

	Lstlun = 2

	Term_dev = 4

	Sys$output = 6

	output_file_string_length = LEN (output_file_string)

	open(	unit = sys$output,
	1	name = 'sys$output',
	1	type = 'new',
	1	access = 'sequential',
	1	useropen = sys$output_open,
	1	carriagecontrol = 'list')

	if (output_file_string .ne. 'SYS$OUTPUT') then

   	Forms = .TRUE.
        open(	unit = lstlun,
	1	name = output_file_string(1:output_file_string_length),
	1	err  = 200,
	1	type = 'new',
	1	access = 'sequential',
	1	useropen = lstlun_open,
	1	carriagecontrol = 'list')

	        IF (FORMS
	1       .AND.
	2       JIAND(DEV_CHAR,TERM_DEV) .EQ. 0) PRINTER = .TRUE.
	ELSE

	  lstlun = sys$output

	ENDIF

 
	return

200	Call ERRSNS (fnum,rmssts,rmsstv,iunit,condval)

	If (rmssts .eq. 0) then
	   Call LIB$INSV (3,0,3,condval)
	   Call LIB$SIGNAL (%VAL(condval),%VAL(3),%VAL(iunit),
	1  output_file_string(1:output_file_string_length))
	Else
	   Call LIB$INSV (3,0,3,rmssts)
	   Call LIB$SIGNAL (%VAL(rmssts),%VAL(rmsstv))
	ENDIF

	Print 9000
9000	Format (1x, 'ERF-F-OPENERR, FATAL OPEN ERROR ON FILE')

	Print 9010, output_file_string
9010	Format (1x, a80)

	Call exit
	end
