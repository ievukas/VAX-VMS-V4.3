	Subroutine TU81_SENSE_BYTES_DECODE (lun)
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
C	Author: Sharon Reynolds		Creation Date: 5-Jul-1984
C
C	Description:
C
C		This routine decodes the device dependent information 
C		for the TU81 that is returned with a 'tape tranfer error'
C		packet.
C
C--
C**

	Include 'SRC$:MSGHDR /nolist'


	Byte	lun, code, extended_sense(0:15)

	Logical*1	bit

	Integer*4	COMPRESS4

	Equivalence	(emb(82),extended_sense)

	Character*22	byte_0(0:7)
	Data	byte_0(0)	/'UNIT EXCEPTION*'/
	Data	byte_0(1)	/'UNIT CHECK*'/
	Data	byte_0(3)	/'DATA CHECK*'/
	Data	byte_0(4)	/'EQUIPMENT CHECK*'/
	Data	byte_0(6)	/'INTERVENTION REQUIRED*'/
	Data	byte_0(7)	/'COMMAND REJECT*'/

	Character*24	byte_1(0:7)
	Data	byte_1(0)	/'DEVICE OFFLINE*'/
	Data	byte_1(1)	/'DEVICE NOT READY*'/
	Data	byte_1(3)	/'RESET KEY*'/
	Data	byte_1(4)	/'FILE PROTECTED*'/
	Data	byte_1(6)	/'DEVICE COMMAND CHECK*'/
	Data	byte_1(7)	/'ILLEGAL CHANNEL COMMAND*'/

	Character*23	byte_2(0:7)
	Data	byte_2(0)	/'DEVICE INTERRUPT CHECK*'/
	Data	byte_2(1)	/'VELOCITY CHECK*'/
	Data	byte_2(2)	/'DEVICE HARDWARE CHECK*'/
	Data	byte_2(3)	/'DEVICE RESPONSE CHECK*'/
	Data	byte_2(4)	/'WRITE HARDWARE CHECK*'/
	Data	byte_2(5)	/'READ HARDWARE CHECK*'/
	Data	byte_2(6)	/'CHANNEL RESPONSE CHECK*'/
	Data	byte_2(7)	/'CHANNEL PARITY ERROR*'/

	Character*14	byte_3_prt1(0:2)
	Data	byte_3_prt1(0)	/'TAPE MOVED*'/
	Data	byte_3_prt1(1)	/'BOT*'/
	Data	byte_3_prt1(2)	/'UNRECOVERABLE*'/

	Character*16	byte_3_prt2(4:7)
	Data	byte_3_prt2(4)	/'ID FAULT*'/
	Data	byte_3_prt2(5)	/'READ DATA CHECK*'/
	Data	byte_3_prt2(6)	/'PE CRC CHECK*'/
	Data	byte_3_prt2(7)	/'AGC FAULT*'/

	Character*26	byte_5(0:7)
	Data	byte_5(0)	/'VARIABLE GAP MODE (SHORT)*'/
	Data	byte_5(1)	/'VARIABLE GAP MODE (LONG)*'/
	Data	byte_5(2)	/'START/STOP MODE*'/
	Data	byte_5(3)	/'DIAGNOSTIC MODE*'/
	Data	byte_5(4)	/'FILE MARK DETECTED*'/
	Data	byte_5(5)	/'AUTO SPEED MODE*'/
	Data	byte_5(6)	/'HIGH SPEED MODE*'/
	Data	byte_5(7)	/'GCR MODE*'/

	Character*33	byte_6(2:7)
	Data	byte_6(2)	/'WRITE AUXILIARY CRC PARITY ERROR*'/
	Data	byte_6(4)	/'45 PARITY ERROR*'/
	Data	byte_6(5)	/'WRITE CRC PARITY ERROR*'/
	Data	byte_6(6)	/'RESIDUAL BYTE COUNT CHECK*'/
	Data	byte_6(7)	/'WRITE TRANSFER CHECK*'/

	Character*25	byte_7(0:7)
	Data	byte_7(0)	/'EXCESSIVE POINTERS*'/
	Data	byte_7(1)	/'NO TRACK POINTER*'/
	Data	byte_7(2)	/'UNCORRECTABLE DATA*'/
	Data	byte_7(3)	/'ECC3 CHECK*'/
	Data	byte_7(4)	/'RESYNC CHECK*'/
	Data	byte_7(5)	/'READ AUXILIARY CRC CHECK*'/
	Data	byte_7(6)	/'READ CRC CHECK*'/
	Data	byte_7(7)	/'RESIDUAL CHECK*'/

	Character*22	byte_8(0:7)
	Data	byte_8(0)	/'ARA ID CHECK*'/
	Data	byte_8(1)	/'ARA BURST CHECK*'/
	Data	byte_8(2)	/'ID CHECK*'/
	Data	byte_8(3)	/'WRITE TAPE MARK CHECK*'/
	Data	byte_8(4)	/'READ TIME OUT*'/
	Data	byte_8(5)	/'SKEW ERROR*'/
	Data	byte_8(6)	/'POSTAMBLE ERROR*'/
	Data	byte_8(7)	/'NOISE CHECK*'/

	Character*29	byte_9(0:7)
	Data	byte_9(0)	/'TRACK IN ERROR PARITY BIT = *'/
	Data	byte_9(1)	/'SINGLE TRACK CORRECTABLE*'/
	Data	byte_9(2)	/'DUAL TRACK CORRECTABLE*'/
	Data	byte_9(3)	/'END MARK CHECK*'/
	Data	byte_9(4)	/'READ DATA PARITY ERROR*'/
	Data	byte_9(5)	/'READ TRANSFER CHECK*'/
	Data	byte_9(6)	/'READ BUFFER IN PARITY ERROR*'/
	Data	byte_9(7)	/'EC HARDWARE CHECK*'/

	Character*1	byte_10(0:7)
	Data	byte_10(0)	/'2'/
	Data	byte_10(1)	/'8'/
	Data	byte_10(2)	/'1'/
	Data	byte_10(3)	/'9'/
	Data	byte_10(4)	/'3'/
	Data	byte_10(5)	/'5'/
	Data	byte_10(6)	/'6'/
	Data	byte_10(7)	/'7'/

	Character*15	byte_11(0:7)
	Data	byte_11(0)	/'EOT*'/
	Data	byte_11(1)	/'BOT*'/
	Data	byte_11(2)	/'HIGH SPEED*'/
	Data	byte_11(3)	/'GAP CONTROL*'/
	Data	byte_11(4)	/'FILE PROTECTED*'/
	Data	byte_11(5)	/'REWIND*'/
	Data	byte_11(6)	/'ONLINE*'/
	Data	byte_11(7)	/'READY*'/

	Character*9	byte_12(2:7)
	Data	byte_12(2)	/'S/S MODE*'/
	Data	byte_12(3)	/'LONG GAP*'/
	Data	byte_12(4)	/'GCR*'/
	Data	byte_12(5)	/'DSE*'/
	Data	byte_12(6)	/'WRITE*'/
	Data	byte_12(7)	/'REVERSE*'/

	Character*22	byte_13(0:7)
	Data	byte_13(0)	/'AIR FLOW/TEMP CHECK*'/
	Data	byte_13(1)	/'REVERSE IN BOT*'/
	Data	byte_13(2)	/'RESET KEY*'/
	Data	byte_13(3)	/'AGC CHECK*'/
	Data	byte_13(4)	/'DENSITY CHANGE*'/
	Data	byte_13(5)	/'DIAGNOSTIC REQUEST*'/
	Data	byte_13(6)	/'INTERVENTION REQUIRED*'/
	Data	byte_13(7)	/'COMMAND REJECT*'/

