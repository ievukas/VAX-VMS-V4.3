	Subroutine INIT_COMMONS
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
C++
C
C	AUTHOR:		CREATION DATE:	6-Sep-1983
C
C	Functional Description:
C
C	This routine initializes the data commons used by the device
C	dependent fortran routines. 
C
C
C	Modified By:
C
C	V03-002	SAR0276		Sharon A. Reynolds	20-Jun-1984
C		Added qio function code text for TMSCP support.
C
C**
C--


C
C	Include files
C 
	Include 'SRC$:QIOCOMMON.FOR /nolist'
	Include 'SRC$:MODES.FOR /nolist'
	Include 'SRC$:OPCODES.FOR /nolist'


C
C	Initialize the QIOCOMMON. This common contains all of the
C	QIO codes.
C
	io$_nop		= 'NO OPERATION*'
	io$_unload	= 'UNLOAD*'
	io$_loadmcode	= 'LOAD MICRO-CODE*'
	io$_seek	= 'SEEK*'
	io$_spacefile	= 'SPACE FILE(S)*'
	io$_startmproc	= 'START MICRO-PROCESSOR*'
	io$_recal	= 'RECALIBRATE*'
	io$_stop	= 'STOP DEVICE*'
	io$_drvclr	= 'DRIVE CLEAR*'
	io$_initialize	= 'INITIALIZE*'

	io$_release	= 'RELEASE PORT*'
	io$_setclockp	= 'SET CLOCK (PHYSICAL)*'
	io$_offset	= 'OFFSET HEADS*'
	io$_erasetape	= 'ERASE TAPE*'
	io$_startdatap	= 'START DATA (PHYSICAL)*'
	io$_retcenter	= 'RETURN TO CENTRE LINE*'
	io$_qstop	= 'QUEUE STOP*'
	io$_packack	= 'PACK ACKNOWLEDGE*'
	io$_search	= 'SEARCH FOR SECTOR*'
	io$_spacerecord	= 'SPACE RECORD(S)*'

	io$_writecheck	= 'WRITE CHECK*'
	io$_writepblk	= 'WRITE PHYSICAL BLOCK*'
	io$_readpblk	= 'READ PHYSICAL BLOCK*'
	io$_writehead	= 'WRITE HEADER AND DATA*'
	io$_readhead	= 'READ HEADER AND DATA*'
	io$_writetrackd	= 'WRITE TRACK DESCRIPTOR*'
	io$_readtrackd	= 'READ TRACK DESCRIPTOR*'
	io$_rereadn	= 'RE-READ NEXT*'
	io$_rereadp	= 'RE-READ PREVIOUS*'
	io$_writeret	= 'WRITE PHYSICAL BLOCK RETRY*'

	io$_writecheckh	= 'WRITE CHECK HEADER AND DATA*'
	io$_readpreset	= 'READ IN PRESET*'
	io$_startspndl	= 'START SPINDLE*'
	io$_setchar	= 'SET CHARACTERISTICS*'
	io$_sensechar	= 'SENSE CHARACTERISTICS*'
	io$_writemark	= 'WRITE TAPE MARK*'
	io$_wrttmkr	= 'WRITE TAPE MARK RETRY*'
	io$_diagnose	= 'DIAGNOSE*'
	io$_format	= 'SET MEDIA DENSITY, REFORMAT DISK*'
	io$_clean	= 'CLEAN TAPE*'

	io$_writelblk	= 'WRITE LOGICAL BLOCK*'
	io$_readlblk	= 'READ LOGICAL BLOCK*'
	io$_rewindoff	= 'REWIND, GO OFF-LINE*'
	io$_setmode	= 'SET MODE*'
	io$_rewind	= 'REWIND*'
	io$_skipfile	= 'SKIP FILE(S)*'
	io$_skiprecord	= 'SKIP RECORD(S)*'
	io$_sensemode	= 'SENSE MODE*'
	io$_writeof	= 'WRITE END-OF-FILE*'
	io$_writevblk	= 'WRITE VIRTUAL BLOCK*'

	io$_readvblk	= 'READ VIRTUAL BLOCK*'
	io$_access	= 'ACCESS FILE/DIRECTORY ENTRY*'
	io$_create	= 'CREATE FILE/DIRECTORY ENTRY*'
	io$_deaccess	= 'DEACCESS FILE*'
	io$_delete	= 'DELETE FILE/DIRECTORY ENTRY*'
	io$_modify	= 'MODIFY FILE ATTRIBUTES*'
	io$_setclock	= 'SET CLOCK*'
	io$_acpcontrol	= 'ACP CONTROL FUNCTION*'
	io$_startdata	= 'START DATA*'
	io$_mount	= 'MOUNT VOLUME*'

	io$_rdstats	= 'READ STATISTICS*'
	io$_writecsr	= 'WRITE CONTROL AND STATUS REGISTER*'
	io$_readcsr	= 'READ CONTROL AND STATUS RESISTER*'
	io$_abort	= 'ABORT*'
	io$_writewthbuf	= 'WRITE WITH BUFFER*'
	io$_readwthbuf	= 'READ WITH BUFFER*'
	io$_writebufncrc = 'WRITE BUFFER WITH NO CRC*'
	io$_readwthxbuf	= 'READ WITH TRANSPARENT BUFFER*'
	io$_available	= 'AVAILABLE, NO SPIN DOWN*'
	io$_dse		= 'DATA SECURITY ERASE*'

	qio_string	= 'QIO FUNCTION CODE*'


