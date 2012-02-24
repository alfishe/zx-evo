// This module decodes video modes

`include "../include/tune.v"


module video_mode (

// clocks
	input wire clk, f1, c3,

// video config
	input wire [7:0] vconf,
	input wire [7:0] vpage,
	output reg [7:0] vpage_d,
	input wire [3:0] palsel,
	output reg [3:0] palsel_d,
	
// video parameters & mode controls
	input  wire [8:0] gx_offs,
	output wire [9:0] x_offs_mode,
	output wire [8:0] hpix_beg,
	output wire [8:0] hpix_end,
	output wire [8:0] vpix_beg,
	output wire [8:0] vpix_end,
	output wire [5:0] x_tiles,
	output wire [4:0] go_offs,
	output wire [3:0] fetch_sel,
	output wire	[1:0] fetch_bsl,
	input wire	[3:0] fetch_cnt,
	input wire	[1:0] tm_en,
	input wire tm_pf,
	input wire pix_start,
	input wire line_start,
	output wire tv_hires,
	output reg  vga_hires,
	output wire [1:0] render_mode,
	output wire pix_stb,
	output wire	fetch_stb,
	output wire nogfx,

// video data
	input wire [15:0] txt_char,
    
// video counters
    input wire [7:0] cnt_col,
    input wire [8:0] cnt_row,
    input wire [8:0] cnt_tp_row,
    input wire cptr,
	
// Z80 controls
    input wire zvpage_wr,

// TMBUF interface
    output wire [8:0] tmb_waddr,
    
// DRAM interface
    output wire [20:0] video_addr,
    output wire [ 4:0] video_bw
	
);


    // wire [2:0] vmod = vconf[2:0];
    wire [2:0] vmod = {1'b0, vconf_d[1:0]};
	wire [1:0] rres = vconf_d[7:6];
	assign nogfx = vconf_d[5];

	
// latching regs at line start, delaying hires for 1 line
    reg [7:0] vconf_d;
    reg [8:0] gx_offs_d;
    
    always @(posedge clk) if (line_start & c3)
    begin
        vconf_d <= vconf;
        gx_offs_d <= gx_offs;
        palsel_d <= palsel;
		
        vga_hires <= tv_hires;
    end
    
    always @(posedge clk) if ((line_start & c3) | zvpage_wr)
        vpage_d <= vpage;
    
    
// clocking strobe for pixels (TV)
	assign pix_stb = tv_hires ? f1 : c3;


// Modes
    localparam M_ZX = 3'h0;		// ZX
    localparam M_HC = 3'h1;		// 16c
    localparam M_XC = 3'h2;		// 256c
    localparam M_TX = 3'h3;		// Text
    localparam M_T2 = 3'h4;		// (reserved)
    localparam M_T0 = 3'h5;		// ZX hi-res (test)
    localparam M_T1 = 3'h6;		// (reserved)
    localparam M_T3 = 3'h7;		// (reserved)
    
// Render modes (affects 'video_render.v')
    localparam R_ZX = 2'h0;
    localparam R_HC = 2'h1;
    localparam R_XC = 2'h2;
    localparam R_TX = 2'h3;

	
// fetch strobes
	wire ftch[0:3];
	assign fetch_stb = (pix_start | ftch[render_mode]) & c3;
	assign ftch[R_ZX] = &fetch_cnt[3:0];
	assign ftch[R_HC] = &fetch_cnt[1:0];
	assign ftch[R_XC] = fetch_cnt[0];
	assign ftch[R_TX] = &fetch_cnt[3:0];

    
// fetch window
	wire [4:0] g_offs[0:7];
// these values are empiric!!! recheck them occasionally!
    assign g_offs[M_ZX] = 5'd18;
    assign g_offs[M_HC] = 5'd6;
    assign g_offs[M_XC] = 5'd4;	
    assign g_offs[M_TX] = 5'd10;
    assign g_offs[M_T2] = 5'd18;
    assign g_offs[M_T0] = 5'd10;
    assign g_offs[M_T1] = 5'd18;
    assign g_offs[M_T3] = 5'd18;
    assign go_offs = g_offs[vmod];


// fetch selectors
// Attention: counter is already incremented at the time of video data fetching!

	// wire m_c = (vmod == M_HC) | (vmod == M_XC);
	// assign fetch_sel = vmod == M_TX ? f_txt_sel[cnt_col[1:0]] : {~cptr, ~cptr, cptr | m_c, cptr | m_c};
	
	wire [3:0] f_sel[0:7];
	assign f_sel[M_ZX] = {~cptr, ~cptr, cptr, cptr};
	assign f_sel[M_HC] = {~cptr, ~cptr, 2'b11};
	assign f_sel[M_XC] = {~cptr, ~cptr, 2'b11};
	assign f_sel[M_TX] = f_txt_sel[cnt_col[1:0]];
	assign f_sel[M_T2] = {~cptr, ~cptr, cptr, cptr};
	assign f_sel[M_T0] = {~cptr, ~cptr, cptr, cptr};
	assign f_sel[M_T1] = {~cptr, ~cptr, cptr, cptr};
	assign f_sel[M_T3] = {~cptr, ~cptr, cptr, cptr};
	assign fetch_sel = f_sel[vmod];
	
	assign fetch_bsl = vmod == M_TX ? f_txt_bsl[cnt_col[1:0]] : 2'b10;
	
	// wire [1:0] f_bsl[0:7];
	// assign f_bsl[M_ZX] = 2'b10;
	// assign f_bsl[M_HC] = 2'b10;
	// assign f_bsl[M_XC] = 2'b10;
	// assign f_bsl[M_TX] = f_txt_bsl[cnt_col[1:0]];
	// assign f_bsl[M_T2] = 2'b10;
	// assign f_bsl[M_T0] = 2'b10;
	// assign f_bsl[M_T1] = 2'b10;
	// assign f_bsl[M_T3] = 2'b10;
	// assign fetch_bsl = f_bsl[vmod];

	wire [3:0] f_txt_sel[0:3];
	assign f_txt_sel[1] = 4'b0011;			// char
	assign f_txt_sel[2] = 4'b1100;			// attr
	assign f_txt_sel[3] = 4'b0001;			// gfx0
	assign f_txt_sel[0] = 4'b0010;			// gfx1
	
	wire [1:0] f_txt_bsl[0:3];
	assign f_txt_bsl[1] = 2'b10;			// char
	assign f_txt_bsl[2] = 2'b10;			// attr
	assign f_txt_bsl[3] = {2{cnt_row[0]}};	// gfx0
	assign f_txt_bsl[0] = {2{cnt_row[0]}};	// gfx1
	

// X offset
	assign x_offs_mode = {vmod == M_XC ? {gx_offs_d[8:1], 1'b0} : {1'b0, gx_offs_d[8:1]}, gx_offs_d[0]};

	
// DRAM bandwidth usage
    localparam BW2 = 2'b00;
    localparam BW4 = 2'b01;
    localparam BW8 = 2'b11;
    
    localparam BU1 = 3'b001;
    localparam BU2 = 3'b010;
    localparam BU4 = 3'b100;
    
	// [4:3] - total cycles: 11 = 8 / 01 = 4 / 00 = 2
	// [2:0] - need cycles
    wire [4:0] bw[0:7];
    assign bw[M_ZX] = {BW8, BU1};	// '1 of 8' (ZX)
    assign bw[M_HC] = {BW4, BU1};	// '1 of 4' (16c)
    assign bw[M_XC] = {BW2, BU1};	// '1 of 2' (256c)
    assign bw[M_TX] = {BW8, BU4};	// '4 of 8' (text)
    assign bw[M_T2] = {BW8, BU1};	// '1 of 8' (reserved)
    assign bw[M_T0] = {BW8, BU2};	// '2 of 8' (ZX Hi-res test)
    assign bw[M_T1] = {BW8, BU1};	// '1 of 8' (reserved)
    assign bw[M_T3] = {BW8, BU1};	// '1 of 8' (No graphics)
    assign video_bw = tm_pf ? tm_bw : bw[vmod];
    
    wire [5:0] tm_bw = {BW4, &tm_en ? BU2 : BU1};      // '1/2 of 4' (1 or 2 tile-planes used)

	
// pixelrate
	wire [7:0] pixrate = 8'b00101000;	// change these if you change the modes indexes!
	assign tv_hires = pixrate[vmod];

	
// render mode
    wire [1:0] r_mode[0:7];
    assign r_mode[M_ZX] = R_ZX;
    assign r_mode[M_HC] = R_HC;
    assign r_mode[M_XC] = R_XC;
    assign r_mode[M_TX] = R_TX;
    assign r_mode[M_T2] = R_ZX;
    assign r_mode[M_T0] = R_ZX;
    assign r_mode[M_T1] = R_ZX;
    assign r_mode[M_T3] = R_ZX;
	assign render_mode = r_mode[vmod];
	
	
// raster resolution
	wire [8:0] hp_beg[0:3];
	wire [8:0] hp_end[0:3];
	wire [8:0] vp_beg[0:3];
	wire [8:0] vp_end[0:3];
	wire [5:0] x_tile[0:3];

	assign hp_beg[0] = 9'd140;	// 256 (88-52-256-52)
	assign hp_beg[1] = 9'd108;	// 320 (88-20-320-20)
	assign hp_beg[2] = 9'd108;	// 320 (88-20-320-20)
	assign hp_beg[3] = 9'd88;	// 360 (88-0-360-0  )

	assign hp_end[0] = 9'd396;	// 256
	assign hp_end[1] = 9'd428;	// 320
	assign hp_end[2] = 9'd428;	// 320
	assign hp_end[3] = 9'd448;	// 360

	assign vp_beg[0] = 9'd080;	// 192 (32-48-192-32)
	assign vp_beg[1] = 9'd076;	// 200 (32-44-200-44)
	assign vp_beg[2] = 9'd056;	// 240 (32-24-240-24)
	assign vp_beg[3] = 9'd032;	// 288 (32-0-288-0  )

	assign vp_end[0] = 9'd272;	// 192
	assign vp_end[1] = 9'd276;	// 200
	assign vp_end[2] = 9'd296;	// 240
	assign vp_end[3] = 9'd320;	// 288

	assign x_tile[0] = 6'd33;	// 256
	assign x_tile[1] = 6'd41;	// 320
	assign x_tile[2] = 6'd41;	// 320
	assign x_tile[3] = 6'd46;	// 360

	assign hpix_beg = hp_beg[rres];
	assign hpix_end = hp_end[rres];
	assign vpix_beg = vp_beg[rres];
	assign vpix_end = vp_end[rres];
	assign x_tiles = x_tile[rres];

	
// addresses
    wire [20:0] v_addr[0:7];
    assign v_addr[M_ZX] = addr_zx;
    assign v_addr[M_HC] = addr_16c;
    assign v_addr[M_XC] = addr_256c;
    assign v_addr[M_TX] = addr_text;
    assign v_addr[M_T2] = addr_zx;
    assign v_addr[M_T0] = addr_zx;
    assign v_addr[M_T1] = addr_zx;
    assign v_addr[M_T3] = addr_zx;
    assign video_addr = tm_pf ? tm_addr : v_addr[vmod];

    
// Tiles
    wire [20:0] tm_addr = {vpage_d, tpos_y, tpn, tpos_x};
    wire [5:0] tpos_y = cnt_tp_row[8:3];
    wire [5:0] tpos_x = {cnt_tp_row[2:0], cnt_tp_col};
    wire [2:0] cnt_tp_col = &tm_en ? cnt_col[3:1] : cnt_col[2:0];
    wire tpn = &tm_en ? cnt_col[0] : tm_en[1];
    
    assign tmb_waddr = {cnt_tp_row[4:0], cnt_tp_col, tpn};
    
    
// ZX
	wire [20:0] addr_zx = {vpage_d, 1'b0, ~cnt_col[0] ? addr_zx_gfx : addr_zx_atr};
	wire [11:0] addr_zx_gfx = {cnt_row[7:6], cnt_row[2:0], cnt_row[5:3], cnt_col[4:1]};
	wire [11:0] addr_zx_atr = {3'b110, cnt_row[7:3], cnt_col[4:1]};

    
// 16c
	wire [20:0] addr_16c = {vpage_d[7:3], cnt_row, cnt_col[6:0]};


// 256c
	wire [20:0] addr_256c = {vpage_d[7:4], cnt_row, cnt_col[7:0]};


// Textmode
    wire [20:0] addr_text = {vpage_d[7:1], addr_tx[cnt_col[1:0]]};
	wire [13:0] addr_tx[0:3];
    assign addr_tx[0] = {vpage_d[0], cnt_row[8:3], 1'b0, cnt_col[7:2]};			// char codes, data[15:0]
    assign addr_tx[1] = {vpage_d[0], cnt_row[8:3], 1'b1, cnt_col[7:2]};			// char attributes, data[31:16]
    assign addr_tx[2] = {~vpage_d[0], 3'b000, (txt_char[7:0]), cnt_row[2:1]};		// char0 graphics, data[7:0]
    assign addr_tx[3] = {~vpage_d[0], 3'b000, (txt_char[15:8]), cnt_row[2:1]};	// char1 graphics, data[15:8]

    // assign addr_tx[0] = {1'b0, 6'd0, 1'b0, cnt_col[7:2]};	// char codes, data[15:0]
    // assign addr_tx[0] = {1'b0, 6'd0, 1'b0, 6'd0};	// char codes, data[15:0]
    // assign addr_tx[3] = {14'b10000000000000};		// debug!!!
    

endmodule


