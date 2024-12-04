$ !
$ !	[ S O R T 3 2 . C O M ] S O R T 3 2 S H R . C O M
$ !
$ !	Link the shareable image of SORT/MERGE procedures
$ !
$ !	Link SORTSHR
$ !
$ DELETE EXE$:SORTSHR.EXE;*, MAP$:SORTSHR.MAP;*
$ LINK	/NOTRACE	-
/SHARE=EXE$:SORTSHR	-
/MAP=MAP$:SORTSHR/FULL/CROSS	-
COM$:SOROPTION/OPTIONS
