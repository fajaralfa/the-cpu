const std = @import("std");
const lexer = @import("lexer.zig");

pub const Program = std.ArrayList(Instruction);

pub const Inherent = u5;

pub const RType = struct {
    op: u5,
    dest: u3,
};
pub const IType = struct {
    op: u5,
    dest: u3,
    imm: u8,
};
pub const IType2 = struct {
    op: u5,
    dest: u3,
    src1: u3,
    imm: u5,
};
pub const RType2 = struct {
    op: u5,
    dest: u3,
    src1: u3,
};
pub const RType3 = struct {
    op: u5,
    dest: u3,
    src1: u3,
    src2: u3,
};
pub const LabelDef = []const u8;

pub const Instruction = union(enum) {
    labeldef: LabelDef,
    inherent: Inherent,
    rType: RType,
    iType: IType,
    iType2: IType2,
    rType2: RType2,

    fn print(self: Instruction) void {
        switch (self) {
            .labeldef => |v| {
                std.debug.print("labeldef {s}\n", .{v});
            },
            .inherent => |v| {
                std.debug.print("inherent {}\n", .{v});
            },
            .rType => |v| {
                std.debug.print("rType {}\n", .{v});
            },
            .iType => |v| {
                std.debug.print("iType {}\n", .{v});
            },
            .rType2 => |v| {
                std.debug.print("rType {}\n", .{v});
            },
            .iType2 => |v| {
                std.debug.print("iType2 {}\n", .{v});
            },
        }
    }
};

pub const Parser = struct {
    allocator: std.mem.Allocator,
    input: []lexer.Token,
    ast: Program = Program.empty,

    pub fn init(allocator: std.mem.Allocator) Parser {
        return Parser{
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Parser) void {
        self.ast.deinit(self.allocator);
    }
};

test "Manual ast" {
    const lui = Instruction{
        .iType = .{
            .op = 5,
            .dest = 1,
            .imm = 0xFF,
        },
    };

    const halt = Instruction{
        .inherent = 0x1F,
    };

    lui.print();
    halt.print();
}
