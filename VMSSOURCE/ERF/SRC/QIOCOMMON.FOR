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

C	Author	Brian Porter			Creation date	05-APR-1982

C++
C	Function description:
C
C	This is an include file that lists all device QIO strings.
C
C	Modified by:
C
C	V03-003	SAR0275		Sharon A. Reynolds	20-June-1984
C		Added new function code for TMSCP support.
C
C	V03-002	EAD0002		Elliott A. Drayton	16-DEC-1982
C		Moved data statements which initilized the common to
C		ERRPRT.
C
C	v03-001	BP0001		Brian Porter,		05-APR-1982
C		Added new string.
C**
C--



	character*13	io$_nop
	common	/qiocommon/	io$_nop

	character*7	io$_unload
	common	/qiocommon/	io$_unload

	character*16	io$_loadmcode
	common	/qiocommon/	io$_loadmcode

	character*5	io$_seek
	common	/qiocommon/	io$_seek

	character*14	io$_spacefile
	common	/qiocommon/	io$_spacefile

	character*22	io$_startmproc
	common	/qiocommon/	io$_startmproc

	character*12	io$_recal
	common	/qiocommon/	io$_recal

	character*12	io$_stop
	common	/qiocommon/	io$_stop

	character*12	io$_drvclr
	common	/qiocommon/	io$_drvclr

	character*11	io$_initialize
	common	/qiocommon/	io$_initialize

	character*12	io$_release
	common	/qiocommon/	io$_release

	character*21	io$_setclockp
	common	/qiocommon/	io$_setclockp

	character*12	io$_offset
	common	/qiocommon/	io$_offset

	character*11	io$_erasetape
	common	/qiocommon/	io$_erasetape

	character*22	io$_startdatap
	common	/qiocommon/	io$_startdatap

	character*22	io$_retcenter
	common	/qiocommon/	io$_retcenter

	character*11	io$_qstop
	common	/qiocommon/	io$_qstop

	character*17	io$_packack
	common	/qiocommon/	io$_packack

	character*18	io$_search
	common	/qiocommon/	io$_search

	character*16	io$_spacerecord
	common	/qiocommon/	io$_spacerecord

	character*12	io$_writecheck
	common	/qiocommon/	io$_writecheck

	character*21	io$_writepblk
	common	/qiocommon/	io$_writepblk

	character*20	io$_readpblk
	common	/qiocommon/	io$_readpblk

	character*22	io$_writehead
	common	/qiocommon/	io$_writehead

	character*21	io$_readhead
	common	/qiocommon/	io$_readhead

	character*23	io$_writetrackd
	common	/qiocommon/	io$_writetrackd

	character*22	io$_readtrackd
	common	/qiocommon/	io$_readtrackd

	character*13	io$_rereadn
	common	/qiocommon/	io$_rereadn

	character*17	io$_rereadp
	common	/qiocommon/	io$_rereadp

	character*27	io$_writeret
	common	/qiocommon/	io$_writeret

	character*28	io$_writecheckh
	common	/qiocommon/	io$_writecheckh

	character*15	io$_readpreset
	common	/qiocommon/	io$_readpreset

	character*14	io$_startspndl
	common	/qiocommon/	io$_startspndl

	character*20	io$_setchar
	common	/qiocommon/	io$_setchar

	character*22	io$_sensechar
	common	/qiocommon/	io$_sensechar

	character*16	io$_writemark
	common	/qiocommon/	io$_writemark

	character*22	io$_wrttmkr
	common	/qiocommon/	io$_wrttmkr

	character*9	io$_diagnose
	common	/qiocommon/	io$_diagnose

	character*33	io$_format
	common	/qiocommon/	io$_format

	character*11	io$_clean
	common	/qiocommon/	io$_clean

	character*20	io$_writelblk
	common	/qiocommon/	io$_writelblk

	character*19	io$_readlblk
	common	/qiocommon/	io$_readlblk

	character*20	io$_rewindoff
	common	/qiocommon/	io$_rewindoff

	character*9	io$_setmode
	common	/qiocommon/	io$_setmode

	character*7	io$_rewind
	common	/qiocommon/	io$_rewind

	character*13	io$_skipfile
	common	/qiocommon/	io$_skipfile

	character*15	io$_skiprecord
	common	/qiocommon/	io$_skiprecord

	character*11	io$_sensemode
	common	/qiocommon/	io$_sensemode

	character*18	io$_writeof
	common	/qiocommon/	io$_writeof

	character*20	io$_writevblk
	common	/qiocommon/	io$_writevblk

	character*19	io$_readvblk
	common	/qiocommon/	io$_readvblk

	character*28	io$_access
	common	/qiocommon/	io$_access

	character*28	io$_create
	common	/qiocommon/	io$_create

	character*14	io$_deaccess
	common	/qiocommon/	io$_deaccess

	character*14	io$_delete
	common	/qiocommon/	io$_delete

	character*23	io$_modify
	common	/qiocommon/	io$_modify

	character*10	io$_setclock
	common	/qiocommon/	io$_setclock

	character*21	io$_acpcontrol
	common	/qiocommon/	io$_acpcontrol

	character*11	io$_startdata
	common	/qiocommon/	io$_startdata

	character*13	io$_mount
	common	/qiocommon/	io$_mount

	character*16	io$_rdstats
	common	/qiocommon/	io$_rdstats

	character*34	io$_writecsr
	common	/qiocommon/	io$_writecsr

	character*33	io$_readcsr
	common	/qiocommon/	io$_readcsr

	character*6	io$_abort
	common	/qiocommon/	io$_abort

	character*18	io$_writewthbuf
	common	/qiocommon/	io$_writewthbuf

	character*17	io$_readwthbuf
	common	/qiocommon/	io$_readwthbuf

	character*25	io$_writebufncrc
	common	/qiocommon/	io$_writebufncrc

	character*29	io$_readwthxbuf
	common	/qiocommon/	io$_readwthxbuf

	character*18	qio_string
	common	/qiocommon/	qio_string

	character*24	io$_available
	common	/qiocommon/	io$_available

	Character*20	io$_dse
	Common	/qiocommon/	io$_dse

