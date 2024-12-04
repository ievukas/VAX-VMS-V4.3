$ WRITE SYS$OUTPUT ""
$ WRITE SYS$OUTPUT "The MicroVMS system is now executing the site-specific startup commands."
$ WRITE SYS$OUTPUT ""
$
$! This is a template command procedure.  You may change anything as
$! you see fit for your system.  If you want to change definitions of
$! symbols defined in other startup procedures, you should do so by
$! redefining the symbols in this procedure--not by changing the other
$! procedures that will be re-distributed with each release of MicroVMS.
$
$! Normally, the error logger and the operator communication processes
$! are not created on a MicroVMS system, to minimize physical memory and
$! disk block usage.  Remove the comment delimiters from the following
$! lines if you wish to create these processes.
$!
$! If you start the OPCOM process, you should remove the definition
$! in SYS$MANAGER:SYLOGIN.COM that equates MOUNT to MOUNT/NOASSIST if
$! you want operators to be able to satisfy user mount requests.
$!@SYS$SYSTEM:STARTUP ERRFMT
$!@SYS$SYSTEM:STARTUP OPCOM
$
$! Turn off account logging and delete the log.  Remove these lines if
$! you want to keep an account log on your system.
$ SET ACCOUNTING/DISABLE
$ IF F$SEARCH("SYS$MANAGER:ACCOUNTNG.DAT") .NES. "" THEN -
    DELETE SYS$MANAGER:ACCOUNTNG.DAT;*
$
$! Purge any operator and network logs back to two versions.
$ IF F$SEARCH("SYS$MANAGER:OPERATOR.LOG") .NES. "" THEN -
    PURGE SYS$MANAGER:OPERATOR.LOG
$ IF F$SEARCH("SYS$MANAGER:EVL.LOG") .NES. "" THEN -
    PURGE SYS$MANAGER:EVL.LOG
