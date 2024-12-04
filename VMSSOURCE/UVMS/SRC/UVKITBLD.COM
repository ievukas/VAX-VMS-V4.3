$	on control_y then goto bad_kit
$	on warning then goto bad_kit
$	ask := inquire/nopunctuation
$	say := write sys$output
$	remount = 0
$	say "''f$fao("!/!/!_VMS Software Product Kit Build Procedure!/")"
$
$	p = "CMKRNL,LOG_IO,SYSNAM,VOLPRO"
$	saved_privs = f$setprv(p)
$	if .not. f$priv(p) then say "You need the following privileges: ",p
$	if .not. f$priv(p) then goto bad_kit
$
$	if p4 .nes. "" then open inpfile 'p4
$	if p1 .nes. "" then goto m5
$	type sys$input:
Kits have names in the format facvvu, where fac is the facility name,
vv is the major version number, and u is the update number.
$	ask p1 "Which kit would you like to build: "
$m5:	facility = f$ext(0,f$len(p1)-3,p1)
$	version = 'f$ext(f$len(p1)-3,2,p1)
$	update = 'f$ext(f$len(p1)-1,1,p1)
$
$	dest = p2
$	if dest .eqs. "" then ask dest "On which device is the kit to be built: "
$	if f$loc(":",dest) .eq. f$len(dest) then dest = dest + ":"
$	dest = f$parse(dest,,,"DEVICE") + f$parse(dest,"[0,0]",,"DIRECTORY")
$	if f$loc("CSA",dest) .ne. f$len(dest) then goto m7
$	if f$getdvi(dest,"EXISTS") then -
		if f$getdvi(dest,"DEVCLASS") .eq. 1 .or. -
		   f$getdvi(dest,"DEVCLASS") .eq. 2 then goto m7
$	say "Device must be a disk or tape."
$	goto bad_kit
$m7:	device = f$parse(dest,,,"DEVICE")
$
$	remount = f$loc("CSA",device) .ne. f$len(device)
$	if .not. remount then goto m9
$	s := $sysgen
$	s connect console
$	if f$getdvi(device,"MNT") then dismount 'device
$	allocate 'device
$m9:
$
$	if f$getdvi(device,"DEVCLASS") .eq. 1 .and. -
	   f$getdvi(device,"MNT") .and. -
	   .not. f$getdvi(device,"FOR") then goto m15
$	if f$getdvi(device,"MNT") then dismount/nounload 'device
$	say "Please ready the first distribution volume on ''device."
$m10:		ask w "Are you ready? "
$		if .not. w then goto m10
$	mount/foreign/noassist 'device
$	remount = 1
$	
$m15:	if f$getdvi(device,"DEVCLASS") .eq. 2 then goto m_TAPE
$	if f$getdvi(device,"MAXBLOCK") .gt. 8*512 then goto m_DISK
$
$m_CONSOLE:
$	backup_quals := /init/block=9000/group=25
$	labels = "''facility'01,''facility'02,''facility'03,''facility'04,''facility'05,"
$	labels = labels + "''facility'06,''facility'07,''facility'08,''facility'09,''facility'10"
$	goto m19
$m_DISK:
$	backup_quals := /block=9000/group=25
$	labels = facility
$	goto m19
$m_TAPE:
$	backup_quals := /rewi/dens=1600
$	ask w "Are there already savesets on this tape? "
$	if w then backup_quals := /norewi/dens=1600
$	labels = facility
$	goto m19
$m19:
$
$	say "Saveset A must contain the KITINSTAL.COM procedure."
$	letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
$
$s10:	say "''f$fao("!/!_!AS V!UL.!UL, Saveset !AS!/",facility,version,update,f$ext(0,1,letters))"
$	f = p3
$	if p3 .eqs. "" then ask f "Which files: "
$	prot := (s:rwed,o:rwed,g:rwed,w:re)
$	write sys$output "Reseting protection on all files to ",prot,"..."
$	set protection='prot 'f
$s12:	backup/comment="VAX/VMS SPKITBLD Procedure"/inter/log/verify -
		'f -
		'dest''p1.'f$ext(0,1,letters)/label=('labels)/save'backup_quals
$!	if p2 .nes. "" then goto s19
$	if p4 .eqs. "" then goto s14
$	read/end_of_file=S19 inpfile p3
$ 	goto s15
$s14:
$	ask w "Is there another saveset to create [NO]? "
$	if .not. w then goto s19
$
$	p3 = ""
$s15:
$	letters = f$ext(1,999,letters)
$	backup_quals := 'backup_quals/noinit/norewi
$	if f$getdvi(device,"DEVCLASS") .eq. 2 .or. -
	   f$getdvi(device,"MAXBLOCK") .gt. 8*512 then goto s10
$	if p4 .nes. "" then goto s10
$	ask w "Does it need to start on a new volume [NO]? "
$	if .not. w then goto s10
$	dismount/nounload 'device
$	mount/foreign/noassist/nomessage 'device
$	i = f$loc(f$getdvi(device,"VOLNAM"),labels)
$	labels = f$ext(i+f$len(facility)+3,999,labels)
$	backup_quals := 'backup_quals/init
$	dismount 'device
$	say "Please mount the next distribution volume on ''device."
$s15:		ask w "Are you ready? "
$		if .not. w then goto s15
$	mount/foreign/noassist 'device
$	goto s10
$s19:
$
$	close inpfile
$	say "''f$fao("!/!_Kit Build Completed Successfully!/!/")"
$
$done:
$	on warning then exit
$	if .not. remount then goto d9
$	if f$getdvi(device,"MNT") then dismount/nounload 'device
$	if f$loc("CSA",device) .eq. f$len(device) then goto d9
$	say "Please remount the console volume."
$d5:		ask w "Are you ready? "
$		if .not. w then goto d5
$	mount/foreign/system/protection=s:rwlp/nowrite/noassist 'device console
$d9:	w = f$setpriv(saved_privs)
$	exit
$
$bad_kit:
$	type sys$input:

	+---------------------+
	|		      |
	|  THIS IS A BAD KIT  |
	|		      |
	+---------------------+

$	goto done

$!++
$! Facility:	SPKITBLD, Procedure to Build a VMS Software Product Kit
$!
$! Abstract:	This procedure is used to build an installation kit
$!		for a VAX/VMS software product.  It is intended to
$!		build kits which are installed by the "new" VMSINSTAL.
$!
$! Environment:	The document "Developer's Guide to the VAX/VMS VMSINSTAL
$!		Procedure" describes this procedure in detail.
$!
$! Parameters:	P1 - product to be built
$!  (all	P2 - device on which to build kit
$!  optional)	P3 - files to place in first saveset
$!
$! Author:	Paul C. Anagnostopoulos, Creation Date: 30 June 1982
$!		STAR::Greek
$!--
