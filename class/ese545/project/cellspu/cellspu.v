// Yufei Ren (yufren@ic.sunysb.edu)
// Cell SPU processor - Lite edition implementation
// for ESE 545 project
module cellspu #(parameter RFWIDTH = 128, WIDTH = 32, REGBITS = 7)
             (input              clk, reset,
              input  [WIDTH-1:0] instrdata0, instrdata1,
	      input  [RFWIDTH-1:0] memdata, writedata,
              output             memread, memwrite, 
              output [WIDTH-1:0] adr);

   // wire: connect the controller and datapath
   wire [31:0] instr0, instr1;
   wire        zero, alusrca, memtoreg, iord, pcen, regwrite, regdst;
   wire [1:0]  aluop,pcsource,alusrcb;
   wire [3:0]  irwrite;
   wire [2:0]  alucont;

   // controller - instr bits from 0:10 is opcode
//   controller  cont(clk, reset, instr0[31:21], zero, memread, memwrite, 
//                    alusrca, memtoreg, iord, pcen, regwrite, regdst,
//                    pcsource, alusrcb, aluop, irwrite);

   // alu controller?
   alucontrol  ac(aluop, instr0[5:0], alucont);

   // datapath
   datapath    #(RFWIDTH, WIDTH, REGBITS)
               dp(clk, reset, instrdata0, instrdata1, memdata, alusrca, memtoreg, iord, pcen,
                  regwrite, regdst, pcsource, alusrcb, irwrite, alucont,
                  zero, instr0, instr1, adr, writedata);

endmodule // cellspu


module datapath #(parameter RFWIDTH = 128, WIDTH = 32, REGBITS = 7)
                 (input              clk, reset, 
                  input  [WIDTH-1:0] memdata0, memdata1,
		  input  [RFWIDTH-1:0] memdata,
                  input              alusrca, memtoreg, iord, pcen, regwrite, regdst,
                  input  [1:0]       pcsource, alusrcb, 
                  input  [3:0]       irwrite, 
                  input  [2:0]       alucont, 
                  output             zero, 
                  output [31:0]      instr0, instr1,
                  output [WIDTH-1:0] adr,
                  output [RFWIDTH-1:0] writedata);

   localparam CONST_ZERO = 32'b0;
   localparam CONST_ONE =  32'b1;

   wire [REGBITS-1:0] ra1, ra2, wa, ra, rb, rt;
   wire [WIDTH-1:0]   pc, nextpc, rd1, rd2, wd, a, src1, src2, aluresult,
                          aluout, constx4;
   wire [2:0] 	      evencont, oddcont;
   wire [15:0] 	      i16_0, i16_1;
   wire [9:0] 	      i10_0, i10_1;
   wire               i10_en_0, i16_en_1;
   wire [6:0]         reg_ra_0, reg_rb_0, reg_rt_0, reg_ra_1, reg_rb_1, reg_rt_1;
   wire [RFWIDTH-1:0]       reg_rd1, reg_rd2;
   wire [RFWIDTH-1:0]       ep_result; // even pipe result
   wire [RFWIDTH-1:0]       op_result; // odd pipe result
   wire [RFWIDTH-1:0] 	    md;

   wire 		    i_en_0, i_en_1, even_or_odd_0, even_or_odd_1;
   
   
   // according to instruction type
   // get register file address fields
   // assign ra1 = instr[REGBITS+20:21];
   // assign ra2 = instr[REGBITS+15:16];
   // mux2       #(REGBITS) regmux(instr[REGBITS+15:16], instr[REGBITS+10:11], regdst, wa);

//   assign ra = instr[20:14];
//   assign rb = instr[13:7];
//   assign rt = instr[6:0];
   
   // load instruction into buffer - instr
//   flopen #(32) ir(clk, irwrite[0], memdata[31:0], instr[31:0]);
   flopen #(WIDTH) ir0(clk, 1, memdata0[31:0], instr0[31:0]);
   flopen #(WIDTH) ir1(clk, 1, memdata1[31:0], instr1[31:0]);
   
   // decode and check if there is any hazard
   decodeen #(WIDTH) id(clk, 1, instr0[31:0], instr1[31:0], i_en_0, i_en_1, even_or_odd_0, even_or_odd_1, reg_ra_0, reg_ra_1, reg_rb_0, reg_rb_1, reg_rt_0, reg_rt_1, i10_en_0, i10_en_1, i16_en_0, i16_en_1, i10_0, i10_1, i16_0, i16_1);
   
   
   // datapath
   // program counter
   pcalu      #(WIDTH)  pcalu(clk, reset, 1'b1, pc, nextpc);
   flopenr    #(WIDTH)  pcreg(clk, reset, 1'b1, nextpc, pc);

   // memory data register
   flop       #(RFWIDTH)  mdr(clk, memdata, md);
   
   flop       #(WIDTH)  areg(clk, rd1, a);	
