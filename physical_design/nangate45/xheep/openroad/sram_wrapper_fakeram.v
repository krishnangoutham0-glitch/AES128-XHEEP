module sram_wrapper #(
  parameter NumWords  = 1024,
  parameter DataWidth = 32,
  parameter AddrWidth = (NumWords > 1) ? $clog2(NumWords) : 1
) (
  input  clk_i, rst_ni, req_i, we_i,
  input  [AddrWidth-1:0] addr_i,
  input  [DataWidth-1:0] wdata_i,
  input  [DataWidth/8-1:0] be_i,
  input  pwrgate_ni,
  output pwrgate_ack_no,
  input  set_retentive_ni,
  output [DataWidth-1:0] rdata_o
);
  localparam NBANK  = (NumWords + 1023) / 1024;
  localparam NSLICE = (DataWidth + 31) / 32;
  localparam BSEL_W = (NBANK > 1) ? $clog2(NBANK) : 1;
  assign pwrgate_ack_no = pwrgate_ni;

  wire [31:0] addr_ext = addr_i;
  wire [9:0]  row      = addr_ext[9:0];
  wire [BSEL_W-1:0] bsel = addr_ext[10 +: BSEL_W];
  reg  [BSEL_W-1:0] bsel_q;
  always @(posedge clk_i) if (req_i && !we_i) bsel_q <= bsel;

  wire [NSLICE*32-1:0] wd_ext = wdata_i;
  wire [NSLICE*4-1:0]  be_ext = be_i;
  wire [NSLICE*32-1:0] rd_ext [0:NBANK-1];

  genvar b, s, k;
  generate
    for (b = 0; b < NBANK; b = b + 1) begin : g_bank
      for (s = 0; s < NSLICE; s = s + 1) begin : g_slice
        wire [31:0] mask;
        for (k = 0; k < 4; k = k + 1) begin : g_m
          assign mask[k*8 +: 8] = {8{be_ext[s*4 + k]}};
        end
        wire [31:0] q;
        fakeram45_1024x32 u_ram (
          .clk(clk_i),
          .ce_in(req_i && (NBANK == 1 || bsel == b)),
          .we_in(we_i),
          .addr_in(row),
          .wd_in(wd_ext[s*32 +: 32]),
          .w_mask_in(mask),
          .rd_out(q)
        );
        assign rd_ext[b][s*32 +: 32] = q;
      end
    end
  endgenerate

  assign rdata_o = rd_ext[(NBANK == 1) ? 0 : bsel_q][DataWidth-1:0];
endmodule
