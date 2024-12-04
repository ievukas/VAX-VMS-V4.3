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

c	Author	Brian Porter			Creation date	10-FEB-1982

c++
c	Functional description:
c
c	This module displays entries logged by MSCP disks (dudriver) and
c	and MSCP tapes (tudriver).
c
c	Modified by:
c
C	V03-007	EAD0200		Elliott A. Drayton		23-Jul-1984
C		Added code to mark the begining of the intervening entries.
C
C	V03-006	SAR0272		Sharon A. Reynolds	18-Jun-1984
C		- Re-structured and re-named the routines in this
C		module to handle disk or tape MSCP entries for the
C		addition of TMSCP support.
C
C	V03-005	SAR0197		Sharon A. Reynolds,	20-Feb-1984
C		Added an SYE update that:
C		- Removed 'invalid mscp command end message'.
C
C	V03-004	SAR0157		Sharon A. Reynolds,	12-Oct-1983
C		Added an SYE update that:
C		- adds an extra arguement to the 'dudriver_mscp_dispatcher'
C		  routine.
C		- adds an extra arguement to the call for the
C		  'dudriver_mscp_dispatcher' routine.
C		- adds an extra arguement to the calls for several
C		  routines that reside in 'mscp.for'.
C
C	V03-003	SAR0072		Sharon A. Reynolds,	20-Jun-1983
C		Changed the carriage control in the 'format' statements
C		for use with ERF.
C
c	v03-002	BP0002		Brian Porter,		08-FEB-1983
c		Corrected argument list to erllogmsg2.
c
c	v03-001	BP0001		Brian Porter,		19-APR-1982
c		Made changes to accomodate invalid command mscp messages.
c**
c--

	Subroutine DISK_TAPE_DRVR_MSCP_DISPATCHER (lun,option,reccnt,
	1 mount_flag_and_label,record_length,queue_count)


	include 'src$:msghdr.for /nolist'
	include 'src$:emblmdef.for /nolist'
	include 'src$:embspdef.for /nolist'


	byte		lun

	character*1	option

c  This value RECCNT is not the record number of the entry just read from the 
c  errlog.sys file it is the value which was saved in the queue when this
c  routine is called by _DQ.
	integer*4	reccnt
c
	integer*4	mount_flag_and_label
	integer*4	record_length
	Integer*4	queue_count
	Integer*4	packet_length

	byte		mslg$b_format
	equivalence	(emb(46),mslg$b_format)

	
	if (emb$w_hd_entry .eq. 100) then		! Logmessage entry

C
C Determine whether to output the long or short header and call
C the appropriate routine.
C
	If (queue_count .EQ. 1) then

	Call FRCTOF (lun)
	Call HEADER2 (lun,reccnt)
	Else

	Call HEADER3 (lun,reccnt)
	Endif

	Call LOGGER (lun,'ERL$LOGMESSAGE ENTRY')

	Call DHEAD3 (lun,'I/O',emb$b_lm_namlng,emb$t_lm_name,emb$w_lm_unit,
	1 mount_flag_and_label)

	Packet_length = record_length - 39

	if (mslg$b_format .eq. 0) then		! Controller error

	if (option .eq. 'S') then
	Call MSLG$K_CNT_ERR (lun,packet_length)
	endif

	else if (mslg$b_format .eq. 1) then	! Memory access error 

	if (option .eq. 'S') then
	Call MSLG$K_BUS_ADDR (lun,packet_length)
	endif

	else if (		! Disk/tape transfer error
	1 mslg$b_format .eq. 2	! mslg$k_disk_trn
	1 .OR.
	1 mslg$b_format .EQ. 5	! mslg$k_tape_trn
	1 ) then

	if (option .eq. 'S') then
	Call DISK_TAPE_TRANSFER_ERRORS (lun,packet_length)
	endif

	else if (		! SDI/STI errors
	1 mslg$b_format .eq. 3	! Disk SDI comm error - mslg$k_sdi
	1 .OR.
	1 mslg$b_format .EQ. 6	! Tape STI comm or cmd failure - mslg$k_sti_err
	1 .OR.
	1 mslg$b_format .EQ. 7	! Tape STI Drive Error Log - mslg$k_sti_del
	1 .OR.
	1 mslg$b_format .EQ. 8	! Tape STI Formatter Error Log - mslg$k_sti_fel
	1 ) then

	if (option .eq. 'S') then
	Call SDI_STI_ERRORS (lun,packet_length)
	endif

	else if (mslg$b_format .eq. 4) then	! Small Disk error

	if (option .eq. 'S') then
	Call MSLG$K_SML_DSK (lun,packet_length)
	endif

	else
