const std = @import("std");
const lexer = @import("lexer.zig");

pub const Program = std.ArrayList(Block);

pub const Block = union(enum) {
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

pub const Operand = union(enum) {
    register: Register,
    immediate: Immediate,
    label: Label,
};

pub const Register = enum { PC, SP, X1, X2, X3, MEPC, MCAUSE, MTVEC };
pub const Immediate = i8;

pub const Parser = struct {
    allocator: std.mem.Allocator,
    tokens: []const lexer.Token,
    ast: Program,

    fn init(allocator: std.mem.Allocator, input: []lexer.Token) Parser {
        return Parser{
            .allocator = allocator,
            .tokens = input,
            .ast = Program.empty,
        };
    }

    fn deinit(self: *Parser) void {
        self.ast.deinit(self.allocator);
    }

    fn parse(self: *Parser) !Program {
        try self.ast.append(self.allocator, Block{ .label = .{ .name = "anjay", .address = 123 } });
        return self.ast;
    }
};

test "Init parser" {
    const allocator = std.testing.allocator;
    var lex = lexer.Lexer.init(allocator,
        \\start: end:
        \\x1 lui
    );
    defer lex.deinit();
    const tokens = try lex.tokenize();

    var parser = Parser.init(allocator, tokens.items);
    defer parser.deinit();
    const ast = try parser.parse();
    _ = ast;
}
