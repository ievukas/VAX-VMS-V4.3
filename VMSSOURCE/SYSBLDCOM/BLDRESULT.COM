$ !
$ ! Modified by:
$ !
$ !	Benn Schreiber			26-AUG-1984
$ !	Copy [SYSHLP.EXAMPLES]MSCPMOUNT.COM
$ !
$ !	Benn Schreiber			 7-AUG-1984
$ !	Don't data reduce ERRORLIB, it's not being built.
$ !
$ !	Rowland R. Bradley		01-Aug-1984
$ !	Correct target directory, from vmslib to prtsmb for
$ !	smbmsg and psmmsg.
$ !
$ !	Trudy C. Matthews		31-Jul-1984
$ !	Copy ERRSNAP.COM to [SYSERR].
$ !
$ !	Rowland R. Bradley		25-Jul-1984
$ !	Copy message files to starlet.  Make message 
$ !	files smbmsg and psmmsg available to other products.
$ !
$ !	J E Johnson			25-Jul-1984
$ !	Copy CHGSYSPAR.EXE into [SYSUPD] for the upgrade.
$ !
$ !	Robert Posniak			25-JUL-1984
$ !	Copy MAILUAF.COM, MAILCOMPRESS.COM and
$ !	MAILCVT.COM to [SYSHLP.EXAMPLES]
$ !
$ !	Benn Schreiber			 8-JUL-1984
$ !	Add building of STARLETSD.TLB, copy SDLNPARSE.
$ !
$ !	Benn Schreiber			30-APR-1984
$ !	Add LIBDECOMP.COM
$ !
$ !	Peter George			12-Apr-1984
$ !	Copy VMSIMAGES.UV to [SYSMGR].
$ !
$ !	R. Scott Hanna			29-Mar-1984
$ !	Remove command that copies QUORUM.DAT. The quorum disk file is now
$ !	created automatically by the CSP process.
$ !
$ !	Tim Halvorsen			25-Mar-1984
$ !	Fix paragraph which copies compilers to use SYS$SYSTEM:, and not
$ !	SYS$SYSROOT:[SYSEXE], since our compilers don't live in SYS$SYSROOT.
$ !
$ !	Benn Schreiber			24-MAR-1984
$ !	Compress helplib for reduction in distribution kit sizes.  Add
$ !	REGKITBLD.DAT for regression test files
$ !
$ !	Maria del C. Nasr		11-Mar-1984
$ !	Use new /DATA=REDUCE qualifier in librarian to reduce libraries.  Also,
$ !	do not reduce HELP library, to make it faster.
$ !
$ !	Copy facility independent files (including programs we do not build)
$ !	to the target device.
$ !	This procedure is slowly being whittled away as system management
$ !	procedures are added to the MANAGE facility.
$ !
$ !	TARGDEV = P1 (Required)	The device name of the target
$ !				volume for this build.
$ !
$ !	INDEV = P2 (Required)	The device name of the source and
$ !				command files.
$ !
$ TARGDEV:='P1'
$ INDEV:='P2'
$ SET NOON
$ !
$ ! Set up acls for the world for encryption when it is present
$ !
$ ! SET FILE /ACL=(IDENT=[DOC1,*],ACCESS=EXECUTE+READ 'TARGDEV'[000000]ENCRYP.DIR
$ ! SET FILE /ACL=(IDENT=[DOC1,*],ACCESS=EXECUTE+READ) 'TARGDEV'[ENCRYP]*.DIR
$ ! SET PROT=(W=RE) 'TARGDEV'[ENCRYP.OBJ]ENCRYPSHR.EXE
$ !
$ !	COPY KIT COMMAND FILES AND SYSUAF DATA FILE
$ !
$ COPY 'INDEV'[SYSEXE]STARTUP.UP2	'TARGDEV'[SYSEXE]
$ COPY 'INDEV'[SYSEXE]STARTUP.UP3	'TARGDEV'[SYSEXE]
$ COPY 'INDEV'[SYSEXE]STARTUP.UP4	'TARGDEV'[SYSEXE]
$ COPY 'INDEV'[SYSEXE]STARTUP.UP5	'TARGDEV'[SYSEXE]
$ COPY 'INDEV'[SYSEXE]STARTUP.INS	'TARGDEV'[SYSEXE]
$ COPY 'INDEV'[SYSEXE]CHGSYSPAR.EXE	'TARGDEV'[SYSEXE]
$ COPY 'INDEV'[SYSUPD]VMS040.COM	'TARGDEV'[SYSUPD]
$ COPY 'INDEV'[SYSUPD]VMS040.COM	'TARGDEV'[SYSUPD]KITINSTAL.COM
$ COPY 'INDEV'[SYSUPD]VMSOPT.COM	'TARGDEV'[SYSUPD]
$ COPY 'INDEV'[SYSEXE]SYSUAF.DAT	'TARGDEV'[SYSEXE]
$ COPY 'INDEV'[SYSEXE]SYSUAF.DAT	'TARGDEV'[SYSEXE]SYSUAF.RL2
$ COPY 'INDEV'[SYSUPD]CONSCOPY.COM	'TARGDEV'[SYSUPD]
$ COPY 'INDEV'[SYSUPD]BOOTBLDR.COM	'TARGDEV'[SYSUPD]
$ COPY 'INDEV'[SYSUPD]BOOTUPD.COM	'TARGDEV'[SYSUPD]
$ COPY 'INDEV'[SYSUPD]CVTNAF.COM	'TARGDEV'[SYSUPD]
$ COPY 'INDEV'[SYSUPD]CVTUAF.COM	'TARGDEV'[SYSUPD]
$ COPY 'INDEV'[SYSUPD]DXCOPY.COM	'TARGDEV'[SYSUPD]
$ COPY 'INDEV'[SYSUPD]LIBDECOMP.COM	'TARGDEV'[SYSUPD]
$ COPY 'INDEV'[SYSUPD]SETDEFBOO.COM	'TARGDEV'[SYSUPD]
$ COPY 'INDEV'[SYSUPD]DIRCLENUP.COM	'TARGDEV'[SYSUPD]
$ COPY 'INDEV'[SYSUPD]MOVE.COM		'TARGDEV'[SYSUPD]
$ COPY 'INDEV'[SYSUPD]VMSKITBLD.DAT	'TARGDEV'[SYSUPD]
$ COPY 'INDEV'[SYSUPD]REGKITBLD.DAT	'TARGDEV'[SYSUPD]
$ COPY 'INDEV'[SYSUPD]VMSOBSLET.DAT	'TARGDEV'[SYSUPD]
$ COPY 'TARGDEV'[SYSUPD]VMSKITBLD.DAT	'TARGDEV'[SYSUPD]VMSKITBLD.V3N
$ APPEND 'TARGDEV'[SYSUPD]VMSOBSLET.DAT	'TARGDEV'[SYSUPD]VMSKITBLD.V3N
$ COPY 'INDEV'[SYSUPD]VMSKITBLD.COM	'TARGDEV'[SYSUPD]
$ COPY 'INDEV'[SYSUPD]VMSTAILOR.COM	'TARGDEV'[SYSUPD]
$ !
$ !	COPY MEDIA BUILDING COMMAND FILES
$ !
$ LIBRARY/CREATE/HELP 'TARGDEV'[SYSHLP]VMSMEDIA	 'INDEV'[SYSHLP]VMSMEDIA
$ LIBRARY/CREATE:MODULES=20/HELP 'TARGDEV'[SYSHLP]VMSTLRHLP 'INDEV'[SYSHLP]VMSTLRHLP
$ COPY 'INDEV'[SYSUPD]VMSMEDIA.COM	'TARGDEV'[SYSUPD]
$ COPY 'INDEV'[SYSUPD]MEDIACOPY.COM	'TARGDEV'[SYSUPD]
$ COPY 'INDEV'[SYSUPD]TAPECOPY.COM	'TARGDEV'[SYSUPD]
$ COPY 'INDEV'[SYSUPD]DISKITBLD.COM	'TARGDEV'[SYSUPD]
$ COPY 'INDEV'[SYSUPD]750CNSL.DAT	'TARGDEV'[SYSUPD]
$ COPY 'INDEV'[SYSUPD]780CNSL.DAT	'TARGDEV'[SYSUPD]
$ COPY 'INDEV'[SYSUPD]730CNSL.DAT	'TARGDEV'[SYSUPD]
$ COPY 'INDEV'[SYSUPD]CONSOLBLD.COM	'TARGDEV'[SYSUPD]
$ COPY 'INDEV'[SYSUPD]CONSOLCPY.COM	'TARGDEV'[SYSUPD]
$ COPY 'INDEV'[SYSUPD]STABACKIT.COM	'TARGDEV'[SYSUPD]
$ !
$ !	COPY BOOTSTRAP COMMAND FILES
$ !
$ COPY 'INDEV'[CONSOLE.780]*.*		'TARGDEV'[CONSOLE.780]
$ COPY 'INDEV'[CONSOLE.750]*.*		'TARGDEV'[CONSOLE.750]
$ COPY 'INDEV'[CONSOLE.730]*.*		'TARGDEV'[CONSOLE.730]
$ !
$ !	COPY MISC FILES
$ !
$ COPY 'INDEV'[SYSEXE]NETSERVER.COM	'TARGDEV'[SYSEXE]
$ COPY 'INDEV'[SYSEXE]DTR.COM		'TARGDEV'[SYSEXE]
$ COPY 'INDEV'[SYSEXE]FAL.COM		'TARGDEV'[SYSEXE]
$ COPY 'INDEV'[SYSEXE]NML.COM		'TARGDEV'[SYSEXE]
$ COPY 'INDEV'[SYSEXE]EVL.COM 		'TARGDEV'[SYSEXE]
$ COPY 'INDEV'[SYSEXE]HLD.COM		'TARGDEV'[SYSEXE]
$ COPY 'INDEV'[SYSMGR]DISKMON.COM	'TARGDEV'[SYSMGR]
$ COPY 'INDEV'[SYSMGR]STARTNET.COM	'TARGDEV'[SYSMGR]
$ COPY 'INDEV'[SYSMGR]LOADNET.COM	'TARGDEV'[SYSMGR]
$ COPY 'INDEV'[SYSMGR]RTTLOAD.COM	'TARGDEV'[SYSMGR]
$ COPY 'INDEV'[SYSMGR]VMSIMAGES.COM	'TARGDEV'[SYSMGR]
$ COPY 'INDEV'[SYSMGR]VMSIMAGES.DAT	'TARGDEV'[SYSMGR]
$ COPY 'INDEV'[SYSMGR]VMSIMAGES.UV	'TARGDEV'[SYSMGR]
$ COPY 'INDEV'[SYSMGR]STARTCJF.COM	'TARGDEV'[SYSMGR]
$ COPY 'INDEV'[SYSEXE]NETNODE.DAT	'TARGDEV'[SYSEXE]
$ COPY 'INDEV'[SYSEXE]NETOBJECT.DAT	'TARGDEV'[SYSEXE]
$ COPY 'INDEV'[SYSEXE]NETLINE.DAT	'TARGDEV'[SYSEXE]
$ COPY 'INDEV'[SYSEXE]NETCIRC.DAT	'TARGDEV'[SYSEXE]
$ COPY 'INDEV'[SYSEXE]NETLOGING.DAT	'TARGDEV'[SYSEXE]
$ COPY 'INDEV'[SYSEXE]RIGHTSMAN.EXE	'TARGDEV'[SYSEXE]
$ COPY 'INDEV'[SYSHLP]RIGHTSMAN.HLB	'TARGDEV'[SYSHLP]
$ COPY 'INDEV'[SYSEXE]SECDMC.SYS	'TARGDEV'[SYSEXE]
$ COPY 'INDEV'[SYSEXE]SECDP.SYS		'TARGDEV'[SYSEXE]
$ COPY 'INDEV'[SYSEXE]SECDQ.SYS		'TARGDEV'[SYSEXE]
$ COPY 'INDEV'[SYSEXE]SECDU.SYS		'TARGDEV'[SYSEXE]
$ COPY 'INDEV'[SYSEXE]SECDUP.SYS	'TARGDEV'[SYSEXE]
$ COPY 'INDEV'[SYSEXE]SECDUV.SYS	'TARGDEV'[SYSEXE]
$ COPY 'INDEV'[SYSEXE]SECDL.SYS		'TARGDEV'[SYSEXE]
$ COPY 'INDEV'[SYSEXE]TERDMC.SYS	'TARGDEV'[SYSEXE]
$ COPY 'INDEV'[SYSEXE]TERDP.SYS		'TARGDEV'[SYSEXE]
$ COPY 'INDEV'[SYSEXE]TERDQ.SYS		'TARGDEV'[SYSEXE]
$ COPY 'INDEV'[SYSEXE]TERDU.SYS		'TARGDEV'[SYSEXE]
$ COPY 'INDEV'[SYSEXE]TERDUP.SYS	'TARGDEV'[SYSEXE]
$ COPY 'INDEV'[SYSEXE]TERDUV.SYS	'TARGDEV'[SYSEXE]
$ COPY 'INDEV'[SYSEXE]TERDL.SYS		'TARGDEV'[SYSEXE]
$ COPY 'INDEV'[SYSERR]ERRSNAP.COM	'TARGDEV'[SYSERR]
$ !
$ !	COPY CODING EXAMPLES THAT GO ON BINARY KITS.
$ !
$ COPY 'INDEV'[SYSHLP.EXAMPLES]ADDRIVER.MAR	'TARGDEV'[SYSHLP.EXAMPLES]
$ COPY 'INDEV'[SYSHLP.EXAMPLES]CONNECT.COM   	'TARGDEV'[SYSHLP.EXAMPLES]
$ COPY 'INDEV'[SYSHLP.EXAMPLES]DOD_ERAPAT.MAR	'TARGDEV'[SYSHLP.EXAMPLES]
$ COPY 'INDEV'[SYSHLP.EXAMPLES]DRCOPY.PRM	'TARGDEV'[SYSHLP.EXAMPLES]
$ COPY 'INDEV'[SYSHLP.EXAMPLES]DRCOPYBLD.COM	'TARGDEV'[SYSHLP.EXAMPLES]
$ COPY 'INDEV'[SYSHLP.EXAMPLES]DRMAST.MAR	'TARGDEV'[SYSHLP.EXAMPLES]
$ COPY 'INDEV'[SYSHLP.EXAMPLES]DRMASTER.FOR	'TARGDEV'[SYSHLP.EXAMPLES]
$ COPY 'INDEV'[SYSHLP.EXAMPLES]DRSLAVE.FOR	'TARGDEV'[SYSHLP.EXAMPLES]
$ COPY 'INDEV'[SYSHLP.EXAMPLES]DRSLV.MAR	'TARGDEV'[SYSHLP.EXAMPLES]
$ COPY 'INDEV'[SYSHLP.EXAMPLES]GBLSECUFO.MAR    'TARGDEV'[SYSHLP.EXAMPLES]
$ COPY 'INDEV'[SYSHLP.EXAMPLES]LABCHNDEF.FOR    'TARGDEV'[SYSHLP.EXAMPLES]
$ COPY 'INDEV'[SYSHLP.EXAMPLES]LABIO.OPT   	'TARGDEV'[SYSHLP.EXAMPLES]
$ COPY 'INDEV'[SYSHLP.EXAMPLES]LABIOACQ.FOR   	'TARGDEV'[SYSHLP.EXAMPLES]
$ COPY 'INDEV'[SYSHLP.EXAMPLES]LABIOCIN.MAR   	'TARGDEV'[SYSHLP.EXAMPLES]
$ COPY 'INDEV'[SYSHLP.EXAMPLES]LABIOCIN.OPT   	'TARGDEV'[SYSHLP.EXAMPLES]
$ COPY 'INDEV'[SYSHLP.EXAMPLES]LABIOCOM.FOR   	'TARGDEV'[SYSHLP.EXAMPLES]
$ COPY 'INDEV'[SYSHLP.EXAMPLES]LABIOCOMP.COM    'TARGDEV'[SYSHLP.EXAMPLES]
$ COPY 'INDEV'[SYSHLP.EXAMPLES]LABIOCON.FOR   	'TARGDEV'[SYSHLP.EXAMPLES]
$ COPY 'INDEV'[SYSHLP.EXAMPLES]LABIOLINK.COM    'TARGDEV'[SYSHLP.EXAMPLES]
$ COPY 'INDEV'[SYSHLP.EXAMPLES]LABIOPEAK.FOR    'TARGDEV'[SYSHLP.EXAMPLES]
$ COPY 'INDEV'[SYSHLP.EXAMPLES]LABIOSAMP.FOR    'TARGDEV'[SYSHLP.EXAMPLES]
$ COPY 'INDEV'[SYSHLP.EXAMPLES]LABIOSEC.FOR   	'TARGDEV'[SYSHLP.EXAMPLES]
$ COPY 'INDEV'[SYSHLP.EXAMPLES]LABIOSTAT.FOR    'TARGDEV'[SYSHLP.EXAMPLES]
$ COPY 'INDEV'[SYSHLP.EXAMPLES]LABIOSTRT.COM    'TARGDEV'[SYSHLP.EXAMPLES]
$ COPY 'INDEV'[SYSHLP.EXAMPLES]LABMBXDEF.FOR    'TARGDEV'[SYSHLP.EXAMPLES]
$ COPY 'INDEV'[SYSHLP.EXAMPLES]LBRDEMO.COM	'TARGDEV'[SYSHLP.EXAMPLES]
$ COPY 'INDEV'[SYSHLP.EXAMPLES]LBRDEMO.FOR	'TARGDEV'[SYSHLP.EXAMPLES]
$ COPY 'INDEV'[SYSHLP.EXAMPLES]LBRMAC.MAR	'TARGDEV'[SYSHLP.EXAMPLES]
$ COPY 'INDEV'[SYSHLP.EXAMPLES]LPATEST.FOR	'TARGDEV'[SYSHLP.EXAMPLES]
$ COPY 'INDEV'[SYSHLP.EXAMPLES]LPMULT.B32   	'TARGDEV'[SYSHLP.EXAMPLES]
$ COPY 'INDEV'[SYSHLP.EXAMPLES]MAILUAF.COM      'TARGDEV'[SYSHLP.EXAMPLES]
$ COPY 'INDEV'[SYSHLP.EXAMPLES]MAILCOMPRESS.COM 'TARGDEV'[SYSHLP.EXAMPLES]
$ COPY 'INDEV'[SYSHLP.EXAMPLES]MAILCVT.COM      'TARGDEV'[SYSHLP.EXAMPLES]
$ COPY 'INDEV'[SYSHLP.EXAMPLES]MSCPMOUNT.COM    'TARGDEV'[SYSHLP.EXAMPLES]
$ COPY 'INDEV'[SYSHLP.EXAMPLES]PEAK.FOR   	'TARGDEV'[SYSHLP.EXAMPLES]
$ COPY 'INDEV'[SYSHLP.EXAMPLES]SCRFT.MAR	'TARGDEV'[SYSHLP.EXAMPLES]
$ COPY 'INDEV'[SYSHLP.EXAMPLES]TDRIVER.MAR	'TARGDEV'[SYSHLP.EXAMPLES]
$ COPY 'INDEV'[SYSHLP.EXAMPLES]TESTLABIO.FOR    'TARGDEV'[SYSHLP.EXAMPLES]
$ COPY 'INDEV'[SYSHLP.EXAMPLES]USSDISP.MAR	'TARGDEV'[SYSHLP.EXAMPLES]
$ COPY 'INDEV'[SYSHLP.EXAMPLES]USSLNK.COM	'TARGDEV'[SYSHLP.EXAMPLES]
$ COPY 'INDEV'[SYSHLP.EXAMPLES]USSTEST.MAR	'TARGDEV'[SYSHLP.EXAMPLES]
$ COPY 'INDEV'[SYSHLP.EXAMPLES]USSTSTLNK.COM	'TARGDEV'[SYSHLP.EXAMPLES]
$ COPY 'INDEV'[SYSHLP.EXAMPLES]XAMESSAGE.MAR	'TARGDEV'[SYSHLP.EXAMPLES]
$ COPY 'INDEV'[SYSHLP.EXAMPLES]XATEST.FOR	'TARGDEV'[SYSHLP.EXAMPLES]
$ COPY 'INDEV'[SYSHLP.EXAMPLES]XATEST.COM	'TARGDEV'[SYSHLP.EXAMPLES]
$ COPY 'INDEV'[SYSHLP.EXAMPLES]XALINK.MAR	'TARGDEV'[SYSHLP.EXAMPLES]
$ !
$ !	Data compress the large libraries 
$ !
$ SET NOON
$ LIB /DATA=REDUCE /OUT='TARGDEV'[SYSLIB] 'TARGDEV'[SYSLIB]LIB.MLB
$ LIB /DATA=REDUCE /OUT='TARGDEV'[SYSLIB] 'TARGDEV'[SYSLIB]STARLET.MLB
$ LIB /DATA=REDUCE /OUT='TARGDEV'[SYSLIB] 'TARGDEV'[SYSLIB]STARLET.OLB
$ LIB /DATA=REDUCE /OUT='TARGDEV'[SYSHLP] 'TARGDEV'[SYSHLP]DEBUGHLP.HLB
$ LIB /DATA=REDUCE /OUT='TARGDEV'[SYSHLP] 'TARGDEV'[SYSHLP]EDTHELP.HLB
$ LIB /DATA=REDUCE /OUT='TARGDEV'[SYSHLP] 'TARGDEV'[SYSHLP]EXCHNGHLP.HLB
$ LIB /DATA=REDUCE /OUT='TARGDEV'[SYSHLP] 'TARGDEV'[SYSHLP]HELPLIB.HLB
$ LIB /DATA=REDUCE /OUT='TARGDEV'[SYSHLP]HELPLIB.UV /HELP -
	'TARGDEV'[SYSHLP]HELPLIB.UV
$ LIB /DATA=REDUCE /OUT='TARGDEV'[SYSHLP] 'TARGDEV'[SYSHLP]MAILHELP.HLB
$ LIB /DATA=REDUCE /OUT='TARGDEV'[SYSHLP] 'TARGDEV'[SYSHLP]NCPHELP.HLB
$ !LIB /DATA=REDUCE /OUT='TARGDEV'[SYSHLP] 'TARGDEV'[SYSHLP]ERRORLIB.HLB
$ SET ON
$ !
$ ! Build the SDL starlet library.  Note that most of this should be
$ ! done in the individual facility build procedures, and we should only
$ ! need to pick up the files from SHRLIB$.  However, for expediency,
$ ! everything is done here, and the facility build files can be modified
$ ! in the future.
$ !
$ sdllib = targdev + "[SYSLIB]STARLETSD.TLB"
$ if f$search(sdllib) .nes. "" then delete 'sdllib';*
$ library /create /text 'sdllib'
$ sdl /nolist /parse=sys$scratch:stardefae.sdi 'targdev'[vmslib.src]stardefae
$ library /text 'sdllib' sys$scratch:stardefae.sdi
$ delete sys$scratch:stardefae.sdi;*
$ sdl /nolist /parse=sys$scratch:stardeffl.sdi 'targdev'[vmslib.src]stardeffl
$ library /text 'sdllib' sys$scratch:stardeffl.sdi
$ delete sys$scratch:stardeffl.sdi;*
$ sdl /nolist /parse=sys$scratch:stardefmp.sdi 'targdev'[vmslib.src]stardefmp
$ library /text 'sdllib' sys$scratch:stardefmp.sdi
$ delete sys$scratch:stardefmp.sdi;*
$ sdl /nolist /parse=sys$scratch:stardefqz.sdi 'targdev'[vmslib.src]stardefqz
$ library /text 'sdllib' sys$scratch:stardefqz.sdi
$ delete sys$scratch:stardefqz.sdi;*
$ sdl /nolist /parse=sys$scratch:starlet.sdi 'targdev'[vmslib.src]starlet
$ library /text 'sdllib' sys$scratch:starlet.sdi
$ delete sys$scratch:starlet.sdi;*
$ sdl /nolist /parse=sys$scratch:ssmsg.sdi 'targdev'[vmslib.src]ssmsg
$ library /text 'sdllib' sys$scratch:ssmsg.sdi
$ delete sys$scratch:ssmsg.sdi;*
$ sdl /nolist /parse=sys$scratch:shrmsg.sdi 'targdev'[vmslib.src]shrmsg
$ library /text 'sdllib' sys$scratch:shrmsg.sdi
$ delete sys$scratch:shrmsg.sdi;*
$ sdl /nolist /parse=sys$scratch:opdef.sdi 'targdev'[vmslib.src]opdef
$ library /text 'sdllib' sys$scratch:opdef.sdi
$ delete sys$scratch:opdef.sdi;*
$ sdl /nolist /parse=sys$scratch:opcdef.sdi 'targdev'[vmslib.src]opcdef
$ library /text 'sdllib' sys$scratch:opcdef.sdi
$ delete sys$scratch:opcdef.sdi;*
$ sdl /nolist /parse=sys$scratch:libcqdef.sdi 'targdev'[vmslib.src]libcqdef
$ library /text 'sdllib' sys$scratch:libcqdef.sdi
$ delete sys$scratch:libcqdef.sdi;*
$ sdl /nolist /parse=sys$scratch:srmdef.sdi 'targdev'[vmslib.src]srmdef
$ library /text 'sdllib' sys$scratch:srmdef.sdi
$ delete sys$scratch:srmdef.sdi;*
$ sdl /nolist /parse=sys$scratch:scrdef.sdi 'targdev'[vmslib.src]scrdef
$ library /text 'sdllib' sys$scratch:scrdef.sdi
$ delete sys$scratch:scrdef.sdi;*
$ sdl /nolist /parse=sys$scratch:objfmt.sdi 'targdev'[vmslib.src]objfmt
$ library /text 'sdllib' sys$scratch:objfmt.sdi
$ delete sys$scratch:objfmt.sdi;*
$ sdl /nolist /parse=sys$scratch:dstdef.sdi 'targdev'[vmslib.src]dstdef
$ library /text 'sdllib' sys$scratch:dstdef.sdi
$ delete sys$scratch:dstdef.sdi;*
$ sdl /nolist /parse=sys$scratch:lbrusr.sdi 'targdev'[lbr.src]lbrusr
$ library /text 'sdllib' sys$scratch:lbrusr.sdi
$ delete sys$scratch:lbrusr.sdi;*
$ sdl /nolist /parse=sys$scratch:rmsdef.sdi 'targdev'[rms.src]rmsdef
$ library /text 'sdllib' sys$scratch:rmsdef.sdi
$ delete sys$scratch:rmsdef.sdi;*
$ sdl /nolist /parse=sys$scratch:rmsusr.sdi 'targdev'[rms.src]rmsusr
$ library /text 'sdllib' sys$scratch:rmsusr.sdi
$ delete sys$scratch:rmsusr.sdi;*
$ sdl /nolist /parse=sys$scratch:crf.sdi 'targdev'[crf.src]crf
$ library /text 'sdllib' sys$scratch:crf.sdi
$ delete sys$scratch:crf.sdi;*
$ sdl /nolist /parse=sys$scratch:libclidef.sdi 'targdev'[librtl.src]libclidef
$ library /text 'sdllib' sys$scratch:libclidef.sdi
$ delete sys$scratch:libclidef.sdi;*
$ sdl /nolist /parse=sys$scratch:libdcfdef.sdi 'targdev'[librtl.src]libdcfdef
$ library /text 'sdllib' sys$scratch:libdcfdef.sdi
$ delete sys$scratch:libdcfdef.sdi;*
$ sdl /nolist /parse=sys$scratch:smgdef.sdi 'targdev'[smgrtl.src]smgdef
$ library /text 'sdllib' sys$scratch:smgdef.sdi
$ delete sys$scratch:smgdef.sdi;*
$ sdl /nolist /parse=sys$scratch:smgtrmptr.sdi 'targdev'[smgrtl.src]smgtrmptr
$ library /text 'sdllib' sys$scratch:smgtrmptr.sdi
$ delete sys$scratch:smgtrmptr.sdi;*
$ !
$ ! Now the ones we generate from message files
$ !
$ message /nolist /noobject /sdl=sys$scratch:psmmsg 'targdev'[prtsmb.src]psmmsg
$ sdl /nolist /parse=sys$scratch:psmmsg.sdi sys$scratch:psmmsg
$ library /text 'sdllib' sys$scratch:psmmsg.sdi
$ delete sys$scratch:psmmsg.*;*
$ message /nolist /noobject /sdl=sys$scratch:smbmsg 'targdev'[prtsmb.src]smbmsg
$ sdl /nolist /parse=sys$scratch:smbmsg.sdi sys$scratch:smbmsg
$ library /text 'sdllib' sys$scratch:smbmsg.sdi
$ delete sys$scratch:smbmsg.*;*
$ message /nolist /noobject /sdl=sys$scratch:opcmsg 'targdev'[vmslib.src]opcmsg
$ sdl /nolist /parse=sys$scratch:opcmsg.sdi sys$scratch:opcmsg
$ library /text 'sdllib' sys$scratch:opcmsg.sdi
$ delete sys$scratch:opcmsg.*;*
$ message /nolist /noobject /sdl=sys$scratch:jbcmsg 'targdev'[jobctl.src]jbcmsg
$ sdl /nolist /parse=sys$scratch:jbcmsg.sdi sys$scratch:jbcmsg
$ library /text 'sdllib' sys$scratch:jbcmsg.sdi
$ delete sys$scratch:jbcmsg.*;*
$ message /nolist /noobject /sdl=sys$scratch:rmsfalmsg 'targdev'[rms.src]rmsfalmsg
$ sdl /nolist /parse=sys$scratch:rmsfalmsg.sdi sys$scratch:rmsfalmsg
$ library /text 'sdllib' sys$scratch:rmsfalmsg.sdi
$ delete sys$scratch:rmsfalmsg.*;*
$ message /nolist /noobject /sdl=sys$scratch:basmsg 'targdev'[basrtl.src]basmsg
$ sdl /nolist /parse=sys$scratch:basmsg.sdi sys$scratch:basmsg
$ library /text 'sdllib' sys$scratch:basmsg.sdi
$ delete sys$scratch:basmsg.*;*
$ message /nolist /noobject /sdl=sys$scratch:cobmsg 'targdev'[cobrtl.src]cobmsg
$ sdl /nolist /parse=sys$scratch:cobmsg.sdi sys$scratch:cobmsg
$ library /text 'sdllib' sys$scratch:cobmsg.sdi
$ delete sys$scratch:cobmsg.*;*
$ message /nolist /noobject /sdl=sys$scratch:formsg 'targdev'[forrtl.src]formsg
$ sdl /nolist /parse=sys$scratch:formsg.sdi sys$scratch:formsg
$ library /text 'sdllib' sys$scratch:formsg.sdi
$ delete sys$scratch:formsg.*;*
$ message /nolist /noobject /sdl=sys$scratch:libmsg 'targdev'[librtl.src]libmsg
$ sdl /nolist /parse=sys$scratch:libmsg.sdi sys$scratch:libmsg
$ library /text 'sdllib' sys$scratch:libmsg.sdi
$ delete sys$scratch:libmsg.*;*
$ message /nolist /noobject /sdl=sys$scratch:mthmsg 'targdev'[mthrtl.src]mthmsg
$ sdl /nolist /parse=sys$scratch:mthmsg.sdi sys$scratch:mthmsg
$ library /text 'sdllib' sys$scratch:mthmsg.sdi
$ delete sys$scratch:mthmsg.*;*
$ message /nolist /noobject /sdl=sys$scratch:otsmsg 'targdev'[librtl.src]otsmsg
$ sdl /nolist /parse=sys$scratch:otsmsg.sdi sys$scratch:otsmsg
$ library /text 'sdllib' sys$scratch:otsmsg.sdi
$ delete sys$scratch:otsmsg.*;*
$ message /nolist /noobject /sdl=sys$scratch:strmsg 'targdev'[librtl.src]strmsg
$ sdl /nolist /parse=sys$scratch:strmsg.sdi sys$scratch:strmsg
$ library /text 'sdllib' sys$scratch:strmsg.sdi
$ delete sys$scratch:strmsg.*;*
$ library /compress /data=reduce 'sdllib' /out='sdllib'
$ purge 'sdllib'
$ COPY 'INDEV'[SYSEXE]SDLNPARSE.EXE 'TARGDEV'[SYSEXE]
$ PURGE 'TARGDEV'[SYSEXE]SDLNPARSE.EXE
$ !
$ !	Copy compilers used for the build.
$ !
$ IF F$LOGICAL("BLISS32").EQS."" THEN DEFINE/USER BLISS32 SYS$SYSTEM:BLISS32.EXE
$ COPY BLISS32	'TARGDEV'[SYSEXE]
$ IF F$LOGICAL("FORTRAN").EQS."" THEN DEFINE/USER FORTRAN SYS$SYSTEM:FORTRAN.EXE
$ COPY FORTRAN	'TARGDEV'[SYSEXE]
$ IF F$LOGICAL("PASCAL").EQS."" THEN DEFINE/USER PASCAL SYS$SYSTEM:PASCAL.EXE
$ COPY PASCAL	'TARGDEV'[SYSEXE]
$ IF F$LOGICAL("PLIG").EQS."" THEN DEFINE/USER PLIG SYS$SYSTEM:PLIG.EXE
$ COPY PLIG	'TARGDEV'[SYSEXE]
$ IF F$LOGICAL("SDL").EQS."" THEN DEFINE/USER SDL SYS$SYSTEM:SDL.EXE
$ COPY SDL	'TARGDEV'[SYSEXE]
$ !
$ !	Copy files needed for TRIALSYS
$ !
$ ON ERROR THEN CONTINUE
$ CREATE/DIR 'TARGDEV'[SYSBLDCOM]
$ COPY 'INDEV'[SYSBLDCOM]TRIALSYS.COM 'TARGDEV'[SYSBLDCOM]
$ COPY 'INDEV'[SYSBLDCOM]TRIALKIT.COM 'TARGDEV'[SYSBLDCOM]
$ COPY 'INDEV'[SYSBLDCOM]VMSNEWBLD.DAT 'TARGDEV'[SYSBLDCOM]VMSNEWBLD.VIR
$ !
$ !	DELETE ANY EXTRA COPIES OF RESULT FILES
$ !
$ EXIT		!Purging deletes files if this procedure run more than once!
$ ! PURGE/LOG 'TARGDEV'[SYSMSG]*.*
$ ! PURGE/LOG 'TARGDEV'[SYSMGR]*.*
$ ! PURGE/LOG 'TARGDEV'[SYSERR]*.*
$ ! PURGE/LOG 'TARGDEV'[SYSTEST]*.*
$ ! PURGE/LOG 'TARGDEV'[SYSUPD]*.*
