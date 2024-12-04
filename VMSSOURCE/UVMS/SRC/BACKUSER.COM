$ CREATE_QUOTA=""
$ if f$search("sys$system:diskquota.exe").eqs."" then goto nodiskquota
$ inquire input "Media to be backed up (SYS$SYSDEVICE:)"
$ if input.eqs."" then input:=sys$sysdevice:
$ input= input-":" + ":"
$ inquire media "Scratch Backup media (ddcu:)"
$ if f$locate("::",media).ne.f$len(media) then goto dosysave
$ media=media-":"+":"
$ all 'media
$ retry1:
$ if p1.nes."" then goto checkquota
$ write sys$output "Mount media for system specific file save on ''media'"
$ inquire ask "* Are you ready"
$ if .not. ask then goto retry1
$ init 'media sysave
$ mount/forei 'media
$dosysave:
$ if p1.nes."" then goto checkquota
$ on error then continue
$ backup/verify sys$system:sysuaf.dat,rightslist.dat,vaxvmssys.par,net*.dat,-
      		notice.txt,modparams.dat,vmsmail.dat -
		'media'sysexe.sav/save/ignore=interlock
$ on error then continue
$ backup/verify sys$manager:*.*;* 'media'sysmgr.sav/save/ignore=interlock
$ if f$locate("::",media).ne.f$len(media) then goto checkquota
$ dism 'media
$checkquota:
$ savver=f$verify(0)
$ SET DEF 'INPUT
$ def/user sys$output sys$update:disq.tmp
$ def/user sys$error nl:
$ mc diskquota
rebuild
sho [*,*]
$ x=f$verify(savver)
$ define/user sys$error nl:
$ define/user sys$output nl:
$ search sys$update:disq.tmp %disk
$ if $status .ne. %X08D78053 then goto create_diskq
$read_file:
$ open/read diskq sys$update:disq.tmp
$ read diskq line
$ read diskq line
$next_uic:
$ read/end=done diskq line
$ uic=F$EDIT(f$extract(0,15,line),"TRIM")
$ uicnam=uic-"["-"]"
$ comma=f$locate(",",uicnam)
$ uicgroup=f$extract(0,comma,uicnam)
$ if uicgroup.eq.1 then goto next_uic
$ uicnam=f$extract(0,comma,uicnam)+"_"+f$extract(comma+1,f$length(uicnam),uicnam)
$ qual=""
$ if f$locate("::",media).ne.f$len(media) then goto dobackup
$retry:
$ WRITE SYS$OUTPUT "Please place first diskette for user ''uic' in drive ''media'"
$ inquire ask "* Are you ready"
$ if .not. ask then goto retry
$ qual="/initialize"
$ init 'media 'uicnam
$ mount/forei 'media
$dobackup:
$ set noon
$ backup/ignore=interlock/verify 'input'[*...]*.*;*/owner='uic 'media''uicnam'.sav/save'qual
$ set on
$ if f$locate("::",media).ne.f$len(media) then goto next_uic
$ dism 'media
$goto next_uic
$done:
$ close/nolog diskq
$ del sys$update:disq.tmp;*
$ write sys$output "		****** user backup is now compete *****
$ if create_quota.nes."" then goto del_quota
$ exit
$create_diskq:
$ IF CREATE_QUOTA.NES."" THEN GOTO BAD_QUOTA
$ create_quota:=y
$ del sys$update:disq.tmp;*
$def/user sys$output nl:
$def/user sys$error nl:
$ mc diskquota
create
$ GOTO checkquota
$bad_quota:
$ write sys$output "bad quotafile"
$goto done
$del_quota:
$ mc diskquota
disable
$ del 'input'[0,0]quota.sys;
$exit
$nodiskquota:
$ write sys$output "The DISKQUOTA utility must be installed on your system"
$ write sys$output "in order for the save to take place.  Please install
$ write sys$Output "this utility and re-run this procedure."
$exit
