$ !
$ ! [ E N C S T B . C O M ] E N C S T B L N K . C O M
$ !
$ !	Link the shareable stub image of the encrypt facility
$ !
$ LINK/NOSYSSHR/SHARE=EXE$:ENCRYPSHR/MAP=MAP$:ENCRYPSHR/FULL/CROSS -
	/SYMBOL=EXE$:ENCRYPSHR COM$:ENCSTBLNK/OPTIONS,-
    	LIB$:ENCSTB/INCLUDE= (-
	encmessag,-		! message definitions
    	encrypt$stubs)		! stub routines for empty sharable library
