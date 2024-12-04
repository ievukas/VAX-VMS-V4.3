$ !
$ !	[ S U M . C O M ] S U M S H R L N K . C O M
$ !
$ !	Command file to produce the shareable image of the
$ !	Source Update Merge procedures.
$ !
$ DELETE EXE$:SUMSHR.EXE;*, MAP$:SUMSHR.MAP;*
$ LINK/NOSYSSHR/SHARE=EXE$:SUMSHR/MAP=MAP$:SUMSHR/FULL/CROSS -
	SYS$INPUT/OPTIONS
!
CLUSTER=ROSECT,,,LIB$:SUM/INCLUDE=(SUM$TFRVEC,SUM$DATA,-
		SUM$LIST,SUM$OPEN,SUM$EDIT,SUM$ERROR)
!
COLLECT=ROSECT,_LIB$CODE
COLLECT=RWSECT,SUM$GLOBAL,SUM$RW_DATA,_LIB$DATA
!
!	Set match control and major id = 1, and minor = 1000
!
GSMATCH=LEQUAL,1,1000
!
!	Reduce number of image sections by combining PSECTS
!
PSECT=_LIB$DATA,NOPIC
PSECT=SUM$RO_DATA,PIC,SHR,EXE
PSECT=SUM$CODE,PIC,SHR
