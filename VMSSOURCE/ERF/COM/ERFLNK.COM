$ IF P1 .EQS. "" THEN P1 := NOTRACE
$ !
$ ! ERFLNK.COM - Command file to link ERF- Error Report Generator
$ !
$ ! ASSUME DEFAULT = [ERF.COM] AND
$ !
$ LINK /'P1' /SHAR=EXE$:ERFCOMMON/MAP=MAP$:ERFCOMMON/FULL/CROSS  -
LIB$:ERF/include=(erfcomvec, erfcom ), com$:commattr/opt
$ !
$ !
$ !
$ LINK /'P1' /SHARE=EXE$:ERFSHR/MAP=MAP$:ERFSHR/FULL/CROSS  -
LIB$:ERF/include=(erfshrvec, label, memory_q, calc_map, compressf, dhead1, -
dhead2, dw780_mapping, dw750_mapping, dw7zz_mapping, dw780_datapath, -
dw750_datapath, dw7zz_datapath, mount, mount_volume, movxx, output, -
irp$l_pid, irp$q_iosb, irp$w_bcnt, irp$w_boff, irp$w_func , uba_datapath, -
uba_mapping, ucb$l_char, ucb$w_errcnt, ucb$b_ertcnt, ucb$b_ertmax, -
ucb$l_media, ucb$l_opcnt, orb$l_owner, ucb$w_sts, vax780reg, vax750reg, -
vaxpsl, xxxque, classify, orb$l_owner_rtn, ucb$l_opcnt_rtn, ucb$w_errcnt_rtn, -
dudriver_qio, tudriver_qio, cdrp$l_bcnt, erllogsts, mslg$$l_cmd_ref, -
undefined, cdrp$l_media, cdrp$l_pid, cdrp$q_iosb, cdrp$w_boff, cdrp$w_func, -
padriver_initialization, padriver_attention_error_code, ucb$w_sts_rtn, -
compress4, compressc, dumpreg, erfmsg, translate_bits, erfoutput, -
exec_image, files, get_code, header, image_loader, intervene_increment, -
linchk, open_out_file, logger, frctof, unknown, useropen), com$:shrattr/opt
$ !
$ !
$ !
$ Link /'P1'/EXE=EXE$/MAP=MAP$/FULL/CROSS -
LIB$:erf/include=(erf, erfparser, recselect, unkn_disp, timrb), -
com$:psectattr/opt, resobj$:cliutl/include=cvttime
$ !
$ !
$ !
$ LINK /'P1' /SHARE=EXE$:ERFBRIEF/MAP=MAP$:ERFBRIEF/FUL/CROSS -
OBJ$:ERF/include = ( erfbrivec, brief_c_dispatcher, -
brief_padriver_logmessage, ucb$$b_bs_errmsg, -
brief_pudriver_mscp_dispatcher, cryptk, brief, string, erllogmsg ), -
resobj$:sys/incl=bugchkmsg, com$:psectattr/option
$ !
$ !
$ !
$ LINK /'P1'/MAP=MAP$:erfproc1/FULL/CROSS/SHARE=EXE$:erfproc1 -
LIB$:ERF/include=(erfproc1vect, erfprc1ini, erl$logstatus_dispatcher, -
status, padriver_logmessage, flags, flags_ds, flags_f, flags_p, flags_pf,-
disk_tape_drivers_mscp_q, pudriver_mscp_dispatcher, -
disk_tape_drvr_mscp_dispatcher, erl$logmessage_dispatcher, -
mslg$$l_cmd_ref ), COM$:proc1/opt, -
logsts/options, psectattr/opt
$ !
$ !
$ !
$ LINK /'P1'/MAP=MAP$:erfproc2/FULL/CROSS/SHARE=EXE$:erfproc2 -
LIB$:ERF/include = (erfproc2vect,erfprc2ini, bugchk, mchk_disp, mcheck_750, -
mcheck_780, mcheck_7zz, mcheck_uv1, parameter_one, parameter_two, string ), -
resobj$:sys/inclu=bugchkmsg, com$:psectattr/opt
$ !
$ !
$ !
$ LINK /'P1'/MAP=MAP$:erfproc3/FULL/CROSS/SHARE=EXE$:erfproc3 -
LIB$:ERF/include = (erfproc3vect,erfprc3ini,mnt_dismnt_disp, ma780, memory, -
ms780c, ms780e, ms750, ms730, decode_ecc,sbi,memory_register_uv1), -
com$:psectattr/opt
$ !
$ !
$ !
$ LINK /'P1'/MAP=MAP$:erfproc4/FULL/CROSS/SHARE=EXE$:erfproc4 -
LIB$:erf/include = (erfproc4vect,erfprc4ini, uba_errors, dw730_error, -
uba_interrupts, dw780_interrupt, mba_interrupts, rh780_interrupt, -
rh780_status_register16_31, rh780_control_registers), com$:psectattr/opt
$ !
$ !
$ !
$ LINK /'P1'/MAP=MAP$:erfproc5/FULL/CROSS/SHARE=EXE$:erfproc5 -
LIB$:ERF/include = (erfproc5vect, erfprc5ini, sys_startup, sys_powerfail, -
message_handling,newfile_and_time_stamp), com$:psectattr/opt
$ !
$ !
$ !
$ LINK /'P1'/MAP=map$:erfdisk/FULL/CROSS/SHARE=EXE$:erfdisk -
LIB$:ERF/include = (erfdiskvect, erfdskini, dbdriver_qio, drdriver_qio, -
dqdisks, dqdisks_qio, massdisk, ml11, ml11_qio, rkdisk, rkdisk_qio, rldisk, -
rldisk_qio, rxdisk, rxdisk_qio, tutape, tutape_qio ), com$:mba/opt,psectattr/opt
$ !
$ !
$ !
$ LINK /'P1'/MAP=map$:erftape/FULL/CROSS/SHARE=EXE$:erftape -
LIB$:ERF/include = (erftapevect, erftapini, masstape, tstape, mftape, -
mftape_qio, masstape_qio, tstape_qio), com$:mba/opt, psectattr/opt
$ !
$ !
$ !
$ LINK /'P1'/MAP=map$:erfbus/FULL/CROSS/SHARE=EXE$:erfbus -
LIB$:ERF/include=(erfbusvect, erfbusini, padriver_attention780, -
padriver_attention750, pudriver, dup3271, dup3271_qio, -
ci_control_store_mismatch, ci_pesr, ci_pmcsr, ci_ppr, ci_psr, dup11, -
output_mlines, sa_error, sb11, sb11_qio, vecmapreg, sa_noerror, -
kms3271_device ), com$:psectattr/opt
$ !
$ !
$ !
$ LINK /'P1'/MAP=map$:erfrltim/FULL/CROSS/SHARE=EXE$:erfrltim -
LIB$:ERF/include=(erfrtvect, erfrtini, lpa11k_qio, pcl11r_qio, pcl11t_qio, -
ucb$$b_bs_errmsg, xfdriver_qio, lpa11k, dr780, dr750, pcl11r, pcl11t, -
bsdriver, dr11w, dr11w_qio), com$:psectattr/opt
$ !
$ !
$ !
$ LINK /'P1'/MAP=map$:erfsumm/FULL/CROSS/SHARE=exe$:erfsumm -
LIB$:ERF/include=(erfsummvect, erfsummary, rollup, label_out, memory_display,-
decode_ecc, entry_summary_descriptor_load, entry_summary_update, -
entry_summary_write, timcmp), com$:psectattr/opt
$ !
$ ! Create ERFINICOM.EXE
$ !
$ LINK /'P1'/MAP=map$:erfinicom/FULL/CROSS/SHARE=exe$:erfinicom -
lib$:ERF/include=(erfinivec, init_commons), -
com$:psectattr/opt
$ exit
