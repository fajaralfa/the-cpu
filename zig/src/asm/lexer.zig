const std = @import("std");

const Token = struct {
    type: TokenType,
    literal: []const u8,
    pos: struct {
        line: u32,
        col: u32,
    },
    pub fn print(self: *Token) void {
        std.debug.print("{}\n", .{self.type});
    }
};

const TokenType = enum {
    LabelDef,
    LabelRef,
    Opcode,
    Register,
    ImmediateVal,
    Comma,
};

const LexerError = error{
    InvalidToken,
};

const Lexer = struct {
    start: usize,
    current: usize,
    input: []const u8,
    tokens: std.ArrayList(Token),

    pub fn init(input: []const u8) Lexer {
        return Lexer{
            .start = 0,
            .current = 0,
            .input = input,
            .tokens = std.ArrayList(Token).empty,
        };
    }

    pub fn tokenize(self: *Lexer, allocator: std.mem.Allocator) !std.ArrayList(Token) {
        while (!self.isAtEnd()) {
            self.start = self.current;
            try self.scanToken(allocator);
        }

        return self.tokens;
    }

    fn scanToken(self: *Lexer, allocator: std.mem.Allocator) !void {
        const c = self.next();
        // simple straightforward scanner
        switch (c) {
            // opcode
            'A'...'Z', 'a'...'z' => {
                const literal = try allocator.alloc(u8, 1);
                @memcpy(literal, &[_]u8{c});
                try self.tokens.append(allocator, Token{
                    .literal = literal,
                    .type = .Opcode,
                    .pos = .{ .col = 1, .line = 1 },
                });
            },
            // register
            '$' => {
                const literal = try allocator.alloc(u8, 1);
                @memcpy(literal, &[_]u8{c});
                try self.tokens.append(allocator, Token{
                    .literal = literal,
                    .type = .Register,
                    .pos = .{ .col = 1, .line = 1 },
                });
            },
            // label def
            '_' => {
                const literal = try allocator.alloc(u8, 1);
                @memcpy(literal, &[_]u8{c});
                try self.tokens.append(allocator, Token{
                    .literal = literal,
                    .type = .LabelDef,
                    .pos = .{ .col = 1, .line = 1 },
                });
            },
            // label ref
            ':' => {
                const literal = try allocator.alloc(u8, 1);
                @memcpy(literal, &[_]u8{c});
                try self.tokens.append(allocator, Token{
                    .literal = literal,
                    .type = .LabelRef,
                    .pos = .{ .col = 1, .line = 1 },
                });
            },
            // immediate
            '#' => {
                const imm = try allocator.alloc(u8, 1);
                @memcpy(imm, &[_]u8{c});
                try self.tokens.append(allocator, Token{
                    .type = .ImmediateVal,
                    .literal = imm,
                    .pos = .{ .col = 1, .line = 1 },
                });
            },
            // comma
            ',' => {
                try self.tokens.append(allocator, Token{
                    .type = .Comma,
                    .literal = &.{},
                    .pos = .{ .col = 1, .line = 1 },
                });
            },
            ' ', '\n', '\t', '/' => {},
            else => {
                return LexerError.InvalidToken;
            },
        }
    }

    fn freeTokens(self: *Lexer, allocator: std.mem.Allocator) void {
        for (self.tokens.items) |item| {
            allocator.free(item.literal);
        }
        self.tokens.deinit(allocator);
    }

    fn next(self: *Lexer) u8 {
        const c = self.input[self.current];
        self.current += 1;
        return c;
    }

    fn isAtEnd(self: *Lexer) bool {
        return self.current >= self.input.len;
    }
};

test "Scan" {
    //  Immediate, Comma, Opcode, Register, LabelDef, LabelRef
    const str: []const u8 = "# , l $ _ :";
    var lex = Lexer.init(str);
    const allocator = std.testing.allocator;
    const tokens = try lex.tokenize(allocator);
    defer lex.freeTokens(allocator);

    const expected = &[_]TokenType{ .ImmediateVal, .Comma, .Opcode, .Register, .LabelDef, .LabelRef };
    for (expected, tokens.items) |exp, act| {
        try std.testing.expectEqual(exp, act.type);
    }

    try std.testing.expect(true);
}
