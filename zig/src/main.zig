const std = @import("std");
const mod = @import("zig");
const cpu = mod.cpu;
const assembler = mod.assembler;

pub fn main() !void {
    var mem = [_]u8{0} ** cpu.max_memory;
    var machine = try cpu.CPU.init(&mem);
    const program_words = [_]u16{
        assembler.lui(1, 0xFF),
        assembler.addi(1, 1, 0x1F),
        assembler.halt(),
    };
    var buffer: [program_words.len * 2]u8 = undefined;
    const program = try assembler.assemble(buffer[0..], program_words[0..]);
    try machine.loadProgram(program);
    try machine.runProgram();
    std.log.info("register r1 equal expected = {}", .{machine.register[1] == 0xFF1F});
}
