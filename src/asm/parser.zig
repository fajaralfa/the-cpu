const std = @import("std");
const lexer = @import("lexer.zig");

pub const Program = std.ArrayList(Block);

pub const Block = union {
    label: Label,
    instruction: Instruction,
};

pub const Label = struct {
    name: []const u8,
    address: ?u16 = null, // absolute address from start of the program
};

pub const Instruction = struct {
    opcode: Opcode,
    operand: []Operand,
};

pub const Opcode = enum {
    Halt,
    Lui,
    Addi,
};

pub const Operand = union {
    register: Register,
    immediate: Immediate,
    label: Label,
};

pub const Register = enum { PC, SP, X1, X2, X3, MEPC, MCAUSE, MTVEC };
pub const Immediate = i8;

test "Parse label" {
    const allocator = std.testing.allocator;
    var lex = lexer.Lexer.init(allocator,
        \\start: end:
        \\x1 lui
    );
    defer lex.deinit();
    // const tokens = try lex.tokenize();

    // var parser = Parser.init(allocator, tokens.items);
    // defer parser.deinit();
    // const ast = try parser.parse();

    // std.debug.print("token len {}\n", .{tokens.items.len});
    // std.debug.print("ast len {}\n", .{ast.items.len});
    // for (ast.items) |instr| {
    //     instr.print();
    // }
}
