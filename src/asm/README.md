# Assembler

Grammar:

```

program -> instruction*

instruction -> labeldef | inherent | rtype | itype | rtype2 | itype2 | rtype3

labeldef -> label ':'
inherent -> opcode
rtype -> opcode register
rtype2 -> opcode register, register
rtype3 -> opcode register, register, register
itype -> opcode (immediate | label)
itype2 -> opcode register, register, immediate

opcode -> Defined in spec
register -> 'pc' | 'sp' | 'x1' | 'x2' | 'x3' | 'mepc' | 'mcause' | 'mtvec'
immediate -> # (dec | hex | oct | bin)+
label -> ('a' - 'z' | 'A' - 'Z' | '_')+
```