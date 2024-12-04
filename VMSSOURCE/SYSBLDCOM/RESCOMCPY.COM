$ !	[SYSBLDCOM]RESCOMCPY.COM
$ !
$ ! This command file copies to the result disk the command files to
$ ! build those components that link with the exec. The files are
$ ! placed in directories with the name [SYSOBJ.facility.COM].
$ !
$ !	P1 = device name of result disk
$ !	P2 = device name of the master disk (default = MASD$:)
$ !
$ pcopy = "copy /prot=(s=rw,o=rwed,g=r,w=r)"
$10:
$ if p1 .nes. "" then goto 20
$ inquire p1 "What is the device name of the result disk? [ddcu:]"
$ goto 10
$20:
$ if p2 .eqs. "" then p2 = "MASD$:"
$ if f$mode() .eqs. "BATCH" then define sys$print nowhere
$ set noon
$ p1 = p1 - ":" + ":"
$ p2 = p2 - ":" + ":"
$ !
$ !	Copy the full build database file onto the result disk.  The one
$ !	already there may have been modified to do a partial build.
$ !
$ pcopy 'p2'[sysbldcom]vmsnewbld.dat 'p1'[sysbldcom]  ! this file must be current
$ !
$ !	Copy into [SYSOBJ] some files already on RESD$ but which were
$ !	found in [SYSOBJ] on the system device. They may be expected
$ !	to be here by some command files.
$ !
$ pcopy 'P1'[sysbldcom]vmsnewbld.dat,trialsys.com,trialkit.com 'P1'[sysobj]
$ !
$ !	Open the facility data file and find the components that link
$ !	with the exec. For each one, create the [component.COM] directory
$ !	if it doesn't already exist and copy in the command files.
$ !
$ open /read data 'P2'[sysbldcom]vmsnewbld.dat  ! open facility data file
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
$ newdir = "False"
$ if f$search("''p1'[sysobj.''facnam']com.dir;1") .nes. "" then goto nxt_40
$ create/directory 'P1'[sysobj.'facnam'.com]
$ newdir = "True"
$nxt_40:
$ pcopy 'p2'['facnam'.com]*.* 'P1'[sysobj.'facnam'.com]
$ !
$ !	Purge back the directory AFTER we do the copy.  This is done, rather
$ !	than deleting it beforehand, so that TRIALSYS jobs can be running
$ !	while this is updating the procedures.
$ !
$ if .not. newdir then purge 'p1'[sysobj.'facnam'.com]*.*
$ goto nxtcmd
$
$exit:
$ close data
$ exit
