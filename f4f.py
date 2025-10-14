class F4F:
    def __init__(self):
        self.running = True
        self.register = [0] * 6
        self.memory = [0] * (2 ** 16)
        handler = []
        self.handler = [None] * (2 ** 5)
        self.handler[0:len(handler)] = handler
        self.handler[-1] = self.h_halt

    def load_program(self, program: list, start_address=0xC000):
        self.register[0] = start_address
        self.memory[start_address:(start_address + len(program))] = program
        pass

    def run_program(self):
        while self.running:
            instruction = self.fetch()
            print('instruction', hex(instruction))
            opcode = self.decode(instruction)
            print('opcode', hex(opcode))
            handler = self.handler[opcode]
            if handler is not None:
                handler()
            else:
                print(f'invalid opcode at {self.register[0]:4X}')

    def fetch(self):
        instruction = (self.memory[self.register[0]] << 8) + self.memory[self.register[0] + 1]
        self.register[0] += 2
        return instruction
    
    def decode(self, instruction):
        opcode = (instruction >> 11)
        return opcode

    def h_halt(self):
        self.running = False


cpu = F4F()

program = [
    0x12, 0xFF, # random instruction
    0x01, 0x23, # random instruction
    (0x1f << 3), 0x00 # halt
]

cpu.load_program(program)
cpu.run_program()