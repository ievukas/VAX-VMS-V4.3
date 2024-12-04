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
c	This module provides dispatching for entries logged by erl$logmessage.
c	Dispatching is done by emb$w_lm_msgtyp.
c
c	Modified by:
c
C	V03-009 EAD0196		Elliott A. Drayton		 6-Jul-1984
C		Changed LUN, OPTION and RECCNT to now come from SYECOM.
C
C
C	V03-008 SAR0271		Sharon A. Reynolds	18-Jun-1984
C		- Added TMSCP support.
C
C	V03-007	SAR0196		Sharon A. Reynolds,	20-Feb-1984
C		Added an SYE update that:
C		- Added code to interrogate the 'mscp command reference'
C		numbers. If zero output the entry immediately.
C		- Fixed a bug in the output of mscp entries when
C		error logging mailbox selected as output.
C
C	V03-006	SAR0134		Sharon A. Reynolds,	9-Sep-1983
C		Added changes that were made to SYE (erllogmsg) to 
C		remove the mscp 'first part' info msg and fix a bug
C		relating to summary reports.
C
C	V03-005	SAR0073		Sharon A. Reynolds,	20-Jun-1983
C		Changed the carriage control in the 'format' statements
C		for use with ERF.
C
c	v03-004	BP0004		Brian Porter,		08-FEB-1983
c		Corrected argument list to pudriver.
c
c	v03-003	BP0003		Brian Porter,		18-JUN-1982
c		Added ci780 support.
c
c	v03-002	BP0002		Brian Porter,		25-MAY-1982
c		Added 'option' filtering.
c
c	v03-001	BP0001		Brian Porter,		14-APR-1982
c		Added more routines.
c--
c**

	Subroutine ERL$LOGMESSAGE_DISPATCHER (lun,record_length,reccnts,option)
	

	include	'src$:msghdr.for /nolist'
	include	'src$:emblmdef.for /nolist'
	include 'src$:syecom.for /nolist'

	byte		lun
	integer*4	record_length
	integer*4	reccnts
	character*1	option

	byte		mount_flag_and_label_array(16)

	integer*4	volume_mount_flag
	integer*4	current_volume_label

	equivalence	(mount_flag_and_label_array(1),volume_mount_flag)
	equivalence	(mount_flag_and_label_array(5),current_volume_label)


C
C Via the message type, determine which module to call to decode/output
C the MSCP entry.
C
	if (
	1 emb$w_lm_msgtyp .eq. 1		! Disk message
	1 .OR.
	1 emb$w_lm_msgtyp .EQ. 2		! Tape message
	1 ) then

	if (option .eq. 'B') then		! Brief report
C
C Output the entry header.
C
	Call HEADER (lstlun)
	Call LOGGER (lstlun,'ERL$LOGMESSAGE ENTRY')
	Call DHEAD2 (lstlun,'I/O',emb$b_lm_namlng,emb$t_lm_name,emb$w_lm_unit)

	Else if (option .eq. 'S') then		! Full report

C
C Determine if output is going to the mailbox or if there is no message
C text logged in this packet, if so output the entry immediately.
C
	If (
	1 mailbox_channel .NE. 0
	1 .OR.
	1 LIB$EXTZV(0,31,emb$b_lm_msgtxt) .EQ. 0
	1 ) then

	Call INTERVENE_DECREMENT (lstlun)

	Volume_mount_flag = -1
	Call GET_CURRENT_LABEL (3,emb$l_hd_sid,emb$b_lm_namlng,emb$t_lm_name,
	1 emb$w_lm_unit,%REF(current_volume_label), *5)

	Volume_mount_flag = %LOC(current_volume_label)
5	Continue

	Call DISK_TAPE_DRVR_MSCP_DISPATCHER (lstlun,option,reccnt,
	1 mount_flag_and_label_array,record_size, (1))

	Else
C
C Save the entry so it can be output with the software status information
C that is logged in a seperate packet.
C
	Call DISK_TAPE_DRIVERS_MSCP_Q (record_size,reccnt,emb$b_lm_msgtxt)

	Endif
	Endif

	else if (emb$w_lm_msgtyp .eq. 3) then	! CI Port message

	if (
	1 option .eq. 'S'
	1 .or.
	1 option .eq. 'B'
	1 ) then

	Call INTERVENE_DECREMENT (lstlun)
	Call PADRIVER_LOGMESSAGE (lstlun,option)
	endif

	else if (emb$w_lm_msgtyp .eq. 4) then	! UDA Port message

	if (
	1 option .eq. 'S'
	1 .or.
	1 option .eq. 'B'
	1 ) then


	Call INTERVENE_DECREMENT (lstlun)
	Call PUDRIVER_MSCP_DISPATCHER (lstlun,option,reccnt,record_size)
	Endif

	else if (emb$w_lm_msgtyp .eq. 5) then	! Available Attention Msg

	if (
	1 option .eq. 'S'
	1 .or.
	1 option .eq. 'B'
	1 ) then

	Call INTERVENE_DECREMENT (lstlun)

	If (option .EQ. 'S') then
	Call FRCTOF (lstlun)
	Endif

	Call HEADER (lstlun)
	Call LOGGER (lstlun,'ERL$LOGMESSAGE ENTRY')
	Call DHEAD2 (lstlun,'I/O',emb$b_lm_namlng,emb$t_lm_name,emb$w_lm_unit)

	Call LINCHK (lstlun,2)
	write(lstlun,10) '"AVAILABLE" MSCP ATTENTION MESSAGE'
