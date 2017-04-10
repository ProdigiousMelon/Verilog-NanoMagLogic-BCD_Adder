//wire
module Wire_4 (A, B, status);
//forward =1 information goes A-> B
//status 00=relax,01=switch, 10=hold, 11=release
	input [1:0] status;
	inout B;
	input A;
	reg loaded,regg;
	wor B,A;
assign B =  (status == 2'b10) ? loaded :
	    (status == 2'b01) ?	 A     :
	     1'bz;
initial
loaded =1'bZ;

always @(posedge status[1])
	begin
		if (status[0]==0)
			begin
				loaded <= (A===1'bx)? 1'bz : A;
			end
	end
endmodule

//fanouts
module Fanout (in, out1, out2, fault);
	input in, fault;
	output out1, out2;
	// if fault =1 the out2 is inverted
	assign out1 = in;
	assign out2 = fault ? ~in : in;
endmodule

//inverter
module Inverter (in, out, fault);
	input in, fault;
	output out;
	// if fault =1  out is not inverted
	assign out = fault ? in : ~in;
endmodule

//crosswire
module Crosswire (in1, in2, out1, out2, fault0, fault1);
	input in1, in2,  fault0, fault1;
	output out1, out2;
	// if ~fault1 && fault0  out1  is ~in1
	// if   fault1  && ~fault0 out2 is ~in1 (interference) 
	assign out1 = fault0 ? (~fault1 ? ~in1 : in1) : in1;
	assign out2 = fault1 ? (~fault0 ? ~in1 :in2)  : in2 ;
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

//3-input-majority
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

//5-input majority
module FMajorityVoter (A, B, C, D, E, out ,fault1, fault0);
	input A,B,C,D,E;
	input fault1, fault0;
	output out;
	wor wi1, wi2, wi3;
	wor out;
	// fault1=0 fault0=0 output fault free
	// fault1=1 fault0=0 output S a B
	// fault1=0(1) fault0=1 output Maj(A',B,C')
	assign wi1 = (A & B & C) | (A & B & D) | (A & B & E) | (A & C & D) |
				 (A & C & D) | (A & C & E) | (A & D & E) | (B & C & D) |
				 (B & C & E) | (B & D & E) | (C & D & E);
	assign wi3 = (~A & B) | (B & ~C) | (~A & ~C);
	assign wi2 = (fault1) ? B : wi1;
	assign out = (fault0) ?  wi3: wi2;
endmodule

//QCA Fulladder
module QCAFA(a,b,cin,sum,carry);
	input a, b, cin; 
	output sum , carry;
	
	//first crosswire
	wire acw0, bcw0, faultcw0, faultcw1;
	assign faultcw0 = 1'b0;
	assign faultcw1 = 1'b0;
	Crosswire cw1(a, b, acw0, bcw0, faultcw0,faultcw1);
	
	// A l-shaped
	wire als0, faultals0;
	assign faultals0 = 1'b0;	
	LShapedWire_4 ls1(a , als0,faultals0);
	
	// B l-shaped
	wire bls0, faultbls0;
	assign faultbls0 = 1'b0;
	LShapedWire_4 ls2(b , bls0,faultbls0);
	
	//first 3-input majority
	wire maj3out, fault3mj0, fault3mj1;
	assign fault3mj0 = 1'b0;
	assign fault3mj1 = 1'b0;
	MajorityVoter maj3(als0,bcw0,cin,maj3out,fault3mj0,fault3mj1);
	
	//inverter for 3-input maj
	wire invout, faultinv0;
	assign faultinv0 = 1'b0;
	Inverter inv0(maj3out,invout,faultinv0);
	
	//5 input majority
	wire maj5out, fault5mj0, fault5mj1;
	assign fault5mj0 = 1'b0;
	assign fault5mj1 = 1'b0;	
	FMajorityVoter maj5(acw0,bls0,cin,invout,invout, maj5out,fault5mj0,fault5mj1);
	
	//crosswire for 5 and 3-input
	wire cw3out, cw5out, faultcw2, faultcw3;
	assign faultcw2 = 1'b0;
	assign faultcw3 = 1'b0;
	Crosswire cw2(maj3out,maj5out, cw3out, cw5out, faultcw2, faultcw3);
	
	assign sum = cw5out;
	assign carry = cw3out;
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

module rc(a,b,sum, Tens);
	input [3:0] a, b;
	wire [3:0] topsum;
	output Tens;
	wire Cout, bCout;
	output [3:0] sum;

	
	wire [3:0] cchain; //top carry chain
	wire [3:0] bcchain; //bottom carry chain

	
	//4 bit ripple carry
	QCAFA add0(a[0],b[0],1'b0,topsum[0],cchain[0]);
	
	//first connective wire
	wire twcchain0;
	wire [1:0] faulttwc0;
	assign faulttwc0 = 2'b01;
	Wire_4 tw0(cchain[0],twcchain0, faulttwc0);
	
	
	QCAFA add1(a[1],b[1],twcchain0,topsum[1],cchain[1]);
	QCAFA add2(a[2],b[2],cchain[1],topsum[2],cchain[2]);
	QCAFA add3(a[3],b[3],cchain[2],topsum[3],Cout);
	
	//fanout from the top 4-bit ripple carry
	wire sum3fo0, sum3fo1, sum3f, sum2fo0, sum2fo1, sum2f, sum1fo0, sum1fo1, sum1f;
	assign sum3f = 1'b0;
	assign sum2f = 1'b0;
	assign sum1f = 1'b0;
	Fanout sum3fo(topsum[3],sum3fo0,sum3fo1,sum3f);
	Fanout sum2fo(topsum[2],sum2fo0,sum2fo1,sum2f);
	Fanout sum1fo(topsum[1],sum1fo0,sum1fo1,sum1f);
	
	Correction cor(sum1fo0,sum2fo0,sum3fo0,Cout,Tens);
	
	QCAFA badd0(1'b0,topsum[0],1'b0,sum[0],bcchain[0]);
	QCAFA badd1(Tens,sum1fo1,bcchain[0],sum[1],bcchain[1]);
	QCAFA badd2(Tens,sum2fo1,bcchain[1],sum[2],bcchain[2]);
	QCAFA badd3(1'b0,sum3fo1,bcchain[2],sum[3],bCout);

	
endmodule

module test;
	//inputs
	reg [3:0] a; 
	reg [3:0] b;
	
	//outputs
	wire [3:0] sum;
	wire Tens;
	
	reg tester;
	
	integer i,j;
	
	rc go(
		.a(a),
		.b(b),
		.sum(sum),
		.Tens(Tens)
	);
	
	initial begin
		//initialize inputs
		a=0;
		b=0;
	end
	
	always @ (a,b)
		begin
		
		for(i=0; i < 16; i = i + 1)
		begin
			for(j=0;j<16;j=j+1)
			begin
				a=i; b=j;
				#10
				tester=(sum==a+b);
				$monitor("a=%b, b=%b, sum=%b, carry=%h, test=%d",a, b, sum, Tens, tester);
			end
		end
			
		#20 $stop;	
	end
	
	initial begin
		$dumpfile("BCDFinalout.txt");
		$dumpvars(0,test);
	
	end
endmodule