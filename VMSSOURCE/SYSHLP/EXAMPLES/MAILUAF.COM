$ !++
$ !
$ !  MAILUAF.COM - Modify SYS$SYSTEM:VMSMAIL.DAT
$ !
$ !
$ !  ABSTRACT:	Sample command procedure to modify
$ !		SYS$SYSTEM:VMSMAIL.DAT
$ !
$ !		This command procedure will prompt
$ !		the user for a command.  The valid
$ !		commands are:
$ !
$ !		ADD username	- Add a new user to SYS$SYSTEM:VMSMAIL.DAT
$ !		CANCEL username - Cancel mail forwarding for username
$ !		EXIT		- Exit from this procedure
$ !		HELP		- Type help message
$ !		MODIFY username - Modify mail forwarding address for username
$ !		REMOVE username - Remove username from SYS$SYSTEM:VMSMAIL.DAT
$ !		SHOW username 	- Display mail information about username
$ !		LIST		- List forwarding addresses for all users 
$ !
$ !
$ !  REQUIRED PRIVILEGES:
$ !		BYPASS
$ !
$ !		
$ !  IMPLICIT OUTPUT:
$ !		SYS$SYSTEM:VMSMAIL.DAT will be created if it does
$ !		not exsist.
$ !
$ !
$ !--
$ if = "IF"
$ inquire = "INQUIRE"
$ open = "OPEN"
$ goto = "GOTO"
$ write = "WRITE"
$ create = "CREATE"
$ type = "TYPE"
$ read = "READ"
$ close = "CLOSE"
$ exit = "EXIT"
$ ask = "inquire/nopunctuation"
$ prev_priv = f$setprv("SYSPRV")
$ sysmai = "SYS$SYSTEM:VMSMAIL.DAT"
$ open /share=write /read /write /error=no_file f1 'sysmai'
$ goto file_open
$no_file:
$ write sys$output sysmai," not found...creating new file"
$ create /fdl=sys$input 'sysmai'	!Create new VMSMAIL.DAT
IDENT	VMS MAIL Information data file

FILE
	ALLOCATION              10
	BEST_TRY_CONTIGUOUS     yes
	BUCKET_SIZE             2
	CONTIGUOUS              no
	EXTENSION               10
	GLOBAL_BUFFER_COUNT     0
	ORGANIZATION            indexed
	OWNER                   [001,004]
	PROTECTION              (system:RWE, owner:RWE, group:, world:)

RECORD
	BLOCK_SPAN              yes
	CARRIAGE_CONTROL        none
	FORMAT                  variable
	SIZE                    0

AREA 0
	ALLOCATION              10
	BEST_TRY_CONTIGUOUS     yes
	BUCKET_SIZE             2
	CONTIGUOUS              no
	EXTENSION               10

KEY 0
	CHANGES                 no
	DATA_KEY_COMPRESSION    yes
	DATA_RECORD_COMPRESSION yes
	DATA_AREA               0
	DATA_FILL               100
	DUPLICATES              no
	INDEX_AREA              0
	INDEX_COMPRESSION       yes
	INDEX_FILL              100
	LEVEL1_INDEX_AREA       0
	NULL_KEY                no
	PROLOGUE                3
	SEG0_LENGTH             31
	SEG0_POSITION           0
	TYPE                    string
$ open /share=read /read /write f1 'sysmai'
$file_open:
$ on control_y then goto done
$ !
$ ! Main loop.  Get command and username then dispatch
$ !
$do_command:
$ ask line "MAILUAF> "
$ line:='line
$ if line .eqs. "" then goto done
$ t1 = f$locate(" ",line)
$ command = f$extract(0,t1,line)
$ user = f$extract(t1+1,31,line)
$ if f$locate(command,"HELP") .eq. 0 then goto help_user
$ if f$locate(command,"EXIT") .eq. 0 then goto done
$ if f$locate(command,"LIST") .eq. 0 then goto list_users
$ if user .eqs. "" then goto syntaxerr
$ fulluser[0,31]:='user'
$ if f$locate(command,"ADD") .eq. 0 then goto add_user
$ if f$locate(command,"CANCEL") .eq. 0 then goto cancel_user
$ if f$locate(command,"MODIFY") .eq. 0 then goto modify_user
$ if f$locate(command,"REMOVE") .eq. 0 then goto remove_user
$ if f$locate(command,"SHOW") .eq. 0 then goto show_user
$help_user:
$ type sys$input:

 ADD username		Add a new user
 CANCEL username	Cancel forwarding for a user
 EXIT			Exit from MAIUAF
 HELP			Type this
 MODIFY username	Modify forwarding address for a user
 REMOVE username	Remove a user completely
 SHOW username		Show MAIL information about user
 LIST			List forwarding addresses for all users in VMSMAIL.DAT

