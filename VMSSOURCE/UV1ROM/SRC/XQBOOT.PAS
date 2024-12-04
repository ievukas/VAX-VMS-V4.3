module xqboot;

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
{
{ FACILITY:
{
{	VAXELN and MicroVAX
{
{ ABSTRACT:
{
{	This module contains a VAX QNA (QBUS/Ethernet) Controller
{	bootstrap driver.
{
{ AUTHOR:
{
{	Kris Barker 25-October-1983
{
{ VERSION:
{
{	V1.0-00
{
{ REVISED:
{
{	23-May-1984	Kris K. Barker	    1) Changed polling routines to
{	V1.0-01				       check for error/use bits in
{					       status word rather than flag
{					       word to fix extern. loopback
{					       and down-line load failures.
{					    2) Fixed zeroing of status word
{					       to fix 3rd LED shut-off problem.
{					    3) Added net_stop routine to shut
{					       QNA off after down-line loading.
{
{--}



include
	$datalink;
 
const

    { qna controller parameters }

    qna_addr_size   = 6;			{address size}
    qna_type_size   = 2;			{protocol type size}
    qna_header_size = (2 * qna_addr_size) + qna_type_size;
    qna_crc_size    = 4;			{CRC size}

    xmt_list_length = 1;		{number of transmit ring descriptors}
    rec_list_length = 4;		{number of receive ring descriptors}
    setup_packet_size = %o200;

    xq_devtype = 1;


    { Values for use bits in descriptor flag word }

    _last_noerr = 0;		{last segment of message with no errors}
    _last_werr  = 1;		{last segment of message with errors}
    _not_using  = 2;		{qna is not yet using this descriptor}
    _using      = 3;		{qna using or used and not last segment}

    { LED values (occur in bit positions 2-4) }

    mode_base = 0;	{no multicasting, no promiscuous mode, timer=0}
    led_nop   = 0;	{no effect}
    led1_out  = 1*4;	{LED 1 off to indicate self test running}
    led2_out  = 2*4;	{LED 2 off to indicate internal loopback passed}
    led3_out  = 3*4;	{LED 3 off to indicate external loopback passed}

    load_protocol_type = %x160;	{DECnet MOP load protocol type}

    max_wait_count     = 150000;  {max loop count for receive/transmit wait}
    delay_count        = 500;	  {delay count for resetting interface}

    xq_base_physical     = %o014440;
    qbus_base_physical = %x20000000;



type

    byte = 0..255;
    word = 0..65535;
    signed = -32768..32767;
    nibble = 0..%xF;

    datalink_message = datalink_data_message;

    bit_array = [word] packed record
	case boolean of
	    true  : ( bits : packed array [0..15] of boolean );
	    false : ( hex : packed array [0..3] of nibble );
	end;

    data_format(n:integer) = packed record
		        	length : word;
		        	data   : string(n)
		             end; { record }

    { A physical address }
    phy_address_high = 0..63;
    phy_address = [long] packed record
	case integer of
	    0 : ( ptr  : ^anytype );
	    1 : ( full : integer );
	    2 : ( low  : word;
		  high : phy_address_high );
	    3 : ( fl   : word;
		  fh   : word )
	end; { record }


    { QNA csr register }

    csr_register = [word] packed record
	rx_ena      : boolean;		{receiver enable}
    	rset	    : boolean;		{reset}
	nxm_int     : boolean;		{non-existant memory interrupt}
	boot_diag   : boolean;		{boot diagnostic rom}
	tx_invalid  : boolean;		{transmit list invalid}
	rx_invalid  : boolean;    	{receive list invalid}
	inte	    : boolean;		{interrupt enable}
    	txi	    : boolean;		{transmit interrupt request}
	iloop       : boolean;		{internal loopback - set is disabled}
	eloop       : boolean;		{external loopback}
	stimer_ena  : boolean;		{sanity timer enable}
	transceiver : [pos(12)] boolean;{power is being supplied}
	carrier     : boolean;		{sample of carrier sense signal}
    	rxi	    : [pos(15)] boolean;{receive interrupt request}
        end; { record }

    { QNA register layout }

    word_reg = [word] packed record
	qbus_word : word;
	end;

    qna_registers = packed record
	case boolean of
	    true  : ( station_address   : array [1..6] of word_reg );
	    false : ( rx_desc_list_low  : [pos(32),word] word;
		      rx_desc_list_high : [word] word;
		      tx_desc_list_low  : [word] word;
		      tx_desc_list_high : [word] word;
	  	      vector_address    : [word] word;
		      csr               : csr_register );
        end; { record }
		
    register_ptr = ^qna_registers;


    { Setup descriptor format }

    one_line = packed record
	addr_byte : [pos(8)] packed array [1..7] of byte;
	end;

    setup_half = [aligned(2)] packed record
	addresses : packed array [1..6] of one_line;
	zeros     : packed array [1..2] of one_line
	end;

    setup_descriptor = packed array [1..2] of setup_half;


    { Descriptor format }

    descriptor = packed record
	use_status  : [pos(14)] _last_noerr.._using;	{flag word}
	bufadr_high : phy_address_high;		{high order address}
	hbo_beg     : boolean;
	lbo_term    : boolean;

	setup       : [pos(16+12)] boolean;
	end_of_mess : boolean;			{buffer is last in message}
	chain_addr  : boolean;			{address is chain address}
	valid       : boolean;			{valid bit}

	bufadr_low  : word;			{low order buffer address}
	buffer_size : signed;			{length of the message}
	status      : status_words;		{two status words}
	end; { record }

    transmit_list_array = array [0..xmt_list_length] of descriptor;
    receive_list_array  = array [0..rec_list_length] of descriptor;

    status_words = [long] packed record
	case integer of
	    0 :     ( whole_thing : integer );

	    1 : { status for transmit descriptors }
		    ( count   : [pos(4)] 0..15;	{collision count}
		      fail    : boolean;	{no collision pulse}
		      abort   : boolean;	{transmission aborted}
		      ste16   : boolean;	{default sanity timer on}
		      nocar   : boolean;	{no carrier}
		      loss    : boolean;	{carrier loss during xmt}
		      tx_use  : [pos(14)] _last_noerr.._using; {use status}
		      tdr     : 0..%x3fff);	{time domain reflectometry}
	    2 : { status for receive descriptors }
		    ( ovf     : boolean;	{overflow}
		      crcerr  : boolean;	{crc error}
		      frame   : boolean;	{framing alignment error}
		      short   : boolean;	{short packet}

		      rbl_hi  : [pos(8)] 0..7;	{bits 8-10 of rx byte length}
		      runt    : boolean;	{packed could not be flushed}
		      discard : boolean;	{packet discarded}
		      esetup  : boolean;	{eloop/setup packet}
		      rx_use  : [pos(14)] _last_noerr.._using;	{use status}
		      rbl_low : byte)		{high bits of byte length}
	end; { record }

    { Mode bits }

    mode_flag = packed record
	case boolean of
	    true  : ( full : integer );
	    false : ( multicast    : boolean;
		      promiscuous  : boolean;	{promiscuous mode}
		      led_value    : 0..3;	{LED value}
		      sanity_timer : 0..7)	{sanity timer in 1/4 sec.}
	end; { record }

    qna_boot_structure = record
	transmit_list      : transmit_list_array;
	xmt_list_address   : phy_address;
	receive_list       : receive_list_array;
	rec_list_address   : phy_address;

	hardware_address    : datalink_address; {current system address}
	load_server_address : datalink_address;	{address of load server}

	transmit_buffer    : datalink_message;
	xmt_buffer_address : phy_address;
	receive_buffer     : array [0..rec_list_length-1] of datalink_message;
	rec_buffer_address : array [0..rec_list_length-1] of phy_address;

	address_control_packet : setup_descriptor;	{setup packet}
	setup_packet_physical  : phy_address;	{address of setup packet}
	end;

qna_structure_pointer = ^qna_boot_structure;



			
var

    qna_ptr        : qna_structure_pointer;
    qna_reg        : register_ptr;		{qna registers pointer}
    receive_index  : integer;




function net_init ( var devtype      : integer;
	            xptr             : ^anytype ) : boolean;
{++
{
{ This procedure is called to initialize the QNA controller
{
{ Inputs:
{
{	xptr = pointer to some usable memory
{
{ Outputs:
{
{	devtype = qna device type
{
{	controller initialized
{
{--}
type
    station_addr = [word] packed record
	case boolean of
	    true  : ( full : word_reg );
	    false : ( address_byte : [byte] byte );
	end; { record }

var
    pa_byte : station_addr;
    i       : integer;
    xmt_index : integer;
    rec_index : integer;
    six_bytes : integer;
    status    : boolean;


begin


    { Save the location of the available memory }

    qna_ptr := xptr;
    qna_ptr^ := zero;

    { Initialize the register and vector addresses }

    qna_reg :: integer := xq_base_physical + qbus_base_physical;

    { Initialize the controller: toggle the reset bit and boot
      diagnostic bit to reset the controller and turn on the LEDs }

    write_register ( qna_reg^.csr, rset := true );
    write_register ( qna_reg^.csr, rset := false );
    delay;
    write_register ( qna_reg^.csr, boot_diag := true );
    delay;
    write_register ( qna_reg^.csr, boot_diag := false );
    receive_index := 0;

    { Get the descriptor lists, buffers, and setup packet addresses }

    with qna_ptr^ do
	begin
	xmt_list_address.ptr      := address ( transmit_list );
	rec_list_address.ptr      := address ( receive_list );
	xmt_buffer_address.ptr    := address ( transmit_buffer );
	setup_packet_physical.ptr := address(address_control_packet);

        { Initialize the setup frame }

	for six_bytes := 1 to 6 do
            begin
            pa_byte.full := read_register (qna_reg^.station_address[six_bytes] );
            hardware_address::datalink_address_byte[six_bytes] :=
					pa_byte.address_byte;
            end;

	{ Put the addresses into the setup descriptor }

        update_multicast_addresses;

       { Set up the transmit descriptor list }
        for i := 0 to xmt_list_length do
	    with transmit_list[i] do
	        begin
		    use_status    := _not_using;
		    chain_addr    := false;
		    valid         := false;
	        end;


        { And the receive descriptor list }

	for rec_index := 0 to rec_list_length-1 do
	    begin
            rec_buffer_address[rec_index].ptr := 
				address ( receive_buffer[rec_index] );
	    with receive_list[rec_index] do
	        begin
	        use_status  := _not_using;
	        bufadr_high := rec_buffer_address[rec_index].high;
	        bufadr_low  := rec_buffer_address[rec_index].low;
	        buffer_size := -((size(datalink_message)+1) div 2);
	        chain_addr  := false;
	        valid       := true;
		status      := zero;
	        end;
	    end;

        { Last entry is to chain }

	with receive_list[rec_list_length] do
	    begin
	    chain_addr := true;
	    use_status := _not_using;
	    valid      := true;
	    bufadr_high := rec_list_address.high;
	    bufadr_low  := rec_list_address.low;
	    end;

        { Pass the descriptor address to the controller }
        write_register ( qna_reg^.rx_desc_list_low, rec_list_address.low );
        write_register ( qna_reg^.rx_desc_list_high, rec_list_address.high );


        { Set the load server address to the load server multicast address }

        load_server_address := ''(171,00,00,01,00,00);

	end; { with qna_ptr^ }

    { Start the good citizen tests }

    net_init := false;

    { LED #1 out indicates start of test }

    status := set_mode ( led1_out );

    { Set up the transmit buffer for the tests }

    with qna_ptr^.transmit_buffer do
	begin
	dest_address := qna_ptr^.hardware_address;
	source_address := zero;
	protocol_type  := %x6000;
	for i := 1 to datalink_max_packet_size do
	    data[i] := i mod 512;
	end;

    { Run the internal loopback test }

    status := loopback_test ( true );

    { If ok, then turn out the 2nd LED and run the external test }

    if status then
	begin
        status := set_mode ( led2_out );
        status := loopback_test ( false );

	{ If ok, turn out LED #3 and set the return status to true }

        if status then
	    begin
	    status := set_mode ( led3_out );
            reset_for_normal_operations;
            devtype := xq_devtype;
	    net_init := true;
	    end

	end;

end;



procedure net_stop;
{++
{
{ This procedure is called following the down-line load to turn off the
{ QNA
{
{--}

begin

    { Simply set the reset bit }

    write_register ( qna_reg^.csr, rset := true );

end;



procedure reset_for_normal_operations;
{++
{
{ This procedure resets the device either following the initialization tests
{ or after a receive or transmit timeout.
{
{--}

begin

    { Reset the device }

    write_register ( qna_reg^.csr, rset := true );
    delay;
    write_register ( qna_reg^.csr, rset   := false );
    delay;
    write_register ( qna_reg^.csr, rx_ena := true,
				   iloop  := true,
				   eloop  := false );

    { Pass the descriptor address to the controller }

    receive_index := 0;
    write_register (qna_reg^.rx_desc_list_low,qna_ptr^.rec_list_address.low);
    write_register (qna_reg^.rx_desc_list_high,qna_ptr^.rec_list_address.high);

end;



procedure load_transmit_descriptor ( msize : integer;
				     buffer_address : phy_address;
				     setup_packet   : boolean );
{++
{
{ This function will load the transmit descriptor
{
{ Inputs:
{
{	msize specifies the size of the message
{	buffer_address is the physical address of the buffer
{	setup_packet is true if the buffer is a setup packet
{
{ Outputs:
{
{	Transmit descriptor initialized
{
{--}
begin

    with qna_ptr^, qna_ptr^.transmit_list[0] do
	begin
	use_status  := _not_using;
	hbo_beg     := false;
	lbo_term    := odd(msize);
	buffer_size := -((msize+1) div 2);
	bufadr_high := buffer_address.high;
	bufadr_low  := buffer_address.low;
	end_of_mess := true;
	valid       := true;
	setup       := setup_packet;
	end;

end;




function start_transmission : boolean;
{++
{
{ This function will write the transmit descriptor address to the qna
{ and wait for the qna to transmit the packet and receive the looped
{ response (called by the loopback routine and the set_mode routine).
{
{ Inputs:
{
{	none
{
{ Outputs:
{
{	function returns the value of the csr on return
{
{--}
var
    time_count : integer;

begin

    { Write the descriptor address }
    write_register (qna_reg^.tx_desc_list_low,qna_ptr^.xmt_list_address.low);
    write_register (qna_reg^.tx_desc_list_high,qna_ptr^.xmt_list_address.high);

    { Wait for completion }

    time_count := 0;
    repeat
	time_count := time_count+1;
    until (qna_ptr^.receive_list[receive_index].status.whole_thing<>0) or
	  (time_count > max_wait_count);

    start_transmission := time_count < max_wait_count;

end;



function internal_loop : boolean;
{++
{
{ This function handles the special case of internal loopback
{
{--}

var
    time_count : integer;
    csr        : csr_register;

begin

    { Write the descriptor address }

    write_register (qna_reg^.tx_desc_list_low,
			qna_ptr^.xmt_list_address.low);
    write_register (qna_reg^.tx_desc_list_high,
			qna_ptr^.xmt_list_address.high);

    { Wait for the transmit interrupt bit }

    time_count := 0;
    repeat
        csr:= read_register ( qna_reg^.csr );
        time_count := time_count+1;
        nop;
    until (csr.txi) or (time_count > max_wait_count);

    { Clear the transmit bit and enable the receiver }

    write_register ( qna_reg^.csr, txi    := true,
    			           iloop  := false,
				   rx_ena := true );

    { Now wait for the receive to complete }

    time_count := 0;
    repeat
	time_count := time_count+1;
	nop;
    until (qna_ptr^.receive_list[receive_index].status.whole_thing<>0) or
	  (time_count > max_wait_count);

    internal_loop := time_count < max_wait_count;

end;



function loopback_test ( internal : boolean ) : boolean;
{++
{
{ This function will perform the indicated kind of loopback test (either
{ internal or external) and return the results of the test.
{
{ Inputs:
{
{       internal is true for internal loopback test
{
{ Outputs:
{
{	function returns true if test passed
{
{--}
var

    status     : boolean;
    time_count : integer;
    msize      : integer;

begin

    { Set the proper value in the csr }

    write_register ( qna_reg^.csr, iloop  := not internal,
				   eloop  := not internal,
				   rx_ena := false );

				   
    { Write the descriptor address to start the transmission }

    qna_ptr^.receive_buffer[receive_index] := zero;

    if internal then
	msize := 6
    else
	msize := size(datalink_message);

    load_transmit_descriptor ( msize, qna_ptr^.xmt_buffer_address, false );

    if internal then
	status := internal_loop
    else
        status := start_transmission;

    if status then
	begin
	qna_ptr^.receive_list[receive_index].use_status := _not_using;
        if qna_ptr^.receive_buffer[receive_index]::string(msize) =
	                         qna_ptr^.transmit_buffer::string(msize) then
	    loopback_test := true
	else
	    loopback_test := false;
	qna_ptr^.receive_list[receive_index].status := zero;
        receive_index := ( receive_index + 1 ) mod rec_list_length;
	end
    else
	loopback_test := false;

end;



function net_receive ( var buff  : string(buff_size);
                       buff_size : word ) : boolean;

{++
{
{ This function is called to receive a message
{
{ Inputs:
{
{	buff = buffer to receive message
{	buff_size = buffer size
{
{ Outputs:
{
{	Message received into callers' buffer
{
{--}

var
    source_address : datalink_address;
    dest_address   : datalink_address;
    protocol_type  : datalink_protocol_type;
    xlen           : integer;
    done           : boolean;
    timecount      : integer;
    status         : boolean;

begin

    done := false;
    timecount := 0;

    while not done do
        begin
        repeat
	    timecount := timecount + 1;
	    nop;
        until (qna_ptr^.receive_list[receive_index].status.whole_thing<>0) or
	      (timecount > max_wait_count);

	status := timecount < max_wait_count;

        { Clear the interrupt bits }
	write_register ( qna_reg^.csr, rxi     := true,
				       nxm_int := true,
				       rx_ena  := true,
				       iloop   := true );

	with qna_ptr^ do
	    begin

            net_receive := false;

	    if status and not receive_list[receive_index].status.discard then
		begin
                source_address := receive_buffer[receive_index].source_address;
                protocol_type  := receive_buffer[receive_index].protocol_type;

                if ( protocol_type = load_protocol_type ) and
	           ( odd(load_server_address::datalink_address_byte[1])
			 or (source_address = load_server_address) ) then
                    begin

	            { Extract length and message out of the data buffer }

	            with receive_buffer[receive_index] do
	                begin
	                xlen := data :: data_format(1).length;
	                buff := data :: data_format(xlen).data;
	                end; { with }

	            load_server_address := source_address;
	            done := true;
	            net_receive := true;
	            end;
		end
	    else
		with receive_list[receive_index].status do
		    if not status or (crcerr and discard and not runt) then
			done := true;

	    end; { with }

        { Now update the receive list index }

        if status then
	    begin
	    qna_ptr^.receive_list[receive_index].use_status := _not_using;
	    qna_ptr^.receive_list[receive_index].status := zero;
	    receive_index := (receive_index+1) mod rec_list_length;
	    end;

        end; { while }


end;



function net_transmit ( var buff  : string(buff_size);
                        buff_size : word ) : boolean;

{++
{
{ This function is called to transmit a message
{
{ Inputs:
{
{	buff = buffer
{	buff_size = buffer size
{
{ Outputs:
{
{	buffer transmitted
{--}
var
    csr        : csr_register;
    msize      : integer;
    timecount  : integer;

begin

    with qna_ptr^ do
	begin

	with transmit_buffer do
	    begin
	    dest_address   := load_server_address;
	    source_address := hardware_address;
	    protocol_type  := load_protocol_type;
	    data :: data_format(1).length := buff_size;
	    data :: data_format(buff_size).data := buff
	    end; { with }

	{ Load the transmit descriptor }

	msize       := buff_size + datalink_header_size + 2;
	if msize < datalink_min_packet_size then
	        msize := datalink_min_packet_size;
	load_transmit_descriptor ( msize, xmt_buffer_address, false );

	{ Write the descriptor address to start the transmission }

	write_register ( qna_reg^.tx_desc_list_low, xmt_list_address.low );
	write_register ( qna_reg^.tx_desc_list_high, xmt_list_address.high );
    
	end; { with }

    { Wait for completion }

    timecount := 0;
    repeat
	csr := read_register ( qna_reg^.csr );
	timecount := timecount + 1;
	nop;
    until csr.txi or ( timecount > max_wait_count );
    write_register ( qna_reg^.csr, txi := true,
				   nxm_int := true,
				   rx_ena  := true,
				   iloop   := true );

    { Set the return status.  If the transmit timed out, reset the device }

    if ( csr.nxm_int ) or ( not csr.txi ) or
       ( qna_ptr^.transmit_list[0].status.tx_use = _last_werr ) then
	net_transmit := false
    else
	net_transmit := true;

end;



procedure update_multicast_addresses;
{++
{
{ This procedure takes the current saved multicast address list and uses
{ it to fill the setup descriptor.
{
{ Inputs:
{
{	multicast address save list
{
{ Outputs:
{
{	updated setup descriptor
{
{ The address control packet looks like:
{
{                          0   1   2   3   4   5   6   7
{                        +-------------------------------+
{                  0     | 0 | P | B | M | M | M | M | M |
{                        +   + H + R + U + U + U + U + U +
{                 10     | 0 | Y | O | L | L | L | L | L |
{                        +   + S + A + T + T + T + T + T +
{                 20     | 0 | I | D | I | I | I | I | I |
{                        +   + C + C + C + C + C + C + C +
{                 30     | 0 | A | A | A | A | A | A | A |
{                        +   + L + S + S + S + S + S + S +
{                 40     | 0 |   | T | T | T | T | T | T |
{                        +   +   +   +   +   +   +   +   +
{                 50     | 0 |ADR|ADR| 1 | 2 | 3 | 4 | 5 |
{			 |   +---+---+---+---+---+---+---|   
{                 60     | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
{                        +   +   +   +   +   +   +   +   +
{                 70     | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
{			 +   +---+---+---+---+---+---+---+
{                100     | 0 | M | M | M | M | M | M | M |
{                        +   + U + U + U + U + U + U + U +
{                110     | 0 | L | L | L | L | L | L | L |
{                        +   + T + T + T + T + T + T + T +
{                120     | 0 | I | I | I | I | I | I | I |
{                        +   + C + C + C + C + C + C + C +
{                130     | 0 | A | A | A | A | A | A | A |
{                        +   + S + S + S + S + S + S + S +
{                140     | 0 | T | T | T | T | T | T | T |
{                        +   +   +   +   +   +   +   +   +
{                150     | 0 | 6 | 7 | 8 | 9 | 10| 11| 12|
{			 +   +---+---+---+---+---+---+---+
{                160     | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
{                        +   +   +   +   +   +   +   +   +
{                170     | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
{                        +-------------------------------+
{--}
var
    i,j,k    : integer;

begin

    { Load all addresses as the hardware address }

    with qna_ptr^ do
	for i := 1 to 2 do
	    for j := 1 to 6 do
	        for k := 1 to 7 do
		    address_control_packet[i].addresses[j].addr_byte[k] :=
				hardware_address::datalink_address_byte[j];

end;



function set_mode ( led_value_mode : integer ) : boolean;
{++
{
{ This procedure will write the mode to the qna
{
{ Inputs  : Current mode flags are used to set the mode
{
{ Outputs : Controller mode set
{
{--}
var
    mode_multiplier : integer;
    tsize           : integer;
    time_count      : integer;

begin

    { Load the transmit descriptor }

    mode_multiplier := mode_base + led_value_mode;
    load_transmit_descriptor ( (setup_packet_size+mode_multiplier),
			       qna_ptr^.setup_packet_physical,
			       true );

    { Wait for completion }

    set_mode := true;
    if start_transmission then
	begin
	qna_ptr^.receive_list[receive_index].use_status := _not_using;
	qna_ptr^.receive_list[receive_index].status := zero;
        receive_index := ( receive_index + 1 ) mod rec_list_length;
        if qna_ptr^.transmit_list[0].status.tx_use = _last_werr then
	    set_mode := false;
	end
    else
        set_mode := false;

end;



procedure delay;

var

    i : integer;

begin

    for i := 1 to delay_count do
	nop

end;


procedure nop;
begin
end;


end; { module xqboot }

