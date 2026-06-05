# 32-bit Pipelined Processor

This project is a 32-bit pipelined processor designed and implemented in Verilog as part of my exploration of computer architecture and digital design. The processor follows a 5-stage pipeline structure consisting of Instruction Fetch (IF), Instruction Decode (ID), Execute (EX), Memory Access (MEM), and Write Back (WB).

The design includes core processor components such as the Program Counter, Control Unit, Register File, ALU, Data Memory, Instruction Memory, and pipeline registers between each stage. It supports arithmetic, logical, memory, branch, and shift operations while demonstrating how instructions move through a pipelined datapath.

Working on this project helped me understand how modern processors execute instructions, improve performance through pipelining, and coordinate datapath and control signals across multiple stages. A significant part of the project involved debugging module interactions, verifying data flow between pipeline stages, and ensuring correct instruction execution.

### Features

* 32-bit processor architecture
* 5-stage pipelined datapath
* Arithmetic and logical operations
* Load and store instructions
* Branch instruction support
* Shift operations
* Modular Verilog implementation
* Separate instruction and data memory

### Skills Gained

* Verilog HDL
* Digital System Design
* Computer Architecture
* Processor Datapath Design
* Pipeline Implementation
* Hardware Debugging and Verification

This project provided hands-on experience in designing a processor from the ground up and strengthened my understanding of how hardware and control logic work together to execute instructions efficiently.
