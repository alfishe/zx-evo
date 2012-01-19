// PentEvo project (c) NedoPC 2008-2010
//
// most of pentevo ports are here

`include "../include/tune.v"

module zports(

	input  wire        zclk,   // z80 clock
	input  wire        fclk,
	input  wire        rst_n, // system reset

	input  wire        zpos,
	input  wire        zneg,


	input  wire [ 7:0] din,
	output reg  [ 7:0] dout,
	output wire        dataout,
	input  wire [15:0] a,

	input  wire        iorq_n,
	input  wire        mreq_n,
	input  wire        m1_n,
	input  wire        rd_n,
	input  wire        wr_n,

	output reg         porthit, // when internal port hit occurs, this is 1, else 0; used for iorq1_n iorq2_n on zxbus
	output reg         external_port, // asserts for AY and VG93 accesses

	output wire [15:0] ideout,
	input  wire [15:0] idein,
	output wire        idedataout, // IDE must IN data from IDE device when idedataout=0, else it OUTs
	output wire [ 2:0] ide_a,
	output wire        ide_cs0_n,
	output wire        ide_cs1_n,
	output wire        ide_rd_n,
	output wire        ide_wr_n,
	// output wire        t0,	// debug!!!


	input  wire [ 4:0] keys_in, // keys (port FE)
	input  wire [ 7:0] mus_in,  // mouse (xxDF)
	input  wire [ 4:0] kj_in,

	output reg  [ 7:0] border,

	
// eXTension ports
	output reg [7:0] vconf,
	output reg [7:0] vpage,
	output reg [8:0] x_offs,
	output reg [8:0] y_offs,
	output reg [7:0] tsconf,
	
	output wire [47:0] xt_rampage,
	output reg [4:0] xt_rompage,
	output reg [3:0] xt_override,
	
	output reg [4:0] fmaddr,
	output reg [4:0] tgpage,
	
	output reg [7:0] sysconf,
	output reg [7:0] memconf,
	output reg [7:0] hint_beg,
	output reg [8:0] vint_beg,
	output reg [7:0] im2vect,

	output wire [4:0] dmaport_wr,
	output wire y_offs_wr,
	output wire p7ffd_wr,

	input  wire        dos,


	output wire        ay_bdir,
	output wire        ay_bc1,

	output wire [ 7:0] peff7,

	input  wire [ 1:0] rstrom,

	input  wire        tape_read,

	output wire        vg_cs_n,
	input  wire        vg_intrq,
	input  wire        vg_drq, // from vg93 module - drq + irq read
	output wire        vg_wrFF,        // write strobe of #FF port

	output reg         sdcs_n,
	output wire        sd_start,
	output wire [ 7:0] sd_datain,
	input  wire [ 7:0] sd_dataout,

	// WAIT-ports related
	//
	output reg  [ 7:0] gluclock_addr,
	//
	output reg  [ 2:0] comport_addr,
	//
	output wire        wait_start_gluclock, // begin wait from some ports
	output wire        wait_start_comport,  //
	//
	output reg         wait_rnw,   // whether it was read(=1) or write(=0)
	output reg  [ 7:0] wait_write,
	input  wire [ 7:0] wait_read,


	output wire        atmF7_wr_fclk, // used in atm_pager.v


	output reg  [ 2:0] atm_scr_mode, // RG0..RG2 in docs
	output reg         atm_turbo,    // turbo mode ON
	output reg         atm_pen,      // pager_off in atm_pager.v, NOT inverted!!!
	output reg         atm_cpm_n,    // permanent dos on
	output reg         atm_pen2,     // PEN2 - fucking palette mode, NOT inverted!!!

	output wire        romrw_en, // from port BF


	output wire        pent1m_ram0_0, // d3.eff7
	output wire        pent1m_1m_on,  // d2.eff7
	output wire [ 5:0] pent1m_page,   // full 1 meg page number
	output wire        pent1m_ROM,     // d4.7ffd


	output wire        atm_palwr,   // palette write strobe
	output wire [ 5:0] atm_paldata, // palette write data

	output wire        covox_wr,
	output wire        beeper_wr,

	output wire        clr_nmi,

	output wire        fnt_wr,		// write to font_ram enabled

	// inputs from atm_pagers, to read back its config
	input  wire [63:0] pages,
	input  wire [ 7:0] ramnroms,
	input  wire [ 7:0] dos7ffds,

	input  wire [ 5:0] palcolor,


	// NMI generation
	output reg         set_nmi
);

	// assign t0 = portfd_wr | portfe_wr;	//debug!!!


	reg rstsync1,rstsync2;


	localparam PORTFE = 8'hFE;
	localparam PORTXT = 8'hAF;
	localparam PORTF6 = 8'hF6;
	localparam PORTF7 = 8'hF7;

	localparam NIDE10 = 8'h10;
	localparam NIDE11 = 8'h11;
	localparam NIDE30 = 8'h30;
	localparam NIDE50 = 8'h50;
	localparam NIDE70 = 8'h70;
	localparam NIDE90 = 8'h90;
	localparam NIDEB0 = 8'hB0;
	localparam NIDED0 = 8'hD0;
	localparam NIDEF0 = 8'hF0;
	localparam NIDEC8 = 8'hC8;

	localparam PORTFD = 8'hFD;

	localparam VGCOM  = 8'h1F;
	localparam VGTRK  = 8'h3F;
	localparam VGSEC  = 8'h5F;
	localparam VGDAT  = 8'h7F;
	localparam VGSYS  = 8'hFF;

	localparam SAVPORT1 = 8'h2F;
	localparam SAVPORT2 = 8'h4F;
	localparam SAVPORT3 = 8'h6F;
	localparam SAVPORT4 = 8'h8F;

	localparam KJOY   = 8'h1F;
	localparam KMOUSE = 8'hDF;

	localparam SDCFG  = 8'h77;
	localparam SDDAT  = 8'h57;

	localparam ATMF7  = 8'hF7;
	localparam ATM77  = 8'h77;

	localparam ZXEVBE = 8'hBE; // xxBE config-read and nmi-end port
	localparam ZXEVBF = 8'hBF; // xxBF config port

	localparam COMPORT = 8'hEF; // F8EF..FFEF - rs232 ports


	localparam COVOX   = 8'hFB;




	reg port_wr;
	reg port_rd;

	reg iowr_reg;
	reg iord_reg;


	reg port_wr_fclk,
	    port_rd_fclk,
	    mem_wr_fclk;

	reg [1:0] iowr_reg_fclk,
	          iord_reg_fclk;

	reg [1:0] memwr_reg_fclk;


	wire ideout_hi_wr;
	wire idein_lo_rd;
	reg [7:0] idehiin; // IDE high part read register: low part is read directly to Z80 bus,
	                   // while high part is remembered here
	reg ide_ports; // ide ports selected

	reg ide_rd_trig; // nemo-divide read trigger
	reg ide_rd_latch; // to save state of trigger during read cycle

	reg ide_wrlo_trig,  ide_wrhi_trig;  // nemo-divide write triggers
	reg ide_wrlo_latch, ide_wrhi_latch; // save state during write cycles



	reg  [15:0] idewrreg; // write register, either low or high part is pre-written here,
	                      // while other part is out directly from Z80 bus

	wire [ 7:0] iderdeven; // to control read data from "even" ide ports (all except #11)
	wire [ 7:0] iderdodd;  // read data from "odd" port (#11)




	wire gluclock_on;



	reg  shadow_en_reg; //bit0.xxBF
	reg   romrw_en_reg; //bit1.xxBF
	reg  fntw_en_reg; 	//bit2.xxBF

	wire shadow;



	reg [7:0] portbemux;



	reg [7:0] savport [3:0];





	assign shadow = dos || shadow_en_reg;






	wire [7:0] loa=a[7:0];
	wire [7:0] hoa=a[15:8];

	always @*
	begin
		if( (loa==PORTFE) || (loa==PORTXT) || (loa==PORTF6) ||
		    (loa==PORTFD) ||

		    (loa==NIDE10) || (loa==NIDE11) || (loa==NIDE30) || (loa==NIDE50) || (loa==NIDE70) ||
		    (loa==NIDE90) || (loa==NIDEB0) || (loa==NIDED0) || (loa==NIDEF0) || (loa==NIDEC8) ||

		    (loa==KMOUSE) ||

		    ( (loa==VGCOM)&&shadow ) || ( (loa==VGTRK)&&shadow ) || ( (loa==VGSEC)&&shadow ) || ( (loa==VGDAT)&&shadow ) ||
		    ( (loa==VGSYS)&&shadow ) || ( (loa==KJOY)&&(!shadow) ) ||

    		    ( (loa==SAVPORT1)&&shadow ) || ( (loa==SAVPORT2)&&shadow ) ||
		    ( (loa==SAVPORT3)&&shadow ) || ( (loa==SAVPORT4)&&shadow ) ||


		    ( (loa==PORTF7)&&(!shadow) ) || ( (loa==SDCFG)&&(!shadow) ) || ( (loa==SDDAT) ) ||

		    ( (loa==ATMF7)&&shadow ) || ( (loa==ATM77)&&shadow ) ||

		    ( loa==ZXEVBF ) || ( loa==ZXEVBE) || ( loa==COMPORT )
		  )



			porthit = 1'b1;
		else
			porthit = 1'b0;
	end

	always @*
	begin
			if ( ((loa==PORTFD) & a[15]) || // AY
		   (( (loa==VGCOM)&&shadow ) || ( (loa==VGTRK)&&shadow ) || ( (loa==VGSEC)&&shadow ) || ( (loa==VGDAT)&&shadow )) ) // vg93 ports
			external_port = 1'b1;
		else
			external_port = 1'b0;
	end

	assign dataout = porthit & (~iorq_n) & (~rd_n) & (~external_port);


	// Z80 asynchronous signals
	wire iowr = ~(iorq_n | wr_n);
	wire iord = ~(iorq_n | rd_n);
	

	// this is zclk-synchronous strobes
	always @(posedge zclk)
	begin
		iowr_reg <= iowr;
		iord_reg <= iord;

		if( (!iowr_reg) && (!iorq_n) && (!wr_n) )
			port_wr <= 1'b1;
		else
			port_wr <= 1'b0;


		if( (!iord_reg) && (!iorq_n) && (!rd_n) )
			port_rd <= 1'b1;
		else
			port_rd <= 1'b0;
	end


	// fclk-synchronous stobes
	//
	always @(posedge fclk) if( zpos )
	begin
		iowr_reg_fclk[0] <= iowr;
		iord_reg_fclk[0] <= iord;
	end

	always @(posedge fclk)
	begin
		iowr_reg_fclk[1] <= iowr_reg_fclk[0];
		iord_reg_fclk[1] <= iord_reg_fclk[0];
	end

	always @(posedge fclk)
	begin
		port_wr_fclk <= iowr_reg_fclk[0] && (!iowr_reg_fclk[1]);
		port_rd_fclk <= iord_reg_fclk[0] && (!iord_reg_fclk[1]);
	end

	always @(posedge fclk)
		memwr_reg_fclk[1:0] <= { memwr_reg_fclk[0], ~(mreq_n | wr_n) };

	always @(posedge fclk)
		mem_wr_fclk <= memwr_reg_fclk[0] && (!memwr_reg_fclk[1]);



	// dout data
	always @*
	begin
		case( loa )
		PORTFE:
			dout = { 1'b1, tape_read, 1'b0, keys_in };
		PORTF6:
			dout = { 1'b1, tape_read, 1'b0, keys_in };


		NIDE10,NIDE30,NIDE50,NIDE70,NIDE90,NIDEB0,NIDED0,NIDEF0,NIDEC8:
			dout = iderdeven;
		NIDE11:
			dout = iderdodd;


		//PORTFD:

		VGSYS:
			dout = { vg_intrq, vg_drq, 6'b111111 };

		SAVPORT1, SAVPORT2, SAVPORT3, SAVPORT4:
			dout = savport[ loa[6:5] ];


		KJOY:
			dout = {3'b000, kj_in};
		KMOUSE:
			dout = mus_in;

		SDCFG:
			dout = 8'h00; // always SD inserted, SD is in R/W mode
		SDDAT:
			dout = sd_dataout;


		PORTF7: begin
			if( !a[14] && (a[8]^shadow) && gluclock_on ) // $BFF7 - data i/o
				dout = wait_read;
			else // any other $xxF7 port
				dout = 8'hFF;
		end

		COMPORT: begin
			dout = wait_read; // $F8EF..$FFEF
		end

		ZXEVBF: begin
			dout = { 4'b0000, set_nmi, fntw_en_reg, romrw_en_reg, shadow_en_reg };
		end

		ZXEVBE: begin
			dout = portbemux;
		end


		default:
			dout = 8'hFF;
		endcase
	end



	wire portxt_wr    = ((loa==PORTXT) && iowr);
	wire portfe_wr    = ((loa==PORTFE) && iowr);
	wire portfd_wr    = ((loa==PORTFD) && iowr);

	// F7 ports (like EFF7) are accessible in shadow mode but at addresses like EEF7, DEF7, BEF7 so that
	// there are no conflicts in shadow mode with ATM xFF7 and x7F7 ports
	assign portf7_wr    = ( (loa==PORTF7) && (a[8]==1'b1) && port_wr && (!shadow) ) ||
	                      ( (loa==PORTF7) && (a[8]==1'b0) && port_wr &&   shadow  ) ;

	assign portf7_rd    = ( (loa==PORTF7) && (a[8]==1'b1) && port_rd && (!shadow) ) ||
	                      ( (loa==PORTF7) && (a[8]==1'b0) && port_rd &&   shadow  ) ;

	assign vg_wrFF = ( ( (loa==VGSYS)&&shadow ) && port_wr);

	assign comport_wr   = ( (loa==COMPORT) && port_wr);
	assign comport_rd   = ( (loa==COMPORT) && port_rd);



//eXTension port #nnAF

	localparam VCONF		= 8'h00;
	localparam VPAGE		= 8'h01;
	localparam XOFFSL		= 8'h02;
	localparam XOFFSH		= 8'h03;
	localparam YOFFSL		= 8'h04;
	localparam YOFFSH		= 8'h05;
	localparam TSCONF		= 8'h06;
	localparam XBORDER		= 8'h0F;

	localparam RAMPAGE		= 8'h10;	// this uses #10-#13
	localparam ROMPAGE		= 8'h14;
	localparam FMADDR		= 8'h15;
	localparam RAMPAGES		= 8'h16;	// this uses #16-#17
	localparam TGPAGE		= 8'h18;
	localparam DMAADDRL		= 8'h1A;
	localparam DMAADDRH		= 8'h1B;
	localparam DMAADDRX		= 8'h1C;
	
	localparam SYSCONF		= 8'h20;
	localparam MEMCONF		= 8'h21;
	localparam HSINT		= 8'h22;
	localparam VSINTL		= 8'h23;
	localparam VSINTH		= 8'h24;
	localparam IM2VECT		= 8'h25;
	localparam DMALEN		= 8'h26;
	localparam DMACTRL		= 8'h27;

	
	wire rampage_h = hoa[7:2] == RAMPAGE[7:2];
	wire rampagsh_h = hoa[7:1] == RAMPAGES[7:1];
	wire rampage_wr = portxt_wr & rampage_h;
	wire rampagsh_wr = portxt_wr & rampagsh_h;
	
	assign dmaport_wr[0] = portxt_wr & (hoa == DMAADDRL);
	assign dmaport_wr[1] = portxt_wr & (hoa == DMAADDRH);
	assign dmaport_wr[2] = portxt_wr & (hoa == DMAADDRX);
	assign dmaport_wr[3] = portxt_wr & (hoa == DMALEN);
	assign dmaport_wr[4] = portxt_wr & (hoa == DMACTRL);
	
    assign y_offs_wr = portxt_wr & ((hoa == YOFFSL) | (hoa == YOFFSH));
	
	reg [7:0] rampage[0:5];
	assign xt_rampage = {rampage[5], rampage[4], rampage[3], rampage[2], rampage[1], rampage[0]};
	
// harshest crotch for the ATM fucking pager!!!
	always @(posedge zclk)
		if (!rst_n)
			xt_override <= 4'b0;
		else
		begin
			if (rampage_wr)
				xt_override[a[9:8]] <= 1'b1;	// if XT page write, correspondent override ON
			if (rampagsh_wr)
				xt_override[a[8]+2] <= 1'b1;	// shadow XT pages
			if (p7ffd_wr)
				xt_override[3'b11] <= 1'b0;		// if 7FFD write, C000 window override OFF
			if (atmF7_wr_fclk)
				xt_override[a[15:14]] <= 1'b0;	// if ATM pager write, correspondent override OFF
		end

		
	//border port FE
	always @(posedge zclk)
		if (portfe_wr)
			border <= {5'b11110, din[2:0]};
		else
		if (portxt_wr & (hoa == XBORDER))
			border <= din;
		

	always @(posedge zclk)
		if (!rst_n)
		begin
		
			vconf <= 8'h00;
			x_offs <= 9'b0;
			y_offs <= 9'b0;
			tsconf[7:5] <= 3'b0;
			
			fmaddr[4] <= 1'b0;
			
			sysconf <= 8'h00;
			memconf <= 8'h00;
			hint_beg <= 8'd2;	// pentagon default
			vint_beg <= 9'd0;
			im2vect <= 8'hFF;
	
			rampage[0] <= 8'h00;
			rampage[1] <= 8'h05;
			rampage[2] <= 8'h02;
			rampage[3] <= 8'h00;
			rampage[4] <= 8'h02;
			rampage[5] <= 8'h00;
			
		end
		else
		if (portxt_wr)
		begin
		
			if (hoa == VCONF)
				vconf <= din;
			if (hoa == XOFFSL)
				x_offs[7:0] <= din;
			if (hoa == XOFFSH)
				x_offs[8] <= din[0];
			if (hoa == YOFFSL)
				y_offs[7:0] <= din;
			if (hoa == YOFFSH)
				y_offs[8] <= din[0];
			if (hoa == TSCONF)
				tsconf <= din;
				
			if (hoa == FMADDR)
				fmaddr <= din[4:0];
			if (hoa == TGPAGE)
				tgpage <= din[7:3];

			if (rampage_h)
				rampage[a[9:8]] <= din;
			if (rampagsh_h)
				rampage[a[8]+4] <= din;
				
			if (hoa == ROMPAGE)
				xt_rompage <= din[4:0];
				
			if (hoa == SYSCONF)
				sysconf <= din;
			if (hoa == MEMCONF)
				memconf <= din;
			if (hoa == HSINT)
				hint_beg <= din;
			if (hoa == VSINTL)
				vint_beg[7:0] <= din;
			if (hoa == VSINTH)
				vint_beg[8] <= din[0];
			if (hoa == IM2VECT)
				im2vect <= din;
				
		end
	

		
	// IDE ports

	// IDE physical ports (that go to IDE device)
	always @(loa)
		case( loa )
		NIDE10,NIDE30,NIDE50,NIDE70,NIDE90,NIDEB0,NIDED0,NIDEF0,NIDEC8: ide_ports = 1'b1;
		default: ide_ports = 1'b0;
		endcase


	assign idein_lo_rd  = port_rd && (loa==NIDE10) && (!ide_rd_trig);

	// control read & write triggers, which allow nemo-divide mod to work.
	//
	// read trigger:
	always @(posedge zclk)
	begin
		if( (loa==NIDE10) && port_rd && !ide_rd_trig )
			ide_rd_trig <= 1'b1;
		else if( ( ide_ports || (loa==NIDE11) ) && ( port_rd || port_wr ) )
			ide_rd_trig <= 1'b0;
	end
	//
	// two triggers for write sequence...
	always @(posedge zclk)
	if( ( ide_ports || (loa==NIDE11) ) && ( port_rd || port_wr ) )
	begin
		if( (loa==NIDE11) && port_wr )
			ide_wrhi_trig <= 1'b1;
		else
			ide_wrhi_trig <= 1'b0;
		//
		if( (loa==NIDE10) && port_wr && !ide_wrhi_trig && !ide_wrlo_trig )
			ide_wrlo_trig <= 1'b1;
		else
			ide_wrlo_trig <= 1'b0;
	end

	// normal read: #10(low), #11(high)
	// divide read: #10(low), #10(high)
	//
	// normal write: #11(high), #10(low)
	// divide write: #10(low),  #10(high)


	always @(posedge zclk)
	begin
		if( port_wr && (loa==NIDE11) )
			idewrreg[15:8] <= din;

		if( port_wr && (loa==NIDE10) && !ide_wrlo_trig )
			idewrreg[ 7:0] <= din;
	end




	always @(posedge zclk)
	if( idein_lo_rd )
			idehiin <= idein[15:8];


	assign ide_a = a[7:5];


	// This is unknown shit... Probably need more testing with old WD
	// drives WITHOUT this commented fix.
	//
	// trying to fix old WD drives...
	//assign ide_cs0_n = iorq_n | (rd_n&wr_n) | (~ide_ports) | (~(loa!=NIDEC8));
	//assign ide_cs1_n = iorq_n | (rd_n&wr_n) | (~ide_ports) | (~(loa==NIDEC8));
	// fix ends...


	assign ide_cs0_n = (~ide_ports) | (~(loa!=NIDEC8));
	assign ide_cs1_n = (~ide_ports) | (~(loa==NIDEC8));


	// generate read cycles for IDE as usual, except for reading #10
	// instead of #11 for high byte (nemo-divide). I use additional latch
	// since 'ide_rd_trig' clears during second Z80 IO read cycle to #10
	always @* if( rd_n ) ide_rd_latch <= ide_rd_trig;
	//
	assign ide_rd_n = iorq_n | rd_n | (~ide_ports) | (ide_rd_latch && (loa==NIDE10));

	always @* if( wr_n ) ide_wrlo_latch <= ide_wrlo_trig; // same for write triggers
	always @* if( wr_n ) ide_wrhi_latch <= ide_wrhi_trig; //
	//
	assign ide_wr_n = iorq_n | wr_n | (~ide_ports) | ( (loa==NIDE10) && !ide_wrlo_latch && !ide_wrhi_latch );
	                                          // do NOT generate IDE write, if neither of ide_wrhi|lo latches
	                                          // set and writing to NIDE10



	// assign idedataout = ide_rd_n;
	assign idedataout = !ide_wr_n;



	// data read by Z80 from IDE
	//
	assign iderdodd[ 7:0] = idehiin[ 7:0];
	//
	assign iderdeven[ 7:0] = (ide_rd_latch && (loa==NIDE10)) ? idehiin[ 7:0] : idein[ 7:0];

	// data written to IDE from Z80
	//
	assign ideout[15:8] = ide_wrhi_latch ? idewrreg[15:8] : din[ 7:0];
	assign ideout[ 7:0] = ide_wrlo_latch ? idewrreg[ 7:0] : din[ 7:0];


	// AY control
	wire ay_hit = (loa==PORTFD) & a[15] & (~iorq_n);
	assign ay_bc1  = ay_hit & a[14] & ((~rd_n)|(~wr_n));
	assign ay_bdir = ay_hit & (~wr_n);
	

	// 7FFD port
	reg [7:0] p7ffd, peff7_int;
	reg p7ffd_rom_int;
	reg block7ffd;
	wire block1m;
	assign p7ffd_wr = !a[15] && portfd_wr && !block7ffd;
	
	always @(posedge zclk)
	begin
		if (!rst_n)
		begin
			p7ffd <= 8'h00;
			block7ffd <= 1'b0;
			vpage <= 8'h05;
			pent1m_page <= 6'd0;
		end
		else
		begin
			if (p7ffd_wr)
			begin
				p7ffd <= din;
				block7ffd=p7ffd[5] & block1m;
				pent1m_page <= {block1m ? 3'b0 : {din[5], din[7:6]}, din[2:0]};
				vpage <= {6'b000001, din[3], 1'b1};
			end
			else
			if (portxt_wr)
			begin
				if (hoa == VPAGE)
					vpage <= din;
			end
		end
	end

	
	always @(posedge zclk)
	begin
		if( rstsync2 )
			p7ffd_rom_int <= rstrom[0];
		else if (p7ffd_wr)
			p7ffd_rom_int <= din[4];
	end



	// EFF7 port
	always @(posedge zclk)
	begin
		if( !rst_n )
			peff7_int <= 8'h00;
		else if( !a[12] && portf7_wr && (!shadow) ) // EEF7 in shadow mode is abandoned!
			peff7_int <= din; // 4 - turbooff, 0 - p16c on, 2 - block1meg
	end
	assign block1m = peff7_int[2];

	assign peff7 = block1m ? { peff7_int[7], 1'b0, peff7_int[5], peff7_int[4], 3'b000, peff7_int[0] } : peff7_int;


	assign pent1m_ROM       = p7ffd_rom_int;
	assign pent1m_1m_on     = ~peff7_int[2];
	assign pent1m_ram0_0    = peff7_int[3];




	// gluclock ports (bit7:eff7 is above)

	assign gluclock_on = peff7_int[7] || shadow; // in shadow mode EEF7 is abandoned: instead, gluclock access
	                                             // is ON forever in shadow mode.

	always @(posedge zclk)
	begin
		if( gluclock_on && portf7_wr ) // gluclocks on
		begin
			if( !a[13] ) // $DFF7 - addr reg
				gluclock_addr <= din;

			// write to waiting register is not here - in separate section managing wait_write
		end
	end


	// comports

	always @(posedge zclk)
	begin
		if( comport_wr || comport_rd )
			comport_addr <= a[10:8 ];
	end



	// write to wait registers
	always @(posedge zclk)
	begin
		// gluclocks
		if( gluclock_on && portf7_wr && !a[14] ) // $BFF7 - data reg
			wait_write <= din;
		// com ports
		else if( comport_wr ) // $F8EF..$FFEF - comports
			wait_write <= din;
	end

	// wait from wait registers
	//
	// ACHTUNG!!!! here portxx_wr are ON Z80 CLOCK! logic must change when moving to fclk strobes
	//
	assign wait_start_gluclock = ( gluclock_on && !a[14] && (portf7_rd || portf7_wr) ); // $BFF7 - gluclock r/w
	//
	assign wait_start_comport = ( comport_rd || comport_wr );
	//
	//
	always @(posedge zclk) // wait rnw - only meanful during wait
	begin
		if( port_wr )
			wait_rnw <= 1'b0;

		if( port_rd )
			wait_rnw <= 1'b1;
	end





	// VG93 control
	assign vg_cs_n =  (~shadow) | iorq_n | (rd_n & wr_n) | ( ~((loa==VGCOM)|(loa==VGTRK)|(loa==VGSEC)|(loa==VGDAT)) );





// reset rom selection

	always @(posedge zclk)
	begin
		rstsync1<=~rst_n;
		rstsync2<=rstsync1;
	end




// SD card (z-control�r compatible)

	wire sdcfg_wr,sddat_wr,sddat_rd;

	assign sdcfg_wr = ( (loa==SDCFG) && port_wr_fclk && (!shadow) )                  ||
	                  ( (loa==SDDAT) && port_wr_fclk &&   shadow  && (a[15]==1'b1) ) ;

	assign sddat_wr = ( (loa==SDDAT) && port_wr_fclk && (!shadow) )                  ||
	                  ( (loa==SDDAT) && port_wr_fclk &&   shadow  && (a[15]==1'b0) ) ;

	assign sddat_rd = ( (loa==SDDAT) && port_rd_fclk              );

	// SDCFG write - sdcs_n control
	always @(posedge fclk)
	begin
		if( !rst_n )
			sdcs_n <= 1'b1;
		else // posedge zclk
			if( sdcfg_wr )
				sdcs_n <= din[1];
	end


	// start signal for SPI module with resyncing to fclk

	assign sd_start = sddat_wr || sddat_rd;


	// data for SPI module
	assign sd_datain = wr_n ? 8'hFF : din;







/////////////////////////////////////////////////////////////////////////////////////////////////

	///////////////
	// ATM ports //
	///////////////

	wire atm77_wr_fclk;
	wire zxevbf_wr_fclk;

	assign atmF7_wr_fclk = ( (loa==ATMF7) && (a[8]==1'b1) && shadow && port_wr_fclk ); // xFF7 and x7F7 ports, NOT xEF7!
	assign atm77_wr_fclk = ( (loa==ATM77) && shadow && port_wr_fclk );

	assign zxevbf_wr_fclk = ( (loa==ZXEVBF) && port_wr_fclk );


	// port BF write
	//
	always @(posedge fclk)
	if( !rst_n )
	begin
		shadow_en_reg <= 1'b0;
		romrw_en_reg  <= 1'b0;
		fntw_en_reg   <= 1'b0;
		set_nmi       <= 1'b0;
	end
	else if( zxevbf_wr_fclk )
	begin
		shadow_en_reg <= din[0];
		romrw_en_reg  <= din[1];
		fntw_en_reg   <= din[2];
		set_nmi       <= din[3];
	end

	assign romrw_en = romrw_en_reg;



	// port xx77 write
	always @(posedge fclk)
	if( !rst_n )
	begin
		atm_scr_mode = 3'b011;
		atm_turbo    = 1'b0;

		atm_pen =   1'b1; // no manager,
		atm_cpm_n = 1'b0; // permanent dosen (shadow ports on)


		atm_pen2     = 1'b0;
	end
	else if( atm77_wr_fclk )
	begin
		atm_scr_mode <= din[2:0];
		atm_turbo    <= din[3];
		atm_pen      <= ~a[8];
		atm_cpm_n    <=  a[9];
		atm_pen2     <= ~a[14];
	end


	// atm palette strobe and data
	wire vg_wrFF_fclk;

	assign vg_wrFF_fclk = ( ( (loa==VGSYS)&&shadow ) && port_wr_fclk);


	assign atm_palwr = vg_wrFF_fclk & atm_pen2;

	assign atm_paldata = { ~din[4], ~din[7], ~din[1], ~din[6], ~din[0], ~din[5] };



	// port BE write
	assign clr_nmi = ( (loa==ZXEVBE) && port_wr_fclk );




	// covox/beeper writes

	assign beeper_wr = (loa==PORTFE) && iowr;
	assign covox_wr  = (loa==COVOX) && iowr;



	// font write enable
	assign fnt_wr = fntw_en_reg && mem_wr_fclk;



	// port BE read

	always @*
	case( a[11:8] )

	// 4'h0: portbemux = pages[ 7:0 ];
	// 4'h1: portbemux = pages[15:8 ];
	// 4'h2: portbemux = pages[23:16];
	// 4'h3: portbemux = pages[31:24];
	// 4'h4: portbemux = pages[39:32];
	// 4'h5: portbemux = pages[47:40];
	// 4'h6: portbemux = pages[55:48];
	// 4'h7: portbemux = pages[63:56];

	4'h8: portbemux = ramnroms;
	4'h9: portbemux = dos7ffds;

	4'hA: portbemux = p7ffd;
	4'hB: portbemux = peff7_int;

	// 4'hC: portbemux = { ~atm_pen2, atm_cpm_n, ~atm_pen, 1'bX, atm_turbo, atm_scr_mode };

	// 4'hD: portbemux = { ~palcolor[4], ~palcolor[2], ~palcolor[0], ~palcolor[5], 2'b11, ~palcolor[3], ~palcolor[1] };

	default: portbemux = 8'bXXXXXXXX;

	endcase





	// savelij ports write
	//
	always @(posedge fclk)
	if( port_wr_fclk && shadow )
	begin
		if( (loa==SAVPORT1) ||
		    (loa==SAVPORT2) ||
		    (loa==SAVPORT3) ||
		    (loa==SAVPORT4) )
			savport[ loa[6:5] ] <= din;
	end



endmodule