//   flop       #(WIDTH)  wrd(clk, rd2, writedata);
   flop       #(WIDTH)  res(clk, aluresult, aluout);
//   mux2       #(WIDTH)  adrmux(pc, aluout, iord, adr);
   mux2       #(WIDTH)  adrmux(pc, aluout, 0, adr);
   mux2       #(WIDTH)  src1mux(pc, a, alusrca, src1);
//   mux4       #(WIDTH)  src2mux(writedata, CONST_ONE, instr[WIDTH-1:0], 
//                                constx4, alusrcb, src2);
//   mux4       #(WIDTH)  pcmux(aluresult, aluout, constx4, CONST_ZERO, pcsource, nextpc);
//   mux2       #(WIDTH)  wdmux(aluout, md, memtoreg, wd); today
   // register file
   regfile    #(RFWIDTH,WIDTH,REGBITS) rf(clk, regwrite, i_en_0, i_en_1, even_or_odd_0, even_or_odd_1, reg_ra_0, reg_ra_1, reg_rb_0, reg_rb_1, reg_rt_0, reg_rt_1, wa, ep_result, i10_en_0, i10_en_1, i16_en_0, i16_en_1, i10_0, i10_1, i16_0, i16_1, evencont, oddcont, reg_rd1, reg_rd2);
//   regfile    #(WIDTH,REGBITS) rf(clk, regwrite, ra1, ra2, wa, wd, rd1, rd2);
   // even pipe integer unit
   epfx       #(RFWIDTH) evenpipe(reg_rd1, reg_rd2, evencont, ep_result);
//   opls       #(WIDTH) oddpipe(src1, src2, alucont, aluresult);

   zerodetect #(WIDTH) zd(aluresult, zero);

endmodule // datapath

module flop #(parameter WIDTH = 32)
             (input                  clk, 
              input      [WIDTH-1:0] d, 
              output reg [WIDTH-1:0] q);

   always @(posedge clk)
      q <= d;
endmodule

module decodeen #(parameter WIDTH = 32)
		   (input clk, en,
		    input [WIDTH-1:0] instr0, instr1,
		    output reg i_en_0, i_en_1, even_or_odd_0, even_or_odd_1,
		    output reg [6:0] ra_0, ra_1, rb_0, rb_1, rt_0, rt_1,
		    output reg i10_en_0, i10_en_1, i16_en_0, i16_en_1,
		    output reg [9:0] i10_0, i10_1,
		    output reg [15:0] i16_0, i16_1);


   parameter   LQX     = 11'b00111000100;     // load quadword (x-form)
   parameter   STQX    = 11'b00101000100;     // store quadword (x-form)
   parameter   IL      =  9'b010000001;       // immediate load word
//   parameter   IL      = 11'b010000001??;     // immediate load word
   parameter   AH      = 11'b00011001000;     // add halfword
   parameter   A       = 11'b00011000000;     // add word
   parameter   AI      =  8'b00011100;        // add word immediate
   parameter   SF      = 11'b00010000000;     // subtract from word
   parameter   SFI     =  8'b00001100;        // subtract from word immediate
   parameter   MPY     = 11'b01111000100;     // multiply
   parameter   MPYI    =  8'b01110100;        // multiply immediate
   parameter   AVGB    = 11'b00011010011;     // average bytes
   parameter   ABSDB   = 11'b00001010011;     // absolute differences of bytes
   parameter   GBB     = 11'b00110110010;     // gather bits from bytes
   parameter   AND     = 11'b00011000001;     // and
   parameter   OR      = 11'b00001000001;     // or
   parameter   XOR     = 11'b01001000001;     // exclusive or
   parameter   NAND    = 11'b00011001001;     // nand
   parameter   NOR     = 11'b00001001001;     // nor
   parameter   SHL     = 11'b00001011011;     // shift left word
   parameter   ROT     = 11'b00001011000;     // rotate word

   parameter   BR      =  9'b001100100;       // branch relative
   parameter   BRA     =  9'b001100000;       // branch absolute
   parameter   BRNZ    =  9'b001000010;       // branch if not zero word
   parameter   BRHNZ   =  9'b001000110;       // branch if not zero halfword
   parameter   HBR     = 11'b00110101100;     // hint for branch (r-form)

   parameter   FA      = 11'b01011000100;     // floating add
   parameter   FS      = 11'b01011000101;     // floating subtract
   parameter   FM      = 11'b01011000110;     // floating multiply
   parameter   FCEQ    = 11'b01111000010;     // floating compare equal
   parameter   FCGT    = 11'b01011000010;     // floating compare greater than

   always @(posedge clk)
      if (en)
      begin
	 i16_en_0 <= 0;
	 i16_en_1 <= 0;
	 i10_en_0 <= 0;
	 i10_en_1 <= 0;

         i_en_0 <= 1; // the previous instruction would execute first
         i_en_1 <= 0; // if no hazard, the next instruction could execute follows by
         even_or_odd_0 <= 0;
         even_or_odd_1 <= 0;

      // decode instr0	 
	// 9 bit instruction decode
         case(instr0[31:23])
            IL:
	       begin
	          rt_0 <= instr0[6:0];
	          i16_0 <= instr0[22:7];
	          i16_en_0 <= 1;
	       end
	 endcase // case (instr[31:23])
         case(instr1[31:23])
            IL:
	       begin
	          rt_1 <= instr1[6:0];
	          i16_1 <= instr1[22:7];
	          i16_en_1 <= 1;
	       end
	 endcase // case (instr[31:23])

        // 11 bit instruction decode	
	case(instr0[31:21])
          A:
            begin
               ra_0 <= instr0[20:14];
               rb_0 <= instr0[13:7];
               rt_0 <= instr0[6:0];
            end
	endcase // case (instr[31:21])
	case(instr1[31:21])
          A:
            begin
               ra_1 <= instr1[20:14];
               rb_1 <= instr1[13:7];
               rt_1 <= instr1[6:0];
            end
	endcase // case (instr[31:21])
      end
