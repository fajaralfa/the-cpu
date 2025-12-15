const std = @import("std");
const cpu = @import("zig");

pub fn main() !void {
    var mem = [_]u8{0} ** cpu.max_memory;
    var machine = try cpu.CPU.init(&mem);
    const program = [_]u8{
        0, (2 << 3), // load
        0, (1 << 3), // halt
    };
    try machine.loadProgram(&program);
    try machine.runProgram();
}
