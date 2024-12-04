$ !
$ !	Assemble one module onto result disk
$ !
$ ! p1	facility
$ ! p2	module
$ ! p3	result disk
$ ! p4  BUG or ENH (default ENH)
$ ! p5  master disk (default DISK$VMSMASTER:)
$ !
$ if p5 .eqs. "" then p5 := DISK$VMSMASTER:
$ p5 = p5 - ":" + ":"
$ indev = p5
$ prev_default = f$logical("SYS$DISK") + f$directory()
$ set default ['p1']
$ p3 = p3 - ":" + ":"
$ if p4 .eqs. "" then p4 = "ENH"
$ updates := 'p4'		! For BLDLOGNAM procedure
$ @'indev'[sysbldcom]bldlognam 'p3' 'indev'
$ rtlfac = (f$locate("RTL",p1) .ne. f$length(p1)) ! True if xxxRTL facility
$
$ if rtlfac then @'indev'[rtl.com]rtllognam assign
$ if p1 .eqs. "EDT" then @com$:edtasnreq
$ if p1 .eqs. "LINKER" then @com$:assignreq
$ @sysbldcom$:fasm 'p1' 'p2' YES 'updates'
$ if rtlfac then @'indev'[rtl.com]rtllognam deassign
$ if p1 .eqs. "EDT" then @com$:edtdeareq
$ if p1 .eqs. "LINKER" then @com$:deasreq
$
$ @'indev'[sysbldcom]bldeasnam
$ set default 'prev_default'
