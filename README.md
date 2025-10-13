## ISA Specification

### Register

| Name | Description |
| --- | --- |
| R0 | General Purpose |
| R1 | General Purpose |
| R2 | General Purpose |
| SP | Stack Pointer |
| SR | Status Register |
| PC | Program Counter |

### Memory

- 64kb address space (16 bit addresses)
- Mapped as:
    - 0x0000 - 0xBFFF: general RAM
    - 0xC000 - 0xFFFF: ROM

### Instruction Format

Encoding:
- Opcode: 1 byte
- Optional Operand: 2 bytes (for address or immediate value)

Instruction Set:

| Mnemonic | Description | Format |
|---|---| --- |
| NOP | No operation | 0x00 |
| LOAD Rx, addr | Load from memory to gp register | 0x01, reg, addr_hi, addr_lo |
| LOADI Rx, #imm | Load immediate to gp register | 0x02, reg, imm_hi, imm_lo |
| STORE Rx, addr | Store from gp register to memory | 0x03, reg, addr_hi, addr_lo |
| STOREI addr, #imm | Store immediate to memory | 0x04, addr_hi, addr_lo, imm_hi, imm_lo |
| ADD RX, addr | Add RX with memory value | 0x05, reg, addr_hi, addr_lo |
| ADDI RX, #imm | Add RX with memory value | 0x06, reg, imm_hi, imm_lo |
| SUB RX, addr | Subtract RX with memory value | 0x07, reg, addr_hi, addr_lo |
| SUBI RX, #imm | Subtract RX with memory value | 0x08, reg, imm_hi, imm_lo |
| J addr, flags | Jump if SR is flags | 0x09, addr_hi, addr_lo, flags |
| JN addr, flags | Jump if SR is not flags | 0x0A, addr_hi, addr_lo, flags |
| HLT | Halt Execution | 0xFF |

### Status Register

Notes:
- Only arithmetic instructions (ADD, ADDI, SUB, SUBI) update the Status Register (SR).

| Bit | Flag | Description |
| --- | --- | --- |
| 0 | Zero | Set if last operation result was zero |
| 1 | Carry(C) | Set if carry/borrow occured |
| 2 | Overflow(V) | Set if overflow in signed ops |
| 3 | Sign(S) | Set if result negative |
