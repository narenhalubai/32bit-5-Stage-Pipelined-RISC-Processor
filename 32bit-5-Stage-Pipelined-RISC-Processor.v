`timescale 1ns / 1ps

module Processor(clk);
    input clk;
    wire PCsrc;

    wire [31:0] pc, instruction, ReadData1, ReadData2, ALUOut, SEOut;
    wire [31:0] PCin0, PCin1, shl, ALUroute, MemRoute, PCRoute, DataMemoryOut;
    wire [31:0] OutInstruction, OutPCin0, out_address, out_Readdata1, out_Readdata2, out_extended;
    wire [31:0] outAddResult, outALUResult, outReadData2, outReadData, outAddress;
    wire [3:0] ALUCtrlOut;
    wire [4:0] RdRoute, out_Instruction15_11, out_Instruction20_16, outWriteBack, outWriteBackfinal, out_Instruction10_6;
    wire RegDst, RegWrite, ALUSrc, Branch, MemRead, MemWrite, MemtoReg, ALUZero, LoadHalf, LoadHalfUnsigned;
    wire [2:0] ALUop, out_ALUop;
    wire out_WB, out_MemtoReg, out_RegDst, out_AlUsrc, out_MR, out_MW, out_branch;
    wire out_LoadHalf, out_LoadHalfUnsigned, outWB, outMemtoReg, outMR, outMW, outbranch, outZero;
    wire outLoadHalf, outLoadHalfUnsigned, outWBRegWrite, outWBMemtoReg;

    Adder PCadder0(PCin0, pc, 32'd4);
    Adder PCadder1(PCin1, out_address, shl);
    shiftLeft2 SHL2(shl, clk, out_extended);
    Mux2way32 PCMux(PCRoute, PCin0, outAddResult, PCsrc);
    ProgramCounter PC(pc, PCRoute, clk);
    InstructionMemory IM(instruction, PCRoute, clk);

    IFID IFID_stage(OutPCin0, OutInstruction, PCin0, instruction, clk);

    IDEX IDEX_stage(
        out_LoadHalf, out_LoadHalfUnsigned, out_WB, out_MemtoReg, out_MR, out_MW, out_branch,
        out_RegDst, out_ALUop, out_AlUsrc, out_address, out_Readdata1, out_Readdata2, out_extended,
        out_Instruction20_16, out_Instruction15_11, out_Instruction10_6,
        RegWrite, MemtoReg, MemRead, MemWrite, Branch, RegDst, ALUop, ALUSrc,
        OutPCin0, ReadData1, ReadData2, SEOut,
        OutInstruction[20:16], OutInstruction[15:11], OutInstruction[10:6],
        LoadHalf, LoadHalfUnsigned, clk
    );

    EXMEM EXMEM_stage(
        outLoadHalf, outLoadHalfUnsigned, outWB, outMemtoReg, outMR, outMW, outbranch,
        outAddResult, outZero, outALUResult, outReadData2, outWriteBack,
        out_WB, out_MemtoReg, out_MR, out_MW, out_branch, PCin1, ALUZero, ALUOut,
        out_Readdata2, RdRoute, out_LoadHalf, out_LoadHalfUnsigned, clk
    );

    MEMWEB MEMWEB_stage(
        outReadData, outWBRegWrite, outWBMemtoReg, outAddress, outWriteBackfinal,
        DataMemoryOut, outALUResult, outWB, outMemtoReg, outWriteBack, clk
    );

    RegisterFile RF(ReadData1, ReadData2, OutInstruction[25:21], OutInstruction[20:16], outWriteBackfinal, MemRoute, outWBRegWrite, clk);
    ALUControl ALUCtrl(ALUCtrlOut, out_ALUop, out_extended[5:0]);
    ALU ALU_stage(ALUOut, ALUZero, ALUCtrlOut, out_Readdata1, ALUroute, out_Instruction10_6);
    DataMemory DM(DataMemoryOut, outReadData2, outALUResult, outMR, outMW, outLoadHalf, outLoadHalfUnsigned, clk);
    ControlUnit CU(LoadHalf, LoadHalfUnsigned, RegDst, RegWrite, ALUSrc, Branch, MemRead, MemWrite, MemtoReg, ALUop, OutInstruction[31:26]);

    and PCSrc(PCsrc, outZero, outbranch);

    Mux2way5 InstructionMux(RdRoute, out_Instruction20_16, out_Instruction15_11, out_RegDst);
    Mux2way32 RegMux(ALUroute, out_Readdata2, out_extended, out_AlUsrc);
    Mux2way32 MemMux(MemRoute, outAddress, outReadData, outWBMemtoReg);
    SignExtend SE(SEOut, OutInstruction[15:0]);
endmodule

module Adder(out, input1, input2);
    input wire [31:0] input1;
    input wire [31:0] input2;
    output reg [31:0] out;

    always @(*) begin
        out = input1 + input2;
    end
endmodule

module shiftLeft2(shifted, clk, sign_extended);
    input wire clk;
    input wire [31:0] sign_extended;
    output reg [31:0] shifted;

    always @(*) begin
        shifted = sign_extended << 2;
    end
endmodule

module Mux2way32(data_out, a, b, sel);
    output reg [31:0] data_out;
    input wire [31:0] a, b;
    input wire sel;

    always @(*) begin
        if (sel)
            data_out = b;
        else
            data_out = a;
    end
endmodule

module Mux2way5(data_out, a, b, sel);
    output reg [4:0] data_out;
    input wire [4:0] a, b;
    input wire sel;

    always @(*) begin
        if (sel)
            data_out = b;
        else
            data_out = a;
    end
endmodule

module ProgramCounter(NextPC, Address, clk);
    output reg [31:0] NextPC;
    input wire [31:0] Address;
    input wire clk;

    initial begin
        NextPC = 32'hFFFFFFFC;
    end

    always @(posedge clk) begin
        NextPC <= Address;
    end
endmodule

module InstructionMemory(instruction, address, clk);
    input wire clk;
    input wire [31:0] address;
    output reg [31:0] instruction;
    reg [7:0] memory [0:143];

    always @(posedge clk) begin
        instruction[31:24] <= memory[address];
        instruction[23:16] <= memory[address + 1];
        instruction[15:8] <= memory[address + 2];
        instruction[7:0] <= memory[address + 3];
    end
endmodule

module IFID(out_address, out_instruction, In_address, In_instruction, clk);
    input wire clk;
    input wire [31:0] In_address;
    input wire [31:0] In_instruction;
    output reg [31:0] out_address;
    output reg [31:0] out_instruction;

    always @(posedge clk) begin
        out_address <= In_address;
        out_instruction <= In_instruction;
    end
endmodule

module IDEX(out_LoadHalf, out_LoadHalfUnsigned, out_WB, out_MemtoReg, out_MR, out_MW, out_branch, out_RegDst, out_ALUop, out_AlUsrc, out_address, out_Readdata1, out_Readdata2, out_extended, out_Instruction20_16,
    out_Instruction15_11, out_Instruction10_6, In_WB, In_MemtoReg, In_MR, In_MW, In_branch, In_RegDst,
    In_ALUop, In_ALUsrc, In_address, In_Readdata1, In_Readdata2, In_extended, In_Instruction20_16, In_Instruction15_11, In_Instruction10_6, LoadHalf, LoadHalfUnsigned, clk);

    input wire In_WB, In_MR, In_MW, In_branch, In_RegDst, In_ALUsrc, In_MemtoReg, LoadHalf, LoadHalfUnsigned, clk;
    input wire [2:0] In_ALUop;
    input wire [31:0] In_address, In_Readdata1, In_Readdata2, In_extended;
    input wire [4:0] In_Instruction20_16, In_Instruction15_11, In_Instruction10_6;
    output reg out_WB, out_RegDst, out_AlUsrc, out_MR, out_MW, out_branch, out_MemtoReg, out_LoadHalf, out_LoadHalfUnsigned;
    output reg [4:0] out_Instruction15_11, out_Instruction20_16, out_Instruction10_6;
    output reg [31:0] out_address, out_Readdata1, out_Readdata2, out_extended;
    output reg [2:0] out_ALUop;

    always @(posedge clk) begin
        out_WB <= In_WB;
        out_MemtoReg <= In_MemtoReg;
        out_MR <= In_MR;
        out_MW <= In_MW;
        out_branch <= In_branch;
        out_RegDst <= In_RegDst;
        out_ALUop <= In_ALUop;
        out_AlUsrc <= In_ALUsrc;
        out_address <= In_address;
        out_Readdata1 <= In_Readdata1;
        out_Readdata2 <= In_Readdata2;
        out_extended <= In_extended;
        out_Instruction20_16 <= In_Instruction20_16;
        out_Instruction15_11 <= In_Instruction15_11;
        out_Instruction10_6 <= In_Instruction10_6;
        out_LoadHalf <= LoadHalf;
        out_LoadHalfUnsigned <= LoadHalfUnsigned;
    end
endmodule

module EXMEM(outLoadHalf, outLoadHalfUnsigned, outWB, outMemtoReg, outMR, outMW, out_branch, outAddResult, outZero, outALUResult, outReadData2, outWriteBack, WB,
    inMemtoReg, MR, MW, branch, addResult, zero, ALUResult, readData2, writeBack, LoadHalf, LoadHalfUnsigned, clk);

    input wire clk;
    input wire [31:0] addResult, ALUResult, readData2;
    input wire [4:0] writeBack;
    input wire WB, MR, MW, branch, zero, inMemtoReg, LoadHalf, LoadHalfUnsigned;
    output reg [31:0] outAddResult, outALUResult, outReadData2;
    output reg [4:0] outWriteBack;
    output reg outWB, outMemtoReg, outZero, outMR, outMW, out_branch, outLoadHalf, outLoadHalfUnsigned;

    always @(posedge clk) begin
        outAddResult <= addResult;
        outALUResult <= ALUResult;
        outReadData2 <= readData2;
        outWriteBack <= writeBack;
        outMemtoReg <= inMemtoReg;
        outWB <= WB;
        outZero <= zero;
        outMR <= MR;
        outMW <= MW;
        out_branch <= branch;
        outLoadHalf <= LoadHalf;
        outLoadHalfUnsigned <= LoadHalfUnsigned;
    end
endmodule

module MEMWEB(outReadData, outWBRegWrite, outWBMemtoReg, outAddress, outWriteBackfinal, readData, address, WB, memtoreg, writeBack, clk);
    input wire clk;
    input wire [31:0] readData, address;
    input wire [4:0] writeBack;
    input wire WB, memtoreg;
    output reg [31:0] outReadData, outAddress;
    output reg [4:0] outWriteBackfinal;
    output reg outWBRegWrite, outWBMemtoReg;

    always @(posedge clk) begin
        outReadData <= readData;
        outWBRegWrite <= WB;
        outAddress <= address;
        outWBMemtoReg <= memtoreg;
        outWriteBackfinal <= writeBack;
    end
endmodule

module RegisterFile(ReadData1, ReadData2, ReadReg1, ReadReg2, WriteReg, WriteData, RegWrite, clk);
    output reg [31:0] ReadData1, ReadData2;
    input wire [4:0] ReadReg1, ReadReg2, WriteReg;
    input wire [31:0] WriteData;
    input wire RegWrite, clk;
    reg [31:0] Registers [31:0];

    always @(*) begin
        ReadData1 = (ReadReg1 == 0) ? 32'b0 : Registers[ReadReg1];
        ReadData2 = (ReadReg2 == 0) ? 32'b0 : Registers[ReadReg2];
    end

    always @(posedge clk) begin
        if (RegWrite && WriteReg != 0)
            Registers[WriteReg] <= WriteData;
    end
endmodule

module ALUControl(out, ALUOp, FuncCode);
    input wire [2:0] ALUOp;
    input wire [5:0] FuncCode;
    output reg [3:0] out;

    always @(*) begin
        case (ALUOp)
            3'b000: out = 4'b0010;
            3'b001: out = 4'b0110;
            3'b011: out = 4'b0010;
            3'b100: out = 4'b0000;
            3'b101: out = 4'b0001;
            default: begin
                case (FuncCode)
                    6'b100000: out = 4'b0010;
                    6'b100010: out = 4'b0110;
                    6'b100100: out = 4'b0000;
                    6'b100101: out = 4'b0001;
                    6'b101010: out = 4'b0111;
                    6'b101011: out = 4'b1000;
                    6'b000000: out = 4'b1001;
                    6'b000010: out = 4'b1010;
                    default: out = 4'b0000;
                endcase
            end
        endcase
    end
endmodule

module ALU(out, zero, ALUControl, Data1, Data2, shiftvalue);
    input wire [3:0] ALUControl;
    input wire [4:0] shiftvalue;
    input wire [31:0] Data1, Data2;
    output reg zero;
    output reg [31:0] out;

    always @(*) begin
        case (ALUControl)
            4'b0000: out = Data1 & Data2;
            4'b0001: out = Data1 | Data2;
            4'b0010: out = Data1 + Data2;
            4'b0110: out = Data1 - Data2;
            4'b0111: out = ($signed(Data1) < $signed(Data2)) ? 32'd1 : 32'd0;
            4'b1000: out = (Data1 < Data2) ? 32'd1 : 32'd0;
            4'b1001: out = Data2 << shiftvalue;
            4'b1010: out = Data2 >> shiftvalue;
            default: out = 32'd0;
        endcase
        zero = (out == 32'd0);
    end
endmodule

module DataMemory(data_out, data_in, address, MemRead, MemWrite, lh, lhu, Clk);
    output reg [31:0] data_out;
    input wire [31:0] data_in;
    input wire [31:0] address;
    input wire lh, lhu, Clk;
    input wire MemRead, MemWrite;
    reg [7:0] memory [0:63];
    integer i;

    initial begin
        for (i = 0; i < 64; i = i + 1)
            memory[i] = 8'h00;
    end

    always @(posedge Clk) begin
        if (MemWrite) begin
            memory[address] <= data_in[7:0];
            memory[address + 1] <= data_in[15:8];
            memory[address + 2] <= data_in[23:16];
            memory[address + 3] <= data_in[31:24];
        end
    end

    always @(*) begin
        if (MemRead) begin
            if (lh) begin
                data_out[7:0] = memory[address];
                data_out[15:8] = memory[address + 1];
                data_out[31:16] = memory[address + 1][7] ? 16'hFFFF : 16'h0000;
            end else if (lhu) begin
                data_out[7:0] = memory[address];
                data_out[15:8] = memory[address + 1];
                data_out[31:16] = 16'h0000;
            end else begin
                data_out[7:0] = memory[address];
                data_out[15:8] = memory[address + 1];
                data_out[23:16] = memory[address + 2];
                data_out[31:24] = memory[address + 3];
            end
        end else begin
            data_out = 32'd0;
        end
    end
endmodule

module ControlUnit(LoadHalf, LoadHalfUnsigned, RegDst, RegWrite, ALUSrc, Branch, MemRead, MemWrite, MemtoReg, ALUop, OPCode);
    output reg RegDst, RegWrite, ALUSrc, Branch, MemRead, MemWrite, MemtoReg, LoadHalf, LoadHalfUnsigned;
    output reg [2:0] ALUop;
    input wire [5:0] OPCode;

    always @(*) begin
        RegDst = 0;
        RegWrite = 0;
        ALUSrc = 0;
        Branch = 0;
        MemRead = 0;
        MemWrite = 0;
        MemtoReg = 0;
        LoadHalf = 0;
        LoadHalfUnsigned = 0;
        ALUop = 3'b000;

        case (OPCode)
            6'h00: begin RegDst = 1; RegWrite = 1; ALUop = 3'b010; end
            6'h08: begin RegWrite = 1; ALUSrc = 1; ALUop = 3'b011; end
            6'h23: begin RegWrite = 1; ALUSrc = 1; MemRead = 1; MemtoReg = 1; ALUop = 3'b000; end
            6'h2B: begin ALUSrc = 1; MemWrite = 1; ALUop = 3'b000; end
            6'h21: begin RegWrite = 1; ALUSrc = 1; MemRead = 1; MemtoReg = 1; LoadHalf = 1; ALUop = 3'b000; end
            6'h25: begin RegWrite = 1; ALUSrc = 1; MemRead = 1; MemtoReg = 1; LoadHalfUnsigned = 1; ALUop = 3'b000; end
            6'h0C: begin RegWrite = 1; ALUSrc = 1; ALUop = 3'b100; end
            6'h0D: begin RegWrite = 1; ALUSrc = 1; ALUop = 3'b101; end
            6'h04: begin Branch = 1; ALUop = 3'b001; end
        endcase
    end
endmodule

module SignExtend(out, in);
    output reg [31:0] out;
    input wire [15:0] in;

    always @(*) begin
        out = {{16{in[15]}}, in};
    end
endmodule
