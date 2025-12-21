const std = @import("std");
const assembler = @import("assembler.zig");

pub const CPUError = error{
    OutOfBounds,
    InvalidInstruction,
    MemoryTooLarge,
    MisalignedMemory,
};

pub const register_count = 8;
pub const max_memory: u32 = 1 << 16;

pub const CPU = struct {
    running: bool,
    register: [register_count]u16,
    memory: []u8,
    start_prog: u16,
    handler: [32]*const fn (*CPU, u16) CPUError!void,

    pub fn init(memory: []u8) CPUError!CPU {
        if (memory.len > max_memory) {
            return CPUError.MemoryTooLarge;
        }

        var cpu = CPU{
            .register = .{0} ** register_count,
            .running = false,
            .memory = memory,
            .start_prog = @intCast(memory.len / 2),
            .handler = .{invalid} ** 32,
        };
        cpu.handler[0x1F] = halt;
        cpu.handler[0x1] = lw;
        cpu.handler[0x2] = sw;
        cpu.handler[0x3] = lui;
        cpu.handler[0x4] = addi;
        cpu.handler[0x5] = add;
        cpu.handler[0x6] = sub;
        cpu.handler[0x7] = andInstr;
        cpu.handler[0x8] = notInstr;
        cpu.handler[0x9] = orInstr;
        cpu.handler[0xa] = xorInstr;
        cpu.handler[0xb] = sll;
        cpu.handler[0xc] = srl;
        return cpu;
    }

    pub fn loadProgram(self: *CPU, program: []const u8) CPUError!void {
        if (program.len > (max_memory - self.start_prog)) {
            return CPUError.OutOfBounds;
        }
        for (program, self.start_prog..) |byte, addr| {
            self.memory[addr] = byte;
        }
    }

    pub fn runProgram(self: *CPU) CPUError!void {
        self.running = true;
        self.register[0] = self.start_prog;
        while (self.running) {
            const instr = try self.fetchInstr();
            try self.execInstr(instr);
        }
    }

    fn fetchInstr(self: *CPU) CPUError!u16 {
        const addr = self.register[0];

        if (addr + 1 >= self.memory.len) {
            return CPUError.OutOfBounds;
        }

        const lo = self.memory[addr];
        const hi = self.memory[addr + 1];
        self.register[0] += 2;

        return (@as(u16, hi) << 8) | lo;
    }

    fn execInstr(self: *CPU, instr: u16) CPUError!void {
        std.log.info("instr {b}", .{instr});
        const opcode = (instr >> 11);
        std.log.info("opcode {}", .{opcode});
        const handler = self.handler[opcode];
        std.log.info("instr: {b}", .{instr});
        try handler(self, instr);
    }

    fn invalid(self: *CPU, instr: u16) CPUError!void {
        std.log.info("invalid instruction dispatched!", .{});
        _ = self;
        _ = instr;
        return CPUError.InvalidInstruction;
    }

    fn halt(self: *CPU, _: u16) CPUError!void {
        std.log.info("halt dispatched!", .{});
        self.running = false;
    }

    fn lw(self: *CPU, instr: u16) CPUError!void {
        const dest: u3 = @intCast((instr >> 8) & std.math.maxInt(u3));
        const base: u3 = @intCast((instr >> 5) & std.math.maxInt(u3));
        const offset: u5 = @intCast(instr & std.math.maxInt(u5));
        const addr = self.register[base] + offset;
        if (addr % 2 != 0) {
            return CPUError.MisalignedMemory;
        }
        if (addr + 1 > self.memory.len) {
            return CPUError.OutOfBounds;
        }
        const lo = self.memory[addr];
        const hi = self.memory[addr + 1];
        self.register[dest] = (@as(u16, hi) << 8) | lo;
    }

    fn sw(self: *CPU, instr: u16) CPUError!void {
        const src: u3 = @intCast((instr >> 8) & std.math.maxInt(u3));
        const base: u3 = @intCast((instr >> 5) & std.math.maxInt(u3));
        const offset: u5 = @intCast(instr & std.math.maxInt(u5));
        const addr = self.register[base] + offset;
        if (addr % 2 != 0) {
            return CPUError.MisalignedMemory;
        }
        if (addr > self.memory.len - 2) {
            return CPUError.OutOfBounds;
        }
        const hi: u8 = @intCast(self.register[src] >> 8 & std.math.maxInt(u8));
        const lo: u8 = @intCast(self.register[src] & std.math.maxInt(u8));
        self.memory[addr] = lo;
        self.memory[addr + 1] = hi;
    }

    fn lui(self: *CPU, instr: u16) CPUError!void {
        std.log.info("lui dispatched!", .{});
        const dest: u3 = @intCast((instr >> 8) & ((1 << 3) - 1));
        const imm: u16 = @intCast(instr & 0xFF); // casting this to u8 throws:
        self.register[dest] = imm << 8; // type 'u3' cannot represent integer value '8'
    }

    fn addi(self: *CPU, instr: u16) CPUError!void {
        std.log.info("addi dispatched!", .{});
        const dest: u3 = @intCast((instr >> 8) & ((1 << 3) - 1));
        const src: u3 = @intCast((instr >> 5) & ((1 << 3) - 1));
        const imm: u5 = @intCast((instr) & ((1 << 5) - 1));
        self.register[dest] = self.register[src] +% imm; // wrap around
    }

    fn add(self: *CPU, instr: u16) CPUError!void {
        std.log.info("add dispatched!", .{});
        const dest: u3 = @intCast((instr >> 8) & ((1 << 3) - 1));
        const src1: u3 = @intCast((instr >> 5) & ((1 << 3) - 1));
        const src2: u3 = @intCast((instr >> 2) & ((1 << 3) - 1));
        self.register[dest] = self.register[src1] +% self.register[src2]; // wrap around
    }

    fn sub(self: *CPU, instr: u16) CPUError!void {
        std.log.info("sub dispatched!", .{});
        const dest: u3 = @intCast((instr >> 8) & ((1 << 3) - 1));
        const src1: u3 = @intCast((instr >> 5) & ((1 << 3) - 1));
        const src2: u3 = @intCast((instr >> 2) & ((1 << 3) - 1));
        self.register[dest] = self.register[src1] -% self.register[src2]; // wrap around
    }

    fn andInstr(self: *CPU, instr: u16) CPUError!void {
        std.log.info("and dispatched!", .{});
        const dest: u3 = @intCast((instr >> 8) & ((1 << 3) - 1));
        const src1: u3 = @intCast((instr >> 5) & ((1 << 3) - 1));
        const src2: u3 = @intCast((instr >> 2) & ((1 << 3) - 1));
        self.register[dest] = self.register[src1] & self.register[src2];
    }

    fn notInstr(self: *CPU, instr: u16) CPUError!void {
        std.log.info("not dispatched!", .{});
        const dest: u3 = @intCast((instr >> 8) & ((1 << 3) - 1));
        const src: u3 = @intCast((instr >> 5) & ((1 << 3) - 1));
        self.register[dest] = ~self.register[src];
    }

    fn orInstr(self: *CPU, instr: u16) CPUError!void {
        std.log.info("or dispatched!", .{});
        const dest: u3 = @intCast((instr >> 8) & ((1 << 3) - 1));
        const src1: u3 = @intCast((instr >> 5) & ((1 << 3) - 1));
        const src2: u3 = @intCast((instr >> 2) & ((1 << 3) - 1));
        self.register[dest] = self.register[src1] | self.register[src2];
    }

    fn xorInstr(self: *CPU, instr: u16) CPUError!void {
        std.log.info("or dispatched!", .{});
        const dest: u3 = @intCast((instr >> 8) & ((1 << 3) - 1));
        const src1: u3 = @intCast((instr >> 5) & ((1 << 3) - 1));
        const src2: u3 = @intCast((instr >> 2) & ((1 << 3) - 1));
        self.register[dest] = self.register[src1] ^ self.register[src2];
    }

    fn sll(self: *CPU, instr: u16) CPUError!void {
        std.log.info("sll dispatched!", .{});
        const dest: u3 = @intCast((instr >> 8) & ((1 << 3) - 1));
        const src1: u3 = @intCast((instr >> 5) & ((1 << 3) - 1));
        const src2: u3 = @intCast((instr >> 2) & ((1 << 3) - 1));
        self.register[dest] = self.register[src1] << @truncate(self.register[src2]);
    }

    fn srl(self: *CPU, instr: u16) CPUError!void {
        std.log.info("srl dispatched!", .{});
        const dest: u3 = @intCast((instr >> 8) & ((1 << 3) - 1));
        const src1: u3 = @intCast((instr >> 5) & ((1 << 3) - 1));
        const src2: u3 = @intCast((instr >> 2) & ((1 << 3) - 1));
        self.register[dest] = self.register[src1] >> @truncate(self.register[src2]);
    }
};

