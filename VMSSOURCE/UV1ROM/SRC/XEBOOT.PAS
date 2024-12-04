module xeboot;

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
{ FACILITY:
{
{	VAXELN
{
{ ABSTRACT:
{
{	This module contains a VAX DEUNA (UNIBUS/Ethernet) Controller
{	bootstrap driver.
{
{ AUTHOR:
{
{	Kris Barker 06-June-1983
{
{ VERSION:
{
{	V1.0-00
{
{-- }


include
	$datalink;
 
const

    { UNA controller parameters }

    una_addr_size   = 6;			{address size}
    una_type_size   = 2;			{protocol type size}
    una_header_size = (2 * una_addr_size) + una_type_size;
    una_crc_size    = 4;			{CRC size}

    xmt_ring_length = 1;
    rec_ring_length = 2;

    { Descriptor ownership states }

    port_driver = 0;
    deuna       = 1;

    { Port commands }

    noop        =  0;			{no operation}
    get_pcbb    =  1;			{get port control block address}
    get_command =  2;			{get command from pcb}
    self_test   =  3;			{self test}
    start       =  4;			{start controller}
    boot        =  5;			{initiate down-line load of ucode}
    poll_demand =  8;			{polling demand}
    stop        = 15;			{stop controller}


    { Port control functions }

    read_default_physical_address = 2;
    read_physical_address         = 4;
    write_physical_address        = 5;
    read_multicast_list           = 6;
    write_multicast_list          = 7;
    read_ring_format              = 8;
    write_ring_format             = 9;
    read_all_counters             = 10;
    read_clear_counters           = 11;
    read_mode                     = 12;
    write_mode                    = 13;

    { Processor register numbers }

    sid  = %x3e;		{system id register}
    iccs = %x18;		{interval clock control register}
    nicr = %x19;		{next interval count register}

    load_protocol_type = %x0160;
    xe_devtype         = 1;

    xe_base_physical     = %o774510;
    unibus_base_physical = %xfc0000;

    vax750 = 2;			{processor types}
    vax730 = 3;



type

    byte = 0..255;
    word = 0..65535;
    port_command_type = noop..stop;
    datalink_message  = datalink_data_message;
    unibus_address    = packed record
			case boolean of
			    true  : ( full : ^anytype );
			    false : ( low  : word;
				      high : 0..3 );
			end; { record }

    ring_entry_owner = port_driver..deuna;

    { UNA registers }

    csr0_register = [word] packed record
    	port_comm : port_command_type;	{command op}
    	rset	  : [pos(5)] boolean;	{reset}
    	inte	  : [pos(6)] boolean;	{interrupt enable}
    	intr	  : [pos(7)] boolean;	{interrupt summary}
    	usci	  : [pos(8)] boolean;	{unsolicited state change interrupt}
    	rcbi	  : [pos(10)] boolean;	{receive buffer unavailable interrupt}
    	dni	  : [pos(11)] boolean;	{done interrupt}
    	txi	  : [pos(12)] boolean;	{transmit ring interrupt}
    	rxi	  : [pos(13)] boolean;	{receive ring interrupt}
    	pcei	  : [pos(14)] boolean;	{port command error interrupt}
    	seri	  : [pos(15)] boolean;	{status error interrupt}
        end; { record }

    csr1_register = [word] packed record
    	state     : 0..7;		{state}
    	rmtc	  : [pos(3)] boolean;	{remote console reserved}
    	pcto	  : [pos(7)] boolean;	{port command timeout}
    	self_test : [pos(8)] 0..63;	{self test error code}
    	icab	  : [pos(14)] boolean;	{port/link cabling ok}
    	xpwr	  : [pos(15)] boolean;	{tranceiver power ok}
        end; { record }


    { UNA register layout }

    una_registers = packed record
      	csr0 : csr0_register;
       	csr1 : csr1_register;
       	csr2 : [word] word;
       	csr3 : [word] word
        end; { record }
		
    register_ptr = ^una_registers;


    { Structure of port control block - varies based on port control function }

    pcb_structure = packed record
	    case port_function : word of {port control function}

		read_default_physical_address,
		read_physical_address,
		write_physical_address :
			( address    : datalink_address );

	        read_multicast_list, write_multicast_list :
			( udbb_low1  : word;	{unibus data block base low}
	 	          udbb_high1 : 0..3;	{unibus data block base high}
			  mbz2       : 0..63;
			  mltlen     : byte );	{multicast address table len.}

	        read_ring_format, write_ring_format :
			( udbb_low2  : word;	{unibus data block base low}
	 	          udbb_high2 : 0..3 );	{unibus data block base high}

		read_mode, write_mode :
			( hdpx    : [pos(16)] boolean;	{half duplex mode}
			  fill1   : [pos(17)] 0..1;
			  loop    : [pos(18)] boolean;	{loopback mode}
			  dtrc    : [pos(19)] boolean;	{no CRC bytes wanted}
			  fill2	  : [pos(20)] 0..31;
			  dmnt	  : [pos(25)] boolean;	{disable maint. mess.}
			  fill3	  : [pos(26)] 0..1;
			  ect	  : [pos(27)] boolean;	{enable collision test}
			  tpad	  : [pos(28)] boolean;	{transmit pad enable}
			  drdc	  : [pos(29)] boolean;	{disable data chaining}
			  enal	  : [pos(30)] boolean;	{enable all multicast}
			  prom	  : [pos(31)] boolean );{promiscouos mode}
	    end; { record }


    { Structure of the UNIBUS data block - also varies with port function }

    udb_structure = packed record
	          tdrb_low  : word;	    {xmt ring address - low}
		  tdrb_high : 0..3;	    {xmt ring address - high}
		  mbz1      : 0..63;
		  telen	    : byte;	    {xmt entry length}
		  trlen     : word;	    {xmt ring length}
		  rdrb_low  : word;	    {rec ring address - low}
		  rdrb_high : 0..3;	    {rec ring address - high}
		  mbz2      : 0..63;
		  relen     : byte;	    {rec entry length}
		  rrlen     : word;
		  end; { record }

    { Ring descriptor entry formats }

    xmt_ring_descriptor = packed record
    	seg_length      : word;	 		{segment length}
    	seg_add_low     : word;		   	{low 16 bits - segment address}
    	seg_add_high    : 0..3;		    	{high 2 bits - segment address}
    	eop             : [pos(40)] boolean;   	{end of packet flag}
    	sop	        : [pos(41)] boolean;	{start of packet flag}
    	def             : [pos(42)] boolean;	{deferred}
    	one             : [pos(43)] boolean;	{one collision}
    	more            : [pos(44)] boolean;	{multiple retries needed}
    	mtch            : [pos(45)] boolean;	{station match}
    	errs            : [pos(46)] boolean;	{error summary}
    	own	        : [pos(47)] ring_entry_owner;     {ownership bit}
    	tdr	        : [pos(48)] 0..1023;	{tdr value}
    	rtry            : [pos(58)] boolean;	{retry}
    	lcar            : [pos(59)] boolean;	{loss of carrier}
    	lcol            : [pos(60)] boolean;	{late collision}
    	zero            : [pos(61)] boolean;	{zero}
    	ubto            : [pos(62)] boolean;	{unibus timeout}
    	bufl            : [pos(63)] boolean;	{buffer length error}
    	end; { record }

    rec_ring_descriptor = packed record
    	seg_length      : word;	 	    	{segment length}
    	seg_add_low     : word;		   	{low 16 bits - segment address}
    	seg_add_high    : 0..3;		    	{high 2 bits - segment address}
    	eop             : [pos(40)] boolean;   	{end of packet flag}
    	sop	        : boolean;		{start of packet flag}
    	zero1           : boolean;		{zero}
    	crc             : boolean;		{crc error}
    	oflo            : boolean;		{message overflow}
    	fram            : boolean;		{frame error}
    	errs            : boolean;		{error summary}
    	own	        : ring_entry_owner;    	{ownership bit}
    	mlen	        : 0..4095;	    	{message length}
    	zero2           : boolean;		{zero}
    	nchn            : boolean;		{no data chaining}
    	ubto            : boolean;		{unibus timeout}
    	bufl            : boolean;		{buffer length error}
    	end; { record }

    data_format(n:integer) = packed record
		        	length : word;
		        	data   : byte_data(n)
		             end; { record }


			
var

    { Controller mode flags }

    half_duplex_mode        : boolean := true;  {half duplex}
    loop_mode               : boolean := false;	{loop mode}
    xmt_crc_mode            : boolean := false;	{generate CRCs on transmits}
    disable_maint_mode      : boolean := false;	{disable maintenance messages}
    enable_coll_test_mode   : boolean := false;	{enable collision test}
    xmt_pad_mode            : boolean := true;	{pad short xmt messages}
    data_chain_disable_mode : boolean := true;  {no data chaining}
    all_multicast_mode      : boolean := false; {all multicasting enabled}
    promiscuous_mode        : boolean := false;	{promiscuous mode flag}

    una_reg             : register_ptr;		{UNA registers pointer}
    hardware_address    : datalink_address;
    load_server_address : datalink_address;

    { UNA communications structures }
    transmit_ring      : xmt_ring_descriptor;
    receive_ring       : array [0..rec_ring_length-1] of rec_ring_descriptor;
    receive_buffers    : array [0..rec_ring_length-1] of datalink_message;
    port_control_block : pcb_structure;
    unibus_data_block  : udb_structure;
    receive_index      : integer;		{index into receive ring}
    transmit_index     : integer;		{index into transmit ring}

    pcb_uba      : unibus_address;
    udb_uba      : unibus_address;
    xmt_ring_uba : unibus_address;
    rec_ring_uba : unibus_address;

    q : byte;




function net_init ( var devtype : integer; data_buffer: ^anytype): boolean;
{++
{
{ This procedure is called to initialize the UNA controller
{
{ Inputs:
{
{	None
{
{ Outputs:
{
{	devtype := una_devtype
{
{	controller started
{--}
type
    sid_reg = [long] packed record
		processor : [pos(24)] 0..255;
	      end; { record }

    map_registers = array [0..511] of integer;

var
    system_id_reg : sid_reg;
    map           : ^map_registers;
    map_number    : integer;
    csr           : csr0_register;
    xmt_index     : integer;
    rec_index     : integer;
    this_uba      : unibus_address;

begin

    { What kind of a processor are we? }

    system_id_reg :: integer := mfpr ( sid );
    if system_id_reg.processor = vax730 then
	map :: integer := %xf26800
    else
	map :: integer := %xf30800;

    { Validate all the UNIBUS map registers to map low memory }

    for map_number := 0 to 495 do
	map^[map_number] := map_number + %x80000000;
    for map_number := 496 to 511 do
	map^[map_number] := 0;


    { Get addresses for the communications structures }

    pcb_uba.full      := address ( port_control_block );
    udb_uba.full      := address ( unibus_data_block );
    xmt_ring_uba.full := address ( transmit_ring );
    rec_ring_uba.full := address ( receive_ring );


    { Set the address of the una registers }

    una_reg :: integer := xe_base_physical + unibus_base_physical;


    { Reset the controller and wait for the done bit }

    write_register ( una_reg^.csr0, rset := true );
    repeat
	csr := read_register ( una_reg^.csr0 );
    until csr.dni;
    clear_interrupt_bits;

    { Write pcb address to csr2 and csr3 of the una and issue get pcb command}

    write_register ( una_reg^.csr2, pcb_uba.low );
    write_register ( una_reg^.csr3, pcb_uba.high );
    issue_port_command ( get_pcbb );

    { Set the ring format in the unibus data block }

    with unibus_data_block do
	begin
	tdrb_low  := xmt_ring_uba.low;
	tdrb_high := xmt_ring_uba.high;
	mbz1      := 0;
	telen     := size (xmt_ring_descriptor) div 2;	{size in words}
	trlen     := xmt_ring_length;
	rdrb_low  := rec_ring_uba.low;
	rdrb_high := rec_ring_uba.high;
	mbz2      := 0;
	relen     := size (rec_ring_descriptor) div 2;	{size in words}
	rrlen     := rec_ring_length
	end; { with }

    { Do a write_ring_format command }

    port_control_block.port_function := write_ring_format;
    port_control_block.udbb_low2     := udb_uba.low;
    port_control_block.udbb_high2    := udb_uba.high;
    issue_port_command ( get_command );

    { Set up the transmit ring }

    with transmit_ring do
        begin
        own             := port_driver;		{owned by the driver}
        sop             := true;		{all messages fit in}
        eop             := true                     {one packet}
        end; { with }

    { And the receive ring }

    for rec_index := 0 to rec_ring_length-1 do
	with receive_ring[rec_index] do
	    begin 
	    this_uba.full   := address ( receive_buffers[rec_index] );
	    seg_length      := size(datalink_message);
	    seg_add_low     := this_uba.low;
	    seg_add_high    := this_uba.high;
	    own             := deuna;			{owned by the una}
	    end; { with }

    { Set up port control block to do a read default physical address command }

    port_control_block.port_function := read_default_physical_address;
    issue_port_command ( get_command );
    hardware_address := port_control_block.address;

    { Set the load server address to the load server multicast address }

    load_server_address := ''(171,00,00,01,00,00);


    { Set the mode }

    with port_control_block do
	begin
	port_function := write_mode;
	hdpx          := half_duplex_mode;
	fill1         := 0;
	loop          := loop_mode;
	dtrc          := xmt_crc_mode;
	fill2         := 0;
	dmnt	      := disable_maint_mode;
	fill3         := 0;
	ect           := enable_coll_test_mode;
	tpad          := xmt_pad_mode;
	drdc          := data_chain_disable_mode;
	enal          := all_multicast_mode;
	prom          := promiscuous_mode
	end; { with }

    issue_port_command ( get_command );

    { When the controller is restarted, the rings get reset }

    receive_index  := 0;
    transmit_index := 0;

    { Start the controller }

    issue_port_command ( start );
	
    devtype := xe_devtype;

    net_init := true;

end;



function net_receive ( var buff  : byte_data(buff_size);
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
{	Message received into caller's buffer
{--}
type
    int_count_csr = [long] packed record
			run : boolean;
			xfr : [pos(4)] boolean;
			sgl : [pos(5)] boolean;
			ie  : [pos(6)] boolean;
			int : [pos(7)] boolean;
			err : [pos(31)] boolean;
		     end; { record }

var
    count_control  : int_count_csr;
    source_address : datalink_address;
    protocol_type  : datalink_protocol_type;
    xlen           : integer;
    csr            : csr0_register;

begin


    { Wait for receive complete or timeout }

    mtpr ( nicr, -10*1000*1000 );	{10 seconds}
    mtpr ( iccs, %x80000091 );   	{clear err and int, set run and xfr}


    { Wait for buffer or timeout }

    with count_control do
    	repeat
	    count_control :: integer := mfpr ( iccs );
	    csr := read_register ( una_reg^.csr0 );
    	until csr.rxi or ( int and run );

    if csr.rxi then
	clear_interrupt_bits;

    { Buffer received? }
    if csr.rxi and ( receive_ring[receive_index].own = port_driver ) then
	begin

	source_address := receive_buffers[receive_index].source_address;
	protocol_type  := receive_buffers[receive_index].protocol_type;

	{ Check to make sure it's a load message and that it's from the
	  right source }

	if ( protocol_type = load_protocol_type ) and
	   ( odd(load_server_address::datalink_address_byte[1])
			 or (source_address = load_server_address) ) then
	    begin

	    { Extract the length and the message out of the data buffer }

	    with receive_buffers[receive_index] do
		begin
	        xlen := data :: data_format(1).length;
	        buff := data :: data_format(xlen).data;
		end; { with }

	    load_server_address := source_address;

	    end;

	{ Return the entry to the UNA and update the ring index }

	receive_ring[receive_index].own := deuna;
	receive_index := ( receive_index + 1 ) mod rec_ring_length;
	net_receive := true;

	end

    else

	net_receive := false;

end;



function net_transmit ( var buff  : byte_data(buff_size);
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

    xmt_buffer : datalink_message;
    this_uba   : unibus_address;
    csr        : csr0_register;

begin

    { Put the uba and message id and pointer into the transmit ring
      descriptor and turn over descriptor ownership to the una }

    this_uba.full := address ( xmt_buffer );

    with xmt_buffer do
	begin
	dest_address   := load_server_address;
	source_address := hardware_address;
	protocol_type  := load_protocol_type;
	data :: data_format(1).length := buff_size;
	data :: data_format(buff_size).data := buff
	end;

    with transmit_ring do
	begin
	seg_length      := buff_size + 2 + datalink_header_size;
	seg_add_low     := this_uba.low;
	seg_add_high    := this_uba.high;
        own             := deuna;
	end; { with }

    { Issue a poll command to get things going }

    issue_port_command ( poll_demand );

    { Wait for completion }

    repeat
	csr := read_register ( una_reg^.csr0 );
    until csr.txi or csr.usci or csr.seri;
    clear_interrupt_bits;

    { Set the return status }

    if transmit_ring.errs then
	net_transmit := false
    else
	net_transmit := true;

end;



procedure issue_port_command ( port_command : port_command_type );
{++
{
{ This procedure will issue a port command command and wait until it has
{ completed
{
{ Inputs:
{
{	Port_command specifies the port command to be issued
{
{ Outputs:
{
{	Port control block or Unibus data block may have results based
{       on what command is issued
{
{--}
var
    csr0 : csr0_register;

begin

    { Issue the command }

    write_register ( una_reg^.csr0, port_comm := port_command );

    { Wait for completion }

    repeat
	csr0 := read_register ( una_reg^.csr0 );
    until csr0.dni;
    
    q := 0;

    clear_interrupt_bits;

end;



procedure clear_interrupt_bits;
{++
{
{ This procedure will clear all of the una CSR0 interrupt bits
{
{--}
begin

    write_register ( una_reg^.csr0, usci := true,
				    rcbi := true,
				    dni  := true,
				    rxi  := true,
				    txi  := true,
				    pcei := true,
				    seri := true );
end;

end;
