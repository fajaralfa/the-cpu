# Assembler

Grammar:

```

program -> instruction*

instruction -> labeldef | inherent | rtype | itype | rtype2 | itype2

labeldef -> label ':'
inherent -> opcode
rtype -> opcode register
rtype2 -> opcode register, register
rtype3 -> opcode register, register, register
itype -> opcode (immediate | labelref)
itype2 -> opcode register, register, immediate

opcode -> 'halt' | 'lui' | 'addi'
register -> 'pc' | 'sp' | 'x1' | 'x2' | 'x3' | 'mepc' | 'mcause' | 'mtvec'
immediate -> # (dec | hex | oct | bin)
label -> ('a' - 'z' | 'A' - 'Z' | '_')
labelref -> label

```