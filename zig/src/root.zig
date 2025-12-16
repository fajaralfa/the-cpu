const std = @import("std");

pub const CPUError = error{
    OutOfBounds,
    InvalidInstruction,
    MemoryTooLarge,
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
        cpu.handler[1] = halt;
        cpu.handler[2] = loadi;
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
        const opcode = (instr >> 11);
        std.log.info("opcode {}", .{opcode});
        const handler = self.handler[opcode];
        try handler(self, instr);
    }

    fn invalid(self: *CPU, instr: u16) CPUError!void {
        std.log.info("invalid instruction dispatched!", .{});
        _ = self;
        _ = instr;
        return CPUError.InvalidInstruction;
    }

    fn loadi(self: *CPU, instr: u16) CPUError!void {
        std.log.info("loadi instruction dispatched!", .{});
        _ = self;
        _ = instr;
    }

    fn halt(self: *CPU, instr: u16) CPUError!void {
        std.log.info("halt instruction dispatched!", .{});
        _ = instr;
        self.running = false;
    }
};

test "Test load program" {
    var mem = [_]u8{0} ** max_memory;
    var cpu = try CPU.init(&mem);
    const program = [_]u8{ 2, 2, 1 };
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
        0, (2 << 3), // load
        0, (1 << 3), // halt
    };
    try cpu.loadProgram(&program);
    try cpu.runProgram();
    try std.testing.expect(true);
}