C
C Unknown format type, call a routine that will decode/output the header
C information and dump the rest of the packet in a hex longword format.
C
	Call ERLLOGMSG2 (lun,record_length)
	endif

	else if (emb$w_hd_entry .eq. 99) then	! Logstatus entry

C
C Determine whether to output the long or short header and call
C the appropriate routine.
C
	If (queue_count .EQ. 1) then
	Call FRCTOF (lun)
	Call HEADER2 (lun,reccnt)

	Else
	Call HEADER3 (lun,reccnt)
	Endif

	Call LOGGER (lun,'ERL$LOGSTATUS ENTRY')

	Call DHEAD3 (lun,'I/O',emb$b_sp_namlng,emb$t_sp_name,emb$w_sp_unit,
	1 mount_flag_and_label)

	Call ERLLOGSTS2 (lun)
	endif

	return
	end



c++
c	Since mscp error log entries are delivered from the port via
c	the datagram service it is possible for them to be delivered
c	out of sequence or duplicated.  It is the responsibility of 
c	this queue to collect all entries containing the same command
c	reference for a given cpu together.  They are placed in order
c	of error log entry type.
c
c	The format of the elements are as follows
c
c	+----------------------------------+
c	|             flink1               |
c	+----------------------------------+
c	|             blink1               |
c	+----------------------------------+
c	|           logging sid            |
c	+----------------------------------+
c	|   root command reference flink   |
c	+----------------------------------+
c	|   root command reference blink   |
c	+----------------------------------+
c	|   command reference entry count  |
c	+----------------------------------+
c
c	+----------------------------------+
c	|             flink2               |
c	+----------------------------------+
c	|             blink2               |
c	+----------------------------------+
c	|     command reference number     |
c	+----------------------------------+
c	|    root_emb$$w_hd_entry_flink    |
c	+----------------------------------+
c	|    root_emb$$w_hd_entry_blink    |
c	+----------------------------------+
c	|      emb$$w_hd_entry count       |
c	+----------------------------------+
c
c	+----------------------------------+
c	|             flink3               |
c	+----------------------------------+
c	|             blink3               |
c	+----------------------------------+
c	|          emb$$w_hd_entry         |
c	+----------------------------------+
c	|      error log record number     |
c	+----------------------------------+
c	|   error log record size (bytes)  |
c	+----------------------------------+
c	|                                  |
c	+--                              --+
c	.                                  .
c	.        error log record          .
c	.                                  .
c	+--                              --+
c	|                                  |
c	+----------------------------------+
c	|         mounted flag             |
c	+----------------------------------+
c	|                                  |
c	+--                              --+
c	|   mounted volume label (if any)  |
c	+--                              --+
c	|                                  |
c	+----------------------------------+
c--



	Subroutine DISK_TAPE_DRIVERS_MSCP_Q (record_length,reccnt,
	1 search_command_reference_number)


	include 'src$:msghdr.for /nolist'
	include 'src$:emblmdef.for /nolist'
	include 'src$:embspdef.for /nolist'



	byte		lun

	character*1	option

	integer*4	record_length
	integer*4	reccnt
	integer*4	search_command_reference_number
	integer*4	buffer(2)
	logical*4	lib$get_vm
	integer*4	insert_blink
	integer*4	logging_sid_entry_address
	integer*4	command_reference_entry_address
	integer*4	emb$$w_hd_entry_address
	integer*4	root_logging_sid_flink
	integer*4	root_logging_sid_blink

	equivalence	(buffer(1),root_logging_sid_flink)
	equivalence	(buffer(2),root_logging_sid_blink)

	integer*4	logging_sid_entry_count
	data		logging_sid_entry_count	/0/

	integer*4	buffer1(6)
	integer*4	flink1
	integer*4	blink1
	integer*4	logging_sid
	integer*4	root_command_reference_flink
	integer*4	root_command_reference_blink
	integer*4	command_reference_entry_count

	equivalence	(buffer1(1),flink1)
	equivalence	(buffer1(2),blink1)
	equivalence	(buffer1(3),logging_sid)
	equivalence	(buffer1(4),root_command_reference_flink)
	equivalence	(buffer1(5),root_command_reference_blink)
	equivalence	(buffer1(6),command_reference_entry_count)

	integer*4	buffer2(6)
	integer*4	flink2
	integer*4	blink2
	integer*4	command_reference_number
	integer*4	root_emb$$w_hd_entry_flink
	integer*4	root_emb$$w_hd_entry_blink
	integer*4	emb$$w_hd_entry_count

	equivalence	(buffer2(1),flink2)
	equivalence	(buffer2(2),blink2)
	equivalence	(buffer2(3),command_reference_number)
	equivalence	(buffer2(4),root_emb$$w_hd_entry_flink)
	equivalence	(buffer2(5),root_emb$$w_hd_entry_blink)
	equivalence	(buffer2(6),emb$$w_hd_entry_count)

	integer*4	buffer3(5)
	integer*4	flink3
	integer*4	blink3
	integer*4	emb$$w_hd_entry
	integer*4	error_log_record_number
	integer*4	error_log_record_length

	equivalence	(buffer3(1),flink3)
	equivalence	(buffer3(2),blink3)
	equivalence	(buffer3(3),emb$$w_hd_entry)
	equivalence	(buffer3(4),error_log_record_number)
	equivalence	(buffer3(5),error_log_record_length)


	if (logging_sid_entry_count .eq. 0) then

	root_logging_sid_flink = %loc(root_logging_sid_flink)
	root_logging_sid_blink = root_logging_sid_flink
	endif

	logging_sid_entry_address = root_logging_sid_flink

	do 100,i = 1,logging_sid_entry_count

	call movc3 (%val(24),%val(logging_sid_entry_address),buffer1)

	if (logging_sid .eq. emb$l_hd_sid) then

