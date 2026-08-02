`timescale 1ns/1ns

module tb_regfile;
    reg clk,we;
    wire [31:0]rdata1,rdata2;
    reg [31:0]wdata;
    reg [4:0]raddr1,raddr2,waddr;
    integer errors=0;

    regfile u_regfile(
        .clk(clk),
        .we(we),
        .rdata1(rdata1),
        .rdata2(rdata2),
        .raddr1(raddr1),
        .raddr2(raddr2),
        .wdata(wdata),
        .waddr(waddr)
    );

    initial clk=0;
    always #10 clk=~clk;
    
    initial begin      
        we=0;
        waddr=0;
        wdata=0;
        raddr1=0;
        raddr2=0;
        u_regfile.regs[3]=32'h5555_5555;
        u_regfile.regs[2]=32'hAAAA_AAAA;
        #1;
        if(rdata1!==32'd0) begin
            $display("FAIL: x0 = %h, expect 0", rdata1);
            errors=errors+1;
        end else $display("PASS: x0 reads 0");
        
        @(negedge clk);
        we=1;
        waddr=5'd1;
        wdata=32'h1234_5678;
        @(posedge clk);
        #1;
        we=0;
        raddr1=5'd1;
        raddr2=5'd1;
        #1;
        if(rdata1!==32'h1234_5678) begin
            $display("FAIL: port1 x1 = %h", rdata1);
            errors = errors +1;
        end else $display("PASS: port1 reads x1");
        if(rdata2!==32'h1234_5678) begin
            $display("FAIL: port2 x1 = %h", rdata2);
            errors = errors +1;
        end else $display("PASS: port2 reads x1");

        @(negedge clk);
        we=1;
        waddr=5'd0;
        wdata=32'hFFFF_FFFF;
        @(posedge clk);
        #1;
        we=0;
        raddr1=5'd0;
        #1;
        if(rdata1!==32'h0000_0000) begin
            $display("FAIL: x0 = %h,expect 0", rdata1);
            errors = errors +1;
        end else $display("PASS: reads x0");

        @(posedge clk);
        #1;
        we=0;
        raddr1=5'd2;
        raddr2=5'd3;
        #1;
        if(rdata1!==32'hAAAA_AAAA) begin
            $display("FAIL: x2 = %h,expect 0xAAAA_AAAA", rdata1);
            errors = errors +1;
        end else $display("PASS: reads x2");
         if(rdata2!==32'h5555_5555) begin
            $display("FAIL: x3 = %h,expect 0x5555_5555", rdata2);
            errors = errors +1;
        end else $display("PASS: reads x3");

         @(negedge clk);
        we=1;
        waddr=5'd5;
        wdata=32'h1111_1111;
        @(posedge clk);
        #1;
        we=0;
        raddr1=5'd5;
        #1;
        if(rdata1!==32'h1111_1111) begin
            $display("FAIL: x5 = %h, expect 0x1111_1111", rdata1);
            errors=errors+1;
        end else $display("PASS: reads x5");
        @(negedge clk);
        we=1;
        waddr=5'd5;
        wdata=32'h2222_2222;
        @(posedge clk);
        #1;
        we=0;
        raddr1=5'd5;
        #1;
         if(rdata1!==32'h2222_2222) begin
            $display("FAIL: x5 = %h, expect 0x2222_2222", rdata1);
            errors=errors+1;
        end else $display("PASS: reads x5");

        if(errors==0) $display("ALL PASS");
        else         $display("%0d ERRORS",errors);

         $finish;
    end
        
endmodule