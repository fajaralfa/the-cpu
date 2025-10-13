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
            if result == 0:
                self.SR |= self.FLAG_ZERO
            if result & 0x8000:
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

    def add(self):
        register = self.fetch_byte()
        value = self.fetch_mem_word()
        if register in range(self.GPR_COUNT):
            value = (self.GPR[register] + value)
            self.GPR[register] = value & 0xFFFF
            self.set_flags(result=value)
    
    def addi(self):
        register = self.fetch_byte()
        value = self.fetch_word()
        if register in range(self.GPR_COUNT):
            value = (self.GPR[register]) + value
            self.GPR[register] = value & 0xFFFF
            self.set_flags(result=value)
    
    def sub(self):
        register = self.fetch_byte()
        value = self.fetch_mem_word()
        if register in range(self.GPR_COUNT):
            value = (self.GPR[register]) - value
            self.GPR[register] = value & 0xFFFF
            self.set_flags(result=value)
        pass

    def subi(self):
        register = self.fetch_byte()
        value = self.fetch_word()
        if register in range(self.GPR_COUNT):
            value = (self.GPR[register]) - value
            self.GPR[register] = value & 0xFFFF
            self.set_flags(result=value)
        pass

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
    0x02, 0x00, 0x02, 0x00, # load 2 to R0
    0x03, 0x00, 0x22, 0x00, # store R0 to addr
    0x01, 0x01, 0x22, 0x00, # load addr to R1
    0x04, 0x23, 0x00, 0x05, 0x00, # store 5 to addr
    0x01, 0x00, 0x23, 0x00, # load addr to R0
    0x02, 0x02, 0x0A, 0x00, # load 10 to R2
    0x05, 0x02, 0x23, 0x00, # add addr to R2
    0x06, 0x02, 0x07, 0x00, # add 7 to R2
    0x07, 0x02, 0x23, 0x00, # sub addr 0x23 to R2
    0x08, 0x02, 0x23, 0x00, # sub 0x23 to R2
    0xFF # halt
]

program = [
    0x02, 0x00, 0x02, 0x00, # load 2 to R0
    0x03, 0x00, 0x22, 0x00, # store R0 to addr
    0x06, 0x00, 0x00, 0x80, # make an overflow
    0x08, 0x00, 0x00, 0x83, # make negative sign
    0x09, 0x25, 0xC0, 0b1100,# jump to 0xC025 addr
    0x01, 0x01, 0x22, 0x00, # load addr to R1
    0x04, 0x23, 0x00, 0x05, 0x00, # store 5 to addr
    0x01, 0x00, 0x23, 0x00, # load addr to R0
    0x02, 0x02, 0x0A, 0x00, # load 10 to R2
    0x06, 0x02, 0x07, 0x00, # add 7 to R2
    0xFF # halt
]

with open('program.bin', 'wb') as f:
    f.write(bytes(program))

with open('program.bin', 'rb') as f:
    data = f.read()
    cpu.load_program(data)
    cpu.run()