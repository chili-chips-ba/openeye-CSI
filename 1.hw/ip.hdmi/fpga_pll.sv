//------------------------------------------------------------------------ 
// openeye-CSI * NLnet-sponsored open-source core for Camera I/F with ISP
//------------------------------------------------------------------------
//                   Copyright (C) 2024 Chili.CHIPS*ba
// 
// Redistribution and use in source and binary forms, with or without 
// modification, are permitted provided that the following conditions 
// are met:
//
// 1. Redistributions of source code must retain the above copyright 
// notice, this list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright 
// notice, this list of conditions and the following disclaimer in the 
// documentation and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its 
// contributors may be used to endorse or promote products derived
// from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS 
// IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED 
// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A 
// PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
// HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT 
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY 
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//              https://opensource.org/license/bsd-3-clause
//------------------------------------------------------------------------
// Designers  : Armin Zunic, Isam Vrce
// Description: From external 100MHz source, it creates:
//  for rendering on a 1280x720P@60Hz and 1920x1080P@30Hz screen
//      371.25MHz 5x serial pixel clock
//       74.25MHz pixel clock
//  for rendering on a 1080p@60Hz screen
//      666.666MHz 5x serial pixel clock
//       133.32MHz pixel clock
//
// Also see: https://github.com/hdl-util/hdmi
//           https://tomverbeure.github.io/video_timings_calculator (CEA-861 standard)
//			 https://tomverbeure.github.io/video_timings_calculator (CVT-RBv2)
//
// Xilinx Artix7 (XC7A100T-CSG324) on Trenz Adapter board (TEB0707-2)
// 100MHz ext.clock. 
//--------------------------------------------------------------------------------

`define HDMI_720p60
//`define HDMI_1080p30
//`define HDMI_1080p60

module fpga_pll (
    input logic clk_ext,      // 100MHz
    output logic srst_n,
    output logic clk_pix,     // 5x pixel clock: 371.25MHz (or 666.66MHz)
    output logic clk_pix5     // pixel clock: 74.25MHz (or 133.32MHz)
);

    logic pll_lock;
    logic clkfb;
    logic [2:0] srst_n_pipe;
    logic uclk_pix;
    logic uclk_pix5;