C Output the extended sense information header.
C
	Write (lun,5) 'TU81 EXTENDED SENSE INFORMATION'
5	Format (/' ',A31,/)
	

C Decode and output byte 0 of the extended sense information.
C
	Write (lun,10) 'BYTE 0', extended_sense(0)
10	Format (' ',T8,A,T24,Z2.2)

	Call OUTPUT (lun,extended_sense(0),byte_0, 0, 0, 7, '0') 


C Decode and output byte 1 of the extended sense information.
C
	Write (lun,10) 'BYTE 1', extended_sense(1)
	Call OUTPUT (lun,extended_sense(1),byte_1, 0, 0, 7, '0')
	
C Decode and output byte 2 of the extended sense information.
C
	Write (lun,10) 'BYTE 2', extended_sense(2)
	Call OUTPUT (lun,extended_sense(2),byte_2, 0, 0, 7, '0')


C Decode and output byte 3 of the extended sense information.
C
	Write (lun,10) 'BYTE 3', extended_sense(3)

	Call OUTPUT (lun,extended_sense(3),byte_3_prt1, 0, 0, 2, '0')
	Call OUTPUT (lun,extended_sense(3),byte_3_prt2, 4, 4, 7, '0')


C Decode and output byte 4 of the extended sense information.
C
	Write (lun,10) 'BYTE 4', extended_sense(4)

	Write (lun,20) 'FORMATTER COMMAND CODE = ', extended_sense(4)