$
$! Define system-wide login command procedure invoked for all users.
$ DEFINE /SYSTEM /EXEC SYS$SYLOGIN SYS$MANAGER:SYLOGIN.COM
$
$! Define system announcement message before each user logs in.
$ DEFINE /SYSTEM SYS$ANNOUNCE "	Welcome to MicroVMS V4.0"
$
$! Define system announcement message after each user logs in.
$ DEFINE /SYSTEM SYS$WELCOME "@SYS$MANAGER:WELCOME.TXT" 
$
$! Remove the comment delimiter in the next command, to start the
$! queue manager, if you are going to have either print or batch queues.
$! START/QUEUE/MANAGER/BUFFER_COUNT=10/EXTEND_QUANTITY=25
$
$! Set up print queue -- commented out below.
$! Remove comment delimiters if you have installed queues from the
$! Secure User Environment Option and want a print queue set up.
$
$! Your print device can be either a line printer or a hard-copy terminal.
$! There are different commands depending upon what you use for a print device.
$
$! First define $PRINTER to name the device you will use for printing.
$! DEFINE /SYSTEM $PRINTER  $TERMINAL0	! if terminal
$! DEFINE /SYSTEM $PRINTER  _LPA0:	! if line printer
$
$! Set the printer characteristics if you will be printing on a line printer.
$! SET PRINTER /NOWRAP /NOTRUNCATE /CR $PRINTER
$
$! Set the terminal characteristics if a you will be printing on a terminal.
$! Some terminal characteristics vary, depending upon the type of terminal
$! being used.  These include:  speed, width, length, and device_type.
$! SET TERMINAL $PRINTER /PERMANENT /NOBROADCAST /NOTYPEAHEAD /NOWRAP -
$!	/SPEED=(1200) /WIDTH=(132) /LENGTH=(66) /DEVICE_TYPE=(LA100)
$
$! Set your printing device spooled to the queue SYS$PRINT.
$! SET DEVICE /SPOOLED=(SYS$PRINT, SYS$SYSDEVICE:) $PRINTER
$
$! Start the queue manager and the print queue.  You may want to specify
$! a flag page if you have a line printer for a printing device.
$! INITIALIZE /QUEUE /START /ON=$PRINTER SYS$PRINT	! if terminal
$! INITIALIZE /QUEUE /START /ON=$PRINTER SYS$PRINT /DEFAULT=FLAG ! if line printer
$
$! Set up batch queue -- commented out initially.
$! Remove comment delimiters if you have installed queues from the
$! Secure User Environment Option and want a batch queue set up.
$! INITIALIZE /QUEUE /START SYS$BATCH /BATCH /JOB:3 /BASE_PRIORITY=3
$
$! If you install some of these optional utilities onto your system, 
$! then you should remove the comment delimiter from the RUN command, and the
$! "$!" from the appropriate utilities and install them as specified below.
$! You might want to add the "/shared" qualifier, if you have multiple
$! users on your system.  (Utilities that are installed shared, have the 
$! characteristic that if two users are running the same utility at the 
$! same time, then they share the same pages in memory, rather than each 
$! having a private copy.)
$! RUN SYS$SYSTEM:INSTALL
$!sys$system:analimdmp		/priv=(cmexec,cmkrnl)
$!sys$system:mail		/open/header/priv=(sysprv,oper,world,netmbx)
$!sys$system:monitor		/priv=(cmkrnl)
$!sys$system:phone		/priv=(netmbx,oper,prmmbx,world,sysnam)
$!sys$system:request		/priv=(tmpmbx)
$!sys$system:rtpad		/priv=(tmpmbx)
$!sys$system:submit		/open/header/priv=(tmpmbx)
$
$! If your system has multiple users and you have more than 1MB of memory,
$! you might want to install some or all of the following utilities as shared.
$! Installing an utility "/open/header" requires two pages of memory and
$! causes one less disk access when you run that utility.  Installing an
$! utility "/shared" requires global sections and global page table space.
$! If you install many things "/shared", you may need to increase some
$! system parameters in SYS$MANAGER:MODPARAMS.DAT, namely, GBLSECTIONS
$! and GBLPAGES.
$! RUN SYS$SYSTEM:INSTALL
$!sys$system:copy		/open/header/shared
$!sys$system:delete		/open/header/shared
$!sys$system:edt		/open/header/shared
$!sys$system:rename		/open/header/shared
$!sys$system:search		/open/header/shared
$!sys$system:type		/open/header/shared
$!sys$system:vmshelp		/open/header/shared
$
$! You might want to re-install some of the utilities installed by the MicroVMS
$! boot procedures as shared.  Rather than change SYS$MANAGER:VMSIMAGES.DAT,
$! you should re-install them here, as in the following example:
$! RUN SYS$SYSTEM:INSTALL
$!sys$library:librtl		/delete
$!sys$library:librtl		/open/header/shared
$
$! Since the math routines of the run-time library are based on which floating
$! point data type is implemented in microcode, the following will determine
$! which file is installed and re-install it shared.
$! D_IN_HARDWARE = F$GETSYI("G_FLOAT_EMULATED")
$! IF D_IN_HARDWARE THEN GOTO RE_INSTALL_D
$RE_INSTALL_G:
$! RUN SYS$SYSTEM:INSTALL
$!SYS$LIBRARY:UVMTHRTL		/delete
$!SYS$LIBRARY:UVMTHRTL		/open/header/shared
$! GOTO RE_INSTALL_DONE
$RE_INSTALL_D:
$! RUN SYS$SYSTEM:INSTALL
$!SYS$LIBRARY:MTHRTL		/delete
$!SYS$LIBRARY:MTHRTL		/open/header/shared
$RE_INSTALL_DONE:
$
$! Start up DECnet if it is installed.  You must have already set up
$! the DECnet node database as described in the MicroVMS documentation.
$! otherwise you will get errors stating th the database is not initialized.
$!
$! If you are using asynchronous DECnet, then you have to set the terminal
$! line characteristics first, as in the next SET TERMINAL command commented
$! out below.  You should change the command to specify the terminal line
$! that you are using.  Be sure to remove the SET TERMINAL command from
$! Reminder:  The SET TERMINAL command must also be issued on the routing
$! node that you are connecting to specifying the terminal line being used
$! on that side.)
$! SET TERMINAL $TERMINAL1 /PERMANENT /NOAUTOBAUD /SPEED=9600 /PROTOCOL=DDCMP
$
$ IF F$SEARCH("SYS$MANAGER:STARTNET.COM") .NES. "" THEN @SYS$MANAGER:STARTNET
$! IF F$SEARCH("SYS$MANAGER:STARTNET.COM") .NES. "" - !This is faster, if you
$!	THEN SUBMIT SYS$MANAGER:STARTNET.COM	      !have batch queues set up.
$
$! Report that the installation was successful and that you can now log in.
$
$ IF F$SEARCH("SYS$MANAGER:SUCCESS.TXT") .NES. "" THEN -
	TYPE SYS$MANAGER:SUCCESS.TXT
$ IF F$SEARCH("SYS$MANAGER:SUCCESS.TXT") .NES. "" THEN -
	DELETE SYS$MANAGER:SUCCESS.TXT;*
