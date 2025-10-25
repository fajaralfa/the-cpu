import unittest
import cpu
import assembly

class TestCaseCPU(unittest.TestCase):
    def setUp(self):
        self.cpu = cpu.CPU()

class TestLoadProgram(unittest.TestCase):
    def setUp(self):
        self.cpu = cpu.CPU()
    
    def test_load_program(self):
        program = [
            0xFF, 0x10, 0xFA, 0x32
        ]
        start_address = 0xFFFC
        self.cpu.load_program(program, start_address)
        self.assertEqual(self.cpu.memory[start_address:start_address + len(program)], program)
    
    def test_load_program_out_of_bound(self):
        program = [
            0xFF, 0x10, 0xFA, 0x32
        ]
        start_address = 0xFFFD
        with self.assertRaises(cpu.OutOfBoundException):
            self.cpu.load_program(program, start_address)


class TestFetchMemory(unittest.TestCase):
    def setUp(self):
        self.cpu = cpu.CPU()
    
    def test_fetch_word(self):
        self.cpu.memory[10] = 0xFC
        self.cpu.memory[11] = 0x25
        result = self.cpu.fetch_word(10)
        self.assertEqual(result, 0x25FC)

    def test_fetch_word_out_of_bound(self):
        with self.assertRaises(cpu.OutOfBoundException):
            self.cpu.fetch_word(0x10000)

    def test_fetch_word_misaligned(self):
        self.cpu.memory[12] = 0xA1
        self.cpu.memory[13] = 0x98
        with self.assertRaises(cpu.MisalignedMemoryException):
            self.cpu.fetch_word(13)


class TestFetchDecode(unittest.TestCase):
    def setUp(self):
        self.cpu = cpu.CPU()

    def test_fetch(self):
        program = [
            0xFF, 0x00,
            0xFA, 0x07,
        ]
        self.cpu.load_program(program)
        instruction1 = self.cpu.fetch()
        instruction2 = self.cpu.fetch()
        self.assertEqual(instruction1, 0x00FF)
        self.assertEqual(instruction2, 0x07FA)

    def test_fetch_out_of_bound(self):
        program = [
            0xFF, 0x00,
            0xFA, 0x07,
        ]
        self.cpu.load_program(program, 0xFFFC)
        self.cpu.fetch()
        self.cpu.fetch()
        with self.assertRaises(cpu.OutOfBoundException):
            self.cpu.fetch()

    def test_decode(self):
        program = [
            0b01010111, 0b00011000,
            0xFA, 0x07,
        ]
        self.cpu.load_program(program, 0xC000)
        instruction1 = self.cpu.fetch()
        opcode, operand = self.cpu.decode(instruction1)
        self.assertEqual(opcode, 0b00011)
        self.assertEqual(operand, 0b0001010111)


class TestHalt(unittest.TestCase):
    def setUp(self):
        self.cpu = cpu.CPU()

    def test_halt(self):
        self.cpu.running = True
        self.cpu.h_halt(0)
        self.cpu.running = False


class TestLoadImmediate(unittest.TestCase):
    def setUp(self):
        self.cpu = cpu.CPU()

    def test_load_upper_immediate(self):
        register_dest = 4
        value = 0xC2
        operand = (register_dest << 8) | value
        self.cpu.h_load_upper_immediate(operand)
        self.assertEqual(self.cpu.register[register_dest], value << 8)
    
    def test_add_immediate(self):
        register_dest = 5
        value = 0x12
        operand = (register_dest << 8) | value
        self.cpu.h_add_immediate(operand)
        self.assertEqual(self.cpu.register[register_dest], value)

    def test_load_full_immediate(self):
        register_dest = 5
        value = 0x12CA
        high_value = 0x12
        low_value = 0xCA
        operand_upper = (register_dest << 8) | high_value
        operand_lower = (register_dest << 8) | low_value
        self.cpu.h_load_upper_immediate(operand_upper)
        self.cpu.h_add_immediate(operand_lower)
        self.assertEqual(self.cpu.register[register_dest], value)


class TestAddImmediate(unittest.TestCase):
    def setUp(self):
        self.cpu = cpu.CPU()
    
    def test_add(self):
        register_dest = 4
        value = 0xEA
        operand = (register_dest << 8) | value
        self.cpu.h_add_immediate(operand)
        self.assertEqual(self.cpu.register[register_dest], value)

    def test_add_overflow(self):
        register_dest = 5
        value = 0xFF
        operand = (register_dest << 8) | value
        self.cpu.h_load_upper_immediate(operand)
        self.cpu.h_add_immediate(operand)
        # actual overflow
        value = 0x11
        operand = (register_dest << 8) | value
        self.cpu.h_add_immediate(operand)
        self.assertEqual(self.cpu.register[register_dest], value)


