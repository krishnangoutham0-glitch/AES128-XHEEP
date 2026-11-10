module aes_core (
	clk,
	rst_n,
	start,
	plaintext,
	key,
	ciphertext,
	busy,
	done
);
	reg _sv2v_0;
	input wire clk;
	input wire rst_n;
	input wire start;
	input wire [127:0] plaintext;
	input wire [127:0] key;
	output wire [127:0] ciphertext;
	output wire busy;
	output wire done;
	wire [3:0] round;
	wire do_initial_key;
	wire do_round;
	wire do_final_round;
	wire [127:0] round_key;
	wire [3:0] key_round;
	wire key_valid;
	wire key_done;
	reg [127:0] state_reg;
	reg [127:0] state_next;
	wire [127:0] initial_key_out;
	wire [127:0] normal_round_out;
	wire [127:0] final_round_out;
	round_controller u_controller(
		.clk(clk),
		.rst_n(rst_n),
		.start(start),
		.round(round),
		.busy(busy),
		.done(done),
		.do_initial_key(do_initial_key),
		.do_round(do_round),
		.do_final_round(do_final_round)
	);
	key_expansion u_key_expansion(
		.clk(clk),
		.rst_n(rst_n),
		.start(start),
		.key_in(key),
		.round_key(round_key),
		.round(key_round),
		.valid(key_valid),
		.done(key_done)
	);
	add_round_key u_initial_add_round_key(
		.state_in(plaintext),
		.round_key(round_key),
		.state_out(initial_key_out)
	);
	aes_round u_aes_round(
		.state_in(state_reg),
		.round_key(round_key),
		.state_out(normal_round_out)
	);
	aes_final_round u_aes_final_round(
		.state_in(state_reg),
		.round_key(round_key),
		.state_out(final_round_out)
	);
	always @(*) begin
		if (_sv2v_0)
			;
		state_next = state_reg;
		if (do_initial_key)
			state_next = initial_key_out;
		else if (do_round)
			state_next = normal_round_out;
		else if (do_final_round)
			state_next = final_round_out;
	end
	always @(posedge clk or negedge rst_n)
		if (!rst_n)
			state_reg <= 128'h00000000000000000000000000000000;
		else
			state_reg <= state_next;
	assign ciphertext = state_reg;
	initial _sv2v_0 = 0;