endmodule // decode
		   
		   
module flopen #(parameter WIDTH = 32)
               (input                  clk, en,
                input      [WIDTH-1:0] d, 
                output reg [WIDTH-1:0] q);

   always @(posedge clk)
   //begin
      if (en) q <= d;
   //$display("%b",q);
   //$finish;
   //end
endmodule

module flopenr #(parameter WIDTH = 32)
                (input                  clk, reset, en,
                 input      [WIDTH-1:0] d, 
                 output reg [WIDTH-1:0] q);
 
//   always @(posedge clk)
   always @(*)
      if      (reset) q <= 0;
      else if (en)    q <= d;
endmodule

module pcalu #(parameter WIDTH = 32)
                (input                  clk, reset, en,
                 input      [WIDTH-1:0] d, 
                 output reg [WIDTH-1:0] q);

   wire [WIDTH-1:0] 			nextpc;

   assign nextpc = d + 8;
   
   always @(posedge clk)
      if      (reset) q <= 0;
      else if (en)    q <= nextpc;
endmodule

module mux2 #(parameter WIDTH = 32)
             (input  [WIDTH-1:0] d0, d1, 
              input              s, 
              output [WIDTH-1:0] y);

   assign y = s ? d1 : d0; 
endmodule

module mux4 #(parameter WIDTH = 32)
             (input      [WIDTH-1:0] d0, d1, d2, d3,
              input      [1:0]       s, 
              output reg [WIDTH-1:0] y);

   always @(*)
      case(s)
         2'b00: y <= d0;
         2'b01: y <= d1;
         2'b10: y <= d2;
         2'b11: y <= d3;
      endcase
endmodule

module epfx #(parameter WIDTH = 128)
            (input      [WIDTH-1:0] a, b, 
             input      [2:0]       alucont, 
             output reg [WIDTH-1:0] result);

   wire     [WIDTH-1:0] b2, sum, slt;

   assign b2 = alucont[2] ? ~b:b; 
   assign sum = a + b2 + alucont[2];
   // slt should be 1 if most significant bit of sum is 1
   assign slt = sum[WIDTH-1];

   always@(*)
      case(alucont[1:0])
         2'b00: result <= a & b; // asynchronize way
         2'b01: result <= a | b;
         2'b10: result <= sum;
         2'b11: result <= slt;
      endcase
endmodule

module opls #(parameter WIDTH = 32)
            (input      [WIDTH-1:0] a, b, 
             input      [2:0]       alucont, 
             output reg [WIDTH-1:0] result);

   wire     [WIDTH-1:0] b2, sum, slt;

   assign b2 = alucont[2] ? ~b:b; 
   assign sum = a + b2 + alucont[2];
   // slt should be 1 if most significant bit of sum is 1
   assign slt = sum[WIDTH-1];

   always@(*)
      case(alucont[1:0])
         2'b00: result <= a & b; // asynchronize way
         2'b01: result <= a | b;
         2'b10: result <= sum;
         2'b11: result <= slt;
      endcase
endmodule


module zerodetect #(parameter WIDTH = 32)
                   (input [WIDTH-1:0] a, 
                    output            y);

   assign y = (a==0);
endmodule