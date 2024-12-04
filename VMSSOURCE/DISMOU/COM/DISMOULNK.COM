$!
$! [DISMOU.COM]DISMOULNK.COM - COMMAND FILE TO LINK DISMOUNT COMMAND
$!
$! Note that the DISMOUNT command needs to link against the $DISMOU
$! system service, which is in the shareable image DMTSHR.EXE, which
$! in turn is located in IMAGELIB.OLB.
$!
$ LINK/EXE:EXE$:DISMOUNT/MAP:MAP$:DISMOUNT/FULL/CROSS/NOTRACE -
	 LIB$:DISMOUNT/INCLUDE:(DISPAR)
