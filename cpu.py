class CPU:
    GPR_COUNT = 3
    FLAG_ZERO = 0b0001
    FLAG_CARRY = 0b0010
    FLAG_OVERFLOW = 0b0100
    FLAG_SIGN = 0b1000

    def __init__(self) -> None:
        self.memory = [0] * (2 ** 16)
        self.GPR = [0] * self.GPR_COUNT
        self.PC = 0x0000
        self.SR = 0
        self.running = True

        instruction_handlers = [
            lambda: None,
            self.load,
            self.loadi,
            self.store,
            self.storei,
            self.add,
            self.addi,
            self.sub,
            self.subi,
            self.jump,
            self.jumpnot,
        ]
        self.dispatchers = [lambda: None] * 256
        self.dispatchers[:len(instruction_handlers)] = instruction_handlers
        self.dispatchers[-1] = self.halt

    def load_program(self, program, start_address=0xC000):
        self.memory[start_address:(start_address + len(program))] = program
        self.PC = 0xC000

    def fetch_byte(self):
        byte = self.memory[self.PC]
        self.PC += 1
        return byte

    def fetch_word(self):
        lo = self.fetch_byte()
        hi = self.fetch_byte()
        return lo | (hi << 8)

    def fetch_mem_word(self):
        addr = self.fetch_word()
        lo = self.memory[addr]
        hi = self.memory[addr + 1]
        return lo | (hi << 8)

    def run(self):
        while self.running:
            opcode = self.fetch_byte()
            if opcode < len(self.dispatchers):
                self.dispatchers[opcode]()
            else:
                print(f"Unknown opcode: {opcode:02X} at {self.PC - 1:04X}")
                self.running = False
            self.debug_state()

    def set_flags(self, *, result=None, carry=None, overflow=None):
        if result is not None:
            self.SR &= ~(self.FLAG_ZERO | self.FLAG_SIGN)
            result16 = result & 0xFFFF
            if result16 == 0:
                self.SR |= self.FLAG_ZERO
            if result16 & 0x8000:
                self.SR |= self.FLAG_SIGN

        if carry is not None:
            self.SR &= ~self.FLAG_CARRY
            if carry:
                self.SR |= self.FLAG_CARRY

        if overflow is not None:
            self.SR &= ~self.FLAG_OVERFLOW
            if overflow:
                self.SR |= self.FLAG_OVERFLOW

    def debug_state(self):
        print(f"PC: {self.PC:04X}, ", end="")
        for i in range(len(self.GPR)):
            print(f"R{i}: {self.GPR[i]:04X}, ", end="")
        print(f"SR: {self.SR:04b}")
    
    def halt(self):
        self.running = False

    def load(self):
        register = self.fetch_byte()
        value = self.fetch_mem_word()
        if register in range(self.GPR_COUNT):
            self.GPR[register] = value & 0xFFFF
        else:
            print(f"Unknown register: R{register} at {self.PC - 1:04X}")
    
    def loadi(self):
        register = self.fetch_byte()
        value = self.fetch_word()
        if register in range(self.GPR_COUNT):
            self.GPR[register] = value & 0xFFFF
        else:
            print(f"Unknown register: R{register} at {self.PC - 1:04X}")

    def store(self):
        register = self.fetch_byte()
        addr = self.fetch_word()
        if register in range(self.GPR_COUNT):
            value = self.GPR[register]
            self.memory[addr] = value & 0xFF
            self.memory[addr + 1] = (value >> 8) & 0xFF
        else:
            print(f"Unknown register: R{register} at {self.PC - 1:04X}")
    
    def storei(self):
        addr = self.fetch_word()
        value = self.fetch_word()
        self.memory[addr] = value & 0xFF
        self.memory[addr + 1] = (value >> 8) & 0xFF

    @staticmethod
    def detect_overflow_add(a, b, result):
        # a, b, result are full 16-bit signed integers
        sign_a = a & 0x8000
        sign_b = b & 0x8000
        sign_r = result & 0x8000
        # Overflow happens if a and b have same sign, but result has different sign
        return (sign_a == sign_b) and (sign_r != sign_a)

    @staticmethod
    def detect_overflow_sub(a, b, result):
        # Subtraction: overflow if a and b have different signs, and result has different sign from a
        sign_a = a & 0x8000
        sign_b = b & 0x8000
        sign_r = result & 0x8000
        return (sign_a != sign_b) and (sign_r != sign_a)

    def add(self):
        register = self.fetch_byte()
        value = self.fetch_mem_word()
        if register in range(self.GPR_COUNT):
            a = self.GPR[register]
            result = a + value
            self.GPR[register] = result & 0xFFFF
            overflow = self.detect_overflow_add(a, value, result)
            self.set_flags(result=result, overflow=overflow)
    
    def addi(self):
        register = self.fetch_byte()
        value = self.fetch_word()
        if register in range(self.GPR_COUNT):
            a = self.GPR[register]
            result = a + value
            self.GPR[register] = result & 0xFFFF
            overflow = self.detect_overflow_add(a, value, result)
            self.set_flags(result=result, overflow=overflow)
    
    def sub(self):
        register = self.fetch_byte()
        value = self.fetch_mem_word()
        if register in range(self.GPR_COUNT):
            a = self.GPR[register]
            result = a - value
            self.GPR[register] = result & 0xFFFF
            overflow = self.detect_overflow_sub(a, value, result)
            self.set_flags(result=result, overflow=overflow)

    def subi(self):
        register = self.fetch_byte()
        value = self.fetch_word()
        if register in range(self.GPR_COUNT):
            a = self.GPR[register]
            result = a - value
            self.GPR[register] = result & 0xFFFF
            overflow = self.detect_overflow_sub(a, value, result)
            self.set_flags(result=result, overflow=overflow)

    def jump(self):
        addr = self.fetch_word()
        flags = self.fetch_byte()
        if flags == self.SR:
            self.PC = addr
    
    def jumpnot(self):
        addr = self.fetch_word()
        flags = self.fetch_byte()
        if flags != self.SR:
            self.PC = addr


cpu = CPU()

program = [
    0x02, 0x00, 0x02, 0x00, # load R0, 2
    0x03, 0x00, 0x22, 0x00, # store R0, 0x22
    0x06, 0x00, 0xFF, 0x7F, # addi R0, 0x7FFF
    0x09, 0x1D, 0xC0, 0b1100,# j 0xC025, 0b1100
    0x01, 0x01, 0x22, 0x00, # load 0x22, R1
    0x04, 0x23, 0x00, 0x05, 0x00, # store 0x23, 0x05
    0x01, 0x00, 0x23, 0x00, # load R0, 0x23
    0x02, 0x02, 0x0A, 0x00, # load R2, 0x0A
    0x06, 0x02, 0x07, 0x00, # addi R2, 0x07
    0xFF # halt
]

with open('program.bin', 'wb') as f:
    f.write(bytes(program))

with open('program.bin', 'rb') as f:
    data = f.read()
    cpu.load_program(data)
    cpu.run()