class TestLoadStoreWord(unittest.TestCase):
    def setUp(self):
        self.cpu = cpu.CPU()

    def test_load_word(self):
        register_dest = 4
        register_base = 5
        base_addr = 10
        offset = 2

        # mock value 0x1F5A (integer of 8026)
        value = 0x1F5A
        self.cpu.memory[base_addr + offset] = (value) & 0xFF
        self.cpu.memory[base_addr + offset + 1] = (value >> 8) & 0xFF

        # mock register value to base_addr
        self.cpu.register[register_base] = base_addr

        operand = (register_dest << 8) | (register_base << 5) | offset

        self.cpu.h_load_word(operand)
        self.assertEqual(self.cpu.register[register_dest], value)

    def test_load_word_misaligned(self):
        register_dest = 4
        register_base = 5
        base_addr = 11
        offset = 0

        # mock register value to base_addr
        self.cpu.register[register_base] = base_addr

        operand = (register_dest << 8) | (register_base << 5) | offset

        with self.assertRaises(cpu.MisalignedMemoryException):
            self.cpu.h_load_word(operand)
        
    def test_store_word(self):
        # set register_src value to 12345
        # store register_src value to memory address at register_base + offset
        value = 12345
        register_src = 3
        register_base = 4
        base_addr = 20
        offset = 0

        self.cpu.register[register_src] = value
        self.cpu.register[register_base] = base_addr

        operand = (register_src << 8) | (register_base << 5) | offset
        self.cpu.h_store_word(operand)
        
        self.assertEqual(self.cpu.fetch_word(base_addr), value)

    def test_store_word_misaligned(self):
        register_src = 3
        register_base = 4
        base_addr = 21
        offset = 0

        # reset register value from previous test
        self.cpu.register[register_base] = base_addr
        operand = (register_src << 8) | (register_base << 5) | offset
        with self.assertRaises(cpu.MisalignedMemoryException):
            self.cpu.h_store_word(operand)


class TestAdd(unittest.TestCase):
    def setUp(self):
        self.cpu = cpu.CPU()

    def test_add(self):
        dest = 3
        src1 = 3
        src2 = 4
        self.cpu.register[src1] = 0xFA9
        self.cpu.register[src2] = 0xF010
        result = self.cpu.register[src1] + self.cpu.register[src2]

        operand = (dest << 8) | (src1 << 5) | (src2 << 2)
        self.cpu.h_add(operand)

        self.assertEqual(self.cpu.register[dest], result)

    def test_add_wrap_around(self):
        dest = 3
        src1 = 3
        src2 = 4
        self.cpu.register[src1] = 0xFFFF
        self.cpu.register[src2] = 20
        result = self.cpu.register[src1] + self.cpu.register[src2]

        operand = (dest << 8) | (src1 << 5) | (src2 << 2)
        self.cpu.h_add(operand)

        self.assertEqual(self.cpu.register[dest], 19)


def build_program(instructions):
    program = []
    for i in instructions:
        low = i & 0xFF
        high = (i >> 8) & 0xFF
        program.append(low)
        program.append(high)
    return program

class TestRunSimpleProgram(unittest.TestCase):
    def setUp(self):
        self.cpu = cpu.CPU()

    def test_run(self):
        # build instruction
        program = build_program([
            # load immediate 0x357F to x1
            assembly.lui(3, 0x35), # lui x1, 0x35
            assembly.addi(3, 0x7F), # addi x1, 0x7F

            # load immediate 0x0034 to x2
            assembly.addi(4, 0x34), # addi x2, 34

            # add x1 & x2 and store to x1
            assembly.add(3, 3, 4), # add x1, x1, x2

            # store x1 to address 0x00FE
            assembly.addi(5, 0xFE), # addi x3, 0xFF
            assembly.sw(3, 5), # sw x1, 0(x3)

            # load address 0x00FF to x3
            assembly.lw(5, 5), # lw x3, 0(x3)

            # halt
            assembly.halt(),
        ])

        self.cpu.load_program(program)
        self.cpu.run_program()

        self.assertEqual(self.cpu.register[5], 0x35b3)