10	command_reference_entry_address = root_command_reference_flink

	do 90,j = 1,command_reference_entry_count

	call movc3 (%val(24),%val(command_reference_entry_address),buffer2)

	if (command_reference_number .eq. search_command_reference_number)
	1 then

25	insert_blink = root_emb$$w_hd_entry_blink

	if (emb$$w_hd_entry_count .ne. 0) then

	call movc3 (%val(12),%val(root_emb$$w_hd_entry_blink),buffer3)

	if (emb$$w_hd_entry .lt. emb$w_hd_entry) then

	insert_blink = blink3
	endif
	endif

	call movc5 (%val(0),,%val(0),%val(20),buffer3)

	if (lib$get_vm((20+record_length+16),emb$$w_hd_entry_address)) then

	call insque (%val(emb$$w_hd_entry_address),%val(insert_blink))

	emb$$w_hd_entry = emb$w_hd_entry

	error_log_record_number = reccnt

	error_log_record_length = record_length

	call movc3 (%val(12),emb$$w_hd_entry,
	1 %val(emb$$w_hd_entry_address + 8))

	call movc3 (%val(record_length),emb,%val(emb$$w_hd_entry_address + 20))

	call movl (-1,%val(emb$$w_hd_entry_address+20+record_length))

	if (emb$w_hd_entry .eq. 100) then

	call get_current_label (3,emb$l_hd_sid,emb$b_lm_namlng,emb$t_lm_name,
	1 emb$w_lm_unit,%val(emb$$w_hd_entry_address+20+record_length+4),*30)

	else if (emb$w_hd_entry .eq. 99) then

	call get_current_label (3,emb$l_hd_sid,emb$b_sp_namlng,emb$t_sp_name,
	1 emb$w_sp_unit,%val(emb$$w_hd_entry_address+20+record_length+4),*30)
	endif

	call movl (emb$$w_hd_entry_address+20+record_length+4,
	1 %val(emb$$w_hd_entry_address+20+record_length))

