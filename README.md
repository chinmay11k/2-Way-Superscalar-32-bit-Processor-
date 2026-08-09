# 2-Way Superscalar 32-bit RISC-V Processor

A **32-bit, 2-way in-order superscalar processor** based on the **RISC-V RV32I instruction set**, implemented in Verilog.

The processor is designed to fetch, decode, issue, execute, access memory, and write back **up to two instructions per cycle**, while maintaining in-order execution semantics.

The current RISC-V implementation is a redesigned version of an earlier MIPS-based superscalar processor. The original implementation is preserved separately under `old_mips_based_processor/`.

---

## Overview

The processor implements a dual-issue pipelined datapath with dedicated logic for instruction decoding, issue control, execution, memory access, write-back, and hazard handling.

The design focuses on a clear and modular implementation of superscalar execution and pipeline hazard management.

### Architecture

```text
                    +------------------+
                    | Instruction Mem  |
                    +--------+---------+
                             |
                             v
                    +------------------+
                    |   Fetch Stage    |
                    +--------+---------+
                             |
                             v
                    +------------------+
                    | Decode / Issue   |
                    |      Stage       |
                    +----+--------+----+
                         |        |
                    +----v--+  +--v----+
                    | EX-A  |  | EX-B  |
                    +----+--+  +--+----+
                         |        |
                    +----v--+  +--v----+
                    | MEM-A |  | MEM-B |
                    +----+--+  +--+----+
                         |        |
                    +----v--+  +--v----+
                    |  WB-A |  |  WB-B |
                    +-------+  +-------+
```

---

## Key Features

* 32-bit RISC-V processor
* RV32I-based instruction set
* 2-way superscalar issue
* In-order execution
* Pipelined datapath
* Separate execution paths for Issue A and Issue B
* Dedicated Decode/Issue stage
* Separate EX-A and EX-B stages
* Separate MEM-A and MEM-B stages
* Separate WB-A and WB-B stages
* Dedicated data hazard handler
* Stall-based hazard handling
* Structural hazard detection
* Control hazard handling
* Separate instruction and data memories
* 32-bit register file
* Modular RTL design

---

## Superscalar Issue

The processor supports **2-way instruction issue**, allowing two instructions to enter the execution pipeline in the same cycle when they can safely execute together.

The Decode/Issue stage evaluates the instruction pair and controls whether:

* Both instructions can be issued.
* Only one instruction can be issued.
* The pipeline must stall because of a dependency or resource conflict.

The issue logic considers instruction dependencies and structural constraints before allowing instructions to proceed.

---
## Pipeline Architecture

The processor uses a dual-pipeline organization in which the two issue paths are **functionally specialized** to reduce structural conflicts.

### 1. Fetch Stage

The Fetch stage uses the program counter (PC) to fetch **two instructions per cycle** from instruction memory.

The fetched instruction pair is passed to the Decode/Issue stage for instruction decoding and issue decisions.

### 2. Decode / Issue Stage

The Decode/Issue stage performs two main functions:

1. Decodes both RISC-V instructions.
2. Determines whether the instructions can be issued into the available pipeline paths.

The issue decision considers:

* Data dependencies between the instructions
* Structural resource requirements
* The operation supported by each pipeline

The processor has two execution paths:

```text
Pipeline A → Branch + ALU operations
Pipeline B → ALU + Memory operations
```

Therefore, instruction placement is determined by the type of operation.

For example:

```text
Instruction 1: ALU
Instruction 2: Memory
        ↓
   A       B
```

can be issued together, whereas two instructions requiring the same exclusive pipeline functionality may not be issued simultaneously.

When both instructions require the same unavailable resource, a pipeline bubble is inserted as a NOP operation, and only the appropriate instruction proceeds while the pipeline stalls as required.

This pipeline specialization is the primary mechanism used to reduce structural hazards.

### 3. Execute Stage

The Execute stage is divided into two specialized paths.

#### EX-A

Pipeline A handles:

* ALU operations
* Branch operations

The branch decision is generated in the EX-A stage. If a branch is taken, the PC is updated to the branch target and incorrectly fetched instructions are flushed.

#### EX-B

