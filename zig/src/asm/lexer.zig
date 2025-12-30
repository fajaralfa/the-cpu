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
    Label,
    Opcode,
    Register,
    ImmediateVal,
    Comma,
    Colon,
};

const LexerError = error{
    InvalidToken,
};

const Lexer = struct {
    allocator: std.mem.Allocator,
    start: usize,
    current: usize,
    input: []const u8,
    tokens: std.ArrayList(Token),

    pub fn init(allocator: std.mem.Allocator, input: []const u8) Lexer {
        return Lexer{
            .allocator = allocator,
            .start = 0,
            .current = 0,
            .input = input,
            .tokens = std.ArrayList(Token).empty,
        };
    }

    pub fn tokenize(self: *Lexer) !std.ArrayList(Token) {
        while (!self.isAtEnd()) {
            self.start = self.current;
            try self.scanToken();
        }

        return self.tokens;
    }

    fn scanToken(self: *Lexer) !void {
        const c = self.next();
        // simple straightforward scanner
        switch (c) {
            'A'...'Z', 'a'...'z', '_' => {
                try self.identifier();
            },
            '#' => {
                const imm = try self.allocator.alloc(u8, 1);
                @memcpy(imm, &[_]u8{c});
                try self.tokens.append(self.allocator, Token{
                    .type = .ImmediateVal,
                    .literal = imm,
                    .pos = .{ .col = 1, .line = 1 },
                });
            },
            ',' => {
                try self.tokens.append(self.allocator, Token{
                    .type = .Comma,
                    .literal = &.{},
                    .pos = .{ .col = 1, .line = 1 },
                });
            },
            ' ', '\n', '\t', '/' => {},
            ':' => {
                try self.tokens.append(self.allocator, Token{
                    .type = .Colon,
                    .literal = &.{},
                    .pos = .{ .col = 1, .line = 1 },
                });
            },
            else => {
                return LexerError.InvalidToken;
            },
        }
    }

    fn deinit(self: *Lexer) void {
        for (self.tokens.items) |item| {
            self.allocator.free(item.literal);
        }
        self.tokens.deinit(self.allocator);
    }

    fn next(self: *Lexer) u8 {
        const c = self.input[self.current];
        self.current += 1;
        return c;
    }

    fn isAtEnd(self: *Lexer) bool {
        return self.current >= self.input.len;
    }

    fn peek(self: *Lexer) u8 {
        if (self.isAtEnd()) {
            return 0;
        }
        return self.input[self.current];
    }

    fn advance(self: *Lexer) u8 {
        self.current += 1;
        return self.input[self.current];
    }

    fn addToken(self: *Lexer, typ: TokenType) !void {
        const literal = try self.allocator.alloc(u8, self.current - self.start);
        const text = self.input[self.start..self.current];
        @memcpy(literal, text);
        const token = Token{
            .literal = literal,
            .pos = .{ .col = 1, .line = 1 },
            .type = typ,
        };
        try self.tokens.append(self.allocator, token);
    }

    fn identifier(self: *Lexer) !void {
        while (std.ascii.isAlphanumeric(self.peek())) {
            _ = self.advance();
        }
        try self.addToken(TokenType.Register);
    }
};

test "Scan" {
    //  Immediate, Comma, Opcode, Register, LabelDef, LabelRef
    const str: []const u8 = "# , x1 _start:";
    const allocator = std.testing.allocator;
    var lex = Lexer.init(allocator, str);
    const tokens = try lex.tokenize();
    defer lex.deinit();

    const expected = &[_]Token{
        .{
            .type = .ImmediateVal,
            .literal = "#",
            .pos = .{
                .line = 1,
                .col = 1,
            },
        },
        .{
            .type = .Comma,
            .literal = "",
            .pos = .{
                .line = 1,
                .col = 1,
            },
        },
        .{
            .type = .Register,
            .literal = "x1",
            .pos = .{
                .line = 1,
                .col = 1,
            },
        },
        .{
            .type = .Register,
            .literal = "_start",
            .pos = .{
                .line = 1,
                .col = 1,
            },
        },
        .{
            .type = .Colon,
            .literal = "",
            .pos = .{
                .line = 1,
                .col = 1,
            },
        },
    };
    for (expected, tokens.items) |exp, act| {
        try std.testing.expectEqual(exp.type, act.type);
        try std.testing.expectEqualSlices(u8, exp.literal, act.literal);
    }

    try std.testing.expect(true);
}
