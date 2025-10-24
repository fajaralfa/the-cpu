## ISA Spec

### Register

- Register is 3 bit address that hold 16 bit value

| ABI Name | Register | Description | Register Address |
| - | - | - | - |
| pc | r0 | Program Counter | 0x00 |
| sp | r1 | Stack Pointer | 0x01 |
| x1 | r2 | General Purpose | 0x02 |
| x2 | r3 | General Purpose | 0x03 |
| x3 | r4 | General Purpose | 0x04 |
| mepc | r5 | Exception Program Counter | 0x05 |
| mcause | r6 | Cause of Exception | 0x06 |
| mtvec | r7 | Trap Handler Address | 0x07 |

### Memory

- 64KB address space (16 bit addresses)

### Instruction

#### Encoding:

- Little Endian is used for 16 bit values in memory.

#### Instruction Set:

- value is two's complement
- word is 16 bit value

| Opcode | Machine Code | Mnemonic | Fields Size | Operation |
| - | - | - | - | - |
| lw | 0x00 | lw x1, x2, 5 | 5, 3, 3, 5 (op, dest, base, offset) | x1 = mem[x2 + offset] |
| sw | 0x01 | sw x1, x2, 5 | 5, 3, 3, 5 (op, src, base, offset) | mem[x2 + offset] = x1 |
| lui | 0x02 |lui x1, #0xFF00 | 5, 3, 8 (op, dest, val) | x1 = 0xFF00 |
| addi | 0x03 | addi x1, #0x00FF | 5, 3, 8 (op, dest, val) | x1 += 0x00FF |
| add | 0x04 |add x1, x2, x3 | 5, 3, 3, 3, 2 (op, dest, src1, src2, pad) | x1 = x2 + x3 |
| sub | 0x05 |sub x1, x2, x3 | 5, 3, 3, 3, 2 (op, dest, src1, src2, pad) | x1 = x2 - x3 |
| rem | 0x08 |rem x1, x2, x3 | 5, 3, 3, 3, 2 (op, dest, src1, src2) | x1 = x2 % x3 |
| and | 0x09 |and x1, x2, x3 | 5, 3, 3, 3, 2 (op, dest, src1, src2) | x1 = x2 & x3 |
| not | 0x0a |not x1, x2 | 5, 3, 3, 5 (op, dest, src1, pad) | x1 = ~x2 |
| or | 0x0b | or x1, x2, x3 | 5, 3, 3, 3, 2 (op, dest, src1, src2) | x1 = x2 OR x3|
| xor | 0x0c |xor x1, x2, x3 | 5, 3, 3, 3, 2 (op, dest, src1, src2) | x1 = x2 ^ x3 |
| sll | 0x0d |sll x1, x2, x3 | 5, 3, 3, 3, 2 (op, dest, src1, src2) | x1 = x2 << x3 |
| srl | 0x0e |srl x1, x2, x3 | 5, 3, 3, 3, 2 (op, dest, src1, src2) | x1 = x2 >> x3 |
| sra | 0x0f |sra x1, x2, x3 | 5, 3, 3, 3, 2 (op, dest, src1, src2) | x1 = x2 >>> x3 |
| ja | 0x10 | ja x1 | 5, 3, 8 (op, dest, pad) | PC = x1 |
| jr | 0x11 | jr x1 | 5, 3, 8 (op, dest, pad) | PC += x1 |
| beq | 0x12 |beq x1, x2, x3 | 5, 3, 3, 3, 2 (op, dest, src1, src2) | if (x2 == x3) PC = x1 |
| bne | 0x13 |bne x1, x2, x3 | 5, 3, 3, 3, 2 (op, dest, src1, src2) | if (x2 != x3) PC = x1 |
| halt | 0x1f | halt | 5, 11 (op, pad) | stop cpu |