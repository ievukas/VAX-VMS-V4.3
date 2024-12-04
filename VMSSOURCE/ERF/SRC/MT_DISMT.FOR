	Subroutine mnt_dismnt_disp (lun,option)
C
C Version:	'V04-000'
C
C****************************************************************************
C*									    *
C*  COPYRIGHT (c) 1978, 1980, 1982, 1984 BY				    *
C*  DIGITAL EQUIPMENT CORPORATION, MAYNARD, MASSACHUSETTS.		    *
C*  ALL RIGHTS RESERVED.						    *
C* 									    *
C*  THIS SOFTWARE IS FURNISHED UNDER A LICENSE AND MAY BE USED AND COPIED   *
C*  ONLY IN  ACCORDANCE WITH  THE  TERMS  OF  SUCH  LICENSE  AND WITH THE   *
C*  INCLUSION OF THE ABOVE COPYRIGHT NOTICE. THIS SOFTWARE OR  ANY  OTHER   *
C*  COPIES THEREOF MAY NOT BE PROVIDED OR OTHERWISE MADE AVAILABLE TO ANY   *
C*  OTHER PERSON.  NO TITLE TO AND OWNERSHIP OF  THE  SOFTWARE IS  HEREBY   *
C*  TRANSFERRED.							    *
C* 									    *
C*  THE INFORMATION IN THIS SOFTWARE IS  SUBJECT TO CHANGE WITHOUT NOTICE   *
C*  AND  SHOULD  NOT  BE  CONSTRUED AS  A COMMITMENT BY DIGITAL EQUIPMENT   *
C*  CORPORATION.							    *
C* 									    *
C*  DIGITAL ASSUMES NO RESPONSIBILITY FOR THE USE  OR  RELIABILITY OF ITS   *
C*  SOFTWARE ON EQUIPMENT WHICH IS NOT SUPPLIED BY DIGITAL.		    *
C* 									    *
C*									    *
C****************************************************************************
C
C
C Functional Description:
C
C    This module will dispatch to the appropriate volume mount and dismount
C    routines. 
C
C Author: Sharon Reynolds		Creation date:	15-Mar-1983
C
C Modified by:
C
C	V03-001	SAR004	Sharon Reynolds,	23-Mar-1983
C		Added volume output support.
C
C--

	Include 'src$:msghdr.for /nolist'
	Include 'src$:volmount.for /nolist'
	Include 'src$:syecom.for /nolist'

	Byte		Lun

	Character*1	Option

C
C	Determine if this is a 'mount' entry. If so, call the 
C	routine 'label' to save the error and I/O data for this device 
C	and media, then	call the routine 'mount' to record/output the 
C	device name and media information.
C
	If (volume_output) then
	
	If (emb$w_hd_entry .EQ. 64) then

	Call LABEL (1,emb$l_hd_sid,emb$b_vm_namlng,emb$t_vm_name,
	1 emb$w_vm_unit,emb$t_vm_label,emb$l_vm_oprcnt,emb$l_vm_errcnt)

	Call MOUNT (lun,option)

	Return 
C
C	Determine if this is a 'dismount' entry. If so, call the 
C	routine 'label' to update the error and I/O data for this device 
C	and media, then	call the routine 'dismount' to get the error and
C	I/O counts and to remove the device name and media information
C	from the mount list.
C
	ELSE if (emb$w_hd_entry .EQ. 65) then

	Call LABEL (2,emb$l_hd_sid,emb$b_vm_namlng,emb$t_vm_name,
	1 emb$w_vm_unit,emb$t_vm_label,emb$l_vm_oprcnt,emb$l_vm_errcnt)

	Call DISMOUNT (lun,option)

	Return 
	Endif

	Else		! Volume output
C
C	Don't output the volume mount/dismount entry but save of the 
C	information in the entry. This information will used later for
C	the summary report and to get the volume label for output
C	when a device error, device timeout, and device attention 
C 	entry is output.
C
	If (emb$w_hd_entry .eq. 64) then

	Call MOUNT_VOLUME (1,emb$l_hd_sid,emb$b_vm_namlng,emb$t_vm_name,
	1 emb$w_vm_unit,emb$t_vm_label,emb$l_vm_oprcnt,emb$l_vm_errcnt)

	Return


	Else if (emb$w_hd_entry .eq. 65) then

	Call DISMOUNT_VOLUME (2,emb$l_hd_sid,emb$b_vm_namlng,emb$t_vm_name,
	1 emb$w_vm_unit,emb$t_vm_label,field,field)

	Return 
	Endif

	Endif		! volume_output
	End	! Module
