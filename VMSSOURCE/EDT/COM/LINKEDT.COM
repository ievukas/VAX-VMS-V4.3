$ ! LINKEDT.COM - Link executeable version of EDT
$ !
$ ! 1-001 - Original.  SBL 14-July-1982
$ ! 1-002 - Link /NOTRACE.  SBL 21-Jul-1982
$ !
$ !
$ ! Link a configuration of the utility which uses the shareable image
$ ! 
$ LINK/NOTRACE/MAP=MAP$:EDT/FULL/CROSS/EXE=EXE$:EDT SYS$INPUT:/OPTIONS
LIB$:EDT/INCLUDE=EDT$STARTEDT/LIB
EXE$:EDTSHR/SHARE
