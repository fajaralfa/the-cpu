const std = @import("std");
const zig = @import("zig");

pub fn main() !void {
    var cpu: CPU = CPU{};
    const program = [_]u8{ 1, 2, 3 };
    try cpu.loadProgram(&program);
    try cpu.runProgram();
}

const CPUError = error{
    OutOfBound,
    InvalidInstruction,
};

const register_count = 6;
const max_memory = 1 << 16;

const CPU = struct {
    running: bool = false,
    register: [register_count]u16 = .{0} ** register_count,
    memory: [max_memory]u8 = .{0} ** max_memory,
    handler: [31]*const fn (u16) CPUError!void = .{invalid} ** 31,
    start_addr: u16 = max_memory / 2,

    pub fn loadProgram(self: *CPU, program: []const u8) CPUError!void {
        if (program.len > (max_memory - @as(u32, self.start_addr))) {
            return CPUError.OutOfBound;
        }
        for (program, self.start_addr..) |byte, addr| {
            self.memory[addr] = byte;
        }
    }

    pub fn runProgram(self: *CPU) CPUError!void {
        self.running = true;
        self.register[0] = self.start_addr;
        while (self.running) {
            const instr = self.fetchInstr();
            try self.execInstr(instr);
        }
    }

    fn fetchInstr(self: *CPU) u16 {
        const addr = self.register[0];
        const lo = self.memory[addr];
        const hi = self.memory[addr + 1];
        const instr: u16 = (@as(u16, hi) << 8) | lo;
        self.register[0] += 2;
        return instr;
    }

    fn execInstr(self: *CPU, instr: u16) CPUError!void {
        const opcode = (instr >> 11);
        const handler = self.handler[opcode];
        try handler(instr);
    }
};

fn invalid(instr: u16) CPUError!void {
    _ = instr;
    return CPUError.InvalidInstruction;
}

test "Test load program" {
    var cpu: CPU = CPU{};
    const program = [_]u8{ 1, 2, 3 };
    try cpu.loadProgram(&program);
    try std.testing.expect(cpu.memory[cpu.start_addr] == program[0]);
    try std.testing.expect(cpu.memory[cpu.start_addr + 1] == program[1]);
    try std.testing.expect(cpu.memory[cpu.start_addr + 2] == program[2]);
}

test "Test load program out of bound" {
    var cpu: CPU = CPU{};
    const start_addr: usize = max_memory / 2;
    const program = [_]u8{3} ** (start_addr + 1);
    try std.testing.expectError(CPUError.OutOfBound, cpu.loadProgram(&program));
}

test "Test run program" {
    var cpu: CPU = CPU{};
    const program = [_]u8{ 1, 2, 3 };
    try cpu.loadProgram(&program);
    try cpu.runProgram();
    try std.testing.expect(true);
}
