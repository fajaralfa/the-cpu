const std = @import("std");
const zig = @import("zig");

pub fn main() !void {
    var cpu: CPU = CPU{};
    try cpu.loadProgram();
}

const register_count = 6;
const max_memory = std.math.pow(u16, 2, 6);

const CPU = struct {
    running: bool = false,
    register: [register_count]i16 = .{0} ** register_count,
    memory:  [max_memory]u8 = .{0} ** max_memory,
    handler: [31]*const fn(u16) void = .{nop} ** 31,

    pub fn loadProgram(self: CPU) !void {
        std.debug.print("Running {}\n", .{self.running});
    }
};

fn nop(instr: u16) void {
    _ = instr;
}