Pipeline B handles:

* ALU operations
* Memory-related operations

The Decode/Issue stage determines which instructions can enter each path based on these functional capabilities.

The division of functionality between A and B allows compatible instruction pairs to execute simultaneously while reducing structural conflicts.

### 4. Memory Stage

The two memory-stage paths have different responsibilities.

#### MEM-A

MEM-A does **not perform the actual memory read/write operation**.

It primarily acts as a pipeline/buffer stage for results from the A execution path before write-back.

#### MEM-B

MEM-B handles the actual memory operations for Pipeline B, including:

* Memory reads
* Memory writes
* Byte, half-word, and word accesses
* Store-data masking
* Load-data extraction and extension

The memory logic handles different access widths according to the instruction.

For loads, the required portion of the memory data is extracted and converted to the appropriate **8-bit, 16-bit, or 32-bit** value before being passed to the write-back stage.

For stores, the store data is masked according to the requested access size so that only the required bytes are modified.

### 5. Write-Back Stage

Both execution paths have independent write-back stages:

```text
Pipeline A → WB-A ─┐
                   ├──→ Register File
Pipeline B → WB-B ─┘
```

Results from both pipelines are written back to the register file, allowing up to two register updates from the dual-issue datapath.

---

## Hazard Handling

Hazard handling is divided into **structural, data, and control hazards**.

### 1. Structural Hazards

Structural hazards are primarily handled through the **specialized A/B pipeline organization and the Decode/Issue stage**.

The two pipelines provide different functional capabilities:

| Pipeline | Supported Operations |
| -------- | -------------------- |
| **A**    | ALU + Branch         |
| **B**    | ALU + Memory         |

This division allows compatible instructions to execute simultaneously without requiring duplicate hardware for every operation type.

For example:

```text
ADD + LOAD     →  A + B → Can issue together
ADD + STORE    →  A + B → Can issue together
BRANCH + LOAD  →  A + B → Can issue together
```

However, if both instructions require the same pipeline resource, they cannot both be issued simultaneously.

For example:

```text
ALU + ALU
```

cannot use Pipeline B arbitrarily if the second instruction is required to remain on Pipeline A based on the implemented issue constraints.

The Decode/Issue stage therefore selects which instruction can proceed. If the second instruction cannot be safely issued, it is held and the pipeline is stalled until it can be issued.

### 2. Data Hazards

Data hazards are handled using a **dedicated data hazard handler** rather than forwarding logic.

The current design uses **stall-based hazard resolution**.

#### RAW — Read After Write

When a younger instruction requires a register value that is still being produced by an older instruction, the hazard handler detects the dependency.

The dependent instruction is stalled until the required value has been written back to the register file.

```text
Older instruction
      |
      | writes R1
      v
   Pipeline
      |
      | R1 required
      v
Younger instruction

        ↓
   RAW detected
        ↓
      STALL
        ↓
Register updated
        ↓
Instruction proceeds
```

No operand forwarding/bypassing network is used in the current implementation.

#### WAW — Write After Write

When two instructions in the same issue group write to the same destination register, a WAW conflict can occur.

The implemented logic gives priority to the **younger instruction's write**, so the final register value corresponds to the younger instruction.

### 3. Control Hazards

Control hazards are handled for branch instructions in the EX-A stage.

When a branch is determined to be taken:

1. The branch target address is calculated.
2. The PC is updated to the target.
3. Instructions fetched after the branch are identified as invalid.
4. The affected pipeline instructions are flushed.

```text
Branch in EX-A
      |
      v
Branch Taken?
   /       \
 No        Yes
 |          |
Continue    Update PC
            |
            v
          Flush
            |
            v
      Fetch from target
```

This prevents instructions from the wrong control-flow path from being executed.
****
## RISC-V ISA

The processor is based on the **RISC-V RV32I base integer ISA** and uses the standard 32-bit instruction formats:

- **R-type** — Register-register ALU operations
- **I-type** — Immediate ALU operations, loads, and JALR
- **S-type** — Store instructions
- **B-type** — Conditional branches
- **U-type** — LUI and AUIPC
- **J-type** — JAL

### Supported Instruction Groups