class TestSubtract(unittest.TestCase):
    def setUp(self):
        self.cpu = cpu.CPU()

    def test_subtract(self):
        dest = 3
        src1 = 4
        src2 = 3
        # set register value
        self.cpu.register[src1] = 451
        self.cpu.register[src2] = 51

        operand = (dest << 8) | (src1 << 5) | (src2 << 2)
        self.cpu.h_sub(operand)

        self.assertEqual(self.cpu.register[dest], 400)
    
    def test_subtract_wrap_around(self):
        dest = 3
        src1 = 4
        src2 = 3
        # set register value
        self.cpu.register[src1] = 10
        self.cpu.register[src2] = 12

        operand = (dest << 8) | (src1 << 5) | (src2 << 2)
        self.cpu.h_sub(operand)

        self.assertEqual(self.cpu.register[dest], (2 ** 16) - 2)


class TestJump(TestCaseCPU):
    def test_jump_absolute(self):
        self.cpu.register[0] = 0 # program counter
        addr = 0x0F86
        dest = 3
        self.cpu.register[dest] = addr
        operand = (dest << 8)
        self.cpu.h_jump_absolute(operand)
        self.assertEqual(self.cpu.register[0], addr)

    def test_jump_absolute_misaligned(self):
        self.cpu.register[0] = 0 # program counter
        addr = 0x0F85
        dest = 3
        self.cpu.register[dest] = addr
        operand = (dest << 8)
        with self.assertRaises(cpu.MisalignedMemoryException):
            self.cpu.h_jump_absolute(operand)

    def test_jump_absolute_outofbound(self):
        self.cpu.register[0] = 0 # program counter
        addr = 0x10002
        dest = 3
        self.cpu.register[dest] = addr
        operand = (dest << 8)
        with self.assertRaises(cpu.OutOfBoundException):
            self.cpu.h_jump_absolute(operand)

    def test_jump_relative(self):
        self.cpu.register[0] = 100 # program counter
        offset = 20
        dest = 3
        self.cpu.register[dest] = offset
        operand = (dest << 8)
        self.cpu.h_jump_relative(operand)
        self.assertEqual(self.cpu.register[0], 100 + offset)

    def test_jump_relative_misaligned(self):
        self.cpu.register[0] = 100 # program counter
        offset = 21
        dest = 3
        self.cpu.register[dest] = offset
        operand = (dest << 8)
        with self.assertRaises(cpu.MisalignedMemoryException):
            self.cpu.h_jump_relative(operand)

    def test_jump_relative_outofbound(self):
        self.cpu.register[0] = 0xFFFE # program counter
        offset = 20
        dest = 3
        self.cpu.register[dest] = offset
        operand = (dest << 8)
        with self.assertRaises(cpu.OutOfBoundException):
            self.cpu.h_jump_relative(operand)


class TestBranch(TestCaseCPU):
    def test_branch_eq(self):
        current, offset = 100, 0x22
        dest, src1, src2 = 4, 3, 2

        self.cpu.register[0] = current # program counter
        self.cpu.register[src1] = 0x23 # src1
        self.cpu.register[src2] = 0x23 # src2
        self.cpu.register[dest] = offset # offset addr

        operand = (dest << 8) | (src1 << 5) | (src2 << 2)

        self.cpu.h_branch_equal(operand)
        self.assertEqual(self.cpu.register[0], current + offset)

    def test_branch_not_eq(self):
        current, offset = 100, 0x22
        dest, src1, src2 = 4, 3, 2

        self.cpu.register[0] = current # program counter
        self.cpu.register[src1] = 0x20 # src1
        self.cpu.register[src2] = 0x23 # src2
        self.cpu.register[dest] = offset # offset addr

        operand = (dest << 8) | (src1 << 5) | (src2 << 2)

        self.cpu.h_branch_equal(operand)
        self.assertEqual(self.cpu.register[0], current)

    def test_branch_eq_misaligned(self):
        current, offset = 100, 0x23
        dest, src1, src2 = 4, 3, 2

        self.cpu.register[0] = current # program counter
        self.cpu.register[src1] = 0x23 # src1
        self.cpu.register[src2] = 0x23 # src2
        self.cpu.register[dest] = offset # offset addr

        operand = (dest << 8) | (src1 << 5) | (src2 << 2)

        with self.assertRaises(cpu.MisalignedMemoryException):
            self.cpu.h_branch_equal(operand)

    def test_branch_eq_outofbound(self):
        current, offset = 0xFFFC, 0x00FF
        dest, src1, src2 = 4, 3, 2

        self.cpu.register[0] = current # program counter
        self.cpu.register[src1] = 0x23 # src1
        self.cpu.register[src2] = 0x23 # src2
        self.cpu.register[dest] = offset # offset addr

        operand = (dest << 8) | (src1 << 5) | (src2 << 2)

        with self.assertRaises(cpu.OutOfBoundException):
            self.cpu.h_branch_equal(operand)


if __name__ == "__main__":
    unittest.main()
