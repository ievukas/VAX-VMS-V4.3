(* PASSTATUS.PAS - VAX-11 Pascal V2 STATUS Function Value Definitions *)

(****************************************************************************
(*									    *
(*  COPYRIGHT (c) 1978, 1980, 1982, 1984 BY				    *
(*  DIGITAL EQUIPMENT CORPORATION, MAYNARD, MASSACHUSETTS.		    *
(*  ALL RIGHTS RESERVED.						    *
(* 									    *
(*  THIS SOFTWARE IS FURNISHED UNDER A LICENSE AND MAY BE USED AND COPIED   *
(*  ONLY IN  ACCORDANCE WITH  THE  TERMS  OF  SUCH  LICENSE  AND WITH THE   *
(*  INCLUSION OF THE ABOVE COPYRIGHT NOTICE. THIS SOFTWARE OR  ANY  OTHER   *
(*  COPIES THEREOF MAY NOT BE PROVIDED OR OTHERWISE MADE AVAILABLE TO ANY   *
(*  OTHER PERSON.  NO TITLE TO AND OWNERSHIP OF  THE  SOFTWARE IS  HEREBY   *
(*  TRANSFERRED.							    *
(* 									    *
(*  THE INFORMATION IN THIS SOFTWARE IS  SUBJECT TO CHANGE WITHOUT NOTICE   *
(*  AND  SHOULD  NOT  BE  CONSTRUED AS  A COMMITMENT BY DIGITAL EQUIPMENT   *
(*  CORPORATION.							    *
(* 									    *
(*  DIGITAL ASSUMES NO RESPONSIBILITY FOR THE USE  OR  RELIABILITY OF ITS   *
(*  SOFTWARE ON EQUIPMENT WHICH IS NOT SUPPLIED BY DIGITAL.		    *
(* 									    *
(*									    *
(****************************************************************************

(* These values are returned by the predefined STATUS function. *)

CONST
    PAS$K_EOF        =   -1;	(* file is at end-of-file *)
    PAS$K_SUCCESS    =    0;    (* last operation successful *)

    PAS$K_FILALROPE  =    1;    (* file is already open *)
    PAS$K_ERRDUROPE  =    2;    (* error during OPEN *)
    PAS$K_FILNOTFOU  =    3;    (* file not found *)
    PAS$K_INVFILSYN  =    4;    (* invalid filename syntax *)
    PAS$K_ACCMETINC  =    5;    (* ACCESS_METHOD specified is incompatible with this file *)
    PAS$K_RECLENINC  =    6;    (* RECORD_LENGTH specified is inconsistent with this file *)
    PAS$K_RECTYPINC  =    7;    (* RECORD_TYPE specified is inconsistent with this file *)
    PAS$K_ORGSPEINC  =    8;    (* ORGANIZATION specified is inconsistent with this file *)
    PAS$K_INVKEYDEF  =    9;    (* invalid key definition *)
    PAS$K_KEYDEFINC  =   10;    (* KEY(<n>) definition is inconsistent with this file *)
    PAS$K_KEYNOTDEF  =   11;    (* KEY(<n>) is not defined in this file *)
    PAS$K_INVRECLEN  =   12;    (* invalid record length of <n> *)
    PAS$K_TEXREQSEQ  =   13;    (* textfiles require sequential organization and access *)
    PAS$K_FILNAMREQ  =   14;    (* FILE_NAME required for this HISTORY or DISPOSITION *)
    PAS$K_FILALRCLO  =   15;    (* file is already closed *)
    PAS$K_ERRDURCLO  =   16;    (* error during CLOSE *)
    PAS$K_AMBVALENU  =   30;    (* "<string>" is an ambiguous value for enumerated type "<type>" *)
    PAS$K_INVSYNENU  =   31;    (* "<string>" is invalid syntax for an enumerated value *)
    PAS$K_INVSYNINT  =   32;    (* "<string>" is invalid syntax for an integer value *)
    PAS$K_INVSYNREA  =   33;    (* "<string>" is invalid syntax for a real value *)
    PAS$K_INVSYNUNS  =   34;    (* "<string>" is invalid syntax for an unsigned value *)
    PAS$K_NOTVALTYP  =   35;    (* "<string>" is not a value of type "<type>" *)
    PAS$K_ERRDURPRO  =   36;    (* error during prompting *)
    PAS$K_ERRDURWRI  =   50;    (* error during WRITELN *)
    PAS$K_INVFIESPE  =   51;    (* invalid field specification for WRITE *)
    PAS$K_LINTOOLON  =   52;    (* line is too long, exceeded record length by <n> character(s) *)
    PAS$K_NEGWIDDIG  =   53;    (* negative Width or Digits specification is not allowed *)
    PAS$K_WRIINVENU  =   54;    (* WRITE of an invalid enumerated value *)
    PAS$K_KEYVALINC  =   70;    (* key value is incompatible with this file's key <n> *)
    PAS$K_KEYDUPNOT  =   71;    (* key field duplication is not allowed *)
    PAS$K_KEYCHANOT  =   72;    (* key field change is not allowed *)
    PAS$K_CURCOMUND  =   73;    (* current component is undefined for DELETE or UPDATE *)
    PAS$K_FAIGETLOC  =   74;    (* failed to GET locked component *)
    PAS$K_DELNOTALL  =  100;    (* DELETE is not allowed for a sequential organization file *)
    PAS$K_ERRDURDEL  =  101;    (* error during DELETE *)
    PAS$K_ERRDURFIN  =  102;    (* error during FIND or FINDK *)
    PAS$K_ERRDURGET  =  103;    (* error during GET *)
    PAS$K_ERRDURPUT  =  104;    (* error during PUT *)
    PAS$K_ERRDURRES  =  105;    (* error during RESET or RESETK *)
    PAS$K_ERRDURREW  =  106;    (* error during REWRITE *)
    PAS$K_ERRDURTRU  =  107;    (* error during TRUNCATE *)
    PAS$K_ERRDURUNL  =  108;    (* error during UNLOCK *)
    PAS$K_ERRDURUPD  =  109;    (* error during UPDATE *)
    PAS$K_FILNOTDIR  =  110;    (* file is not opened for direct access *)
    PAS$K_FILNOTGEN  =  111;    (* file is not in Generation mode *)
    PAS$K_FILNOTINS  =  112;    (* file is not in Inspection mode *)
    PAS$K_FILNOTKEY  =  113;    (* file is not opened for keyed access *)
    PAS$K_FILNOTOPE  =  114;    (* file is not open *)
    PAS$K_FILNOTSEQ  =  115;    (* file is not sequential organization *)
    PAS$K_FILNOTTEX  =  116;    (* file is not a textfile *)
    PAS$K_GENNOTALL  =  117;    (* Generation mode is not allowed for a READONLY file *)
    PAS$K_GETAFTEOF  =  118;    (* GET attempted after end-of-file *)
    PAS$K_INSNOTALL  =  119;    (* Inspection mode is not allowed for a WRITEONLY file *)
    PAS$K_INSVIRMEM  =  120;    (* insufficient virtual memory *)
    PAS$K_INVARGPAS  =  121;    (* invalid argument to Pascal Run-Time Library *)
    PAS$K_LINVALEXC  =  122;    (* LINELIMIT value exceeded *)
    PAS$K_REWNOTALL  =  123;    (* REWRITE is not allowed for a shared file *)
    PAS$K_RESNOTALL  =  124;    (* RESET is not allowed on an unopened internal file *)
    PAS$K_TRUNOTALL  =  125;    (* TRUNCATE is not allowed for a shared file *)
    PAS$K_UPDNOTALL  =  126;    (* UPDATE is not allowed for a sequential organization file *)

(* End of PASSTATUS.PAS *)