30	emb$$w_hd_entry_count = emb$$w_hd_entry_count + 1

	call movl (emb$$w_hd_entry_count,
	1 %val(command_reference_entry_address + 20))
	endif

	return
	endif

	command_reference_entry_address = flink2

90	continue

	call movc5 (%val(0),,%val(0),%val(24),buffer2)

	if (lib$get_vm(24,command_reference_entry_address)) then

	call insque (%val(command_reference_entry_address),
	1 %val(root_command_reference_blink))

	command_reference_number = search_command_reference_number

	root_emb$$w_hd_entry_flink = command_reference_entry_address + 12

	root_emb$$w_hd_entry_blink = root_emb$$w_hd_entry_flink

	call movc3 (%val(16),command_reference_number,
	1 %val(command_reference_entry_address + 8))

	command_reference_entry_count = command_reference_entry_count + 1

	call movl (command_reference_entry_count,
	1 %val(logging_sid_entry_address + 20))

	goto 25
	endif

	return
	endif

	logging_sid_entry_address = flink1

100	continue

	call movc5 (%val(0),,%val(0),%val(24),buffer1)

	if (lib$get_vm(24,logging_sid_entry_address)) then

	call insque (%val(logging_sid_entry_address),
	1 %val(root_logging_sid_blink))

	logging_sid = emb$l_hd_sid

	root_command_reference_flink = logging_sid_entry_address + 12

	root_command_reference_blink = root_command_reference_flink

	call movc3 (%val(16),logging_sid,%val(logging_sid_entry_address + 8))

	logging_sid_entry_count = logging_sid_entry_count + 1

	goto 10
	endif

	return



	entry DISK_TAPE_DRIVERS_MSCP_DQ (lun,option)


	logging_sid_entry_address = root_logging_sid_flink

	If (logging_sid_entry_count .GT. 0) then 
	    Write (lun, 9000)
9000	    Format (/////////////////////
	1'	B E G I N I N G   O F   I N T E R V E N I N G   E N T R I E S')
	Endif

	do 150,i = 1,logging_sid_entry_count

	call movc3 (%val(24),%val(logging_sid_entry_address),buffer1)

	command_reference_entry_address = root_command_reference_flink

	do 200,j = 1,command_reference_entry_count

	call movc3 (%val(24),%val(command_reference_entry_address),buffer2)

	emb$$w_hd_entry_address = root_emb$$w_hd_entry_flink

	do 250,k = 1,emb$$w_hd_entry_count

	call movc3 (%val(20),%val(emb$$w_hd_entry_address),buffer3)

	call movc5 (%val(0),,%val(0),%val(512),emb)

	call movc3 (%val(error_log_record_length),
	1 %val(emb$$w_hd_entry_address + 20),emb)

	call DISK_TAPE_DRVR_MSCP_DISPATCHER (lun,option,
	1 error_log_record_number,
	1 %val(emb$$w_hd_entry_address+20+error_log_record_length),
	1 error_log_record_length,k)

	emb$$w_hd_entry_address = flink3

250	continue

	command_reference_entry_address = flink2

200	continue

	logging_sid_entry_address = flink1

