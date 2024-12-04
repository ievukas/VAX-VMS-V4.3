$ !
$ ! Start the Local Area Terminal facility (LAT)
$ !
$ ! P1-P7 are qualifiers for the start command to latcp
$ !
$ RUN SYS$SYSTEM:SYSGEN
CONNECT LTA0 /NOADAPTER
$ LCP := $LATCP
$ LCP START 'P1' 'P2' 'P3' 'P4' 'P5' 'P6' 'P7'
