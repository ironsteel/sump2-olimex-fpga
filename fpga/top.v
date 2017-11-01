/* ****************************************************************************
-- Source file: top.v                
-- Date:        October 08, 2016
-- Author:      khubbard
-- Description: Top Level Verilog RTL for Lattice ICE5LP FPGA Design
-- Language:    Verilog-2001 and VHDL-1993
-- Simulation:  Mentor-Modelsim 
-- Synthesis:   Icestorm     
-- License:     This project is licensed with the CERN Open Hardware Licence
--              v1.2.  You may redistribute and modify this project under the
--              terms of the CERN OHL v.1.2. (http://ohwr.org/cernohl).
--              This project is distributed WITHOUT ANY EXPRESS OR IMPLIED
--              WARRANTY, INCLUDING OF MERCHANTABILITY, SATISFACTORY QUALITY
--              AND FITNESS FOR A PARTICULAR PURPOSE. Please see the CERN OHL
--              v.1.2 for applicable Conditions.
-- 
--
-- Revision History:
-- Ver#  When      Who      What
-- ----  --------  -------- ---------------------------------------------------
-- 0.1   10.08.16  khubbard Creation
-- ***************************************************************************/
`default_nettype none // Strictly enforce all nets to be declared

module top
(
  input  wire         clk_100m,
  input  wire         ftdi_wi,
  output wire         ftdi_ro,
  input  wire [7:0]   events_din,

  output wire         LED1,
  output wire         LED2
);// module top

  wire          lb_wr;
  wire          lb_rd;
  wire [31:0]   lb_addr;
  wire [31:0]   lb_wr_d;
  wire [31:0]   lb_rd_d;
  wire          lb_rd_rdy;
  wire [23:0]   events_loc;

  wire          clk_cap_tree;
  wire          clk_lb_tree;
  wire          reset_loc;
  wire          pll_lock;

  wire          mesa_wi_loc;
  wire          mesa_wo_loc;
  wire          mesa_ri_loc;
  wire          mesa_ro_loc;

  wire          mesa_wi_nib_en;
  wire [3:0]    mesa_wi_nib_d;
  wire          mesa_wo_byte_en;
  wire [7:0]    mesa_wo_byte_d;
  wire          mesa_wo_busy;
  wire          mesa_ro_byte_en;
  wire [7:0]    mesa_ro_byte_d;
  wire          mesa_ro_busy;
  wire          mesa_ro_done;
  wire [7:0]    mesa_core_ro_byte_d;
  wire          mesa_core_ro_byte_en;
  wire          mesa_core_ro_done;
  wire          mesa_core_ro_busy;


  wire          mesa_wi_baudlock;
  wire [3:0]    led_bus;
  reg  [7:0]    test_cnt;
  reg           ck_togl;

  assign LED1 = led_bus[1];
  assign LED2 = led_bus[2];

  assign reset_loc = 0;

  // Hookup FTDI RX and TX pins to MesaBus Phy
  assign mesa_wi_loc = ftdi_wi;
  assign ftdi_ro     = mesa_ro_loc;


  // Hook some signals to inputs for testing
  assign events_loc[7] = clk_lb;
  assign events_loc[6] = mesa_wi_loc;
  assign events_loc[5] = mesa_ro_loc;

  assign events_loc[4:0]   = events_din[4:0];
  assign events_loc[15:8]  = 8'd0;  


reg	[1:0]		clk_div; // 2 bit counter
wire			clk_lb;	

assign 	clk_lb 	= clk_div[1];	// 25Mhz clock for mesa local bus (UART) 

always @ (posedge clk_cap_tree) begin // 2-bt counter ++ on each positive edge of 100Mhz clock
	clk_div <= clk_div + 2'b1;
end

SB_GB u0_sb_gb 
(
  .USER_SIGNAL_TO_GLOBAL_BUFFER ( clk_lb      ),
  .GLOBAL_BUFFER_OUTPUT         ( clk_lb_tree  )
);

SB_GB u1_sb_gb 
(
  .USER_SIGNAL_TO_GLOBAL_BUFFER ( clk_100m  ),
  .GLOBAL_BUFFER_OUTPUT         ( clk_cap_tree )
);



 assign mesa_ro_byte_d[7:0] = mesa_core_ro_byte_d[7:0];
 assign mesa_ro_byte_en     = mesa_core_ro_byte_en;
 assign mesa_ro_done        = mesa_core_ro_done;
 assign mesa_core_ro_busy   = mesa_ro_busy;


//-----------------------------------------------------------------------------
// MesaBus Phy : Convert UART serial to/from binary for Mesa Bus Interface
//  This translates between bits and bytes
//-----------------------------------------------------------------------------
mesa_phy u_mesa_phy
(
  .reset            ( reset_loc           ),
  .clk              ( clk_lb_tree         ),
  .clr_baudlock     ( 1'b0                ),
  .disable_chain    ( 1'b1                ),
  .mesa_wi_baudlock ( mesa_wi_baudlock    ),
  .mesa_wi          ( mesa_wi_loc         ),
  .mesa_ro          ( mesa_ro_loc         ),
  .mesa_wo          ( mesa_wo_loc         ),
  .mesa_ri          ( mesa_ri_loc         ),
  .mesa_wi_nib_en   ( mesa_wi_nib_en      ),
  .mesa_wi_nib_d    ( mesa_wi_nib_d[3:0]  ),
  .mesa_wo_byte_en  ( mesa_wo_byte_en     ),
  .mesa_wo_byte_d   ( mesa_wo_byte_d[7:0] ),
  .mesa_wo_busy     ( mesa_wo_busy        ),
  .mesa_ro_byte_en  ( mesa_ro_byte_en     ),
  .mesa_ro_byte_d   ( mesa_ro_byte_d[7:0] ),
  .mesa_ro_busy     ( mesa_ro_busy        ),
  .mesa_ro_done     ( mesa_ro_done        )
);// module mesa_phy


//-----------------------------------------------------------------------------
// MesaBus Core : Decode Slot,Subslot,Command Info and translate to LocalBus
//-----------------------------------------------------------------------------
mesa_core 
#
(
  .spi_prom_en       ( 1'b0                       )
)
u_mesa_core
(
  .reset               ( ~mesa_wi_baudlock        ),
  .clk                 ( clk_lb_tree              ),
  .spi_sck             ( ),
  .spi_cs_l            ( ),
  .spi_mosi            ( ),
  .spi_miso            ( ),
  .rx_in_d             ( mesa_wi_nib_d[3:0]       ),
  .rx_in_rdy           ( mesa_wi_nib_en           ),
  .tx_byte_d           ( mesa_core_ro_byte_d[7:0] ),
  .tx_byte_rdy         ( mesa_core_ro_byte_en     ),
  .tx_done             ( mesa_core_ro_done        ),
  .tx_busy             ( mesa_core_ro_busy        ),
  .tx_wo_byte          ( mesa_wo_byte_d[7:0]      ),
  .tx_wo_rdy           ( mesa_wo_byte_en          ),
  .subslot_ctrl        (                          ),
  .bist_req            (                          ),
  .reconfig_req        (                          ),
  .reconfig_addr       (                          ),
  .oob_en              ( 1'b0                     ),
  .oob_done            ( 1'b0                     ),
  .lb_wr               ( lb_wr                    ),
  .lb_rd               ( lb_rd                    ),
  .lb_wr_d             ( lb_wr_d[31:0]            ),
  .lb_addr             ( lb_addr[31:0]            ),
  .lb_rd_d             ( lb_rd_d[31:0]            ),
  .lb_rd_rdy           ( lb_rd_rdy                )
);// module mesa_core


//-----------------------------------------------------------------------------
// Design Specific Logic
//-----------------------------------------------------------------------------
core u_core
(
  .reset               ( ~mesa_wi_baudlock        ),
  .clk_lb              ( clk_lb_tree              ),
  .clk_cap             ( clk_cap_tree             ),
  .lb_wr               ( lb_wr                    ),
  .lb_rd               ( lb_rd                    ),
  .lb_wr_d             ( lb_wr_d[31:0]            ),
  .lb_addr             ( lb_addr[31:0]            ),
  .lb_rd_d             ( lb_rd_d[31:0]            ),
  .lb_rd_rdy           ( lb_rd_rdy                ),
  .led_bus             ( led_bus[3:0]             ),
  .events_din          ( events_loc[23:0]         )
);


endmodule // top.v