test "load program" {
    var mem = [_]u8{0} ** max_memory;
    var cpu = try CPU.init(&mem);
    const program = [_]u8{ 2, 2, 31 };
    try cpu.loadProgram(&program);
    try std.testing.expect(cpu.memory[cpu.start_prog] == program[0]);
    try std.testing.expect(cpu.memory[cpu.start_prog + 1] == program[1]);
    try std.testing.expect(cpu.memory[cpu.start_prog + 2] == program[2]);
}

test "load program out of bound" {
    var mem = [_]u8{0} ** max_memory;
    var cpu = try CPU.init(&mem);
    const start_addr: usize = max_memory / 2;
    const program = [_]u8{3} ** (start_addr + 1);
    try std.testing.expectError(CPUError.OutOfBounds, cpu.loadProgram(&program));
}

test "run program" {
    var mem = [_]u8{0} ** max_memory;
    var cpu = try CPU.init(&mem);
    const program_words = [_]u16{
        assembler.lui(1, 0xFF),
        assembler.addi(1, 1, 0x1F),
        assembler.halt(),
    };
    var buffer: [program_words.len * 2]u8 = undefined;
    var program = try assembler.assemble(buffer[0..], program_words[0..]);
    try cpu.loadProgram(program[0..]);
    try cpu.runProgram();
    try std.testing.expect(true);
}

