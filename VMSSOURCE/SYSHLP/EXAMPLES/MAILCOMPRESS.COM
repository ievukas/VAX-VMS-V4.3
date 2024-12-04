$ !++
$ !
$ !  MAILCOMPRESS.COM - Compress mail file by username
$ !
$ !
$ !  ABSTRACT:	Sample command procedure to compress
$ !		MAIL ISAM files for a single user
$ !		or list of users.
$ !
$ !
$ !
$ !  REQUIRED PRIVILEGES:
$ !		BYPASS, EXQUOTA or SETPRV
$ !
$ !
$ !
$ !  INPUT:	Input can be specified in two forms:
$ !
$ !	   o	Username whose default MAIL ISAM 
$ !		file is to be compressed.
$ !
$ !	   o	@FILENAME where FILENAME is the
$ !		file-spec of a file which contains
$ !		a list of usernames whose default
$ !		MAIL ISAM files are to be compressed.
$ !
$ !		Either form of input may be specified
$ !		on the command line.  However, if
$ !		"@FILENAME" is specified on the command
$ !		line it MUST be enclosed in double
$ !		quotes.
$ !
$ !
$ !  OUTPUT:	New default MAIL ISAM file of a smaller
$ !		size.
$ !
$ !
$ !  IMPLICIT OUTPUT:
$ !		Old default MAIL ISAM file is deleted.
$ !
$ !
$ !--
$
$
$	set	= "SET"
$	if	= "IF"
$	open	= "OPEN"
$	goto	= "GOTO"
$	read	= "READ"
$	write	= "WRITE"
$	convert	= "CONVERT"
$	delete	= "DELETE"
$	close	= "CLOSE"
$	exit	= "EXIT"
$	no_compression_needed_size = 40
$	time_stamp = f$cvtime("","COMPARISON","DATETIME")
$	old_verify = f$verify()
$	set noon
$	required_privileges = "BYPASS,EXQUOTA"
$	prev_privs = f$setprv(required_privileges)
$	if .not. f$privilege(required_privileges) then goto no_privileges
$	def_dev_dir = f$environment("DEFAULT")
$	open /read /share uaf  sys$system:sysuaf.dat
$	open /read /share vmai sys$system:vmsmail.dat
$	cmd_file = 0
$	param_flag = 0
$	if f$length(p1) .eq. 0  then  goto get_username
$	username = p1
$	param_flag = 1
$	goto 10$
$ !
$ !  Prompt for username
$ !
$ get_username:
$	open_delimit = "["
$	close_delimit = "]"
$	dir_close_delimit = "]"
$	if cmd_file  then  goto 20$
$	if param_flag  then  goto exit_procedure
$	read /end=exit_procedure /prompt="Username: " sys$command  username
$ 10$:
$	username = f$edit(username,"COLLAPSE,UNCOMMENT,UPCASE")
$	if f$length(username) .eq. 0  then  goto get_username
$	if f$extract(0,1,username) .nes. "@" then goto 100$
$	cmd_file = 1
$	username = f$extract(1,99,username)
$	open /read /error=cant_open  cmdf  'username'
$ 20$:
$	read /end=cmd_file_eof /prompt="USERNAME> "  cmdf  username
$	username = f$edit(username,"COLLAPSE,UNCOMMENT,UPCASE")
$	if f$length(username) .eq. 0  then  goto 10$
$ !
$ !  Get mail directory for USERNAME
$ !
$ 100$:
$	read /nolock /error=no_user /key="''username'"  uaf  uaf_record 
$	dir_len = f$cvui(32*8,8,uaf_record)
$	dir_string = f$extract(149,dir_len,uaf_record)
$	temp_string = f$edit(dir_string,"COLLAPSE")
$	if temp_string .eqs. "" then goto bad_spec
$	if f$locate("[",dir_string) .ne. dir_len then goto okay_delimit
$	dir_close_delimit = ">"
$okay_delimit:
$	dir_string = dir_string - dir_close_delimit
$	dev_len = f$cvui(64*8,8,uaf_record)
$	dev_string = f$extract(117,dev_len-1,uaf_record)
$	temp_string = f$edit(dev_string,"COLLAPSE")
$	if temp_string .eqs. "" then goto bad_spec
$	vmai_record = ""
$	mail = ""
$	read /nolock /error=110$ /key="''username'"  vmai  vmai_record
$ 110$:
$	if f$length(vmai_record) .eq. 0  then  goto 120$
$	mail_len = f$cvui(65*8,8,vmai_record)
$	personal_len = f$cvui(66*8,8,vmai_record)
$	forward_len = f$cvui(67*8,8,vmai_record)
$	mail = f$extract(68+personal_len+forward_len,mail_len,vmai_record)
$	if f$locate("[",mail) .ne. mail_len then goto 120$
$	open_delimit = "<"
$	close_delimit =">"
$ 120$:
$	temp = ""
$	if mail .nes. ""  then temp =mail- open_delimit - close_delimit
$	mail_dir = dev_string + dir_string + temp + dir_close_delimit
$	mail_dir = f$edit(mail_dir,"COLLAPSE")
$	write sys$output ""
$	write sys$output "Processing directory ''mail_dir' for user ''username'"
$ !
$ !  Compress mail file
$ !
$	set default 'mail_dir'
$	if f$search("MAIL.MAI") .eqs. ""  then  goto no_mail_file
$	create_time = f$file_attributes("MAIL.MAI","CDT")
$	create_time = f$cvtime(create_time,"COMPARISON","DATETIME")
$	if create_time .gts. time_stamp then goto already_compressed
$	! VERIFY THERE'S A MAIL.MAI FILE, THAT IT'S INDEXED WITH 2 KEYS.
$	! CHECK TO SEE THAT DISK HAS ENOUGH SPACE FOR THE COMPRESS.
$	!
$	!
$	if (f$file_attributes("MAIL.MAI","ORG") .nes. "IDX")  .or.  -
	   (f$file_attributes("MAIL.MAI","NOK") .ne. 2)  -
	then  goto not_mail_file
