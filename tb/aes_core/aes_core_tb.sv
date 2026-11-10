module tb;
  reg clk=0, rst_n=0, start=0;
  reg [127:0] pt = 128'h00112233445566778899aabbccddeeff;
  reg [127:0] key = 128'h000102030405060708090a0b0c0d0e0f;
  wire [127:0] ct; wire busy, done;
  aes_core dut(clk, rst_n, start, pt, key, ct, busy, done);
  always #5 clk = ~clk;
  initial begin
    #20 rst_n = 1; #10 start = 1; #10 start = 0;
    wait(done); #10 $display("CT = %h", ct); $finish;
  end
endmodule