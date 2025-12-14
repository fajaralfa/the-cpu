const std = @import("std");
const zig = @import("zig");

pub fn main() !void {
    var cpu: CPU = CPU{};
    const program = [_]u8{ 1, 2, 3 };
    try cpu.loadProgram(&program);
}

const CPUError = error{
    OutOfBound,
};

const register_count = 6;
const max_memory = std.math.pow(u16, 2, 6);

const CPU = struct {
    running: bool = false,
    register: [register_count]i16 = .{0} ** register_count,
    memory: [max_memory]u8 = .{0} ** max_memory,
    handler: [31]*const fn (u16) void = .{nop} ** 31,

    pub fn loadProgram(self: *CPU, program: []const u8) CPUError!void {
        const start_addr: usize = max_memory / 2;
        if (program.len > (max_memory - start_addr)) {
            return CPUError.OutOfBound;
        }
        for (program, start_addr..) |byte, addr| {
            self.memory[addr] = byte;
        }
    }
};

fn nop(instr: u16) void {
    _ = instr;
}

test "Test load program" {
    var cpu: CPU = CPU{};
    const program = [_]u8{ 1, 2, 3 };
    const start_addr: usize = max_memory / 2;
    try cpu.loadProgram(&program);
    try std.testing.expect(cpu.memory[start_addr] == program[0]);
    try std.testing.expect(cpu.memory[start_addr + 1] == program[1]);
    try std.testing.expect(cpu.memory[start_addr + 2] == program[2]);
}

test "Test load program out of bound" {
    var cpu: CPU = CPU{};
    const start_addr: usize = max_memory / 2;
    const program = [_]u8{3} ** (start_addr + 1);
    try std.testing.expectError(CPUError.OutOfBound, cpu.loadProgram(&program));
}
