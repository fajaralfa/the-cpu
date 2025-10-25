class CPU:
    def __init__(self):
        self.running = True
        self.register = [0] * 6
        self.memory = [0] * (2 ** 16)
        self.handler = [None] * (2 ** 5)
        handler = [
                self.h_load_word,
                self.h_store_word,
                self.h_load_upper_immediate,
                self.h_add_immediate,
                self.h_add,
                self.h_sub,
        ]
        self.handler[0:len(handler)] = handler
        self.handler[-1] = self.h_halt

    def load_program(self, program: list, start_address=0xC000):
        if start_address + len(program) > len(self.memory):
            raise OutOfBoundException()
        self.register[0] = start_address
        self.memory[start_address:(start_address + len(program))] = program
        pass

    def run_program(self):
        while self.running:
            instruction = self.fetch()
            opcode, operand = self.decode(instruction)
            handler = self.handler[opcode]
            if handler is not None:
                handler(operand)
            else:
                raise IllegalInstructionException()
            self.debug_state()

    def fetch_word(self, address):
        if address % 2 != 0:
            raise MisalignedMemoryException()
        if address >= len(self.memory) - 1:
            raise OutOfBoundException()
        low = self.memory[address]
        high = self.memory[address + 1]
        word = low | (high << 8)
        return word

    def fetch(self):
        address = self.register[0]
        if address >= len(self.memory) - 1:
            raise OutOfBoundException()
        self.register[0] += 2
        return self.fetch_word(address)
    
    def decode(self, instruction):
        opcode = (instruction >> 11) & ((1 << 5) - 1)
        operand = instruction & ((1 << 11) - 1)
        return opcode, operand
    
    def to_signed_16(self, value):
        value &= 0xFFFF
        if value & 8000:
            return value - 0x10000
        else:
            return value

    def debug_state(self):
        print(f"PC: {self.register[0]:04X}, ", end="")
        for i in range(3, 6):
            print(f"R{i}: {self.register[i]:04X}, ", end="")
        print(f"SR: {self.register[1]:04b}")

    def h_halt(self, operand):
        self.running = False

    def h_load_upper_immediate(self, operand):
        dest = (operand >> 8) & ((1 << 3) - 1)
        value_upper = (operand & 0xFF) << 8
        self.register[dest] = value_upper
    
    def h_add_immediate(self, operand):
        dest = (operand >> 8) & ((1 << 3) - 1)
        value = operand & 0xFF
        current = self.register[dest]
        new = current + value
        if new <= 0xFFFF:
            self.register[dest] = new
        else:
            self.register[dest] = new % 0xFFFF

    def h_add(self, operand):
        dest = (operand >> 8) & ((1 << 3) - 1)
        src1 = (operand >> 5) & ((1 << 3) - 1)
        src2 = (operand >> 2) & ((1 << 3) - 1)
        new = self.register[src1] + self.register[src2]
        self.register[dest] = new % (1 << 16)
        
    def h_sub(self, operand):
        dest = (operand >> 8) & ((1 << 3) - 1)
        src1 = (operand >> 5) & ((1 << 3) - 1)
        src2 = (operand >> 2) & ((1 << 3) - 1)
        self.register[dest] = (self.register[src1] - self.register[src2]) % (2 ** 16)

    def h_load_word(self, operand):
        dest = (operand >> 8) & ((1 << 3) - 1)
        base_register = (operand >> 5) & ((1 << 3) - 1)
        base = self.register[base_register]
        offset = operand & ((1 << 5) - 1)
        word = self.fetch_word(base + offset)
        self.register[dest] = word

    def h_store_word(self, operand):
        src = (operand >> 8) & ((1 << 3) - 1)
        base_register = (operand >> 5) & ((1 << 3) - 1)
        base = self.register[base_register]
        offset = operand & ((1 << 5) - 1)
        address = base + offset
        if (address % 2 != 0):
            raise MisalignedMemoryException()
        low = self.register[src] & 0xFF
        high = (self.register[src] >> 8) & 0xFF
        self.memory[address] = low
        self.memory[address + 1] = high
        
    def h_jump_absolute(self, operand):
        dest = (operand >> 8) & ((1 << 3) - 1)
        addr = self.register[dest]
        if addr >= len(self.memory) - 1:
            raise OutOfBoundException()
        if addr % 2 != 0:
            raise MisalignedMemoryException()
        self.register[0] = addr

    def h_jump_relative(self, operand):
        dest = (operand >> 8) & ((1 << 3) - 1)
        offset = self.to_signed_16(self.register[dest])
        addr = (self.register[0] + offset)
        if addr >= len(self.memory) - 1:
            raise OutOfBoundException()
        if addr % 2 != 0:
            raise MisalignedMemoryException()
        self.register[0] =  addr
    
    def h_branch_equal(self, operand):
        dest = (operand >> 8) & ((1 << 3) - 1)
        src1 = (operand >> 5) & ((1 << 3) - 1)
        src2 = (operand >> 2) & ((1 << 3) - 1)
        addr = self.register[0] + self.register[dest]
        if self.register[src1] == self.register[src2]:
            if addr >= len(self.memory) - 1:
                raise OutOfBoundException()
            if addr % 2 != 0:
                raise MisalignedMemoryException()
            self.register[0] = addr


class IllegalInstructionException(Exception):
    pass
class SegFaultException(Exception):
    pass
class OutOfBoundException(Exception):
    pass
class MisalignedMemoryException(Exception):
    pass