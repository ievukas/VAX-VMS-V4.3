(* PASDEF.PAS - VAX-11 Pascal V2 Condition Code Definitions *)

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

(*  Note:  This file is designed to be included as part of a CONST section. *)

    PAS$_FILALROPE  = %X'0021864C';    (* file is already open *)
    PAS$_ERRDUROPE  = %X'00218654';    (* error during OPEN *)
    PAS$_FILNOTFOU  = %X'0021865C';    (* file not found *)
    PAS$_INVFILSYN  = %X'00218664';    (* invalid filename syntax *)
    PAS$_ACCMETINC  = %X'0021866C';    (* ACCESS_METHOD specified is incompatible with this file *)
    PAS$_RECLENINC  = %X'00218674';    (* RECORD_LENGTH specified is inconsistent with this file *)
    PAS$_RECTYPINC  = %X'0021867C';    (* RECORD_TYPE specified is inconsistent with this file *)
    PAS$_ORGSPEINC  = %X'00218684';    (* ORGANIZATION specified is inconsistent with this file *)
    PAS$_INVKEYDEF  = %X'0021868C';    (* invalid key definition *)
    PAS$_KEYDEFINC  = %X'00218694';    (* KEY(<n>) definition is inconsistent with this file *)
    PAS$_KEYNOTDEF  = %X'0021869C';    (* KEY(<n>) is not defined in this file *)
    PAS$_INVRECLEN  = %X'002186A4';    (* invalid record length of <n> *)
    PAS$_TEXREQSEQ  = %X'002186AC';    (* textfiles require sequential organization and access *)
    PAS$_FILNAMREQ  = %X'002186B4';    (* FILE_NAME required for this HISTORY or DISPOSITION *)
    PAS$_FILALRCLO  = %X'002186BC';    (* file is already closed *)
    PAS$_ERRDURCLO  = %X'002186C4';    (* error during CLOSE *)
    PAS$_AMBVALENU  = %X'00218734';    (* "<string>" is an ambiguous value for enumerated type "<type>" *)
    PAS$_INVSYNENU  = %X'0021873C';    (* "<string>" is invalid syntax for an enumerated value *)
    PAS$_INVSYNINT  = %X'00218744';    (* "<string>" is invalid syntax for an integer value *)
    PAS$_INVSYNREA  = %X'0021874C';    (* "<string>" is invalid syntax for a real value *)
    PAS$_INVSYNUNS  = %X'00218754';    (* "<string>" is invalid syntax for an unsigned value *)
    PAS$_NOTVALTYP  = %X'0021875C';    (* "<string>" is not a value of type "<type>" *)
    PAS$_ERRDURPRO  = %X'00218764';    (* error during prompting *)
    PAS$_ERRDURWRI  = %X'002187D4';    (* error during WRITELN *)
    PAS$_INVFIESPE  = %X'002187DC';    (* invalid field specification for WRITE *)
    PAS$_LINTOOLON  = %X'002187E4';    (* line is too long, exceeded record length by <n> character(s) *)
    PAS$_NEGWIDDIG  = %X'002187EC';    (* negative Width or Digits specification is not allowed *)
    PAS$_WRIINVENU  = %X'002187F4';    (* WRITE of an invalid enumerated value *)
    PAS$_KEYVALINC  = %X'00218874';    (* key value is incompatible with this file's key <n> *)
    PAS$_KEYDUPNOT  = %X'0021887C';    (* key field duplication is not allowed *)
    PAS$_KEYCHANOT  = %X'00218884';    (* key field change is not allowed *)
    PAS$_CURCOMUND  = %X'0021888C';    (* current component is undefined for DELETE or UPDATE *)
    PAS$_FAIGETLOC  = %X'00218894';    (* failed to GET locked component *)
    PAS$_DELNOTALL  = %X'00218964';    (* DELETE is not allowed for a sequential organization file *)
    PAS$_ERRDURDEL  = %X'0021896C';    (* error during DELETE *)
    PAS$_ERRDURFIN  = %X'00218974';    (* error during FIND or FINDK *)
    PAS$_ERRDURGET  = %X'0021897C';    (* error during GET *)
    PAS$_ERRDURPUT  = %X'00218984';    (* error during PUT *)
    PAS$_ERRDURRES  = %X'0021898C';    (* error during RESET or RESETK *)
    PAS$_ERRDURREW  = %X'00218994';    (* error during REWRITE *)
    PAS$_ERRDURTRU  = %X'0021899C';    (* error during TRUNCATE *)
    PAS$_ERRDURUNL  = %X'002189A4';    (* error during UNLOCK *)
    PAS$_ERRDURUPD  = %X'002189AC';    (* error during UPDATE *)
    PAS$_FILNOTDIR  = %X'002189B4';    (* file is not opened for direct access *)
    PAS$_FILNOTGEN  = %X'002189BC';    (* file is not in Generation mode *)
    PAS$_FILNOTINS  = %X'002189C4';    (* file is not in Inspection mode *)
    PAS$_FILNOTKEY  = %X'002189CC';    (* file is not opened for keyed access *)
    PAS$_FILNOTOPE  = %X'002189D4';    (* file is not open *)
    PAS$_FILNOTSEQ  = %X'002189DC';    (* file is not sequential organization *)
    PAS$_FILNOTTEX  = %X'002189E4';    (* file is not a textfile *)
    PAS$_GENNOTALL  = %X'002189EC';    (* Generation mode is not allowed for a READONLY file *)
    PAS$_GETAFTEOF  = %X'002189F4';    (* GET attempted after end-of-file *)
    PAS$_INSNOTALL  = %X'002189FC';    (* Inspection mode is not allowed for a WRITEONLY file *)
    PAS$_INSVIRMEM  = %X'00218A04';    (* insufficient virtual memory *)
    PAS$_INVARGPAS  = %X'00218A0C';    (* invalid argument to Pascal Run-Time Library *)
    PAS$_LINVALEXC  = %X'00218A14';    (* LINELIMIT value exceeded *)
    PAS$_REWNOTALL  = %X'00218A1C';    (* REWRITE is not allowed for a shared file *)
    PAS$_RESNOTALL  = %X'00218A24';    (* RESET is not allowed on an unopened internal file *)
    PAS$_TRUNOTALL  = %X'00218A2C';    (* TRUNCATE is not allowed for a shared file *)
    PAS$_UPDNOTALL  = %X'00218A34';    (* UPDATE is not allowed for a sequential organization file *)
    PAS$_INVFILVAR  = %X'00219F44';    (* invalid file variable at location <n> *)
    PAS$_FILALRACT  = %X'00219F4C';    (* file "<file>" is already active *)
    PAS$_ERRDURNEW  = %X'00219F54';    (* error during NEW *)
    PAS$_ERRDURDIS  = %X'00219F5C';    (* error during DISPOSE *)
    PAS$_ERRDURMAR  = %X'00219F64';    (* error during MARK *)
    PAS$_ERRDURREL  = %X'00219F6C';    (* error during RELEASE *)
    PAS$_HALT       = %X'00219F84';    (* HALT procedure called *)
    PAS$_BUGCHECK   = %X'00219F8C';    (* internal consistency failure <n> in Pascal Run-Time Library *)
    PAS$_NEGDIGARG  = %X'00219F94';    (* negative Digits argument to BIN, HEX or OCT is not allowed *)
    PAS$_ARRINDVAL  = %X'0021BE84';    (* array index value is out of range *)
    PAS$_ARRNOTCOM  = %X'0021BE8C';    (* conformant array is not compatible *)
    PAS$_ARRNOTSTR  = %X'0021BE94';    (* conformant array is not a string *)
    PAS$_CASSELVAL  = %X'0021BE9C';    (* CASE selector value is out of range *)
    PAS$_CONCATLEN  = %X'0021BEA4';    (* string concatenation has more than 65535 characters *)
    PAS$_PADLENERR  = %X'0021BEAC';    (* PAD length error *)
    PAS$_PTRREFNIL  = %X'0021BEB4';    (* pointer reference to NIL *)
    PAS$_SETASGVAL  = %X'0021BEBC';    (* set assignment value has element out of range *)
    PAS$_SETCONVAL  = %X'0021BEC4';    (* set constructor value is out of range *)
    PAS$_STRASGLEN  = %X'0021BECC';    (* string assignment length error *)
    PAS$_STRCOMLEN  = %X'0021BED4';    (* strings comparison length error *)
    PAS$_SUBASGVAL  = %X'0021BEDC';    (* subrange assignment value is out of range *)
    PAS$_SUBSTRSEL  = %X'0021BEE4';    (* SUBSTR selection error *)
    PAS$_VARINDVAL  = %X'0021BEEC';    (* varying index value is greater than current length *)
    PAS$_ORDVALOUT  = %X'0021BEF4';    (* ordinal value is out of range *)

(* End of PASDEF.PAS *)
