`include "../include/tune.v"

// PentEvo project (c) NedoPC 2008-2011
//
// generates horizontal sync, blank and video start strobe, horizontal window
//
// =\                  /=========||...
// ==\                /==========||...
// ====---     -------===========||...
//    |  \   / |      |
//    |   ---  |      |
//    |  |   | |      |
//    0  t1  | t3     t4
//           t2
// at 0, video ends and blank begins
//    t1 = 10 clocks (@7MHz), sync begins
// t2-t1 = 33 clocks
// t3-t2 = 41 clocks, then video starts
//
// repetition period = 448 clocks
//
// refactored by TS-Labs

module video_sync_h(

	input  wire        clk,

	input  wire        init, // one-pulse strobe read at cend==1, initializes phase
	                         // this is mainly for phasing with CPU clock 3.5/7 MHz
	                         // still not used, but this may change anytime

	input  wire        cend,     // working strobes from DRAM controller (7MHz)
	input  wire        pre_cend,

	input wire         mode_zx,		// standard ZX mode
	input wire         mode_tm,		// tiles mode
	input wire         mode_brd,	// no linear gfx - only border color

	input  wire [1:0]  rres,	//raster X resolution 00=256/01=320/10=320/11=360

	output reg         hblank,
	output reg         hsync,

	output reg         line_start,  // 1 video cycle prior to actual start of visible line
	output reg         hsync_start, // 1 cycle prior to beginning of hsync: used in frame sync/blank generation
	                                // these signals coincide with cend

	output reg         hint_start, // horizontal position of INT start, for fine tuning

	output reg         scanin_start,

	output reg         hpix, // marks gate during which pixels are outting

	                                // these signals turn on and turn off 'go' signal
	output reg         fetch_start, // 18/10 cycles earlier than hpix, coincide with cend
	output reg         fetch_end
	output reg         tfetch_start, //at the hsync, starts fetching Yscrolls
	output reg         tfetch_end

);


	localparam HBLNK_BEG = 9'd00;
	localparam HSYNC_BEG = 9'd10;
	localparam HSYNC_END = 9'd43;
	localparam HBLNK_END = 9'd88;

	// 256	=>	88-52-256-52
	localparam HPIX_BEG_256 = 9'd140;
	localparam HPIX_END_256 = 9'd396;

	// 320	=>	88-20-320-20
	localparam HPIX_BEG_320 = 9'd108;
	localparam HPIX_END_320 = 9'd428;

	// 360	=>	88-0-360-0
	localparam HPIX_BEG_360 = 9'd88;
	localparam HPIX_END_360 = 9'd448;


	localparam FETCH_PRE_ZX = 9'd18;
	localparam FETCH_PRE_TM = 9'd10;
	                                 // actual data starts fetching 2 dram cycles after
									// 'go' goes to 1, screen output starts another
									// 16/8 cycles after 1st data bundle is fetched

	localparam TFETCH_PRE = 9'd36;	//16 cycles for tiles and 2 cycles for Xscrolls


	localparam SCANIN_BEG = 9'd88; // when scan-doubler starts pixel storing

	localparam HINT_BEG = 9'd445;


	localparam HPERIOD = 9'd448;


	reg [8:0] hcount;

	reg [8:0] hp_beg, hp_end, f_pre;
	
	always @*
	begin
		case (rres)
		2'b00 : begin
					assign hp_beg = HPIX_BEG_256;
					assign hp_end = HPIX_END_256;
				end
		2'b01 : begin
					assign hp_beg = HPIX_BEG_320;
					assign hp_end = HPIX_END_320;
				end
		2'b10 : begin
					assign hp_beg = HPIX_BEG_320;
					assign hp_end = HPIX_END_320;
				end
		2'b11 : begin
					assign hp_beg = HPIX_BEG_360;
					assign hp_end = HPIX_END_360;
				end
		default : begin
					assign hp_beg = HPIX_BEG_256;
					assign hp_end = HPIX_END_256;
				end
		endcase
	end


	assign f_pre = mode_tm ? FETCH_PRE_TM : FETCH_PRE_ZX;

	
	// for simulation only
	//
	initial
	begin
		hcount = 9'd0;
		hblank = 1'b0;
		hsync = 1'b0;
		line_start = 1'b0;
		hsync_start = 1'b0;
		hpix = 1'b0;
	end


	//hor counter
	always @(posedge clk) if( cend )
	begin
            if( init || (hcount==(HPERIOD-9'd1)) )
            	hcount <= 9'd0;
            else
            	hcount <= hcount + 9'd1;
	end


	//hblank & hsync
	always @(posedge clk) if( cend )
	begin
		if( hcount==HBLNK_BEG )
			hblank <= 1'b1;
		else if( hcount==HBLNK_END )
			hblank <= 1'b0;


		if( hcount==HSYNC_BEG )
			hsync <= 1'b1;
		else if( hcount==HSYNC_END )
			hsync <= 1'b0;
	end

	
	//
	always @(posedge clk)
	begin
		if( pre_cend )
		begin
			if( hcount==HSYNC_BEG )
				hsync_start <= 1'b1;

			if( hcount==HBLNK_END )
				line_start <= 1'b1;

			if( hcount==SCANIN_BEG )
				scanin_start <= 1'b1;
		end
		else
		begin
			hsync_start  <= 1'b0;
			line_start   <= 1'b0;
			scanin_start <= 1'b0;
		end
	end


	//fetcher
	wire	fetch_start_cond,
			fetch_end_cond;
			tfetch_start_cond,
			tfetch_end_cond;

	assign fetch_start_cond = hcount == (hp_beg - f_pre);
	assign fetch_end_cond = hcount == (hp_end - f_pre);
	assign tfetch_start_cond = hcount == (HSYNC_BEG + 9'd2);
	assign tfetch_end_cond = hcount == (HSYNC_BEG + TFETCH_PRE + 9'd2);

	always @(posedge clk)
	if (pre_cend && fetch_start_cond && !mode_brd)		//if no pixel GFX - fetch will never start
		fetch_start <= 1'b1;
	else
		fetch_start <= 1'b0;

	always @(posedge clk)
	if (pre_cend && fetch_end_cond)
		fetch_end <= 1'b1;
	else
		fetch_end <= 1'b0;

	always @(posedge clk)
	if (pre_cend && tfetch_start_cond && mode_tm)
		tfetch_start <= 1'b1;
	else
		tfetch_start <= 1'b0;

	always @(posedge clk)
	if (pre_cend && tfetch_end_cond)
		tfetch_end <= 1'b1;
	else
		tfetch_end <= 1'b0;



	//INT
	always @(posedge clk)
	begin
		if( pre_cend && (hcount==HINT_BEG) )
			hint_start <= 1'b1;
		else
			hint_start <= 1'b0;
	end


	//pixel field
	always @(posedge clk) if( cend )
	begin
		if (hcount == hp_beg)
			hpix <= 1'b1;
		else if (hcount == hp_end)
			hpix <= 1'b0;
	end



endmodule

