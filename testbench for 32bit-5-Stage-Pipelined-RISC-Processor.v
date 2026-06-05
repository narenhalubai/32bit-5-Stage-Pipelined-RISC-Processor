module tb_Processor;
    reg clk;
    integer i;

    Processor uut(.clk(clk));

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_Processor);

        for (i = 0; i < 144; i = i + 1)
            uut.IM.memory[i] = 8'h00;

        for (i = 0; i < 32; i = i + 1)
            uut.RF.Registers[i] = 32'd0;

        uut.RF.Registers[1] = 32'd10;
        uut.RF.Registers[2] = 32'd25;

        uut.IM.memory[0] = 8'h00;
        uut.IM.memory[1] = 8'h22;
        uut.IM.memory[2] = 8'h18;
        uut.IM.memory[3] = 8'h20;

        #200;

        $display("r1 = %0d", uut.RF.Registers[1]);
        $display("r2 = %0d", uut.RF.Registers[2]);
        $display("r3 add result = %0d", uut.RF.Registers[3]);

        $finish;
    end
endmodule
