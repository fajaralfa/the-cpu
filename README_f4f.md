## ISA Spec

### Register

- Register is 5 bit address that hold 16 bit value

| ABI Name | Register | Description | Register Address |
| - | - | - | - |
| pc | r0 | Program Counter | 0x00 |
| sr | r1 | Status Register | 0x01 |
| sp | r2 | Stack Pointer | 0x02 |
| x1 | r3 | General Purpose | 0x03 |
| x2 | r4 | General Purpose | 0x04 |
| x3 | r5 | General Purpose | 0x05 |

### Memory

- 64KB address space (16 bit addresses)
- Mapped as:
    - 0x0000 - 0xBFFF: general RAM
    - 0xC000 - 0xFFFF: ROM

### Instruction

#### Encoding:

- Little Endian is used for 16 bit values in memory.

#### Instruction Set:

- notes: value is two's complement

| Opcode | Machine Code | Description |
| - | - | - |
| lw | 0x00 |
| sw | 0x01 |
| lui | 0x02 |
| ldi | 0x03 |
| add | 0x04 |
| sub | 0x05 |
| mul | 0x06 |
| div | 0x07 |
| rem | 0x08 |
| and | 0x09 |
| not | 0x0a |
| or | 0x0b |
| xor | 0x0c |
| sll | 0x0d |
| srl | 0x0e |
| sra | 0x0f |
| ja | 0x10 |
| jr | 0x11 |
| beq | 0x12 |
| bne | 0x13 |
| halt | 0x1f |

| Mnemonic | Fields Size | Operation |
| - | - | - |
| lw x1, x2, 5 | 5, 3, 3, 5 (op, dest, base, offset) | x1 = mem[x2 + offset] |
| sw x1, x2, 5 | 5, 3, 3, 5 (op, src, base, offset) | mem[x2 + offset] = x1 |
| lui x1, #0xFF00 | 5, 3, 8 (op, dest, val) | x1 = 0xFF00 |
| ldi x1, #0x00FF | 5, 3, 8 (op, dest, val) | x1 += 0x00FF |
| add x1, x2, x3 | 5, 3, 3, 3, 2 (op, dest, src1, src2, pad) | x1 = x2 + x3 |
| sub x1, x2, x3 | 5, 3, 3, 3, 2 (op, dest, src1, src2, pad) | x1 = x2 - x3 |
| mul x1, x2, x3 | 5, 3, 3, 3, 2 (op, dest, src1, src2, pad) | x1 = x2 * x3 |
| div x1, x2, x3 | 5, 3, 3, 3, 2 (op, dest, src1, src2, pad) | x1 = x2 / x3 |
| rem x1, x2, x3 | 5, 3, 3, 3, 2 (op, dest, src1, src2) | x1 = x2 % x3 |
| and x1, x2, x3 | 5, 3, 3, 3, 2 (op, dest, src1, src2) | x1 = x2 & x3 |
| not x1, x2 | 5, 3, 3, 5 (op, dest, src1, pad) | x1 = ~x2 |
| or x1, x2, x3 | 5, 3, 3, 3, 2 (op, dest, src1, src2) | x1 = x2 OR x3  |
| xor x1, x2, x3 | 5, 3, 3, 3, 2 (op, dest, src1, src2) | x1 = x2 ^ x3 |
| sll x1, x2, x3 | 5, 3, 3, 3, 2 (op, dest, src1, src2) | x1 = x2 << x3 |
| srl x1, x2, x3 | 5, 3, 3, 3, 2 (op, dest, src1, src2) | x1 = x2 >> x3 |
| sra x1, x2, x3 | 5, 3, 3, 3, 2 (op, dest, src1, src2) | x1 = x2 >>> x3 |
| ja x1 | 5, 3, 8 (op, dest, pad) | PC = x1 |
| jr x1 | 5, 3, 8 (op, dest, pad) | PC += x1 |
| beq x1, x2, x3 | 5, 3, 3, 3, 2 (op, dest, src1, src2) | if (x2 == x3) PC = x1 |
| bne x1, x2, x3 | 5, 3, 3, 3, 2 (op, dest, src1, src2) | if (x2 != x3) PC = x1 |
| halt | 5, 11 (op, pad) | stop cpu |