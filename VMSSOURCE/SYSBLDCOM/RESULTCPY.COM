$ !	[SYSBLDCOM]RESULTCPY.COM
$ !
$ ! This command file copies the relevant result areas of the output of a
$ ! system build to another disk for use in private development. The
$ ! contents of [SYSOBJ] are copied, along with the command files to
$ ! build those components that link with the exec.
$ !
$ !	P1 = device name of result disk to copy
$ !	P2 = device name of target disk
$ !
$ pcopy = "copy /prot=(owner=rwed)"
$10:
$ if p1 .nes. "" then goto 20
$ inquire p1 "What is the device name of the result disk? [ddcu:]"
$20:
$ if p2 .nes. "" then goto 30
$ inquire p2 "What is the device name of the target disk? [ddcu:]"
$ goto 20
$30:
$ if f$mode() .eqs. "BATCH" then define sys$print nowhere
$ set noon
$ p1 = p1 - ":" + ":"
$ p2 = p2 - ":" + ":"
$ !
$ !	Copy over the new [SYSOBJ]
$ !
$ prev_priv = f$setprv("BYPASS")
$ delete 'P2'[sysobj]*.obj;*,*.olb;*,*.stb;*,*.exe;*
$ delete 'P2'[sysobj]vmsnewbld.dat;*,trialsys.com;*,trialkit.com;*
$ prev_priv = f$setprv(prev_priv)
$ pcopy 'p1'[sysobj]*.* 'P2'[sysobj]
$ pcopy 'p1'[syslib]rsxshr.exe 'P2'[sysobj]
$ pcopy 'P1'[sysbldcom]vmsnewbld.dat,trialsys.com,trialkit.com 'P2'[sysobj]
$ !
$ !	Open the facility data file and find the components that link
$ !	with the exec. For each one, create the [component.COM] directory
$ !	if it doesn't already exist and copy in the command files.
$ !
$ open /read data 'P2'[sysobj]vmsnewbld.dat  ! open facility data file
$ !
$ ! get next facility name from data file and determine if it
$ ! needs to be re-built with the exec (/EX qualifier).
$ !
$ read /index=1 /key="AAINFO " /err=exit data cmd
$ goto nxt_10
$nxtcmd:
$ read data cmd /end = exit
$nxt_10:
$ s1 = f$ext(16,16,cmd)
$ if f$ext(0,f$loc(" ",s1),s1) .nes. "AAINFO" then goto exit
$ if f$locate("/EX",cmd) .eq. f$length(cmd) then goto nxtcmd
$ facnam = f$extract(0,f$loc(" ",cmd),cmd)
$ !
$ !	Create the directory if necessary
$ !
$ if f$search("''p2'[sysobj.''facnam']com.dir;1") .nes. "" then goto nxt_40
$ create/directory 'P2'[sysobj.'facnam'.com]
$ goto nxt_50
$nxt_40:
$ delete 'P2'[sysobj.'facnam'.com]*.*;*
$nxt_50:
$ pcopy masd$:['facnam'.com]*.* 'P2'[sysobj.'facnam'.com]
$ goto nxtcmd
$exit:
$ close data
$ exit