20	Format (' ',T40,A25,Z2.2,'(X)')


C Decode and output byte 5 of the extended sense information.
C
	Write (lun,10) 'BYTE 5', extended_sense(5)
	Call OUTPUT (lun,extended_sense(5),byte_5, 0, 0, 7, '0')


C Decode and output byte 6 of the extended sense information.
C
	Write (lun,10) 'BYTE 6', extended_sense(6)
	Call OUTPUT (lun,extended_sense(6),byte_6, 2, 2, 7, '0')


C Decode and output byte 7 of the extended sense information.
C
	Write (lun,10) 'BYTE 7', extended_sense(7)
	Call OUTPUT (lun,extended_sense(7),byte_7, 0, 0, 7, '0')


C Decode and output byte 8 of the extended sense information.
C
	Write (lun,10) 'BYTE 8', extended_sense(8)
	Call OUTPUT (lun,extended_sense(8),byte_8, 0, 0, 7, '0')


C Decode and output byte 9 of the extended sense information.
C
	Write (lun,10) 'BYTE 9', extended_sense(9)
	Call OUTPUT (lun,extended_sense(9),byte_9, 0, 0, 7, '0')


C Decode and output byte 10 of the extended sense information.
C
	Write (lun,25) 'BYTE 10', extended_sense(10)
25	Format (' ',T8,A,T24,Z2.2)

	If (extended_sense(10) .NE. 0) then

 	  Do 27, I=0,7

	    Bit = LIB$EXTZV (I,1,extended_sense(10))
	    If (bit) then
	      Call LINCHK (lun,1)
	      Write (lun,26) 'TRACK IN ERROR = ', byte_10(I)
26	      Format (' ',T40,A17,A1,'.')
	    Endif		

27 	  Continue
	Endif

C Decode and output byte 11 of the extended sense information.
C
	Write (lun,10) 'BYTE 11', extended_sense(11)
	Call OUTPUT (lun,extended_sense(11),byte_11, 0, 0, 7, '0')


C Decode and output byte 12 of the extended sense information.
C
	Write (lun,10) 'BYTE 12', extended_sense(12)
	Call OUTPUT (lun,extended_sense(12),byte_12, 2, 2, 7, '0')


C Decode and output byte 13 of the extended sense information.
C
	Write (lun,10) 'BYTE 13', extended_sense(13)
	Call OUTPUT (lun,extended_sense(13),byte_13, 0, 0, 7, '0')


C Decode and output byte 14 of the extended sense information.
C
	Write (lun,28) 'BYTE 14', extended_sense(14),'COMMAND CODE'
28	Format (' ',T8,A,T24,Z2.2,/,T40,A12)

C Decode and output byte 15 of the extended sense information.
C
	Write (lun,30) 'BYTE 15', extended_sense(15),'MARGINAL CONDITION CODE'
30	Format (' ',T8,A,T24,Z2.2,/,T40,A23)


	End
