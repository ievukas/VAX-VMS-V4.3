$ if p1 .eqs. "" then p1 = $status
$ if f$type(p1) .eqs. "STRING" then goto done
$ if p2 .nes. "" then write sys$output "Warning - superfluous extra arguments being ignored."
$ p2 = ""
$ p1 = f$message (p1)
$ p1 = f$element (2,"-",p1)
$ p1 = f$element (0,",",p1)
$ if p1 .eqs. "NORMAL" then goto normal
$ if p1 .eqs. "NOMSG" then goto nomsg
$done:
$ help/libr=sys$help:errorlib.hlb/noprompt/nopage/noinst/nolibl/nouser 'p1 'p2
$ exit
$ 
$normal:
$ write sys$output ""
$ write sys$output "NORMAL - Normal successful completion."
$ exit
$
$nomsg:
$ write sys$output ""
$ write sys$output "NOMSG - Messsage cannot be resolved from status code."
$ write sys$output "        Specify IDENTIFICATION text explicitly."$ exit