endmodule
module round_controller (
	clk,
	rst_n,
	start,
	round,
	busy,
	done,
	do_initial_key,
	do_round,
	do_final_round
);
	reg _sv2v_0;
	input wire clk;
	input wire rst_n;
	input wire start;
	output reg [3:0] round;
	output reg busy;
	output reg done;
	output reg do_initial_key;
	output reg do_round;
	output reg do_final_round;
	localparam [4:0] S_IDLE = 5'b00001;
	localparam [4:0] S_INIT = 5'b00010;
	localparam [4:0] S_ROUND = 5'b00100;
	localparam [4:0] S_FINAL = 5'b01000;
	localparam [4:0] S_DONE = 5'b10000;
	reg [4:0] state;
	reg [4:0] next_state;
	always @(posedge clk or negedge rst_n)
		if (!rst_n) begin
			state <= S_IDLE;
			round <= 4'd0;
		end
		else begin
			state <= next_state;
			if (((state == S_IDLE) || (state == S_DONE)) && start)
				round <= 4'd0;
			else if (state == S_INIT)
				round <= 4'd1;
			else if (state == S_ROUND)
				round <= round + 4'd1;
		end
	always @(*) begin
		if (_sv2v_0)
			;
		next_state = state;
		case (state)
			S_IDLE:
				if (start)
					next_state = S_INIT;
			S_INIT: next_state = S_ROUND;
			S_ROUND:
				if (round == 4'd9)
					next_state = S_FINAL;
				else
					next_state = S_ROUND;
			S_FINAL: next_state = S_DONE;
			S_DONE:
				if (start)
					next_state = S_INIT;
				else
					next_state = S_IDLE;
			default: next_state = S_IDLE;
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		do_initial_key = state[1];
		do_round = state[2];
		do_final_round = state[3];
		done = state[4];
		busy = (state[1] | state[2]) | state[3];
	end
	initial _sv2v_0 = 0;
endmodule
module key_expansion (
	clk,
	rst_n,
	start,
	key_in,
	round_key,
	round,
	valid,
	done
);
	input wire clk;
	input wire rst_n;
	input wire start;
	input wire [127:0] key_in;
	output reg [127:0] round_key;
	output reg [3:0] round;
	output reg valid;
	output reg done;
	reg [127:0] key_reg;
	reg [7:0] rcon;
	reg [31:0] w0;
	reg [31:0] w1;
	reg [31:0] w2;
	reg [31:0] w3;
	reg [31:0] t;
	reg [31:0] sub_word;
	reg [31:0] nw0;
	reg [31:0] nw1;
	reg [31:0] nw2;
	reg [31:0] nw3;
	reg [7:0] sbox_in0;
	reg [7:0] sbox_in1;
	reg [7:0] sbox_in2;
	reg [7:0] sbox_in3;
	wire [7:0] sbox_out0;
	wire [7:0] sbox_out1;
	wire [7:0] sbox_out2;
	wire [7:0] sbox_out3;
	aes_sbox sbox0(
		.in(sbox_in0),
		.out(sbox_out0)
	);
	aes_sbox sbox1(
		.in(sbox_in1),
		.out(sbox_out1)
	);
	aes_sbox sbox2(
		.in(sbox_in2),
		.out(sbox_out2)
	);
	aes_sbox sbox3(
		.in(sbox_in3),
		.out(sbox_out3)
	);
	always @(*) begin
		w0 = key_reg[127:96];
		w1 = key_reg[95:64];
		w2 = key_reg[63:32];
		w3 = key_reg[31:0];
		t = {w3[23:16], w3[15:8], w3[7:0], w3[31:24]};
		sbox_in0 = t[31:24];
		sbox_in1 = t[23:16];
		sbox_in2 = t[15:8];
		sbox_in3 = t[7:0];
		sub_word = {sbox_out0, sbox_out1, sbox_out2, sbox_out3};
		nw0 = (w0 ^ sub_word) ^ {rcon, 24'h000000};
		nw1 = w1 ^ nw0;
		nw2 = w2 ^ nw1;
		nw3 = w3 ^ nw2;
	end
	function automatic [7:0] rcon_next;
		input reg [7:0] r;
		if (r[7])
			rcon_next = {r[6:0], 1'b0} ^ 8'h1b;
		else
			rcon_next = {r[6:0], 1'b0};
	endfunction
	always @(posedge clk or negedge rst_n)
		if (!rst_n) begin
			key_reg <= 128'h00000000000000000000000000000000;
			round_key <= 128'h00000000000000000000000000000000;
			round <= 4'd0;
			rcon <= 8'h01;
			valid <= 1'b0;
			done <= 1'b0;
		end
		else begin
			valid <= 1'b0;
			done <= 1'b0;
			if (start) begin
				key_reg <= key_in;
				round_key <= key_in;
				round <= 4'd0;
				rcon <= 8'h01;
				valid <= 1'b1;
			end
			else if (round < 4'd10) begin
				key_reg <= {nw0, nw1, nw2, nw3};
				round_key <= {nw0, nw1, nw2, nw3};
				round <= round + 4'd1;
				rcon <= rcon_next(rcon);
				valid <= 1'b1;
			end
			else
				done <= 1'b1;
		end
endmodule
module aes_round (
	state_in,
	round_key,
	state_out
);
	input wire [127:0] state_in;
	input wire [127:0] round_key;
	output wire [127:0] state_out;
	wire [127:0] sub_bytes_out;
	wire [127:0] shift_rows_out;
	wire [127:0] mix_columns_out;
	sub_bytes u_sub_bytes(
		.state_in(state_in),
		.state_out(sub_bytes_out)
	);
	shift_rows u_shift_rows(
		.state_in(sub_bytes_out),
		.state_out(shift_rows_out)
	);
	mix_columns u_mix_columns(
		.state_in(shift_rows_out),
		.state_out(mix_columns_out)
	);
	add_round_key u_add_round_key(
		.state_in(mix_columns_out),
		.round_key(round_key),
		.state_out(state_out)
	);
endmodule
module aes_final_round (
	state_in,
	round_key,
	state_out
);
	input wire [127:0] state_in;
	input wire [127:0] round_key;
	output wire [127:0] state_out;
	wire [127:0] sub_bytes_out;
	wire [127:0] shift_rows_out;
	sub_bytes u_sub_bytes(
		.state_in(state_in),
		.state_out(sub_bytes_out)
	);
	shift_rows u_shift_rows(
		.state_in(sub_bytes_out),
		.state_out(shift_rows_out)
	);
	add_round_key u_add_round_key(
		.state_in(shift_rows_out),
		.round_key(round_key),
		.state_out(state_out)
	);
endmodule
module add_round_key (
	state_in,
	round_key,
	state_out
);
	input wire [127:0] state_in;
	input wire [127:0] round_key;
	output wire [127:0] state_out;
	assign state_out = state_in ^ round_key;
endmodule
module sub_bytes (
	state_in,
	state_out
);
	input wire [127:0] state_in;
	output wire [127:0] state_out;
	genvar _gv_i_102;
	generate
		for (_gv_i_102 = 0; _gv_i_102 < 16; _gv_i_102 = _gv_i_102 + 1) begin : sbox_instances
			localparam i = _gv_i_102;
			aes_sbox sbox_inst(
				.in(state_in[127 - (i * 8)-:8]),
				.out(state_out[127 - (i * 8)-:8])
			);
		end
	endgenerate
endmodule
module shift_rows (
	state_in,
	state_out
);
	input wire [127:0] state_in;
	output wire [127:0] state_out;
	assign state_out = {state_in[127:120], state_in[87:80], state_in[47:40], state_in[7:0], state_in[95:88], state_in[55:48], state_in[15:8], state_in[103:96], state_in[63:56], state_in[23:16], state_in[111:104], state_in[71:64], state_in[31:24], state_in[119:112], state_in[79:72], state_in[39:32]};
endmodule
module mix_columns (
	state_in,
	state_out
);
	input wire [127:0] state_in;
	output reg [127:0] state_out;
	function automatic [7:0] xtime;
		input reg [7:0] x;
		if (x[7])
			xtime = {x[6:0], 1'b0} ^ 8'h1b;
		else
			xtime = {x[6:0], 1'b0};
	endfunction
	function automatic [7:0] mul3;
		input reg [7:0] x;
		mul3 = xtime(x) ^ x;
	endfunction
	reg [7:0] b0;
	reg [7:0] b1;
	reg [7:0] b2;
	reg [7:0] b3;
	reg [7:0] b4;
	reg [7:0] b5;
	reg [7:0] b6;
	reg [7:0] b7;
	reg [7:0] b8;
	reg [7:0] b9;
	reg [7:0] b10;
	reg [7:0] b11;
	reg [7:0] b12;
	reg [7:0] b13;
	reg [7:0] b14;
	reg [7:0] b15;
	reg [7:0] c0;
	reg [7:0] c1;
	reg [7:0] c2;
	reg [7:0] c3;
	reg [7:0] c4;
	reg [7:0] c5;
	reg [7:0] c6;
	reg [7:0] c7;
	reg [7:0] c8;
	reg [7:0] c9;
	reg [7:0] c10;
	reg [7:0] c11;
	reg [7:0] c12;
	reg [7:0] c13;
	reg [7:0] c14;
	reg [7:0] c15;
	always @(*) begin
		b0 = state_in[127:120];
		b1 = state_in[119:112];
		b2 = state_in[111:104];
		b3 = state_in[103:96];
		b4 = state_in[95:88];
		b5 = state_in[87:80];
		b6 = state_in[79:72];
		b7 = state_in[71:64];
		b8 = state_in[63:56];
		b9 = state_in[55:48];
		b10 = state_in[47:40];
		b11 = state_in[39:32];
		b12 = state_in[31:24];
		b13 = state_in[23:16];
		b14 = state_in[15:8];
		b15 = state_in[7:0];
		c0 = ((xtime(b0) ^ mul3(b1)) ^ b2) ^ b3;
		c1 = ((b0 ^ xtime(b1)) ^ mul3(b2)) ^ b3;
		c2 = ((b0 ^ b1) ^ xtime(b2)) ^ mul3(b3);
		c3 = ((mul3(b0) ^ b1) ^ b2) ^ xtime(b3);
		c4 = ((xtime(b4) ^ mul3(b5)) ^ b6) ^ b7;
		c5 = ((b4 ^ xtime(b5)) ^ mul3(b6)) ^ b7;
		c6 = ((b4 ^ b5) ^ xtime(b6)) ^ mul3(b7);
		c7 = ((mul3(b4) ^ b5) ^ b6) ^ xtime(b7);
		c8 = ((xtime(b8) ^ mul3(b9)) ^ b10) ^ b11;
		c9 = ((b8 ^ xtime(b9)) ^ mul3(b10)) ^ b11;
		c10 = ((b8 ^ b9) ^ xtime(b10)) ^ mul3(b11);
		c11 = ((mul3(b8) ^ b9) ^ b10) ^ xtime(b11);
		c12 = ((xtime(b12) ^ mul3(b13)) ^ b14) ^ b15;
		c13 = ((b12 ^ xtime(b13)) ^ mul3(b14)) ^ b15;
		c14 = ((b12 ^ b13) ^ xtime(b14)) ^ mul3(b15);
		c15 = ((mul3(b12) ^ b13) ^ b14) ^ xtime(b15);
		state_out = {c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13, c14, c15};
	end
endmodule
module aes_sbox (
	in,
	out
);
	reg _sv2v_0;
	input wire [7:0] in;
	output reg [7:0] out;
	always @(*) begin
		if (_sv2v_0)
			;
		case (in)
			8'h00: out = 8'h63;
			8'h01: out = 8'h7c;
			8'h02: out = 8'h77;
			8'h03: out = 8'h7b;
			8'h04: out = 8'hf2;
			8'h05: out = 8'h6b;
			8'h06: out = 8'h6f;
			8'h07: out = 8'hc5;
			8'h08: out = 8'h30;
			8'h09: out = 8'h01;
			8'h0a: out = 8'h67;
			8'h0b: out = 8'h2b;
			8'h0c: out = 8'hfe;
			8'h0d: out = 8'hd7;
			8'h0e: out = 8'hab;
			8'h0f: out = 8'h76;
			8'h10: out = 8'hca;
			8'h11: out = 8'h82;
			8'h12: out = 8'hc9;
			8'h13: out = 8'h7d;
			8'h14: out = 8'hfa;
			8'h15: out = 8'h59;
			8'h16: out = 8'h47;
			8'h17: out = 8'hf0;
			8'h18: out = 8'had;
			8'h19: out = 8'hd4;
			8'h1a: out = 8'ha2;
			8'h1b: out = 8'haf;
			8'h1c: out = 8'h9c;
			8'h1d: out = 8'ha4;
			8'h1e: out = 8'h72;
			8'h1f: out = 8'hc0;
			8'h20: out = 8'hb7;
			8'h21: out = 8'hfd;
			8'h22: out = 8'h93;
			8'h23: out = 8'h26;
			8'h24: out = 8'h36;
			8'h25: out = 8'h3f;
			8'h26: out = 8'hf7;
			8'h27: out = 8'hcc;
			8'h28: out = 8'h34;
			8'h29: out = 8'ha5;
			8'h2a: out = 8'he5;
			8'h2b: out = 8'hf1;
			8'h2c: out = 8'h71;
			8'h2d: out = 8'hd8;
			8'h2e: out = 8'h31;
			8'h2f: out = 8'h15;
			8'h30: out = 8'h04;
			8'h31: out = 8'hc7;
			8'h32: out = 8'h23;
			8'h33: out = 8'hc3;
			8'h34: out = 8'h18;
			8'h35: out = 8'h96;
			8'h36: out = 8'h05;
			8'h37: out = 8'h9a;
			8'h38: out = 8'h07;
			8'h39: out = 8'h12;
			8'h3a: out = 8'h80;
			8'h3b: out = 8'he2;
			8'h3c: out = 8'heb;
			8'h3d: out = 8'h27;
			8'h3e: out = 8'hb2;
			8'h3f: out = 8'h75;
			8'h40: out = 8'h09;
			8'h41: out = 8'h83;
			8'h42: out = 8'h2c;
			8'h43: out = 8'h1a;
			8'h44: out = 8'h1b;
			8'h45: out = 8'h6e;
			8'h46: out = 8'h5a;
			8'h47: out = 8'ha0;
			8'h48: out = 8'h52;
			8'h49: out = 8'h3b;
			8'h4a: out = 8'hd6;
			8'h4b: out = 8'hb3;
			8'h4c: out = 8'h29;
			8'h4d: out = 8'he3;
			8'h4e: out = 8'h2f;
			8'h4f: out = 8'h84;
			8'h50: out = 8'h53;
			8'h51: out = 8'hd1;
			8'h52: out = 8'h00;
			8'h53: out = 8'hed;
			8'h54: out = 8'h20;
			8'h55: out = 8'hfc;
			8'h56: out = 8'hb1;
			8'h57: out = 8'h5b;
			8'h58: out = 8'h6a;
			8'h59: out = 8'hcb;
			8'h5a: out = 8'hbe;
			8'h5b: out = 8'h39;
			8'h5c: out = 8'h4a;
			8'h5d: out = 8'h4c;
			8'h5e: out = 8'h58;
			8'h5f: out = 8'hcf;
			8'h60: out = 8'hd0;
			8'h61: out = 8'hef;
			8'h62: out = 8'haa;
			8'h63: out = 8'hfb;
			8'h64: out = 8'h43;
			8'h65: out = 8'h4d;
			8'h66: out = 8'h33;
			8'h67: out = 8'h85;
			8'h68: out = 8'h45;
			8'h69: out = 8'hf9;
			8'h6a: out = 8'h02;
			8'h6b: out = 8'h7f;
			8'h6c: out = 8'h50;
			8'h6d: out = 8'h3c;
			8'h6e: out = 8'h9f;
			8'h6f: out = 8'ha8;
			8'h70: out = 8'h51;
			8'h71: out = 8'ha3;
			8'h72: out = 8'h40;
			8'h73: out = 8'h8f;
			8'h74: out = 8'h92;
			8'h75: out = 8'h9d;
			8'h76: out = 8'h38;
			8'h77: out = 8'hf5;
			8'h78: out = 8'hbc;
			8'h79: out = 8'hb6;
			8'h7a: out = 8'hda;
			8'h7b: out = 8'h21;
			8'h7c: out = 8'h10;
			8'h7d: out = 8'hff;
			8'h7e: out = 8'hf3;
			8'h7f: out = 8'hd2;
			8'h80: out = 8'hcd;
			8'h81: out = 8'h0c;
			8'h82: out = 8'h13;
			8'h83: out = 8'hec;
			8'h84: out = 8'h5f;
			8'h85: out = 8'h97;
			8'h86: out = 8'h44;
			8'h87: out = 8'h17;
			8'h88: out = 8'hc4;
			8'h89: out = 8'ha7;
			8'h8a: out = 8'h7e;
			8'h8b: out = 8'h3d;
			8'h8c: out = 8'h64;
			8'h8d: out = 8'h5d;
			8'h8e: out = 8'h19;
			8'h8f: out = 8'h73;
			8'h90: out = 8'h60;
			8'h91: out = 8'h81;
			8'h92: out = 8'h4f;
			8'h93: out = 8'hdc;
			8'h94: out = 8'h22;
			8'h95: out = 8'h2a;
			8'h96: out = 8'h90;
			8'h97: out = 8'h88;
			8'h98: out = 8'h46;
			8'h99: out = 8'hee;
			8'h9a: out = 8'hb8;
			8'h9b: out = 8'h14;
			8'h9c: out = 8'hde;
			8'h9d: out = 8'h5e;
			8'h9e: out = 8'h0b;
			8'h9f: out = 8'hdb;
			8'ha0: out = 8'he0;
			8'ha1: out = 8'h32;
			8'ha2: out = 8'h3a;
			8'ha3: out = 8'h0a;
			8'ha4: out = 8'h49;
			8'ha5: out = 8'h06;
			8'ha6: out = 8'h24;
			8'ha7: out = 8'h5c;
			8'ha8: out = 8'hc2;
			8'ha9: out = 8'hd3;
			8'haa: out = 8'hac;
			8'hab: out = 8'h62;
			8'hac: out = 8'h91;
			8'had: out = 8'h95;
			8'hae: out = 8'he4;
			8'haf: out = 8'h79;
			8'hb0: out = 8'he7;
			8'hb1: out = 8'hc8;
			8'hb2: out = 8'h37;
			8'hb3: out = 8'h6d;
			8'hb4: out = 8'h8d;
			8'hb5: out = 8'hd5;
			8'hb6: out = 8'h4e;
			8'hb7: out = 8'ha9;
			8'hb8: out = 8'h6c;
			8'hb9: out = 8'h56;
			8'hba: out = 8'hf4;
			8'hbb: out = 8'hea;
			8'hbc: out = 8'h65;
			8'hbd: out = 8'h7a;
			8'hbe: out = 8'hae;
			8'hbf: out = 8'h08;
			8'hc0: out = 8'hba;
			8'hc1: out = 8'h78;
			8'hc2: out = 8'h25;
			8'hc3: out = 8'h2e;
			8'hc4: out = 8'h1c;
			8'hc5: out = 8'ha6;
			8'hc6: out = 8'hb4;
			8'hc7: out = 8'hc6;
			8'hc8: out = 8'he8;
			8'hc9: out = 8'hdd;
			8'hca: out = 8'h74;
			8'hcb: out = 8'h1f;
			8'hcc: out = 8'h4b;
			8'hcd: out = 8'hbd;
			8'hce: out = 8'h8b;
			8'hcf: out = 8'h8a;
			8'hd0: out = 8'h70;
			8'hd1: out = 8'h3e;
			8'hd2: out = 8'hb5;
			8'hd3: out = 8'h66;
			8'hd4: out = 8'h48;
			8'hd5: out = 8'h03;
			8'hd6: out = 8'hf6;
			8'hd7: out = 8'h0e;
			8'hd8: out = 8'h61;
			8'hd9: out = 8'h35;
			8'hda: out = 8'h57;
			8'hdb: out = 8'hb9;
			8'hdc: out = 8'h86;
			8'hdd: out = 8'hc1;
			8'hde: out = 8'h1d;
			8'hdf: out = 8'h9e;
			8'he0: out = 8'he1;
			8'he1: out = 8'hf8;
			8'he2: out = 8'h98;
			8'he3: out = 8'h11;
			8'he4: out = 8'h69;
			8'he5: out = 8'hd9;
			8'he6: out = 8'h8e;
			8'he7: out = 8'h94;
			8'he8: out = 8'h9b;
			8'he9: out = 8'h1e;
			8'hea: out = 8'h87;
			8'heb: out = 8'he9;
			8'hec: out = 8'hce;
			8'hed: out = 8'h55;
			8'hee: out = 8'h28;
			8'hef: out = 8'hdf;
			8'hf0: out = 8'h8c;
			8'hf1: out = 8'ha1;
			8'hf2: out = 8'h89;
			8'hf3: out = 8'h0d;
			8'hf4: out = 8'hbf;
			8'hf5: out = 8'he6;
			8'hf6: out = 8'h42;
			8'hf7: out = 8'h68;
			8'hf8: out = 8'h41;
			8'hf9: out = 8'h99;
			8'hfa: out = 8'h2d;
			8'hfb: out = 8'h0f;
			8'hfc: out = 8'hb0;
			8'hfd: out = 8'h54;
			8'hfe: out = 8'hbb;
			8'hff: out = 8'h16;
			default: out = 8'h00;
		endcase
	end
	initial _sv2v_0 = 0;
endmodule
