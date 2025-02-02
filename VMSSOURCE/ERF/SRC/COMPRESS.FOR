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
C	AUTHOR	BRIAN PORTER		CREATION DATE	11-OCT-1979
C
C	Functional description:
C
C	Provides the field width for integers and character strings.
C
C	Modified by:
C
C	v03-001	BP0001		Brian Porter,		24-AUG-1982
C		Made 32 bit unsigned numbers work.
C**
C
C


	INTEGER FUNCTION COMPRESS4*4 (INTEGER4)



	INTEGER*4		INTEGER4

	INTEGER*4		INTEGER



	INTEGER = LIB$EXTZV(0,31,INTEGER4)

	COMPRESS4 = 1 + INT(LOG10(REAL(MAX(1,INTEGER))))

	IF (INTEGER4 .LT. 0) COMPRESS4 = COMPRESS4 + 1

	RETURN

	END




	INTEGER FUNCTION COMPRESSF*4 (REAL8,DECIMAL_PLACES)



	REAL		REAL8

	BYTE		DECIMAL_PLACES



	COMPRESSF = (2 + DECIMAL_PLACES) + JINT(ALOG10(AMAX1(1.0,REAL8)))

	RETURN

	END




	INTEGER FUNCTION COMPRESSC*4 (STRING)



	CHARACTER*(*)	STRING



	COMPRESSC = max(1,(MIN(33,(LIB$LOCC('*',STRING)-1))))

	RETURN

	END
