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
C Author: Elliott A. Drayton			Creation Date: 13-Apr-1984
C
C	This modules entry points are called from BLISS modules. This was needed
C	because the routines being called have names which are the same as some
C	bliss UCB symbol.
C
C Modified by:
C
C	V04-001	EAD0150		Elliott A. Drayton		14-Apr-1984
C		Correct routine name from UBC$ to UCB$.
C



	Subroutine ORB$L_OWNER_RTN ( Lstlun, Uic )
	Byte		Lstlun
	Integer*4	Uic
	Call ORB$L_OWNER ( Lstlun , Uic )
	Return
	End

	Subroutine UCB$W_STS_RTN ( Lstlun, Status)
	Byte		Lstlun
	Integer*2	Status
	Call UCB$W_STS ( Lstlun , Status )
	Return
	End

	Subroutine UCB$L_OPCNT_RTN ( Lstlun, Opcnt )
	Byte		Lstlun
	Integer*4	Opcnt
	Call UCB$L_OPCNT ( Lstlun , Opcnt )
	Return
	End

	Subroutine UCB$W_ERRCNT_RTN ( Lstlun, Errcnt )
	Byte		Lstlun
	Integer*2	Errcnt
	Call UCB$W_ERRCNT ( Lstlun , Errcnt )
	Return
	End
