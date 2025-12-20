const std = @import("std");

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
        // cpu.handler[0x2] = sw;
        cpu.handler[0x2] = lui;
        cpu.handler[0x3] = addi;
        cpu.handler[0x4] = add;
        cpu.handler[0x5] = sub;
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
};

test "Test load program" {
    var mem = [_]u8{0} ** max_memory;
    var cpu = try CPU.init(&mem);
    const program = [_]u8{ 2, 2, 31 };
    try cpu.loadProgram(&program);
    try std.testing.expect(cpu.memory[cpu.start_prog] == program[0]);
    try std.testing.expect(cpu.memory[cpu.start_prog + 1] == program[1]);
    try std.testing.expect(cpu.memory[cpu.start_prog + 2] == program[2]);
}

test "Test load program out of bound" {
    var mem = [_]u8{0} ** max_memory;
    var cpu = try CPU.init(&mem);
    const start_addr: usize = max_memory / 2;
    const program = [_]u8{3} ** (start_addr + 1);
    try std.testing.expectError(CPUError.OutOfBounds, cpu.loadProgram(&program));
}

test "Test run program" {
    var mem = [_]u8{0} ** max_memory;
    var cpu = try CPU.init(&mem);
    const program = [_]u8{
        0, (2 << 3) | 1, // load r1, 0
        0, (31 << 3), // halt
    };
    try cpu.loadProgram(&program);
    try cpu.runProgram();
    try std.testing.expect(true);
}

test "Test lw" {
    var mem = [_]u8{0} ** 32;
    var cpu = try CPU.init(&mem);
    cpu.memory[10] = 0x11;
    cpu.memory[11] = 0x23;
    cpu.register[2] = 10;
    try cpu.lw((1 << 8) | (2 << 5) | 0);
    try std.testing.expect(cpu.register[1] == 0x2311);
}

test "Test lw OutOfBounds, Misaligned" {
    var mem = [_]u8{0} ** 32;
    var cpu = try CPU.init(&mem);
    cpu.register[2] = 128; // make alignment checking passes
    var result = cpu.lw((1 << 8) | (2 << 5) | 0);
    try std.testing.expect(result == CPUError.OutOfBounds);

    cpu.register[2] = 61;
    result = cpu.lw((1 << 8) | (2 << 5) | 0);
    try std.testing.expect(result == CPUError.MisalignedMemory);
}

test "Test sw" {
    var mem = [_]u8{0} ** 32;
    var cpu = try CPU.init(&mem);
    cpu.register[2] = 10;
    cpu.register[1] = 0x2311;
    try cpu.sw((1 << 8) | (2 << 5) | 0);
    try std.testing.expect(cpu.memory[10] == 0x11);
    try std.testing.expect(cpu.memory[11] == 0x23);
}

test "Test sw OutOfBound, MisalignedMemory" {
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

test "Test lui" {
    var mem = [_]u8{0} ** max_memory;
    var cpu = try CPU.init(&mem);
    try cpu.lui((1 << 8) | 0xFF);

    try std.testing.expect(cpu.register[1] == 0xFF00);
}

test "Test addi" {
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

test "Test addi wraparound" {
    var mem = [_]u8{0} ** max_memory;
    var cpu = try CPU.init(&mem);
    cpu.register[1] = 0xFFF2;
    try cpu.addi((1 << 8) | (1 << 5) | (0x0F));
    try std.testing.expect(cpu.register[1] == 1);
}

test "Test add" {
    var mem = [_]u8{0} ** max_memory;
    var cpu = try CPU.init(&mem);
    cpu.register[1] = 10;
    cpu.register[2] = 20;

    try cpu.add((1 << 8) | (1 << 5) | (2 << 2));

    try std.testing.expect(cpu.register[1] == 30);
}

test "Test add wraparound" {
    var mem = [_]u8{0} ** max_memory;
    var cpu = try CPU.init(&mem);
    cpu.register[1] = 0xFFF2;
    cpu.register[2] = 0xF;
    try cpu.add((1 << 8) | (1 << 5) | (2 << 2));
    try std.testing.expect(cpu.register[1] == 1);
}

test "Test sub" {
    var mem = [_]u8{0} ** max_memory;
    var cpu = try CPU.init(&mem);
    cpu.register[1] = 32;
    cpu.register[2] = 12;

    try cpu.sub((1 << 8) | (1 << 5) | (2 << 2));

    try std.testing.expect(cpu.register[1] == 20);
}

test "Test sub wraparound" {
    var mem = [_]u8{0} ** max_memory;
    var cpu = try CPU.init(&mem);
    cpu.register[1] = 10;
    cpu.register[2] = 20;
    try cpu.sub((1 << 8) | (1 << 5) | (2 << 2));
    try std.testing.expect(cpu.register[1] == 0xFFF6);
}
