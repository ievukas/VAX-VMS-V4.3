$ ! EDTUPD.COM - Update EDT require files
$ !
$ ! 1-001 - Original.  SBL 14-July-1982
$ ! 1-002 - Make temporary reassignment of SYS$LIBRARY.  SBL 16-Jul-1982
$ ! 1-003 - Add TRANSLATE.REQ.  JBS 09-Aug-1982
$ ! 1-004 - Add EDTVT200.DOC and KEYPADDEF.REQ.  JBS 16-Dec-1982
$ ! 1-005 - Add SUPPORTS.REQ  JBS 11-Mar-1983
$ ! 1-006 - Move compiles and links to the ASSEM phase. EAD 5-May-9183
$ ! 1-007 - Remove WRIEDTMSG.B32 and MSGTXT.B32, now in
$ !	    EDTASM.DAT. BLS 6-May-1983
$ !
$ SRCUPDATE EDT.REQ
$ SRCUPDATE EDTHELP.HLP
$ SRCUPDATE EDTREQ.REQ
$ SRCUPDATE EDTVT100.DOC
$ SRCUPDATE EDTVT200.DOC
$ SRCUPDATE EDTVT52.DOC
$ SRCUPDATE ERRMSG.REQ
$ SRCUPDATE KEYPADDEF.REQ
$ SRCUPDATE PARSTAB.TBL
$ SRCUPDATE PSECTS.REQ
$ SRCUPDATE SUPPORTS.REQ
$ SRCUPDATE SYSSYM.REQ
$ SRCUPDATE TRACELIT.REQ
$ SRCUPDATE TRACEMAC.REQ
$ SRCUPDATE TRACEOFF.REQ
$ SRCUPDATE TRACEON.REQ
$ SRCUPDATE TRANNAMES.REQ
$ SRCUPDATE TRANSLATE.REQ
$ SRCUPDATE TRAROUNAM.REQ
$ SRCUPDATE VERSION.REQ
$ SRCUPDATE VMSMSG.MSG
$ EXIT