$ goto do_command
$add_user:
$ read /index=0 /err=add_10 /key="''fulluser'" f1 record
$ write sys$output "User ",user," record already exists"
$ goto do_command
$add_10:
$ s1 = "''record'"
$ if f$length(s1) .ne. 0 then $ delete/symbol record
$ record[0,31]:='user'
$ record[248,288]=0
$ ask address "Forwarding address? "
$ t1 = f$length(address)
$ record[536,8]='t1'
$ record[68,'t1']:='address'
$ write f1 record
$ write sys$output "User ",user," added"
$ goto do_command
$cancel_user:
$ read /index=0 /err=nosuchuser/key="''fulluser'" f1 record
$ address = f$extract(68,255,record)
$ addr_length = f$cvui(67*8,8,record)
$ address := 'address'
$ naddress = f$extract(0,addr_length,address)
$ t2 = f$length(address)
$ t2 = 't2' - 'addr_length'
$ if addr_length .eq. 0 then goto show_10
$ write sys$output "User ",user,", forwarding address is ",naddress
$ ask yn "Cancel mail forwarding? "
$ if .not. yn then goto do_command
$ record[536,8]=0
$ record[68,255] := "''f$extract(68+addr_length,255-addr_length,record)'"
$ record = f$extract(0,68+'t2',record)
$ write /update f1 record
$ goto do_command
$list_users:
$ close f1
$ open /share=write /read /write f1 'sysmai'
$ write sys$output ""
$ write sys$output "Username                        Forwarding address"
$ write sys$output "--------                        ------------------"
$list_10:
$ read /end=do_command f1 record
$ user = f$extract(0,31,record)
$ addr_length = f$cvui(67*8,8,record)
$ address = f$extract(68,255,record)
$ address := 'address'
$ address = f$extract(0,addr_length,address)
$ write sys$output user,"	",address
$ goto list_10
$ goto do_command
$modify_user:
$ read /index=0 /err=nosuchuser /key="''fulluser'" f1 record
$ address = f$extract(68,255,record)
$ addr_length = f$cvui(67*8,8,record)
$ naddress = f$extract(0,addr_length,address)
$ t2 = f$length(address)
$ if addr_length .ne. 0 then goto xx1
$ write sys$output "User ",user," does not have forwarding enabled"
$ goto xx2
$xx1:
$ write sys$output "Current forwarding address is ",naddress
$xx2:
$ ask naddress "New forwarding address? "
$ if naddress .eqs. "" then goto do_command
$ address = f$extract(addr_length,t2-addr_length,address)
$ t1 = f$length(naddress)
$ record[536,8]='t1'
$ record[68,255]:="''naddress'''address'"
$ record = f$extract(0,68+t1+t2,record)
$ write /update f1 record
$ write sys$output "User ",user," modified"
$ goto do_command
$nosuchuser:
$ write sys$output "User ",user," record does not exist"
$ goto do_command
$remove_user:
$ read /index=0 /err=nosuchuser/key="''fulluser'" f1 record
$ address = f$extract(68,255,record)
$ addr_length = f$cvui(67*8,8,record)
$ address := 'address'
$ if addr_length .eq. 0 then goto xx0
$ address = f$extract(0,addr_length,address)
$ write sys$output "User ",user,", forwarding address is ",address
$ goto xx9
$xx0:
$ write sys$output "User ",user," does not have forwarding enabled"
$xx9:
$ ask yn "Remove? "
$ if .not. yn then goto do_command
$ read /index=0/key="''fulluser'" /delete f1 record
$ goto do_command
$show_user:
$ read /index=0 /err=nosuchuser /key="''fulluser'" f1 record
$ address = f$extract(68,255,record)
$ addr_length = f$cvui(67*8,8,record)
$ fnmlng=f$cvui(66*8,8,record)
$ dirlng=f$cvui(65*8,8,record)
$ address := 'address'
$ full_name := "''f$extract(68+addr_length,fnmlng,record)'"
$ dir_spec  =  f$extract(addr_length+fnmlng,dirlng,address)
$ if dirlng .eq. 0 then goto no_dir
$ write sys$output "User ",user,", MAIL subdirectory is ",dir_spec
$ goto test_full_name
$no_dir:
$ write sys$output "User ",user," did not specify a MAIL subdirectory"
$test_full_name:
$ if fnmlng .eq. 0 then goto no_pers_name
$ write sys$output "User ",user,", MAIL personal name is ",full_name
$ goto check_forward
$no_pers_name:
$ write sys$output "User ",user," does not have a MAIL personal name."
$check_forward:
$ if addr_length .eq. 0 then goto show_10
$ address = f$extract(0,addr_length,address)
$ write sys$output "User ",user,", forwarding address is ",address
$ goto do_command
$show_10:
$ write sys$output "User ",user," does not have forwarding enabled"
$ goto do_command
$syntaxerr:
$ write sys$output "Command syntax error"
$ goto do_command
$done:
$ close f1
$ prev_priv = f$setprv(prev_priv)
$ exit