test "lw" {
    var mem = [_]u8{0} ** 32;
    var cpu = try CPU.init(&mem);
    cpu.memory[10] = 0x11;
    cpu.memory[11] = 0x23;
    cpu.register[2] = 10;
    try cpu.lw((1 << 8) | (2 << 5) | 0);
    try std.testing.expect(cpu.register[1] == 0x2311);
}

test "lw OutOfBounds, Misaligned" {
    var mem = [_]u8{0} ** 32;
    var cpu = try CPU.init(&mem);
    cpu.register[2] = 128; // make alignment checking passes
    var result = cpu.lw((1 << 8) | (2 << 5) | 0);
    try std.testing.expect(result == CPUError.OutOfBounds);

    cpu.register[2] = 61;
    result = cpu.lw((1 << 8) | (2 << 5) | 0);
    try std.testing.expect(result == CPUError.MisalignedMemory);
}

test "sw" {
    var mem = [_]u8{0} ** 32;
    var cpu = try CPU.init(&mem);
    cpu.register[2] = 10;
    cpu.register[1] = 0x2311;
    try cpu.sw((1 << 8) | (2 << 5) | 0);
    try std.testing.expect(cpu.memory[10] == 0x11);
    try std.testing.expect(cpu.memory[11] == 0x23);
}

test "sw OutOfBound, MisalignedMemory" {
    var mem = [_]u8{0} ** 32;
    var cpu = try CPU.init(&mem);

    // OutOfBound
    cpu.register[1] = 0x2311;
    cpu.register[2] = 34;
    var result = cpu.sw((1 << 8) | (2 << 5) | 0);
    try std.testing.expect(result == CPUError.OutOfBounds);

    // Misaligned
    cpu.register[1] = 0x2311;
    cpu.register[2] = 31;
    result = cpu.sw((1 << 8) | (2 << 5) | 0);
    try std.testing.expect(result == CPUError.MisalignedMemory);
}

test "lui" {
    var mem = [_]u8{0} ** max_memory;
    var cpu = try CPU.init(&mem);
    try cpu.lui((1 << 8) | 0xFF);

    try std.testing.expect(cpu.register[1] == 0xFF00);
}

