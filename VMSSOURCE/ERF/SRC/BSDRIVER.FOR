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

c	Author	Brian Porter			Creation date:	16-JUL-1982

c++
c	Functional description:
c
c	This module displays events logged by the BSDRIVER (dt07).
c
c	Modified by:
C
C	V03-003	SAR0216		Sharon A. Reynolds,		28-Mar-1984
C		Changed the call to UCB$L_OWNUIC to ORB$L_OWNER.
C		
C	V03-002	SAR0065		Sharon A. Reynolds,		20-Jun-1983
C		Changed the carriage control in the 'format' statements
C		for use with ERF.
C
C	V03-001	SAR0037		Sharon A. Reynolds,		8-Jun-1983
C		Removed brief/cryptic support.
C
c**
c--

	Subroutine BSDRIVER (lun)


	include 'src$:msghdr.for /nolist'
	include 'src$:deverr.for /nolist'


	byte		lun

	integer*4	ucb$b_bs_errmsg
	integer*4	ucb$l_devdepend
	integer*4	ucb$l_bs_cur
	integer*4	ucb$l_bs_pre

	equivalence	(emb$l_dv_regsav(0),ucb$b_bs_errmsg)
	equivalence	(emb$l_dv_regsav(1),ucb$l_devdepend)
	equivalence	(emb$l_dv_regsav(2),ucb$l_bs_cur)
	equivalence	(emb$l_dv_regsav(3),ucb$l_bs_pre)


	character*32	v1ucb$l_devdepend(0:12)
	data	v1ucb$l_devdepend(0) /'"OWNER", CURRENT PROCESS*'/
	data	v1ucb$l_devdepend(1) /'ATTENTION AST ENABLED*'/
	data	v1ucb$l_devdepend(2) /'SWITCHED BUS IN USE*'/
	data	v1ucb$l_devdepend(3) /'PORT HAS PRIMARY STATUS*'/
	data	v1ucb$l_devdepend(4) /'CURRENTLY IN PROGRAM MODE*'/
	data	v1ucb$l_devdepend(5) /'CURRENTLY IN MANUAL MODE*'/
	data	v1ucb$l_devdepend(6) /'DRIVER STATUS INITIALIZED*'/
	data	v1ucb$l_devdepend(7) /'SWITCHED DEVICES MARKED OFFLINE*'/
	data	v1ucb$l_devdepend(8) /'SWITCHED DEVICES MARKED ON-LINE*'/
	data	v1ucb$l_devdepend(9) /'SWITCHED BUS DISCONNECT-IN-PROG*'/
	data	v1ucb$l_devdepend(10)/'SWITCHED BUS CONNECTED*'/
	data	v1ucb$l_devdepend(11)/'"UBA" INITIALIZE-IN-PROGRESS*'/
	data	v1ucb$l_devdepend(12)/'DEVICE INTERRUPT DISABLED*'/


	character*31	v1csr(0:15)
	data	v1csr(0)	/'REQUEST*'/
	data	v1csr(1)	/'HOLD*'/
	data	v1csr(2)	/'REQUEST LINE #0*'/
	data	v1csr(3)	/'REQUEST LINE #1*'/
	data	v1csr(4)	/'REQUEST LINE #2*'/
	data	v1csr(5)	/'REQUEST LINE #3*'/
	data	v1csr(6)	/'INTERRUPT ENABLE*'/
	data	v1csr(7)	/'PORT CONNECTED TO SWITCHED BUS*'/
	data	v1csr(8)	/'PORT REQUESTING MASTERSHIP*'/
	data	v1csr(9)	/'GENERATE RESET PULSE*'/
	data	v1csr(10)	/'PORT IN MANUAL MODE*'/
	data	v1csr(11)	/'POWER-OK OTHER PORTS*'/
	data	v1csr(12)	/'EXTERNAL INTERRUPT*'/
	data	v1csr(13)	/'SWITCHED BUS ACTIVE*'/
	data	v1csr(14)	/'SWITCHED BUS POWER-FAILURE*'/
	data	v1csr(15)	/'TIMEOUT*'/


	call frctof (lun)

	call dhead1 (lun,'UBA DT07')

	call linchk (lun,1)

	call ucb$$b_bs_errmsg (lun,ucb$b_bs_errmsg)

	call linchk (lun,2)

	write(lun,20) 'DT07 "CSR", CURRENT CONTENTS'
20	format(/' ',a)

	call linchk (lun,2)

	write(lun,25) ucb$l_bs_cur
25	format(/' ',t8,'UCB$L_BS_CUR',t24,z8.8)

	call output (lun,ucb$l_bs_cur,v1csr,0,0,15,'0')

	call linchk (lun,2)

	write(lun,20) 'DT07 "CSR", PREVIOUS CONTENTS'

	call linchk (lun,2)

	write(lun,30) ucb$l_bs_pre
30	format(/' ',t8,'UCB$L_BS_PRE',t24,z8.8)

	call output (lun,ucb$l_bs_pre,v1csr,0,0,15,'0')

	call linchk (lun,1)

	write(lun,32)
32	format(' ',:)

	call orb$l_owner (lun,emb$l_dv_ownuic)

	call ucb$l_char (lun,emb$l_dv_char)

	call ucb$w_sts (lun,emb$w_dv_sts)

	call linchk (lun,1)

	write(lun,35) ucb$l_devdepend