`ifdef HDMI_1080p60
    //__1920x1080Px60Hz CVT-RBv2
    MMCME2_BASE #(
        .BANDWIDTH("OPTIMIZED"),   // Jitter programming (OPTIMIZED, HIGH, LOW)
        .DIVCLK_DIVIDE(3),         // Master division value (1-106)
        .CLKFBOUT_MULT_F(20.0),  // Multiply value for all CLKOUT (2.000-64.000)
        .CLKFBOUT_PHASE(0.0),      // Phase offset in degrees of CLKFB (-360.000-360.000)
        .CLKIN1_PERIOD(10.000),    // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz)

        // CLKOUT0_DIVIDE - CLKOUT6_DIVIDE: Divide amount for each CLKOUT (1-128)
		.CLKOUT0_DIVIDE_F(1.0),    // Divide amount for CLKOUT0 (1.000-128.000)
        .CLKOUT1_DIVIDE(1),
        .CLKOUT2_DIVIDE(5),
        .CLKOUT3_DIVIDE(1),
        .CLKOUT4_DIVIDE(1),
        .CLKOUT5_DIVIDE(1),
        .CLKOUT6_DIVIDE(1),

        // CLKOUT0_DUTY_CYCLE - CLKOUT6_DUTY_CYCLE: Duty cycle for each CLKOUT (0.01-0.99)
        .CLKOUT0_DUTY_CYCLE(0.5),
        .CLKOUT1_DUTY_CYCLE(0.5),
        .CLKOUT2_DUTY_CYCLE(0.5),
        .CLKOUT3_DUTY_CYCLE(0.5),
        .CLKOUT4_DUTY_CYCLE(0.5),
        .CLKOUT5_DUTY_CYCLE(0.5),
        .CLKOUT6_DUTY_CYCLE(0.5),

        // CLKOUT0_PHASE - CLKOUT6_PHASE: Phase offset for each CLKOUT (-360.000-360.000)
        .CLKOUT0_PHASE(0.0),
        .CLKOUT1_PHASE(0.0),
        .CLKOUT2_PHASE(0.0),
        .CLKOUT3_PHASE(0.0),
        .CLKOUT4_PHASE(0.0),
        .CLKOUT5_PHASE(0.0),
        .CLKOUT6_PHASE(0.0),
		
        .CLKOUT4_CASCADE("FALSE"), // Cascade CLKOUT4 counter with CLKOUT6 (FALSE, TRUE)
        .REF_JITTER1(0.0),         // Reference input jitter in UI (0.000-0.999)
        .STARTUP_WAIT("FALSE")     // Delays DONE until MMCM is locked (FALSE, TRUE)
    ) u_MMCME2_BASE (
	    .CLKOUT0(uclk_pix5),       // 1-bit output: CLKOUT0
        .CLKOUT2(uclk_pix),        // 1-bit output: CLKOUT2
        .CLKFBOUT(clkfb),          // 1-bit output: Feedback clock
        .LOCKED(pll_lock),         // 1-bit output: LOCK
        .CLKIN1(clk_ext),          // 1-bit input: Clock
        .CLKFBIN(clkfb)            // 1-bit input: Feedback clock
    );
`else
    //__1280x720Px60Hz or __1920x1080Px30Hz
	MMCME2_BASE #(
        .BANDWIDTH("OPTIMIZED"),   // Jitter programming (OPTIMIZED, HIGH, LOW)
        .DIVCLK_DIVIDE(5),         // Master division value (1-106)
        .CLKFBOUT_MULT_F(37.125),  // Multiply value for all CLKOUT (2.000-64.000)
        .CLKFBOUT_PHASE(0.0),      // Phase offset in degrees of CLKFB (-360.000-360.000)
        .CLKIN1_PERIOD(10.000),    // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz)

        // CLKOUT0_DIVIDE - CLKOUT6_DIVIDE: Divide amount for each CLKOUT (1-128)
		.CLKOUT0_DIVIDE_F(2.0),    // Divide amount for CLKOUT0 (1.000-128.000)
        .CLKOUT1_DIVIDE(1),
        .CLKOUT2_DIVIDE(10),
        .CLKOUT3_DIVIDE(1),
        .CLKOUT4_DIVIDE(1),
        .CLKOUT5_DIVIDE(1),
        .CLKOUT6_DIVIDE(1),

        // CLKOUT0_DUTY_CYCLE - CLKOUT6_DUTY_CYCLE: Duty cycle for each CLKOUT (0.01-0.99)
        .CLKOUT0_DUTY_CYCLE(0.5),
        .CLKOUT1_DUTY_CYCLE(0.5),
        .CLKOUT2_DUTY_CYCLE(0.5),
        .CLKOUT3_DUTY_CYCLE(0.5),
        .CLKOUT4_DUTY_CYCLE(0.5),
        .CLKOUT5_DUTY_CYCLE(0.5),
        .CLKOUT6_DUTY_CYCLE(0.5),

        // CLKOUT0_PHASE - CLKOUT6_PHASE: Phase offset for each CLKOUT (-360.000-360.000)
        .CLKOUT0_PHASE(0.0),
        .CLKOUT1_PHASE(0.0),
        .CLKOUT2_PHASE(0.0),
        .CLKOUT3_PHASE(0.0),
        .CLKOUT4_PHASE(0.0),
        .CLKOUT5_PHASE(0.0),
        .CLKOUT6_PHASE(0.0),
		
        .CLKOUT4_CASCADE("FALSE"), // Cascade CLKOUT4 counter with CLKOUT6 (FALSE, TRUE)
        .REF_JITTER1(0.0),         // Reference input jitter in UI (0.000-0.999)
        .STARTUP_WAIT("FALSE")     // Delays DONE until MMCM is locked (FALSE, TRUE)
    ) u_MMCME2_BASE (
	    .CLKOUT0(uclk_pix5),       // 1-bit output: CLKOUT0
        .CLKOUT2(uclk_pix),        // 1-bit output: CLKOUT2
        .CLKFBOUT(clkfb),          // 1-bit output: Feedback clock
        .LOCKED(pll_lock),         // 1-bit output: LOCK
        .CLKIN1(clk_ext),          // 1-bit input: Clock
		.CLKFBIN(clkfb)            // 1-bit input: Feedback clock
	);
`endif

//----------------------------------------------
// Clock buffers
//----------------------------------------------
    BUFG u_BUFG_clk_pix (
        .I(uclk_pix),
        .O(clk_pix)
    );
	
	BUFG u_BUFG_clk_pix5 (
        .I(uclk_pix5),
        .O(clk_pix5)
    );

//----------------------------------------------
// Reset synchronizer
//----------------------------------------------
	always_ff @(posedge clk_pix or negedge pll_lock) begin
        if (!pll_lock) begin
            srst_n_pipe <= 3'b000;
            srst_n <= 1'b0;
        end else begin
            srst_n_pipe <= {srst_n_pipe[1:0], 1'b1};
            srst_n <= srst_n_pipe[2];
        end
    end
	
endmodule: fpga_pll

/*
------------------------------------------------------------------------------
Version History:
------------------------------------------------------------------------------
 2024/1/4 Isam Vrce: Initial creation
 2024/1/8 Armin Zunic: Timing improvements
 2024/1/10 Isam Vrce: More timing tuning
 2024/1/16 Armin Zunic: Adding ifdef parts
 2024/1/17 Armin Zunic: Converting the code from VHDL to SystemVerilog
*/