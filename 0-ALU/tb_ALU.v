`timescale 1ns/1ns
module tb_ALU;
    reg [31:0] a;
    reg [31:0] b;
    reg [3:0] alu_control;
    wire [31:0] result;
    wire zero;
    integer errors=0;

    ALU u_ALU(
        .a(a),
        .b(b),
        .alu_control(alu_control),
        .result(result),
        .zero(zero)
    );

    initial begin
        a=32'hFFFF_FFFF;
        b=32'h1;
        alu_control=4'd0;
        #10;
        if(result!==32'h0) begin
            $display("ADD fail,result=%h,expect 32'd0",result);
            errors=errors+1;
        end else $display("ADD PASS");
        if(zero!==1) begin
             $display("zero fail,zero=%d,expect 1",zero);
            errors=errors+1;
        end else $display("zero PASS");
         

        a=32'd3;
        b=32'd5;
        alu_control=4'd1;
        #10;
        if(result!==32'hFFFF_FFFE) begin
            $display("SUB fail,result=%h,expect 32'hFFFF_FFFE",result);
            errors=errors+1;
        end else $display("SUB PASS");
        if(zero!==0) begin
             $display("zero fail,zero=%d,expect 0",zero);
            errors=errors+1;
        end else $display("zero PASS");
      

        a=32'hF0F0_F0F0;
        b=32'h0FF0_0FF0;
        alu_control=4'd2;
        #10;
        if(result!==32'h00F0_00F0) begin
            $display("AND fail,result=%h,expect 32'h00F0_00F0",result);
            errors=errors+1;
        end else $display("AND PASS");
         
        alu_control=4'd3;
        #10;
        if(result!==32'hFFF0_FFF0) begin
            $display("OR fail,result=%h,expect 32'hFFF0_FFF0",result);
            errors=errors+1;
        end else $display("OR PASS");


        
        alu_control=4'd15;
        #10;
        if(result!==32'h0) begin
            $display("default fail,result=%h,expect 32'h0",result);
            errors=errors+1;
        end else $display("default PASS");
         if(zero!==1) begin
            $display("zero fail,zero=%d,expect 1",zero);
            errors=errors+1;
        end else $display("zero test PASS");

        if(errors==0) begin
        $display("ALL PASS");
        end else $display("%d Errors",errors);
        $finish;
    end
    


endmodule