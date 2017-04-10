//3 input majority
module MajorityVoter (A, B, C, out ,fault1, fault0);
	input A,B,C;
	input fault1, fault0;
	output out;
	wor wi1, wi2, wi3;
	wor out;
	// fault1=0 fault0=0 output fault free
	// fault1=1 fault0=0 output S a B
	// fault1=0(1) fault0=1 output Maj(A',B,C')
	assign wi1 = (A & B) | (B & C) | (A & C);
	assign wi3 = (~A & B) | (B & ~C) | (~A & ~C);
	assign wi2 = (fault1) ? B : wi1;
	assign out = (fault0) ?  wi3: wi2;
endmodule

//LshapedWire
module LShapedWire_4 (A, B, fault);
//forward =1 information goes A-> B
//status 00=relax,01=switch, 10=hold, 11=release
// if fault =1 the output is inverted
	//input [1:0] status;
	input A,fault;
	output B ;
	//inout A,B;
	
	assign B =  fault? ~A : A;	  
endmodule

module Fanout (in, out1, out2, fault);
	input in, fault;
	output out1, out2;
	// if fault =1 the out2 is inverted
	assign out1 = in;
	assign out2 = fault ? ~in : in;
endmodule

module Correction(sum1, sum2, sum3, Cout, Tens);
	input sum1, sum2, sum3, Cout;
	output Tens;
	
	//fanout
	wire fout1, fout2, faultf0;
	assign faultf0 = 1'b0;
	Fanout fo0(sum3, fout1, fout2, faultf0);
	
	//L-shaped wires
	wire lout1, lout2, faultls0, faultls1;
	assign faultls0 = 1'b0;
	assign faultls1 = 1'b0;
	LShapedWire_4 ls0(fout1,lout1,faultls0);
	LShapedWire_4 ls1(fout2,lout2,faultls1);
	
	//sum1 adn sum2, 3 input maj
	wire maj3out0, maj3out1, fault3mj0, fault3mj1, fault3mj2, fault3mj3;
	assign fault3mj0 = 1'b0;
	assign fault3mj1 = 1'b0;
	assign fault3mj2 = 1'b0;
	assign fault3mj3 = 1'b0;
	MajorityVoter mv0(lout1, sum1, 1'b0, maj3out0, fault3mj0, fault3mj1);
	MajorityVoter mv1(lout2, sum2, 1'b0, maj3out1, fault3mj2, fault3mj3);
	
	//L-shapred wire
	wire lout3, faultls2;
	assign faultls2 = 1'b0;
	LShapedWire_4 ls2(maj3out0,lout3,faultls2);
	
	//or gate
	wire maj3out2, maj3out3, fault3mj4, fault3mj5, fault3mj6, fault3mj7;
	assign fault3mj4 = 1'b0;
	assign fault3mj5 = 1'b0;
	assign fault3mj6 = 1'b0;
	assign fault3mj7 = 1'b0;
	MajorityVoter mv2(lout3, maj3out1, 1'b1, maj3out2, fault3mj4, fault3mj5);
	MajorityVoter mv3(Cout, maj3out2, 1'b1, maj3out3, fault3mj4, fault3mj5);
	
	assign Tens = maj3out3;
endmodule
	
module test;
	reg  sum1; 
	reg  sum2;
	reg  sum3;
	reg  Cout;
	reg clk;
	
	reg [3:0] counter;
	wire Tens;
	
	initial begin
		sum1 = 0;
		sum2 = 0;
		sum3 = 0;
		counter = 0;
		clk = 0;
	end
	
	Correction go(
		.sum1(sum1),
		.sum2(sum2),
		.sum3(sum3),
		.Cout(Cout),
		.Tens(Tens)
		);
		
	always #5 clk <= ~clk;
		always @ (posedge(clk))
			begin
				counter <= counter + 1;
				{sum1,sum2,sum3,Cout} <= counter;
	end
	
	initial begin
		$dumpfile("TestCor.txt");
		$dumpvars(0,test);
	end		
endmodule