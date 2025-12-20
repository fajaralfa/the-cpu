const std = @import("std");
const cpu = @import("zig");

pub fn main() !void {
    var mem = [_]u8{0} ** cpu.max_memory;
    var machine = try cpu.CPU.init(&mem);
    const program = [_]u8{
        0xFF, (3 << 3) | (1), // lui r1, #0xFF
        (1 << 5) | (0x1F), (4 << 3) | (1), // addi r1, r1, #0x1F
        0, (31 << 3), // halt
    };
    try machine.loadProgram(&program);
    try machine.runProgram();
    std.log.info("register r1 {}", .{machine.register[1]});
}
