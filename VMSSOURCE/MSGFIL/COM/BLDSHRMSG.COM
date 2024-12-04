$ !
$ !	[ M S G F I L . C O M ] B L D S H R M S G . C O M
$ !
$ !	This procedure is used to build the Shared Message Images.
$ !
$ !	First, clean up the EXE$ and MAP$ directories, next the message
$ !	objects are 'moved' from the system message directory [SYSMSG]
$ !	to the OBJ$ directory, then the images are linked according to
$ !	the object modules named in the link commands.
$ !
$
$ on error then continue
$
$ delete exe$:cliutlmsg.exe;*,dbgtbkmsg.exe;*,filmntmsg.exe;*,netwrkmsg.exe;*,-
	 prgdevmsg.exe;*,shrimgmsg.exe;*,sysmgtmsg.exe;*
$
$ delete map$:cliutlmsg.map;*,dbgtbkmsg.map;*,filmntmsg.map;*,netwrkmsg.map;*,-
	 prgdevmsg.map;*,shrimgmsg.map;*,sysmgtmsg.map;*
$
$ copy resd$:[sysmsg]*.obb obj$:*.obj
$
$ !
$ ! CLI Utilities Messages
$ !
$
$ link/shareable=exe$:cliutlmsg/map=map$:cliutlmsg/full -
!**JNL**	obj$:auditmsg,-
	obj$:badmsg,excmsg,mailmsg,phonemsgs,quemanmsg,-
	renamemsg,runmsg,set,showmsg,smbmsg,submitmsg,searchmsg
$
$ !
$ ! Debug and Traceback Messages
$ !
$
$ link/shareable=exe$:dbgtbkmsg/map=map$:debtbkmsg/full -
	obj$:dbgmsg,tracemsg
$
$ !
$ ! File Creation/Maintenance Messages
$ !
$
$ link/shareable=exe$:filmntmsg/map=map$:filmntmsg/full -
	obj$:objexemsg,rmsmsg,edfmsg,verifymsg
$
$ !
$ ! Network Messages
$ !
$
$ link/shareable=exe$:netwrkmsg/map=map$:netwrkmsg/full -
	obj$:errmsg,ncperrmsg,rtmsg
$
$ !
$ ! Program Development Messages
$ !
$
$ link/shareable=exe$:prgdevmsg/map=map$:prgdevmsg/full -
	obj$:cdumsgs,difmsg,dumpmsg,librarmsg,-
	linkmsg,macmsg,msgfilmsg,patmsg,sdamsg
$
$ !
$ ! Shareable Image Messages
$ !
$
$ link/shareable=exe$:shrimgmsg/map=map$:shrimgmsg/full -
	obj$:convmsg,dcxmsg,vmsmsg,fdlmsg,sormsg,smgmsg
$
$ !
$ ! System Management Messages
$ !
$
$ link/shareable=exe$:sysmgtmsg/map=map$:sysmgtmsg/full -
	obj$:accmsg,aedmessag,backupmsg,insmsg,monmsg,uafmsg