10	format(/' ',a)
	endif

	if (option .eq. 'S') then
	Call MSCP$$K_OP_AVATN (lstlun,.true.)
	endif

	else if (emb$w_lm_msgtyp .eq. 6) then	! Duplicate Unit Msg

	if (
	1 option .eq. 'S'
	1 .or.
	1 option .eq. 'B'
	1 ) then

	Call INTERVENE_DECREMENT (lstlun)

	If (option .EQ. 'S') then
	Call FRCTOF (lstlun)
	Endif 

	Call HEADER (lstlun)
	Call LOGGER (lstlun,'ERL$LOGMESSAGE ENTRY')
	Call DHEAD2 (lstlun,'I/O',emb$b_lm_namlng,emb$t_lm_name,emb$w_lm_unit)

	Call LINCHK (lstlun,2)
	write(lstlun,10) '"DUPLICATE UNIT NUMBER" MSCP ATTENTION MESSAGE'
	endif

	if (option .eq. 'S') then
	Call MSCP$$K_OP_DUPUN (lstlun,.true.)
	endif

	else if (emb$w_lm_msgtyp .eq. 7) then	! Invalid Command Msg

	if (
	1 option .eq. 'S'
	1 .or.
	1 option .eq. 'B'
	1 ) then

	Call INTERVENE_DECREMENT (lstlun)

	If (option .EQ. 'S') then
	Call FRCTOF (lstlun)
	Endif

	Call HEADER (lstlun)
	Call LOGGER (lstlun,'ERL$LOGMESSAGE ENTRY')
	Call DHEAD2 (lstlun,'I/O',emb$b_lm_namlng,emb$t_lm_name,emb$w_lm_unit)

	Call LINCHK (lstlun,2)
	Write (lstlun,10) '"INVALID COMMAND" MSCP END MESSAGE'
	endif

	if (option .eq. 'S') then
	Call MSCP_INVALID_COMMAND_END_MESAGE (lstlun) 
	endif

	else if (emb$w_lm_msgtyp .eq. 8) then	! Acess Path Attention Msg

	if (
	1 option .eq. 'S'
	1 .or.
	1 option .eq. 'B'
	1 ) then

	Call INTERVENE_DECREMENT (lstlun)

	If (option .EQ. 'S') then
	Call FRCTOF (lstlun)
	Endif

	Call HEADER (lstlun)
	Call LOGGER (lstlun,'ERL$LOGMESSAGE ENTRY')
	Call DHEAD2 (lstlun,'I/O',emb$b_lm_namlng,emb$t_lm_name,emb$w_lm_unit)

	Call LINCHK (lstlun,2)
	write(lstlun,10) '"ACCESS PATH" MSCP ATTENTION MESSAGE'
	endif

	if (option .eq. 'S') then
	Call MSCP$$K_OP_ACPTH (lstlun,.true.)
	endif

c
c	The IF-THEN-ELSE should be expanded at this point to add
c	new entry sub codes.
c

	else

C
C Unknown message type, call the applicable routines to decode/output the
C header and output the remainder of the packet in a hex longword format.
C
	if (
	1 option .eq. 'S'
	1 .or.
	1 option .eq. 'B'
	1 ) then

	Call ERLLOGMSG (lstlun,record_size)
	endif
	endif

	return

	end



	Subroutine ERLLOGMSG (lun,record_length)


	include 'src$:msghdr.for /nolist'
	include	'src$:emblmdef.for /nolist'
	include 'src$:syecom.for /nolist'

	byte		lun

	integer*4	record_length
	integer*4	compress4


	Call FRCTOF (lstlun)
	Call HEADER (lstlun)
	Call LOGGER (lstlun,'ERL$LOGMESSAGE ENTRY')
	Call DHEAD2 (lstlun,'I/O',emb$b_lm_namlng,emb$t_lm_name,emb$w_lm_unit)




	Entry ERLLOGMSG2 (lun,record_length)

	Call LINCHK (lstlun,3)

	write(lstlun,90) 'EMB$W_LM_MSGTYP',(emb$w_lm_msgtyp,i = 1,2)
90	format(/' ',t8,a,t28,z4.4,/,
	1 t40,a,i<compress4 (lib$extzv(0,16,emb$w_lm_msgtyp))>)

	Call DUMPREG (lstlun,((record_size + 3)/4) - 9,emb(38))

	return

	end
