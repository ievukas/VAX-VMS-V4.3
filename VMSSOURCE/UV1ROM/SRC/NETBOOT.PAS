module netboot;

{****************************************************************************
{*									    *
{*  Copyright (c) 1984							    *
{*  by DIGITAL Equipment Corporation, Maynard, Mass.			    *
{* 									    *
{*  This software is furnished under a license and may be used and  copied  *
{*  only  in  accordance  with  the  terms  of  such  license and with the  *
{*  inclusion of the above copyright notice.  This software or  any  other  *
{*  copies  thereof may not be provided or otherwise made available to any  *
{*  other person.  No title to and ownership of  the  software  is  hereby  *
{*  transferred.							    *
{* 									    *
{*  The information in this software is subject to change  without  notice  *
{*  and  should  not  be  construed  as  a commitment by DIGITAL Equipment  *
{*  Corporation.							    *
{* 									    *
{*  DIGITAL assumes no responsibility for the use or  reliability  of  its  *
{*  software on equipment which is not supplied by DIGITAL.		    *
{*									    *
{****************************************************************************
{

{++
* FACILITY:
*
*	VAXELN and MicroVAX I
*
* ABSTRACT:
*
*	This module contains a network primary bootstrap.  It handles the
*	DNA Low-level Maintenance Protocol (MOP) messages to down-line
*	load a VAX processor with a system memory image.
*
* AUTHOR:
*
*	Len Kawell, 19-Nov-1981
*
*	V1.0-01	Len Kawell	23-May-1984
*		Call a new driver entry point to stop the device when the
*		load is complete.  This makes sure that the device does not
*		continue receiving messages once the O/S is loaded.
--}

include
	$datalink;

const
	memload_code 		= 2;		{ Memory load without xfer addr }
	request_program_code 	= 8;		{ Request program }
	request_load_code	= 10;		{ Request memory load }
	parameters_code 	= 20;		{ Paramters with xfer addr }

	opsys_pgmtype 		= 2;		{ Operating system program type }

	transfer_parameter 	= 0;		{ Transfer address parameter }
	node_name_parameter	= 1;		{ Node name parameter }
	node_address_parameter	= 2;		{ Node address parameter }
	host_name_parameter	= 3;		{ Host name parameter }
	host_address_parameter	= 4;		{ Host address parameter }
	
	maximum_retries		= 8;		{ Maximum retries }

	ss$_normal		= 1;		{ Success }
	ss$_bufferovf		= %x600;	{ Buffer overflow error }
	ss$_ctrlerr		= %x54;		{ Device controller error }
	ss$_devinact		= %x20d4;	{ Device initialization error }
	ss$_nosuchnode		= %x28c;	{ No respose from load server }

type
	byte = 0..255;				{ Byte }
	word = 0..65535;			{ Word }
	buffer = array[0..255] of char;		{ I/O buffer }

	xmtmsg = packed record 			{ Transmit message format}
		code: byte;			{  Code }
	    	    case byte of
			request_program_code: (
				devtype: byte;	{  Device type }
				mopver: byte;	{  MOP version }
				pgmtype: byte;	{  Program type }
				);
			request_load_code: (
				loadnum: byte;	{  Load number }
				error: byte;	{  Error flag }
				);
		end;

	rcvmsg = packed record			{ Receive message format}
		code: byte;			{  Code }
		loadnum: byte;			{  Load number }
	    	    case byte of

			memload_code: (		{  Memory load }
				loadaddr: ^buffer; {  Load address }
				image: buffer;	{  Image data }
				);

			parameters_code: (	{  Parameters }
				param: packed array[1..255] of char;
				);
		end;
			
	bitmap = packed array[0..8192] of boolean; { PFN bitmap }

function net_init(var devtype: integer; data_buffer: ^anytype):boolean;
external;

function net_transmit(var buff: byte_data(buff_size); buff_size: word): boolean;
external;

function net_receive(var buff: byte_data(buff_size); buff_size: word): boolean;
external;

procedure net_stop;
external;


function boo$downline_load(load_address: integer;
			   data_buffer: ^anytype;
			   pfn_bitmap: ^bitmap;
			    var transfer_address: integer;
			    var node_address: datalink_address;
			    var node_name: varying_string(6)): integer;
{++
{ boo$downline_load - Downline load a system image
{
{ Inputs:
{
{	load_address - Starting physical load address
{	data_buffer - Pointer to an 8KB buffer for use by the load driver
{	pfn_bitmap - Pointer to the Page Frame Number bitmap
{
{ Outputs:
{
{	transfer_address - Received transfer address
{	node_address - Received node address
{	node_name - Received node name
{
{	Function value -
{			ss$_normal - Downline load completed successfully
{
{			ss$_bufferovf - Load buffer overflow (ie. PFN invalid)
{			ss$_devinact - Device initialization error
{			ss$_ctrlerr - Device I/O error
{			ss$_nosuchnode - No response from a load server
{--}
var
	status: boolean;
	retries: integer := maximum_retries;
	request_opsys: boolean := true;
	current_loadnum: integer := 0;
	current_devtype: integer;
	xmtbuff: xmtmsg;
	rcvbuff: rcvmsg;
	pi: integer;
begin

rcvbuff.code := 0;

{ Initialize the driver }

if not net_init(current_devtype, data_buffer)
then
	begin
	boo$downline_load := ss$_devinact;
	goto return;
	end;

repeat

	{ Create a Request Program or Request Load message }

	if request_opsys
	then
		begin
		xmtbuff.code := request_program_code;
		xmtbuff.devtype := current_devtype;
		xmtbuff.mopver := 1;
		xmtbuff.pgmtype := opsys_pgmtype;
		end
	else
		begin
		xmtbuff.code := request_load_code;
		xmtbuff.loadnum := current_loadnum;
		xmtbuff.error := 0;
		end;

	{ Transmit the message and retry if it fails. }

	while not net_transmit(xmtbuff, size(xmtbuff)) do
		begin
		retries := retries - 1;
		if retries <= 0 
		then 
			begin
			boo$downline_load := ss$_ctrlerr;
			goto return;
			end;
		end;

	{ If last message received was a Parameters message, then load done }

	if rcvbuff.code = parameters_code
	then
		goto done;

	{ Receive a response message }

	status := net_receive(rcvbuff, size(rcvbuff));

	{ If a message successfully received and it is either a Memory Load }
	{ or a Parameters message, process it. }

	if status and
	   ((rcvbuff.code = memload_code) or
	    (rcvbuff.code = parameters_code))
	then
		begin
		if (rcvbuff.loadnum = current_loadnum) 
		or (rcvbuff.loadnum = 0)
		then
			begin
			current_loadnum := (rcvbuff.loadnum + 1) mod 256;

			{ If memory data, then move to proper memory location }

			if rcvbuff.code = memload_code
			then
				begin

				{ Compute memory location for data and check }
				{ that page is valid in page frame bitmap. }

				rcvbuff.loadaddr::integer := 
				      rcvbuff.loadaddr::integer + load_address;

				if not pfn_bitmap^
					[rcvbuff.loadaddr::integer div 512]
				then
					begin
					boo$downline_load := ss$_bufferovf;
					goto return;
					end;

				rcvbuff.loadaddr^ := rcvbuff.image;
				end;
			end;
		request_opsys := false;
		end
	else
		begin

		{ Decrement the retry count.  If it is zero quit. }

		retries := retries - 1;
		if retries <= 0 
		then 
			begin

			{ Return device error status.  If no reponse was ever }
			{ received from a load server, return no response }
			{ from server status. }

			boo$downline_load := ss$_ctrlerr;
			if request_opsys
			then
				boo$downline_load := ss$_nosuchnode;
			goto return;
			end;
		end
until false;
	
done:

{ Get the load parameters }

pi := 1;
transfer_address := -1;
node_name := '';

with rcvbuff do
	repeat

	{ Scan parameter list for parameters. }

	case ord(param[pi]) of

	node_name_parameter:
		node_name := substr(param, pi + 2, ord(param[pi + 1]));

	node_address_parameter:
		begin

		{ If only a 2 byte node address sent, pad it using the }
		{ DECnet Ethernet high-order address. }

		if ord(param[pi + 1]) > 2
		then
			node_address := 
				substr(param, pi + 2, size(node_address))
		else
			begin
			node_address := ''(170,00,04,00,00,00,00,00);
			substr(node_address, 5, 2) := substr(param, pi + 2, 2);
			end;

		{ If the node address does not have an area address, set }
		{ it to area 1. }

		if ord(substr(node_address, 6, 1)) < 4
		then
			substr(node_address, 6, 1) := 
				chr(ord(substr(node_address, 6, 1)) + 4);
		end;

	transfer_parameter:

		transfer_address := substr(param, pi + 1, 4)::integer;
	end;

	pi := pi + ord(param[pi + 1]) + 2;
	
	until transfer_address >= 0;

boo$downline_load := ss$_normal;

return:

{ Make sure the device is stopped }

net_stop;

end;

end;
