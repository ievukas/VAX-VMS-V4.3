$ ! ************************ BUILD TRACE MESSAGE FILE **************************
$ !
$ ! This command procedure takes the module SRC$:TRACEMSG.MDL and produces
$ ! the module TRACEMSG.OBJ.
$ !
$ COPY SRC$:TRACEMSG.MDL []
$ @MASD$:[SYSEXE]CVTMSG TRACEMSG.MDL
$ MESSAGE/OBJ=OBJ$:TRACEMSG.OBJ TRACEMSG
$ RENAME OBJ$:TRACEMSG.OBJ OBJ$:TRACEMSG.OBB
$ MESSAGE/FILE_NAME=DBGTBKMSG/OBJ=OBJ$:TRACEMSG.OBJ TRACEMSG
$ DELETE TRACEMSG.MDL;0
$ DELETE TRACEMSG.MSG;0
