$ inquire input "Device to restore files to (SYS$SYSDEVICE:)"
$ if input.eqs."" then input:=sys$sysdevice:
$ input= input-":" + ":"
$ inquire media "Drive containing Backup media (ddcu:)"
$ if f$locate("::",media).ne.f$len(media) then goto dosysave
$ media=media-":"+":"
$ all 'media
$ retry1:
$ if p1.nes."" then goto checkquota
$ write sys$output "Mount system specific save media on drive ''media'"
$ inquire ask "* Are you ready"
$ if .not. ask then goto retry1
$ init 'media sysave
$ mount/forei 'media
$dosysave:
$ if p1.nes."" then goto checkquota
$ on error then continue
$ create/dir sys$sysroot:[sysexe.old]
$ backup/verify 'media'sysexe.sav/save sys$sysroot:[sysexe.old]*.*;*/owner=[1,4]
$ on error then continue
$ create/dir sys$sysroot:[sysmgr.old]
$ backup/verify 'media'sysmgr.sav/save sys$sysroot:[sysmgr.old]*.*;*/owner=[1,4]
$ if f$locate("::",media).ne.f$len(media) then goto next_uic
$ dism 'media
$checkquota:
$next_uic:
$ inquire ask "Are there any user save sets"
$ if .not. ask then goto endit
$ inquire uic "Uic for the saveset ([nnn,nnn])"
$ uicnam=uic-"["-"]"
$ comma=f$locate(",",uicnam)
$ uicnam=f$extract(0,comma,uicnam)+"_"+f$extract(comma+1,f$length(uicnam),uicnam)
$ if f$locate("::",media).ne.f$len(media) then goto dobackup
$retry:
$ WRITE SYS$OUTPUT "Please place first diskette for user ''uic' in drive ''media'"
$ inquire ask "* Are you ready"
$ if .not. ask then goto retry
$ mount/forei 'media
$dobackup:
$ set noon
$ backup/verify 'media''uicnam'.sav/save 'input'[*...]*.*;*/owner=['uic']
$ set on
$ if f$locate("::",media).ne.f$len(media) then goto next_uic
$ dism 'media
$goto next_uic
$endit:
$no_dismount:
$ write sys$output "	****** User Restore complete ******"
$exit
