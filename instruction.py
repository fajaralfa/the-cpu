def halt():
    return (0xFF << 11)

def lw(dest, base, offset=0):
    return (0x00 << 11) | (dest << 8) | (base << 5) | offset

def sw(src, base, offset=0):
    return (0x01 << 11) | (src << 8) | (base << 5) | offset

def lui(dest, value):
    return (0x02 << 11) | (dest << 8) | value

def addi(dest, value):
    return (0x03 << 11) | (dest << 8) | value

def add(dest, src1, src2):
    return (0x04 << 11) | (dest << 8) | (src1 << 5) | (src2 << 2)

def sub(dest, src1, src2):
    return (0x05 << 11) | (dest << 8) | (src1 << 5) | (src2 << 2)
