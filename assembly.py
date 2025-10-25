def build_program(instructions):
    program = []
    for i in instructions:
        low = i & 0xFF
        high = (i >> 8) & 0xFF
        program.append(low)
        program.append(high)
    return program

def halt():
    return (0x1F << 11)

def lw(dest, base, offset=0):
    return (0x01 << 11) | (dest << 8) | (base << 5) | offset

def sw(src, base, offset=0):
    return (0x02 << 11) | (src << 8) | (base << 5) | offset

def lui(dest, value):
    return (0x03 << 11) | (dest << 8) | value

def addi(dest, value):
    return (0x04 << 11) | (dest << 8) | value

def add(dest, src1, src2):
    return (0x05 << 11) | (dest << 8) | (src1 << 5) | (src2 << 2)

def sub(dest, src1, src2):
    return (0x06 << 11) | (dest << 8) | (src1 << 5) | (src2 << 2)

def ja(dest):
    return (0x11 << 11) | (dest << 8)

def jr(dest):
    return (0x12 << 11) | (dest << 8)

def beq(dest, src1, src2):
    return (0x13 << 11) | (dest << 8) | (src1 << 5) | (src2 << 2)

def bne(dest, src1, src2):
    return (0x14 << 11) | (dest << 8) | (src1 << 5) | (src2 << 2)