$	old_size = f$file_attributes("MAIL.MAI", "ALQ")
$	!
$	! VERIFY THAT MAIL.MAI IS LARGE ENOUGH TO WARRANT
$	! COMPRESSION.
$	if old_size .lt. no_compression_needed_size then $goto too_small
$	free_blks = f$getdvi("SYS$DISK","FREEBLOCKS")
$	if free_blks .lt. old_size * 3  then  goto  no_space
$	! COMPRESS THE FILE, STOP IF ERROR.
$	! DISPLAY OLD/NEW/RECLAIMED SIZES, DELETE OLD FILE, ENSURE CORRECT
$	! FILE OWNERSHIP.
$	!
$	!
$	convert /fdl=sys$input  mail.mai mail.mai
SYSTEM
	SOURCE                  VAX/VMS

FILE
	ALLOCATION              34
	BEST_TRY_CONTIGUOUS     yes
	BUCKET_SIZE             5
	CONTIGUOUS              no
	EXTENSION               15
	GLOBAL_BUFFER_COUNT     0
	ORGANIZATION            indexed
	PROTECTION              (system:RW, owner:RW, group:, world:)

RECORD
	BLOCK_SPAN              yes
	CARRIAGE_CONTROL        none
	FORMAT                  variable
	SIZE                    2048

AREA 0
	ALLOCATION              20
	BUCKET_SIZE             5
	EXTENSION               15

AREA 1
	ALLOCATION              6
	BUCKET_SIZE             5
	EXTENSION               5

AREA 2
	ALLOCATION              8
	BUCKET_SIZE             3
	EXTENSION               3

KEY 0
	CHANGES                 no
	DATA_KEY_COMPRESSION    no
	DATA_RECORD_COMPRESSION yes
	DATA_AREA               0
	DATA_FILL               100
	DUPLICATES              yes
	INDEX_AREA              1
	INDEX_COMPRESSION       no
	INDEX_FILL              100
	LEVEL1_INDEX_AREA       1
	NAME                    ""
	NULL_KEY                no
	PROLOG                  3
	SEG0_LENGTH             8
	SEG0_POSITION           0
	TYPE                    bin8

KEY 1
	CHANGES                 yes
	DATA_KEY_COMPRESSION    yes
	DATA_AREA               2
	DATA_FILL               100
	DUPLICATES              yes
	INDEX_AREA              2
	INDEX_COMPRESSION       yes
	INDEX_FILL              100
	LEVEL1_INDEX_AREA       2
	NAME                    ""
	NULL_KEY                yes
	NULL_VALUE              0
	SEG0_LENGTH             39
	SEG0_POSITION           9
	TYPE                    string

$	if $status .ne. 1  then  goto  convert_error
$	new_size = f$file_attributes("MAIL.MAI;0", "ALQ")
$	tmp = old_size - new_size
$	write sys$output "Old size = ''old_size'  New size = ''new_size'", -
		" reclaimed ''tmp' blocks"
$	delete MAIL.MAI;-1
$	set file/owner=parent MAIL.MAI
$ end_loop:
$	goto get_username
$ !
$ !  Exit command procedure
$ !
$ exit_procedure:
$	close /nolog uaf
$	close /nolog vmai
$	close /nolog cmdf
$	set default 'def_dev_dir'
$	prev_privs = f$setprv(prev_privs)
$	old_verify = f$verify(old_verify)
$	exit
$ !
$ !  Process errors
$ !
$ no_privileges:
$	write sys$output "Insufficient privileges"
$	write sys$output "Requires ",REQUIRED_PRIVILEGES," privileges."
$	goto exit_procedure
$ no_mail_file:
$	write sys$output "No mail file for user ''username'"
$	goto get_username
$ not_mail_file:
$	write sys$output "File ''mail_dir'MAIL.MAI is not a mail file"
$	goto get_username
$ convert_error:
$	write sys$output "Error compressing ''mail_dir'MAIL.MAI ", -
		"for user ''username'"
$	goto get_username
$ cmd_file_eof:
$	cmd_file = 0
$	close cmdf
$	goto get_username
$ no_user:
$	write sys$output "User ''username' not found in UAF"
$	goto get_username
$bad_spec:
$	write sys$output "Bad directory specification for user ''username'"
$	goto get_username
$ no_space:
$	write sys$output "No space to compress file of ''old_size' blocks"
$	goto get_username
$ cant_open:
$	write sys$output "Can not open file ''username'."
$	cmd_file = 0
$	goto get_username
$already_compressed:
$	write sys$output "MAIL.MAI already compressed"
$	goto get_username
$ too_small:
$	write sys$output "MAIL.MAI too small to compress (''old_size' blocks)."
$	goto get_username
$ exit
