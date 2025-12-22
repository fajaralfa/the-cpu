const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn assemble(dest: []u8, words: []const u16) ![]u8 {
    for (words, 0..) |value, i| {
        const ires = i * 2;
        dest[ires] = @intCast(value & std.math.maxInt(u8));
        dest[ires + 1] = @intCast((value >> 8) & std.math.maxInt(u8));
    }
    return dest;
}

fn encodeIType(comptime op: u5, ra: u3, rb: u3, imm: u5) u16 {
    return (@as(u16, op) << 11) | (@as(u16, ra) << 8) | (@as(u16, rb) << 5) | imm;
}

fn encodeRType(comptime op: u5, ra: u3, rb: u3, rc: u3) u16 {
    return (@as(u16, op) << 11) | (@as(u16, ra) << 8) | (@as(u16, rb) << 5) | (@as(u16, rc) << 2);
}

fn opcode(word: u16) u5 {
    return @truncate(word >> 11);
}

pub fn halt() u16 {
    return (0x1F << 11);
}

pub fn lw(dest: u3, base: u3, offset: u5) u16 {
    return encodeIType(1, dest, base, offset);
}

pub fn sw(src: u3, base: u3, offset: u5) u16 {
    return encodeIType(2, src, base, offset);
}

pub fn lui(dest: u3, imm: u8) u16 {
    return (3 << 11) | (@as(u16, dest) << 8) | imm;
}

pub fn addi(dest: u3, src: u3, imm: u5) u16 {
    return encodeIType(4, dest, src, imm);
}

pub fn add(dest: u3, src1: u3, src2: u3) u16 {
    return encodeRType(5, dest, src1, src2);
}

pub fn sub(dest: u3, src1: u3, src2: u3) u16 {
    return encodeRType(6, dest, src1, src2);
}

test "assemble little-endian u16 to bytes" {
    const program_words: []const u16 = &.{ 1, 2, 3 };
    var buffer: [program_words.len * 2]u8 = undefined;
    const bin = try assemble(&buffer, program_words);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 1, 0, 2, 0, 3, 0 }, bin);
}

test "encodeIType layout" {
    const word = encodeIType(0b10101, 0b001, 0b010, 0b11111);

    try std.testing.expectEqual(
        @as(u16, 0b10101_001_010_11111),
        word,
    );
}

test "encodeRType layout" {
    const word = encodeRType(0b00110, 0b111, 0b000, 0b101);

    try std.testing.expectEqual(
        @as(u16, 0b00110_111_000_101_00),
        word,
    );
}

test "Instruction assignments" {
    try std.testing.expectEqual(@as(u5, 1), opcode(lw(0, 0, 0)));
    try std.testing.expectEqual(@as(u5, 2), opcode(sw(0, 0, 0)));
    try std.testing.expectEqual(@as(u5, 3), opcode(lui(0, 0)));
    try std.testing.expectEqual(@as(u5, 4), opcode(addi(0, 0, 0)));
    try std.testing.expectEqual(@as(u5, 5), opcode(add(0, 0, 0)));
    try std.testing.expectEqual(@as(u5, 6), opcode(sub(0, 0, 0)));
}
