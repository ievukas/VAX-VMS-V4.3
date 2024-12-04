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

c	Author	Brian Porter			Creation date	07-FEB-1982

c++
c	Functional description
c
c	This module provides dispatching for entries logged by erl$logstatus.
c
c	Modified by:
c
c	V03-010	EAD184		Elliott A. Drayton	 6-Jul-1984
c		Add page break to begin intervening entry reports.
c
C	V03-009	SAR270		Sharon A. Reynolds	18-Jun-1984
C		- Added TMSCP support.
C
C	V03-008	SAR0259		Sharon A. Reynolds	26-Apr-1984
C		- TU81 partial entry fix.
C	
C	V03-007	SAR0222		Sharon A. Reynolds,	28-Mar-1984
C		Changed the call to UCB$L_OWNUIC to ORB$L_OWNER.
C		
C	V03-006	SAR0195		Sharon A. Reynolds,	20-Feb-1984
C		Added an SYE update that:
C		- Added code to interrogate the 'mscp command reference"
C		numbers. If zero output the entry immediately. 
C		- Fixed a bug in the output of the mscp entries when the
C		error log mailbox is selected as for output.
C
C	V03-005	SAR0133		Sharon A.Reynolds,	9-Sep-1983
C		Added fixes that were made to SYE (erllogsts) that 
C		removed the mscp 'first part' info message and fixed
C		bug relating to summary reports.
C
C	V03-004	SAR0074		Sharon A. Reynolds,	20-Jun-1983
C		Changed the carriage control in the 'format' statements
C		for use with ERF.
C
C	V03-003	SAR0026		Sharon A. Reynolds,	16-May-1983
C		Made SYECOM available and added code to check for eof 
C		flag and call 'dudriver_mscp_dq'. Also changed name of 
C		'reccnt' input parameter due to conflict with SYECOM
C		reccnt.
C
c	v03-002	BP0001		Brian Porter,		21-OCT-1982
c		Added ra60.
c
c	v03-001	BP0001		Brian Porter,		18-APR-1982
c		Added brief.
c--
c**

	Subroutine ERL$LOGSTATUS_DISPATCHER (lun,record_length,record_number,
	1 option)


	include	'src$:msghdr.for /nolist'
	include	'src$:embspdef.for /nolist'
	Include 'src$:syecom.for /nolist'


	byte		lun
	integer*4	record_length
	integer*4	record_number
	character*1	option

	byte		mount_flag_and_label_array(16)

	integer*4	volume_mount_flag
	integer*4	current_volume_label

	equivalence	(mount_flag_and_label_array(1),volume_mount_flag)
	equivalence	(mount_flag_and_label_array(5),current_volume_label)


C
C 	Determine if the entire file has been processed, if so, call
C 	a routine that will de-queue and output the remainder of the 
C	disk and tape MSCP messages and return to the calling routine.
C
	If (EOF_FLAG) then
	  Call DISK_TAPE_DRIVERS_MSCP_DQ (lstlun,options)	! DU and TU drivers
	  Return 
	Endif

	if (options .eq. 'B') then

	Call HEADER (lstlun)
	Call LOGGER (lstlun,'ERL$LOGSTATUS ENTRY')
	Call DHEAD2 (lstlun,'I/O',emb$b_sp_namlng,emb$t_sp_name,emb$w_sp_unit)
	endif

	if (emb$b_sp_class .eq. 128) then

	if (options .eq. 'S') then

	Call PUDRIVER_MSCP_DISPATCHER (lstlun,options,record_number)
	endif

	else if (
	1 emb$b_sp_class .eq. 1			! Disk messages
	1 .OR.
	1 emb$b_sp_class .EQ. 2			! Tape messages
	1 ) then

	if (options .eq. 'S') then

C
C Determine if output is directed to the report generator mailbox or if the
C command reference number is equal to 0 (invalid cmd?). If so, output the 
C entry immediately.
C
	If (
	1 mailbox_channel .NE. 0
	1 .OR.
	1 emb$l_sp_cmdref .EQ. 0
	1 ) then

	Call INTERVENE_DECREMENT (lstlun)

	Volume_mount_flag = -1
	Call GET_CURRENT_LABEL (3,emb$l_hd_sid,emb$b_sp_namlng,emb$t_sp_name,
	1 emb$w_sp_unit,%REF(current_volume_label),*5)

	Volume_mount_flag = %LOC(current_volume_label)
5	Continue

	Call DISK_TAPE_DRVR_MSCP_DISPATCHER (lstlun,options,record_number,
	1 mount_flag_and_label_array,record_length,(1))

	Else
C
C The command is valid and output is not going to the mailbox, save the
C entry so that it can be output together with the device hardware status 
C packet that is logged seperately.
C
	Call DISK_TAPE_DRIVERS_MSCP_Q (record_length,record_number,
	1 emb$l_sp_cmdref)

	Endif
	Endif

C
C Unknown device type, call a routine that will call applicable 
C routines that will decode/output the entry. As new device types
C are defined the IF-THEN-ELSE should be expanded at this point to
C support them.
C
	else
	Call ERLLOGSTS (lstlun)
	endif

	return
	end



	Subroutine ERLLOGSTS (lun)

	include 'src$:msghdr.for /nolist'
	include	'src$:embspdef.for /nolist'
	Include 'src$:syecom.for /nolist'


	byte		lun

	integer*4	compress4

C
C Decode/output the entry header.
C
	Call FRCTOF (lstlun)
	Call HEADER (lstlun)
	Call LOGGER (lstlun,'ERL$LOGSTATUS ENTRY')
	Call DHEAD2 (lstlun,'I/O',emb$b_sp_namlng,emb$t_sp_name,emb$w_sp_unit)



	Entry ERLLOGSTS2 (lun)

C
C Call the applicable routines to decode/output the software status
C entry for an mscp disk/tape device.
C
	Call LINCHK (lstlun,1)
	write(lstlun,10)
10	format(' ',:)

	Call MSLG$$L_CMD_REF (lstlun,emb$l_sp_cmdref)
	Call ORB$L_OWNER (lstlun,emb$l_sp_ownuic)
	Call UCB$L_CHAR (lstlun,emb$l_sp_char)

	Call UCB$L_OPCNT (lstlun,emb$l_sp_opcnt)
	Call UCB$W_ERRCNT (lstlun,emb$w_sp_errcnt)
	Call UCB$W_STS (lstlun,emb$w_sp_sts)

	Call LINCHK (lstlun,1)
	write(lstlun,10)

	Call CDRP$L_MEDIA (lstlun,emb$l_sp_media)

	if (emb$b_sp_class .eq. 1) then			! Disk qio func decode
	Call DUDRIVER_QIO (lstlun,emb$w_sp_func)

	Else if (emb$b_sp_class .EQ. 2) then		! Tape qio func decode
	Call TUDRIVER_QIO (lstlun,emb$w_sp_func)

	else
	Call CDRP$W_FUNC (lstlun,emb$w_sp_func,'QIO FUNCTION')
	endif

	Call CDRP$L_BCNT (lstlun,emb$l_sp_bcnt)
	Call CDRP$W_BOFF (lstlun,emb$w_sp_boff)
	Call CDRP$L_PID (lstlun,emb$l_sp_rqpid)
	Call CDRP$Q_IOSB (lstlun,emb$l_sp_iosb1)

	return

	end
