$	set noon
$	if "''phone$command'" .nes. "" then phone$command
$	phone
$
$! Copyright (C) 1982
$! Digital Equipment Corporation, Maynard, Massachusetts 01754
