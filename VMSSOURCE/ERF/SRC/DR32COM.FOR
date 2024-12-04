C
C	DR32COM 
C
C	This is the DR32 common for text used by both the DR780 and DR750
C	modules.
C
C Version:	'V04-000'
C
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
C	Author: Sharon Reynolds			Creation Date:	10-Aug-1981
C
C Modified by:
C		EAD0008		Elliott A. Drayton		26-Jan-1983
C		Moved data statements which initialized CHARACTER arrays
C		to module ERRPRT.
C
C**

	Common /DR32/
	1 v1dr_sl, v2dr_sl,
	2 v1dr_bb, v1dr_cb

	CHARACTER*23	V1DR_SL(0:14)
	CHARACTER*22	V2DR_SL(21:23)
	CHARACTER*31	V1DR_BB(1:3)
	CHARACTER*32	V1DR_CB(1:3)
