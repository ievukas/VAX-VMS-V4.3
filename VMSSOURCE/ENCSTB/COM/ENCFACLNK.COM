$ !
$ !	[ E N C R Y P . C O M ] E N C F A C L N K . C O M 
$ !
$ DBG := "/DEBUG/CROSS/FULL"
$ IF P1 .EQS. "" THEN DBG:="/NOTRACE"
$ !
$ LINK/EXE=EXE$:ENCRYPFAC/MAP=MAP$:ENCRYPFAC'DBG' -
    LIB$:ENCSTB/INCLUDE=(-
    	encrypt$facility), -	! mainline for facility
    	resobj$:cliutl.olb/libr/incl=cvttime,-
!
! The references to Encrypt primitives are satisfied by the sharable
! section ENCRYPSHR in exe$:encrypshr
!
    	sys$input:/options
    	exe$:encrypshr/share
