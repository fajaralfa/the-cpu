const std = @import("std");
const mod = @import("zig");
const cpu = mod.cpu;
const assembler = mod.assembler;
const mmio = mod.mmio;

pub const std_options: std.Options = .{
    .log_level = .info,
};

pub fn main() !void {
    var mem = [_]u8{0} ** cpu.max_memory;
    var uart = mmio.UART{};

    const uart_mmio = cpu.MMIODevice{
        .base = 0xFF00,
        .size = 4,
        .ctx = &uart,
        .read = mmio.uartRead,
        .write = mmio.uartWrite,
    };

    const allocator = std.heap.smp_allocator;

    var machine = try cpu.CPU.init(mem[0..]);
    try machine.addMMIO(allocator, uart_mmio);
    defer machine.deinitMMIO(allocator);

    // program to print ABCDEF
    const program_words = [_]u16{
        // target mmio
        assembler.lui(1, 0xff),

        // r2 = 1
        assembler.lui(2, 0),
        assembler.addi(2, 2, 0x1),

        // r3 = 6
        assembler.lui(3, 0),
        assembler.addi(3, 3, 0x6),

        // loop:
        // r2 = r2 << r3
        assembler.sll(2, 2, 3),

        // r3 = 1
        assembler.lui(3, 0),
        assembler.addi(3, 3, 0x1),

        // r2 = r2 + 1
        assembler.add(2, 2, 3),

        // mem[0xFF] = r2
        assembler.sw(2, 1, 0),

        // LOOP BACK

        // for shifting
        assembler.lui(6, 0),
        assembler.addi(6, 6, 8),

        // store loop offset in r4 -13 or 0xFFF3 (two's complement)
        // load upper 0xFF
        assembler.lui(4, 0xFF),

        // load lower 0xF3
        assembler.lui(5, 0xF3),
        assembler.srl(5, 5, 6),
        assembler.add(4, 4, 5),

        // store target value in r3 (0x46 for 'F')
        assembler.lui(3, 0x46),
        assembler.srl(3, 3, 6),

        // jump if r2 != r3
        assembler.bne(4, 2, 3),

        // halt
        assembler.halt(),
    };
    var buffer: [program_words.len * 2]u8 = undefined;
    const program = try assembler.assemble(buffer[0..], program_words[0..]);
    try machine.loadProgram(program);
    try machine.runProgram();
    std.debug.print("\n", .{});
}