150	continue

	return

	end



	Subroutine DUDRIVER_QIO (lun,emb$w_dv_func)


	include 'src$:qiocommon.for /nolist'



	byte		lun

	integer*2	emb$w_dv_func

	integer*4	qiocode(0:1,0:63)



	if (qiocode(0,0) .eq. 0) then

	qiocode(1,00) = %loc(io$_nop)
	qiocode(1,01) = %loc(io$_unload)
	qiocode(1,08) = %loc(io$_packack)

	qiocode(1,10) = %loc(io$_writecheck)
	qiocode(1,11) = %loc(io$_writepblk)
	qiocode(1,12) = %loc(io$_readpblk)

	qiocode(1,17) = %loc(io$_available)
	qiocode(1,26) = %loc(io$_setchar)
	qiocode(1,27) = %loc(io$_sensechar)

	qiocode(1,32) = %loc(io$_writelblk)
	qiocode(1,33) = %loc(io$_readlblk)
	qiocode(1,35) = %loc(io$_setmode)

	qiocode(1,39) = %loc(io$_sensemode)
	qiocode(1,48) = %loc(io$_writevblk)
	qiocode(1,49) = %loc(io$_readvblk)

	qiocode(1,50) = %loc(io$_access)
	qiocode(1,51) = %loc(io$_create)
	qiocode(1,52) = %loc(io$_deaccess)

	qiocode(1,53) = %loc(io$_delete)
	qiocode(1,54) = %loc(io$_modify)
	qiocode(1,56) = %loc(io$_acpcontrol)
	qiocode(1,57) = %loc(io$_mount)

	do 10,i = 0,63

	qiocode(0,i) = 33

	if (qiocode(1,i) .eq. 0) then
	qiocode(1,i) = %loc(qio_string)
	endif

10	continue
	endif

	call cdrp$w_func (lun,emb$w_dv_func,
	1 qiocode(0,lib$extzv(0,6,emb$w_dv_func)))

	return
	end



	Subroutine TUDRIVER_QIO (lun,emb$w_dv_func)

	include 'src$:qiocommon.for /nolist'


	byte		lun

	integer*2	emb$w_dv_func

	integer*4	qiocode(0:1,0:63)



	if (qiocode(0,0) .eq. 0) then

	qiocode(1,00) = %loc(io$_nop)
	qiocode(1,01) = %loc(io$_unload)
	qiocode(1,08) = %loc(io$_packack)

	qiocode(1,10) = %loc(io$_writecheck)
	qiocode(1,11) = %loc(io$_writepblk)
	qiocode(1,12) = %loc(io$_readpblk)

	qiocode(1,17) = %loc(io$_available)
	qiocode(1,21) = %LOC(io$_dse)
	qiocode(1,26) = %loc(io$_setchar)

	qiocode(1,27) = %loc(io$_sensechar)
	qiocode(1,32) = %loc(io$_writelblk)
	qiocode(1,33) = %loc(io$_readlblk)

	qiocode(1,35) = %loc(io$_setmode)
	qiocode(1,39) = %loc(io$_sensemode)
	qiocode(1,48) = %loc(io$_writevblk)

	qiocode(1,49) = %loc(io$_readvblk)
	qiocode(1,50) = %loc(io$_access)
	qiocode(1,51) = %loc(io$_create)

	qiocode(1,52) = %loc(io$_deaccess)
	qiocode(1,53) = %loc(io$_delete)
	qiocode(1,54) = %loc(io$_modify)

	qiocode(1,56) = %loc(io$_acpcontrol)
	qiocode(1,57) = %loc(io$_mount)

	do 10,i = 0,63

	qiocode(0,i) = 33

	if (qiocode(1,i) .eq. 0) then
	qiocode(1,i) = %loc(qio_string)
	endif

10	continue
	endif

	call cdrp$w_func (lun,emb$w_dv_func,
	1 qiocode(0,lib$extzv(0,6,emb$w_dv_func)))

	return
	end
