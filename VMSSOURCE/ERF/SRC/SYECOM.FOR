C	SYECOM
C		THIS IS A COMMON WHICH CONTAINS INFORMATION
C		USED BY THE ERRLOG PROGRAM.
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
C	FACILITY:	ERRLOG COMMON AREA
C
C	AUTHOR:		WM. P. STOREY		CREATION DATE:9-JAN-1978
C
C	Functional description:
C
C	This INCLUDE file contains all the global information for output
C	device control and CPU identification.
C
C	MODIFIED BY:
C
C	V03-009	EAD0186		Elliott A. Drayton		 6-Jul-1984
C		Added Mailbox_channel, record_size, lstlun, and options.
C
C	V03-008	SAR0030		Sharon A. Reynolds,		1-Jun-1983
C		Removed counts for label and label_out. Added '/entry=end'
C		value found indicator.
C
C	V03-007	SAR0022		Sharon A. Reynolds,		11-May-1983
C		Added counts for label and label_out. Also added eof_flag 
C		for 'MSCP' entries.
C
C	V03-006	SAR0015		Sharon A. Reynolds,		18-Apr1983
C		Added valid_class, valid_cpu, valid_entry, and valid_type
C		indicators.
C
C	V03-005 SAR0005		Sharon A. Reynolds,		4-Apr-1983
C		Added volume_output flag, it indicates whether the 
C		volume mount and dismount entries should be output or
C		just extract data from them.
C
C	V03-004	EAD0003		Elliott A. Drayton		16-DEC-1982
C		Moved data statements from here to ERRPRT.
C
C	v02-003	BP0001		Brian Porter	11-FEB-1981
C		Made reccnt a longword.
C
C	V02-002	SR0002		Sharon Reynolds 19-Nov-1980
C		Added Cryptk_flag for coordination between the BRIEF
C		and CRYPTK modules to fix a problem with the cryptk
C		report.
C
C	v02-001	BP0001		Brian Porter,	19-SEP-1980
C		Removed origonal Functional description text and
C		replaced with current Functional description.
C		Also removed unwanted arrays and symbols.  Also put in
C		support for the 117zz.
C**
 
	INTEGER*4	RECCNT
	COMMON /SYECOM/	RECCNT
 
	LOGICAL*4	FORMS
	COMMON /SYECOM/ FORMS

	LOGICAL*4	PRINTER
	COMMON /SYECOM/ PRINTER

	BYTE		LINES
	COMMON /SYECOM/ LINES

	integer*4	dev_char
	common /syecom/	dev_char

	LOGICAL*1	CP_11780
	COMMON /SYECOM/ CP_11780

	LOGICAL*1	CP_11750
	COMMON /SYECOM/ CP_11750

	logical*1	cp_117zz
	common /syecom/	cp_117zz

	LOGICAL*4	cryptk_flag
	COMMON /SYECOM/ cryptk_flag

	Logical*1	Volume_output
	Common /SYECOM/ Volume_output

	Logical*1	Valid_class
	Logical*1	Valid_cpu
	Logical*1	Valid_entry
	Logical*1	Valid_type
	Common /SYECOM/ Valid_class,valid_cpu,valid_entry,valid_type

	Byte		Eof_flag
	Common /SYECOM/ Eof_flag

	Byte		End_value
	Common /SYECOM/ End_value

	Integer*4	Mailbox_channel,record_size,lstlun
	Common /SYECOM/	Mailbox_channel,record_size,lstlun

	Character*1	options
	Common /SYECOM/	options
