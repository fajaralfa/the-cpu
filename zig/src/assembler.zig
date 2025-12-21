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

pub fn halt() u16 {
    return (0x1F << 11);
}

pub fn lw(dest: u3, base: u3, offset: u5) u16 {
    return (1 << 11) | (@as(u16, dest) << 8) | (@as(u16, base) << 5) | offset;
}

pub fn sw(src: u3, base: u3, offset: u5) u16 {
    return (2 << 11) | (@as(u16, src) << 8) | (@as(u16, base) << 5) | offset;
}

pub fn lui(dest: u3, imm: u8) u16 {
    return (3 << 11) | (@as(u16, dest) << 8) | imm;
}

pub fn addi(dest: u3, src: u3, imm: u5) u16 {
    return (4 << 11) | (@as(u16, dest) << 8) | (@as(u16, src) << 5) | imm;
}

pub fn add(dest: u3, src1: u3, src2: u3) u16 {
    return (5 << 11) | (@as(u16, dest) << 8) | (@as(u16, src1) << 5) | (@as(u16, src2) << 2);
}

pub fn sub(dest: u3, src1: u3, src2: u3) u16 {
    return (6 << 11) | (@as(u16, dest) << 8) | (@as(u16, src1) << 5) | (@as(u16, src2) << 2);
}

test "assemble little-endian u16 to bytes" {
    const allocator = std.testing.allocator;
    const instructions: []const u16 = &.{ 1, 2, 3 };
    const bin = try assemble(allocator, instructions);
    defer allocator.free(bin);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 1, 0, 2, 0, 3, 0 }, bin);
}

test "lw" {
    const expected: u16 = (1 << 11) | (6 << 8) | (7 << 5) | 25;
    try std.testing.expectEqual(expected, lw(6, 7, 25));

    try std.testing.expectEqual(@as(u16, 1 << 11), lw(0, 0, 0));
}

test "sw" {
    const expected: u16 = (2 << 11) | (6 << 8) | (7 << 5) | 25;
    try std.testing.expectEqual(expected, sw(6, 7, 25));

    try std.testing.expectEqual(@as(u16, 2 << 11), sw(0, 0, 0));
}

test "lui" {
    const expected: u16 = (3 << 11) | (6 << 8) | 7;
    try std.testing.expectEqual(expected, lui(6, 7));

    try std.testing.expectEqual(@as(u16, 3 << 11), lui(0, 0));
}

test "addi" {
    const expected: u16 = (4 << 11) | (1 << 8) | (2 << 5) | 0x1F;
    try std.testing.expectEqual(expected, addi(1, 2, 0x1F));

    try std.testing.expectEqual(@as(u16, 4 << 11), addi(0, 0, 0));
}

test "add" {
    const expected: u16 = (5 << 11) | (1 << 8) | (2 << 5) | (3 << 2);
    try std.testing.expectEqual(expected, add(1, 2, 3));

    try std.testing.expectEqual(@as(u16, 5 << 11), add(0, 0, 0));
}

test "sub" {
    const expected: u16 = (6 << 11) | (1 << 8) | (2 << 5) | (3 << 2);
    try std.testing.expectEqual(expected, sub(1, 2, 3));

    try std.testing.expectEqual(@as(u16, 6 << 11), sub(0, 0, 0));
}
