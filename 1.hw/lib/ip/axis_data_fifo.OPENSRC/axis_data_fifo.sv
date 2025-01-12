module axis_data_fifo #(
   parameter DEPTH = 8192,
   parameter DW    = 24
)(
   input  logic            s_axis_aresetn,
                           
 //Write side
   input  logic            s_axis_aclk,
   input  logic            s_axis_tvalid,
   output logic            s_axis_tready,
   input  logic [DW-1 : 0] s_axis_tdata,

 //Read side
   input  logic            m_axis_aclk,
   output logic            m_axis_tvalid,
   input  logic            m_axis_tready,
   output logic [DW-1 : 0] m_axis_tdata,

   output logic [3:0]      debug_fifo
);

   localparam AW = $clog2(DEPTH);

//-------------------------
// 1. Syncronize reset to both clocks
//-------------------------

//__SCLK
   logic srst_n_sclk, srst_n_sclk_0;

   always_ff @(negedge s_axis_aresetn or posedge s_axis_aclk) begin
      if (s_axis_aresetn == 1'b0) begin
         {srst_n_sclk, srst_n_sclk_0} <= '0;
      end
      else begin
         {srst_n_sclk, srst_n_sclk_0} <= {srst_n_sclk_0, 1'b1};
      end
   end   


//__MCLK
   logic srst_n_mclk, srst_n_mclk_0;

   always_ff @(negedge s_axis_aresetn or posedge m_axis_aclk) begin
      if (s_axis_aresetn == 1'b0) begin
         {srst_n_mclk, srst_n_mclk_0} <= '0;
      end
      else begin
         {srst_n_mclk, srst_n_mclk_0} <= {srst_n_mclk_0, 1'b1};
      end
   end   



//-------------------------
// 2. Async FIFO Controller
//-------------------------
   logic empty, full;
   logic wr, rd;
   logic [AW-1:0] waddr, raddr;
    
   assign s_axis_tready = ~full;
 
   afifo_ctrl #(.DW(DW), .AW(AW)) u_afifo_ctrl (
    // Write side
      .i_wclk   (s_axis_aclk),
      .i_wrst_n (srst_n_sclk), 
      .i_wr     (s_axis_tvalid),

      .o_wr     (wr),
      .o_wfull  (full),
      .o_waddr  (waddr),
    
    // Read side 
      .i_rclk   (m_axis_aclk),
      .i_rrst_n (srst_n_mclk),
      .i_rd     (~m_axis_tvalid | m_axis_tready),

      .o_rd     (rd),
      .o_rempty (empty),
      .o_raddr  (raddr)
   );
    
//-------------------------
// 3. Inferable Dual-port BRAM
//-------------------------
   DP_BRAM #(
     .D      (DEPTH), 
     .W      (DW)
   ) 
   ram (
    //Side-A 
     .clka   (s_axis_aclk),
     .ena    (wr),
     .addra  (waddr),
     .wea    ('1),
     .dina   (s_axis_tdata),
     .douta  (), // unused
    
    //Side-B
     .clkb   (m_axis_aclk),
     .enb    (rd),
     .addrb  (raddr),
     .web    ('0), // unused
     .dinb   ('0), // unused
     .doutb  (m_axis_tdata)
   );
    
//-------------------------
// 4. m_axis_tvalid = delayed ~empty
//-------------------------
   always_ff @(posedge m_axis_aclk) begin
      m_axis_tvalid <= ~empty;
   end

   assign debug_fifo = {
      empty,
      full,
      rd,
      wr
   };

endmodule: axis_data_fifo