test "addi" {
    var mem = [_]u8{0} ** max_memory;
    var cpu = try CPU.init(&mem);
    cpu.register[1] = 0xFF00;

    // just so you know
    try cpu.addi((1 << 8) | (1 << 5) | (0x1F));
    try cpu.addi((1 << 8) | (1 << 5) | (0x1F));
    try cpu.addi((1 << 8) | (1 << 5) | (0x1F));
    try cpu.addi((1 << 8) | (1 << 5) | (0x1F));
    try cpu.addi((1 << 8) | (1 << 5) | (0x1F));
    try cpu.addi((1 << 8) | (1 << 5) | (0x1F));
    try cpu.addi((1 << 8) | (1 << 5) | (0x1F));
    try cpu.addi((1 << 8) | (1 << 5) | (0x1F));
    try cpu.addi((1 << 8) | (1 << 5) | (0x7));

    try std.testing.expect(cpu.register[1] == 0xFFFF);
}

test "addi wraparound" {
    var mem = [_]u8{0} ** max_memory;
    var cpu = try CPU.init(&mem);
    cpu.register[1] = 0xFFF2;
    try cpu.addi((1 << 8) | (1 << 5) | (0x0F));
    try std.testing.expect(cpu.register[1] == 1);
}

test "add" {
    var mem = [_]u8{0} ** max_memory;
    var cpu = try CPU.init(&mem);
    cpu.register[1] = 10;
    cpu.register[2] = 20;

    try cpu.add((1 << 8) | (1 << 5) | (2 << 2));

    try std.testing.expect(cpu.register[1] == 30);
}

test "add wraparound" {
    var mem = [_]u8{0} ** max_memory;
    var cpu = try CPU.init(&mem);
    cpu.register[1] = 0xFFF2;
    cpu.register[2] = 0xF;
    try cpu.add((1 << 8) | (1 << 5) | (2 << 2));
    try std.testing.expect(cpu.register[1] == 1);
}

test "sub" {
    var mem = [_]u8{0} ** max_memory;
    var cpu = try CPU.init(&mem);
    cpu.register[1] = 32;
    cpu.register[2] = 12;

    try cpu.sub((1 << 8) | (1 << 5) | (2 << 2));

    try std.testing.expect(cpu.register[1] == 20);
}

test "sub wraparound" {
    var mem = [_]u8{0} ** max_memory;
    var cpu = try CPU.init(&mem);
    cpu.register[1] = 10;
    cpu.register[2] = 20;
    try cpu.sub((1 << 8) | (1 << 5) | (2 << 2));
    try std.testing.expect(cpu.register[1] == 0xFFF6);
}

test "and" {
    var mem = [_]u8{0} ** 10;
    var cpu = try CPU.init(&mem);
    cpu.register[1] = 0b1100;
    cpu.register[2] = 0b1011;
    try cpu.andInstr((1 << 8) | (1 << 5) | (2 << 2));
    try std.testing.expect(cpu.register[1] == 0b1000);
}

test "not" {
    var mem = [_]u8{0} ** 10;
    var cpu = try CPU.init(&mem);
    cpu.register[1] = 0b1011;
    try cpu.notInstr((1 << 8) | (1 << 5));
    const result = cpu.register[1] & std.math.maxInt(u4); // only compare last 4 bit
    try std.testing.expect(result == 0b0100);
}

test "or" {
    var mem = [_]u8{0} ** 10;
    var cpu = try CPU.init(&mem);
    cpu.register[1] = 0b1100;
    cpu.register[2] = 0b1011;
    try cpu.orInstr((1 << 8) | (1 << 5) | (2 << 2));
    try std.testing.expect(cpu.register[1] == 0b1111);
}

test "xor" {
    var mem = [_]u8{0} ** 10;
    var cpu = try CPU.init(&mem);
    cpu.register[1] = 0b1100;
    cpu.register[2] = 0b1011;
    try cpu.xorInstr((1 << 8) | (1 << 5) | (2 << 2));
    try std.testing.expect(cpu.register[1] == 0b0111);
}

test "sll" {
    var mem = [_]u8{0} ** 10;
    var cpu = try CPU.init(&mem);
    cpu.register[1] = @as(u16, 0b0001);
    cpu.register[2] = 2;
    try cpu.sll((1 << 8) | (1 << 5) | (2 << 2));
    try std.testing.expect(cpu.register[1] == @as(u16, 0b0100));
}

test "srl" {
    var mem = [_]u8{0} ** 10;
    var cpu = try CPU.init(&mem);
    cpu.register[1] = 0b1000;
    cpu.register[2] = 2;
    try cpu.srl((1 << 8) | (1 << 5) | (2 << 2));
    try std.testing.expect(cpu.register[1] == 0b0010);
}
