$ !++
$ !
$ !  MAILCVT.COM - Convert multiple V3 sequential files into V4 folders 
$ !
$ !
$ !  ABSTRACT:  Sample command procedure to convert multiple
$ !  		V3 sequential files into V4 folders.
$ !
$ !		To add the messages from a single V3 sequential
$ !		mail file into a V4 mail file folder, issue the
$ !		follow sequence of commands in MAIL.
$ !
$ !		MAIL> SET FILE v3-sequential-file-name
$ !		MAIL> COPY /ALL folder-name v4-isam-file-name
$ !
$ !  
$ !  INPUT PARAMETERS:
$ !
$ !		p1 - the file specification of the V3 mail files to convert.
$ !		     Wildcards are allowed.  The default file specification
$ !		     applied is *.MAI
$ !
$ !	  	p2 - the V4 ISAM format output file.  the default file
$ !	  	     specification applied is SYS$LOGIN:MAIL.MAI.
$ !
$ !
$ !  OUTPUT:	V4 ISAM format MAIL file.
$ !
$ !
$ !  IMPLICIT OUTPUT:
$ !		The old version of the output file, if it exsists, will 
$ !		be deleted.
$ !
$ !
$ !--
$ set	= "SET"
$ if	= "IF"
$ write	= "WRITE"
$ open	= "OPEN"
$ goto	= "GOTO"
$ close	= "CLOSE"
$ delete = "DELETE"
$ convert = "CONVERT"
$ exit	= "EXIT"
$ v = f$verify(0)
$ set noon
$ if p1 .eqs. "" then p1 = "*.mai"
$ outfile = f$parse(p2,"sys$login:mail.mai")
$ write sys$output "%MAILCVT-I-Output file will be ",outfile
$ lastfile = ""
$ mypid = f$getjpi(0,"pid")
$ tmpfile = "sys$login:cvt" + mypid + ".tmp"
$ open /write f1 'tmpfile'
$ write f1 "$ mail"
$ search_string = f$parse(p1,"sys$login:.mai")
$convert:
$ infile = f$search(search_string)
$ if infile .eqs. "" then goto done
$ if infile .eqs. lastfile then goto done
$ if f$locate("]MAIL.MAI;",infile) .ne. f$length(infile) then goto skip_mail
$ if f$locate(">MAIL.MAI;",infile) .ne. f$length(infile) then goto skip_mail
$ if f$locate("]MAIL$",infile) .ne. f$length(infile) then goto skip_mail
$ if f$locate(">MAIL$",infile) .ne. f$length(infile) then goto skip_mail
$ if f$file(infile,"org") .eqs. "IDX" then goto skip_mail
$ lastfile = infile
$ write sys$output "%MAILCVT-I-File ''infile' added"
$ write f1 "set file ",infile
$ x = f$parse(infile,,,"NAME")
$ write f1 "copy/all/noconfirm ",x," ",outfile
$ goto convert
$skip_mail:
$ write sys$output "%MAILCVT-I-Skipping file ''infile'"
$ lastfile = infile
$ goto convert
$done:
$ write f1 "quit"
$ close f1
$ @'tmpfile'
$ delete 'tmpfile';*
$ lastfile = f$search(outfile)
$ convert/share 'outfile' 'outfile'
$ if .not. $status then exit
$ set prot 'lastfile'/prot=o=rwed
$ delete 'lastfile'
$ exit