35	format(' ',t8,'UCB$L_DEVDEPEND',t24,z8.8)

	call output (lun,ucb$l_devdepend,v1ucb$l_devdepend,0,0,12,'0')

	call ucb$l_opcnt (lun,emb$l_dv_opcnt)

	call ucb$w_errcnt (lun,emb$w_dv_errcnt)

	if (emb$w_hd_entry .ne. 98) then

	call linchk (lun,1)

	write(lun,32)

	if (emb$w_dv_func .eq. 2) then

	call irp$w_func (lun,emb$w_dv_func,'IO$_READEXT*')

	else if (emb$w_dv_func .eq. 5) then

	call irp$w_func (lun,emb$w_dv_func,'IO$_DISCONNECT*')

	else if (emb$w_dv_func .eq. 50) then

	call irp$w_func (lun,emb$w_dv_func,'IO$_CONNECT*')
	else

	call irp$w_func (lun,emb$w_dv_func,'QIO FUNCTION CODE*')
	endif

	call irp$l_pid (lun,emb$l_dv_rqpid)

	call irp$q_iosb (lun,emb$l_dv_iosb1)
	endif

	return

	end


C**Re-written routine, delete old one after testing.
C

	Subroutine UCB$$B_BS_ERRMSG (lun,ucb$b_bs_errmsg)

	byte		lun

	integer*4	ucb$b_bs_errmsg

	Character*(*)	Swi_bus, manual, prog, conn, dis_conn, fail
	Character*(*)	Msg1,msg2,msg3
	Character*80	Message

	Parameter	(
	1 Swi_bus = 'SWITCHED BUS, ',
	2 Manual = 'MANUAL',
	3 Prog = 'PROGRAMABLE ',
	4 Fail = 'POWER-FAILURE ',
	5 Conn = 'CONNECT TO THIS PORT',
	6 Dis_conn = 'DISCONNECT FROM THIS PORT',

	1 Msg1 = '"UBA" INITIALIZE IN PROGRESS',
	2 Msg2 = 'PORT HAS RECEIVED UNRECOGNIZED INTERRUPT',
	3 Msg3 = 'PORT HAS ENCOUNTERED ILLEGAL CONDITION')

	call linchk (lun,2)

	Goto (10,20,30,40,50,60,70,80) ucb$b_bs_errmsg

	write(lun,15) ucb$b_bs_errmsg
15	format(/' ',t8,'UCB$B_BS_ERRMSG',t24,z8.8)
	return

10	Message = swi_bus // manual // conn
	Length = len (swi_bus) + len (manual) + len (conn)
	Goto 999

20	Message = swi_bus // manual // dis_conn
	Length = len (swi_bus) + len (manual) + len (dis_conn)
	Goto 999

30	Message = swi_bus // fail // dis_conn
	Length = len (swi_bus) + len (fail) + len (dis_conn)
	Goto 999

40	Message = swi_bus // prog // dis_conn
	Length = len (swi_bus) + len (prog) + len (dis_conn)
	Goto 999

50	Message = swi_bus // prog // conn
	Length = len (swi_bus) + len (prog) + len (conn)
	Goto 999

60	Message = msg1
	Length = len (msg1)
	Goto 999

70	Message = msg2
	Length = len (msg2)
	Goto 999

80	Message = msg3
	Length = len (msg3)

999	write(lun,998) Message
998	format(/' ',t8,a<length>)

	Return
	End

C	Subroutine UCB$$B_BS_ERRMSG (lun,ucb$b_bs_errmsg)
C
C
C	byte		lun
C
C	integer*4	ucb$b_bs_errmsg
C
C
C	call linchk (lun,2)
C
C	if (ucb$b_bs_errmsg .eq. 1) then
C
C	write(lun,10) 'SWITCHED BUS, MANUAL CONNECT TO THIS PORT'
C10	format(/' ',t8,a)
C
C	else if (ucb$b_bs_errmsg .eq. 2) then
C
C	write(lun,10) 'SWITCHED BUS, MANUAL DISCONNECT FROM THIS PORT'
C
C	else if (ucb$b_bs_errmsg .eq. 3) then
C
C	write(lun,10) 'SWITCHED BUS, POWER-FAILURE DISCONNECT FROM THIS PORT'
C
C	else if (ucb$b_bs_errmsg .eq. 4) then
C
C	write(lun,10) 'SWITCHED BUS, PROGRAMABLE DISCONNECT FROM THIS PORT'
C
C	else if (ucb$b_bs_errmsg .eq. 5) then
C
C	write(lun,10) 'SWITCHED BUS, PROGRAMABLE CONNECT TO THIS PORT'
C
C	else if (ucb$b_bs_errmsg .eq. 6) then
C
C	write(lun,10) '"UBA" INITIALIZE IN PROGRESS'
C
C	else if (ucb$b_bs_errmsg .eq. 7) then
C
C	write(lun,10) 'PORT HAS RECEIVED UNRECOGNIZED INTERRUPT'
C
C	else if (ucb$b_bs_errmsg .eq. 8) then
C
C	write(lun,10) 'PORT HAS ENCOUNTERED ILLEGAL CONDITION'
C	else
C
C	write(lun,15) ucb$b_bs_errmsg
C15	format(/' ',t8,'UCB$B_BS_ERRMSG',t24,z8.8)
C	endif
C
C	return
C
C	end
