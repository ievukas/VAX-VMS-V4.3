!
!	[ R U N O F F . C O M ] D S R U T L S R . C O M
!
!	This command file will either SAVE or RESTORE the object files
!	specific to DSR's utilities.
!
!	The passed parameter must be either SAVE or RESTORE.
!
$ goto 'p1
$ exit 4
!
$SAVE:
!
!	This section saves the object files by renaming them to .OBS
!
!		First those for DSRINDEX:
!
$ RENAME	OBJ$:ndxvrs.OBJ		OBJ$:ndxvrs.OBI
$ RENAME	OBJ$:ndxvms.OBJ		OBJ$:ndxvms.OBI
$ RENAME	OBJ$:ndxini.OBJ		OBJ$:ndxini.OBI
$ RENAME	OBJ$:index.OBJ		OBJ$:index.OBI
$ RENAME	OBJ$:permute.OBJ	OBJ$:permute.OBI
$ RENAME	OBJ$:ndxdat.OBJ		OBJ$:ndxdat.OBI
$ RENAME	OBJ$:ndxout.OBJ		OBJ$:ndxout.OBI
$ RENAME	OBJ$:pool.OBJ		OBJ$:pool.OBI
$ RENAME	OBJ$:ndxxtn.OBJ		OBJ$:ndxxtn.OBI
$ RENAME	OBJ$:ndxtms.OBJ		OBJ$:ndxtms.OBI
$ RENAME	OBJ$:ndxmsg.OBJ		OBJ$:ndxmsg.OBI
$ RENAME	OBJ$:ndxvmsmsg.OBJ	OBJ$:ndxvmsmsg.OBI
$ RENAME	OBJ$:ndxfmt.OBJ		OBJ$:ndxfmt.OBI
$ RENAME	OBJ$:pagmrg.OBJ		OBJ$:pagmrg.OBI
$ RENAME	OBJ$:ndxpag.OBJ		OBJ$:ndxpag.OBI
$ RENAME	OBJ$:ndxtex.OBJ		OBJ$:ndxtex.OBI
$
!		Then those for DSRTOC:
!
$ RENAME	OBJ$:cntvrs.OBJ		OBJ$:cntvrs.OBT
$ RENAME	OBJ$:cntvms.OBJ		OBJ$:cntvms.OBT
$ RENAME	OBJ$:cntvmsmsg.OBJ	OBJ$:cntvmsmsg.OBT
$ RENAME	OBJ$:contents.OBJ	OBJ$:contents.OBT
$ RENAME	OBJ$:gbldcl.OBJ		OBJ$:gbldcl.OBT
$ RENAME	OBJ$:format.OBJ		OBJ$:format.OBT
$ RENAME	OBJ$:caption.OBJ	OBJ$:caption.OBT
$ EXIT 1
!
$RESTORE:
!
!	This section restores the saved object files by renaming them
!	back to .OBJs
!
$ goto 'p2
$ EXIT 4
$
$DSRINDEX:
$ RENAME	OBJ$:*.OBI	OBJ$:*.OBJ
$ EXIT 1
!
$DSRTOC:
$ RENAME	OBJ$:*.OBT	OBJ$:*.OBJ
$ EXIT 1
