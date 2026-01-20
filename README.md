# 2-Way In-Order Superscalar Processor

This repository contains the design and implementation of a **32-bit, 2-way in-order superscalar processor** written in Verilog/SystemVerilog. The processor can fetch, decode, issue, execute, and commit up to **two instructions per cycle** while strictly preserving in-order semantics.

The design is intentionally conservative and focuses on **correctness, clarity, and educational value**, rather than aggressive performance optimizations.

---

## Key Features
- 32-bit RISC-style datapath  
- 2-way **in-order superscalar** issue  
- Classic **5-stage pipeline**: IF, ID/ISSUE, EX, MEM, WB  
- Dual-instruction fetch per cycle  
- Centralized hazard detection and control  
- No out-of-order execution, speculation, or branch prediction  

---

## Instruction Set
- **R-Type ALU**: ADD, SUB, MUL, AND, OR, XOR, SLL, SRL  
- **I-Type ALU**: ADDI, SUBI, ANDI, ORI, XORI  
- **Memory**: LW, SW  
- **Control Flow**: BEQ, BNE, BLT, BGE, J  
- **NOP**

All instructions are 32 bits wide and use fixed register fields similar to MIPS-style encoding.

---

## Superscalar Issue & Hazards
- Up to two instructions can issue per cycle if independent  
- **RAW hazards** are handled by stalling:
  - If the dependency is on an older instruction already in the pipeline, the dependent instruction is stalled until write-back
  - If the dependency is between two instructions in the same fetch group, the first instruction issues and the second is stalled (NOP inserted)
- Structural and control hazards are resolved conservatively using stalls and pipeline flushes  
- No data forwarding is implemented

---

## Repository Structure
├── superscaler_processor.v # Top-level processor
├── ALU.v # ALU implementation
├── tb/ # Testbenches
├── tests/ # Instruction programs
├── docs/ # Report and diagrams
└── README.md


---

## Simulation
The design is verified using directed testbenches focusing on:
- Correct instruction execution
- RAW hazard handling
- Dual-issue vs single-issue behavior
- Branch and pipeline flush correctness

---

## Notes
This processor serves as a **baseline superscalar microarchitecture** suitable for learning, experimentation, and further extension (e.g., forwarding, branch prediction, or out-of-order execution).

**Author:** Chinmay Kulkarni
