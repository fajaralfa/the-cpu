const std = @import("std");
const lexer = @import("lexer.zig");

pub const Program = std.ArrayList(Instruction);

pub const Inherent = []const u8;

pub const RType = struct {
    op: []const u8,
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

pub const ParseError = error{
    UnexpectedToken,
};

pub const Parser = struct {
    allocator: std.mem.Allocator,
    input: []lexer.Token,
    ast: Program = Program.empty,
    current: usize = 0,

    pub fn init(allocator: std.mem.Allocator, input: []lexer.Token) Parser {
        return Parser{
            .allocator = allocator,
            .input = input,
        };
    }

    pub fn deinit(self: *Parser) void {
        self.ast.deinit(self.allocator);
    }

    pub fn parse(self: *Parser) !Program {
        while (self.peek().type != .EOF) {
            try self.block();
        }
        return self.ast;
    }

    fn block(self: *Parser) !void {
        const token = self.consume();
        std.debug.print("type: {}\n", .{token.type});
        if (token.type == .Label) {
            try self.label(token.literal);
        } else if (token.type == .Opcode) {
            try self.instruction();
        }
    }

    fn label(self: *Parser, labelname: []const u8) !void {
        const lookahead = self.peek();
        if (lookahead.type == .Colon) {
            _ = self.consume();
            const result = Instruction{ .labeldef = labelname };
            try self.ast.append(self.allocator, result);
        } else {
            return ParseError.UnexpectedToken;
        }
    }

    fn instruction(self: *Parser) !void {
        var lookahead = self.peek();
        if (lookahead.type == .Register) {
            _ = self.consume();
            lookahead = self.peek();
            var result = undefined;
            if (lookahead.type == .Register) {
                result = Instruction{ .rType = .{ .dest = 2, .op = 3 } };
            } else if (lookahead.type == .ImmVal) {
                result = Instruction{ .inherent = 20 };
            } else {
                result = Instruction{ .rType = 10 };
            }
            try self.ast.append(self.allocator, result);
        } else {
            // inherent type
            _ = self.consume();
            const result = Instruction{ .inherent = lookahead.literal };
            try self.ast.append(self.allocator, result);
        }
    }

    fn peek(self: *Parser) lexer.Token {
        if (self.isAtEnd()) {
            return self.input[self.input.len - 1];
        }
        return self.input[self.current];
    }

    fn consume(self: *Parser) lexer.Token {
        const result = self.input[self.current];
        self.current += 1;
        return result;
    }

    fn isAtEnd(self: *Parser) bool {
        return self.current >= self.input.len;
    }
};

test "Parse label" {
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

    std.debug.print("token len {}\n", .{tokens.items.len});
    std.debug.print("ast len {}\n", .{ast.items.len});
    for (ast.items) |instr| {
        instr.print();
    }
}