| Category | Instructions |
|---|---|
| Upper Immediate | `LUI`, `AUIPC` |
| Jump | `JAL`, `JALR` |
| Branch | `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU` |
| Load | `LB`, `LH`, `LW`, `LBU`, `LHU` |
| Store | `SB`, `SH`, `SW` |
| Immediate ALU | `ADDI`, `SLTI`, `SLTIU`, `XORI`, `ORI`, `ANDI` |
| Immediate Shift | `SLLI`, `SRLI`, `SRAI` |
| Register ALU | `ADD`, `SUB`, `SLL`, `SLT`, `SLTU`, `XOR`, `SRL`, `SRA`, `OR`, `AND` |

The Decode/Issue stage extracts `opcode`, `funct3`, `funct7`, `rs1`, `rs2`, `rd`, and immediate fields to decode and issue instructions into the appropriate pipeline.

## RTL Structure

The main RTL implementation is located in:

```text
RISC-V_Superscaler_Processor/
└── RTL_design/
```

Important modules include:

| Module                  | Description                                 |
| ----------------------- | ------------------------------------------- |
| `RV32_top.v`            | Processor top-level module                  |
| `fetch_stage.v`         | Instruction fetch and PC logic              |
| `decode_issue_stage.v`  | Instruction decoding and dual-issue control |
| `ALU_A.v`               | ALU for execution path A                    |
| `ALU_B.v`               | ALU for execution path B                    |
| `Ex_A_stage.v`          | Execute stage A                             |
| `Ex_B_stage.v`          | Execute stage B                             |
| `MEM_A_stage.v`         | Memory stage A                              |
| `MEM_B_stage.v`         | Memory stage B                              |
| `WB_A_stage.v`          | Write-back stage A                          |
| `WB_B_stage.v`          | Write-back stage B                          |
| `DATA_hazard_handler.v` | Data hazard detection and stall control     |
| `reg_file_module.v`     | Register file                               |
| `inst_mem.v`            | Instruction memory                          |
| `data_mem.v`            | Data memory                                 |
| `LOAD_EXTENDER.v`       | Load-data extension logic                   |
| `STORE_MASKER.v`        | Store-data masking logic                    |
| `parameter_list.v`      | Design parameters                           |

---

## Verification

The repository contains dedicated testbench code under:

```text
RISC-V_Superscaler_Processor/
└── testbench_codes/
```

Current testing focuses on processor functionality and pipeline behavior, including:

* Arithmetic operations
* Logical operations
* Memory operations
* Dual-instruction execution
* RAW hazards
* WAW hazards
* Load-to-use dependencies
* Structural hazards
* Branch instructions
* Jump instructions
* Different instruction-spacing scenarios

Simulation waveforms and results will be added as the verification process is expanded.

---

## Repository Structure

```text
2-Way-Superscalar-32-bit-Processor/
│
├── RISC-V_Superscaler_Processor/
│   │
│   ├── RTL_design/
│   │
│   ├── testbench_codes/
│   │
│   └── reference_documents/
│
├── old_mips_based_processor/
│   └── RTL/
│       └── Original MIPS-based implementation
│
└── README.md
```

---

## Previous MIPS-Based Implementation

An earlier version of this project implemented a similar **2-way superscalar processor using a MIPS-based ISA**.

That implementation has been preserved in:

```text
old_mips_based_processor/
```

The current repository therefore contains both the original MIPS-based implementation and the redesigned RISC-V implementation.

---

## Current Status

**Work Completed**

The implementation is now complete and has been fully verified.

The final system includes:

* Expanded RV32I instruction support
* Completed functional verification
* Verified pipeline hazard handling
* Tested dual-issue instruction combinations
* Added simulation results and waveform analysis
* Improved overall processor robustness

---

## Future Work

* Complete and systematically validate RV32I instruction coverage
* Expand automated processor testing
* Add comprehensive simulation waveforms
* Validate against standard RISC-V test programs
* Evaluate dual-issue performance
* Investigate forwarding-based hazard reduction
* Synthesize the processor and evaluate hardware metrics

---

## Tools

* Verilog
* RISC-V RV32I
* RTL Simulation
* vivado