C
C	Initialize the  MODES common. It contains the cpu modes.
C
	modes(0) = 'KERNEL*'
	modes(1) = 'EXECUTIVE*'
	modes(2) = 'SUPERVISOR*'
	modes(3) = 'USER*'
	modes(4) = 'INTERRUPT*'


C
C	Initialize the  OPCODES common. It contains the operation
C	codes/text that apply to the VAX instruction set.
C
	opcodes('0'x) = 'HALT*'
	opcodes('1'x) = 'NOP*'
	opcodes('2'x) = 'REI*'
	opcodes('3'x) = 'BPT*'
	opcodes('4'x) = 'RET*'
	opcodes('5'x) = 'RSB*'
	opcodes('6'x) = 'LDPCTX*'
	opcodes('7'x) = 'SVPCTX*'
	opcodes('8'x) = 'CVTPS*'
	opcodes('9'x) = 'CVTSP*'
	opcodes('A'x) = 'INDEX*'
	opcodes('B'x) = 'CRC*'
	opcodes('C'x) = 'PROBER*'
	opcodes('D'x) = 'PROBEW*'
	opcodes('E'x) = 'INSQUE*'
	opcodes('F'x) = 'REMQUE*'

	opcodes('10'x) = 'BSBB*'
	opcodes('11'x) = 'BRB*'
	opcodes('12'x) = 'BNEQ, BNEQU*'
	opcodes('13'x) = 'BEQL, BEQLU*'
	opcodes('14'x) = 'BGTR*'
	opcodes('15'x) = 'BLEQ*'
	opcodes('16'x) = 'JSB*'
	opcodes('17'x) = 'JMP*'
	opcodes('18'x) = 'BGEQ*'
	opcodes('19'x) = 'BLSS*'
	opcodes('1A'x) = 'BGTRU*'
	opcodes('1B'x) = 'BLEGU*'
	opcodes('1C'x) = 'BVC*'
	opcodes('1D'x) = 'BVS*'
	opcodes('1E'x) = 'BGEQU, BCC*'
	opcodes('1F'x) = 'BLSSU, BCS*'

	opcodes('20'x) = 'ADDP4*'
	opcodes('21'x) = 'ADDP6*'
	opcodes('22'x) = 'SUBP4*'
	opcodes('23'x) = 'SUBP6*'
	opcodes('24'x) = 'CVTPT*'
	opcodes('25'x) = 'MULP*'
	opcodes('26'x) = 'CVTTP*'
	opcodes('27'x) = 'DIVP*'
	opcodes('28'x) = 'MOVC3*'
	opcodes('29'x) = 'CMPC3*'
	opcodes('2A'x) = 'SCANC*'
	opcodes('2B'x) = 'SPANC*'
	opcodes('2C'x) = 'MOVC5*'
	opcodes('2D'x) = 'CMPC5*'
	opcodes('2E'x) = 'MOVTC*'
	opcodes('2F'x) = 'MOVTUC*'

	opcodes('30'x) = 'BSBW*'
	opcodes('31'x) = 'BRW*'
	opcodes('32'x) = 'CVTWL*'
	opcodes('33'x) = 'CVTWB*'
	opcodes('34'x) = 'MOVP*'
	opcodes('35'x) = 'CMPP3*'
	opcodes('36'x) = 'CVTPL*'
	opcodes('37'x) = 'CMPP4*'
	opcodes('38'x) = 'EDITPC*'
	opcodes('39'x) = 'MATCHC*'
	opcodes('3A'x) = 'LOCC*'
	opcodes('3B'x) = 'SKPC*'
	opcodes('3C'x) = 'MOVZWL*'
	opcodes('3D'x) = 'ACBW*'
	opcodes('3E'x) = 'MOVAW*'
	opcodes('3F'x) = 'PUSHAW*'

	opcodes('40'x) = 'ADDF2*'
	opcodes('41'x) = 'ADDF3*'
	opcodes('42'x) = 'SUBF2*'
	opcodes('43'x) = 'SUBF3*'
	opcodes('44'x) = 'MULF2*'
	opcodes('45'x) = 'MULF3*'
	opcodes('46'x) = 'DIVF2*'
	opcodes('47'x) = 'DIVF3*'
	opcodes('48'x) = 'CVTFB*'
	opcodes('49'x) = 'CVTFW*'
	opcodes('4A'x) = 'CVTFL*'
	opcodes('4B'x) = 'CVTRFL*'
	opcodes('4C'x) = 'CVTBF*'
	opcodes('4D'x) = 'CVTWF*'
	opcodes('4E'x) = 'CVTLF*'
	opcodes('4F'x) = 'ACBF*'

	opcodes('50'x) = 'MOVF*'
	opcodes('51'x) = 'CMPF*'
	opcodes('52'x) = 'MNEGF*'
	opcodes('53'x) = 'TSTF*'
	opcodes('54'x) = 'EMODF*'
	opcodes('55'x) = 'CVTFD*'
	opcodes('56'x) = 'RESERVED*'
	opcodes('57'x) = 'ADAWI*'
	opcodes('58'x) = 'RESERVED*'
	opcodes('59'x) = 'RESERVED*'
	opcodes('5A'x) = 'RESERVED*'
	opcodes('5B'x) = 'RESERVED*'
	opcodes('5C'x) = 'INSQHI*'
	opcodes('5D'x) = 'INSQTI*'
	opcodes('5E'x) = 'REMQHI*'
	opcodes('5F'x) = 'REMQTI*'

	opcodes('60'x) = 'ADDD2*'
	opcodes('61'x) = 'ADDD3*'
	opcodes('62'x) = 'SUBD2*'
	opcodes('63'x) = 'SUBD3*'
	opcodes('64'x) = 'MULD2*'
	opcodes('65'x) = 'MULD3*'
	opcodes('66'x) = 'DIVD2*'
	opcodes('67'x) = 'DIVD3*'
	opcodes('68'x) = 'CVTDB*'
	opcodes('69'x) = 'CVTDW*'
	opcodes('6A'x) = 'CVTDL*'
	opcodes('6B'x) = 'CVTRDL*'
	opcodes('6C'x) = 'CVTBD*'
	opcodes('6D'x) = 'CVTWD*'
	opcodes('6E'x) = 'CVTLD*'
	opcodes('6F'x) = 'ACBD*'

	opcodes('70'x) = 'MOVD*'
	opcodes('71'x) = 'CMPD*'
	opcodes('72'x) = 'MNEGD*'
	opcodes('73'x) = 'TSTD*'
	opcodes('74'x) = 'EMODD*'
	opcodes('75'x) = 'POLYD*'
	opcodes('76'x) = 'CVTDF*'
	opcodes('77'x) = 'RESERVED*'
	opcodes('78'x) = 'ASHL*'
	opcodes('79'x) = 'ASHQ*'
	opcodes('7A'x) = 'EMUL*'
	opcodes('7B'x) = 'EDIV*'
	opcodes('7C'x) = 'CLRQ, CLRD*'
	opcodes('7D'x) = 'MOVQ*'
	opcodes('7E'x) = 'MOVAQ, MOVAD*'
	opcodes('7F'x) = 'PUSHAQ, PUSHAD*'

	opcodes('80'x) = 'ADDB2*'
	opcodes('81'x) = 'ADDB3*'
	opcodes('82'x) = 'SUBB2*'
	opcodes('83'x) = 'SUBB3*'
	opcodes('84'x) = 'MULB2*'
	opcodes('85'x) = 'MULB3*'
	opcodes('86'x) = 'DIVB2*'
	opcodes('87'x) = 'DIVB3*'
	opcodes('88'x) = 'BISB2*'
	opcodes('89'x) = 'BISB3*'
	opcodes('8A'x) = 'BICB2*'
	opcodes('8B'x) = 'BICB3*'
	opcodes('8C'x) = 'xORB2*'
	opcodes('8D'x) = 'xORB3*'
	opcodes('8E'x) = 'MNEGB*'
	opcodes('8F'x) = 'CASEB*'

	opcodes('90'x) = 'MOVB*'
	opcodes('91'x) = 'CMPB*'
	opcodes('92'x) = 'MCOMB*'
	opcodes('93'x) = 'BITB*'
	opcodes('94'x) = 'CLRB*'
	opcodes('95'x) = 'TSTB*'
	opcodes('96'x) = 'INCB*'
	opcodes('97'x) = 'DECB*'
	opcodes('98'x) = 'CVTBL*'
	opcodes('99'x) = 'CVTBW*'
	opcodes('9A'x) = 'MOVZBL*'
	opcodes('9B'x) = 'MOVZBW*'
	opcodes('9C'x) = 'ROTL*'
	opcodes('9D'x) = 'ACBB*'
	opcodes('9E'x) = 'MOVAB*'
	opcodes('9F'x) = 'PUSHAB*'

	opcodes('A0'x) = 'ADDW2*'
	opcodes('A1'x) = 'ADDW3*'
	opcodes('A2'x) = 'SUBW2*'
	opcodes('A3'x) = 'SUBW3*'
	opcodes('A4'x) = 'MULW2*'
	opcodes('A5'x) = 'MULW3*'
	opcodes('A6'x) = 'DIVW2*'
	opcodes('A7'x) = 'DIVW3*'
	opcodes('A8'x) = 'BISW2*'
	opcodes('A9'x) = 'BISW3*'
	opcodes('AA'x) = 'BICW2*'
	opcodes('AB'x) = 'BICW3*'
	opcodes('AC'x) = 'xORW2*'
	opcodes('AD'x) = 'xORW3*'
	opcodes('AE'x) = 'MNEGW*'
	opcodes('AF'x) = 'CASEW*'

	opcodes('B0'x) = 'MOVW*'
	opcodes('B1'x) = 'CMPW*'
	opcodes('B2'x) = 'MCOMW*'
	opcodes('B3'x) = 'BITW*'
	opcodes('B4'x) = 'CLRW*'
	opcodes('B5'x) = 'TSTW*'
	opcodes('B6'x) = 'INCW*'
	opcodes('B7'x) = 'DECW*'
	opcodes('B8'x) = 'BISPSW*'
	opcodes('B9'x) = 'BICPSW*'
	opcodes('BA'x) = 'POPR*'
	opcodes('BB'x) = 'PUSHR*'
	opcodes('BC'x) = 'CHMK*'
	opcodes('BD'x) = 'CHME*'
	opcodes('BE'x) = 'CHMS*'
	opcodes('BF'x) = 'CHMU*'

	opcodes('C0'x) = 'ADDL2*'
	opcodes('C1'x) = 'ADDL3*'
	opcodes('C2'x) = 'SUBL2*'
	opcodes('C3'x) = 'SUBL3*'
	opcodes('C4'x) = 'MULL2*'
	opcodes('C5'x) = 'MULL3*'
	opcodes('C6'x) = 'DIVL2*'
	opcodes('C7'x) = 'DIVL3*'
	opcodes('C8'x) = 'BISL2*'
	opcodes('C9'x) = 'BISL3*'
	opcodes('CA'x) = 'BICL2*'
	opcodes('CB'x) = 'BICL3*'
	opcodes('CC'x) = 'xORL2*'
	opcodes('CD'x) = 'xORL3*'
	opcodes('CE'x) = 'MNEGL*'
	opcodes('CF'x) = 'CASEL*'

	opcodes('D0'x) = 'MOVL*'
	opcodes('D1'x) = 'CMPL*'
	opcodes('D2'x) = 'MCOML*'
	opcodes('D3'x) = 'BITL*'
	opcodes('D4'x) = 'CLRL, CLRF*'
	opcodes('D5'x) = 'TSTL*'
	opcodes('D6'x) = 'INCL*'
	opcodes('D7'x) = 'DECL*'
	opcodes('D8'x) = 'ADWC*'
	opcodes('D9'x) = 'SBWC*'
	opcodes('DA'x) = 'MTPR*'
	opcodes('DB'x) = 'MFPR*'
	opcodes('DC'x) = 'MOVPSL*'
	opcodes('DD'x) = 'PUSHL*'
	opcodes('DE'x) = 'MOVAL, MOVAF*'
	opcodes('DF'x) = 'PUSHAL, PUSHAF*'

	opcodes('E0'x) = 'BBS*'
	opcodes('E1'x) = 'BBC*'
	opcodes('E2'x) = 'BBSS*'
	opcodes('E3'x) = 'BBCS*'
	opcodes('E4'x) = 'BBSC*'
	opcodes('E5'x) = 'BBCC*'
	opcodes('E6'x) = 'BBSSI*'
	opcodes('E7'x) = 'BBCCI*'
	opcodes('E8'x) = 'BLBS*'
	opcodes('E9'x) = 'BLBC*'
	opcodes('EA'x) = 'FFS*'
	opcodes('EB'x) = 'FFC*'
	opcodes('EC'x) = 'CMPV*'
	opcodes('ED'x) = 'CMPZV*'
	opcodes('EE'x) = 'EXTV*'
	opcodes('EF'x) = 'EXTZV*'

	opcodes('F0'x) = 'INSV*'
	opcodes('F1'x) = 'ACBL*'
	opcodes('F2'x) = 'AOBLSS*'
	opcodes('F3'x) = 'AOBLEQ*'
	opcodes('F4'x) = 'SOBGEQ*'
	opcodes('F5'x) = 'SOBGTR*'
	opcodes('F6'x) = 'CVTLB*'
	opcodes('F7'x) = 'CVTLW*'
	opcodes('F8'x) = 'ASHP*'
	opcodes('F9'x) = 'CVTLP*'
	opcodes('FA'x) = 'CALLG*'
	opcodes('FB'x) = 'CALLS*'
	opcodes('FC'x) = 'xFC*'
	opcodes('FD'x) = 'ESCD*'
	opcodes('FE'x) = 'ESCE*'
	opcodes('FF'x) = 'ESCF*'

	Return
	End		! Module
