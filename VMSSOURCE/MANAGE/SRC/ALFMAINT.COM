$!
$!	IDENT V04-001
$!
$!
$! ALFMAINT - Maintain the system-wide auto-login file.
$!
$! MODIFIED BY:
$!
$!	V04-001	BLS0327		Benn Schreiber		25-JUN-1984
$!		Use FULLDEVNAM, make prompts clearer.
$!
$ ask = "inquire/nopunc"
$ say = "write sys$output"
$ alfdef = "SYS$SYSTEM:.DAT"
$ sysalf = f$parse("SYSALF",alfdef,,,"SYNTAX_ONLY")
$ if f$search(sysalf) .nes. "" then goto open_alf
$ say "%ALFMAINT-I-FNF, ",sysalf," not found...creating new file"
$ create /fdl=sys$input 'sysalf'	!Create new SYSALF
TITLE	sysalf auto login data file
FILE
	ORGANIZATION		indexed
	PROTECTION		(system:rwe,o:rwe,g,w)
	OWNER			[1,4]
RECORD
	SIZE			128
KEY 0
	CHANGES                 no
	NAME                    "Terminal"
	PROLOG                  3
	LENGTH			63
	POSITION		0
KEY 1
	CHANGES			YES
	DUPLICATES		YES
	DATA_KEY_COMPRESSION	YES
	INDEX_COMPRESSION	YES
	NAME			"Username"
	NULL_KEY		yes
	NULL_VALUE		" "
	LENGTH			63
	POSITION		63
$open_alf:
$ on control_y then goto done
$ open /share=read /read /write /err=e_noalf f1 'sysalf'
$do_term:
$ say ""
$ say "Enter the name of the terminal that you would like to set"
$ say "for automatic login, or a blank line or EXIT to exit."
$ say ""
$ ask term "Terminal (ddcu)? "
$ if term .eqs. "" then goto done
$ if f$locate(term,"EXIT") .eq. 0 then goto done
$ term = term - "_" - "_" - "_" - ":"
$ term = term + ":"
$ if .not. f$getdvi(term,"EXISTS") then goto e_notaterm
$ term = f$getdvi(term,"FULLDEVNAM")
$ if term .eqs. "" then goto do_term
$ if f$getdvi(term,"TRM") then goto get_user
$e_notaterm:
$ say "%ALFMAINT-E-NOTATERM, ''term' is not a terminal."
$ goto do_term
$get_user:
$ say ""
$ say "Enter the username you would like to automatically login on ''term'."
$ say "Enter a blank line to display and optionally delete the record for ''term'."
$ say ""
$ ask user "Username? "
$ if user .eqs. "" then goto deleterec
$ read /index=0 /key="''term'" /err=addrec f1 line
$ olduser = f$extract(63,63,line)
$ olduser := 'olduser
$ say ""
$ say "The current user for terminal ",term," is ''olduser'."
$ ask yn "Do you want to change this record (Y/N)? "
$ if .not. yn then goto do_term
$ line[63,63]:='user'
$ write /update f1 line
$ say "Terminal ",term, " record modified, new user is ''user'."
$ goto do_term
$addrec:
$ line[0,63]:='term'
$ line[63,63]:='user'
$ write f1 line
$ say "Terminal ",term," user ''user' record added."
$ goto do_term
$ deleterec:
$ read /index=0 /key="''term'" /error=not_there f1 line
$ olduser = f$extract(63,63,line)
$ olduser := 'olduser
$ say "Terminal ''term', current user is ''olduser'."
$ ask yn "Do you want to delete this record (Y/N)? "
$ if .not. yn then goto do_term
$ read /index=0 /key="''term'" /delete f1 line
$ say "Terminal ",term, " record deleted."
$ goto do_term
$not_there:
$ say "%ALFMAINT-E-NONEXREC, Terminal ",term," record does not exist."
$ goto do_term
$done:
$ close /nolog f1
$ exit
$
$e_noalf:
$ status = $status
$ say "%ALFMAINT-E-OPENIN, Error opening ",sysalf
$ say f$message(status)
$ goto done
