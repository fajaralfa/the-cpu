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
    ImmDec,
    ImmHex,
    ImmBin,
    ImmOct,
    Comma,
    Colon,
    EOF,
};

const LexerError = error{
    InvalidToken,
};

const Lexer = struct {
    start: usize,
    current: usize,
    allocator: std.mem.Allocator,
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
        // set pointer at the end of input
        self.start = self.input.len - 1;
        self.current = self.start;
        try self.addToken(.EOF);

        return self.tokens;
    }

    fn scanToken(self: *Lexer) !void {
        const c = self.next();
        switch (c) {
            ' ', '\n', '\t', '/' => {},
            'A'...'Z', 'a'...'z', '_' => try self.identifier(),
            '#' => try self.number(),
            ',' => try self.addToken(.Comma),
            ':' => try self.addToken(.Colon),
            else => return LexerError.InvalidToken,
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

    fn addToken(self: *Lexer, typ: TokenType) !void {
        const literal = try self.captureLiteral();
        const token = Token{
            .type = typ,
            .literal = literal,
            .pos = .{ .line = 1, .col = 1 },
        };
        try self.tokens.append(self.allocator, token);
    }

    fn identifier(self: *Lexer) !void {
        while (std.ascii.isAlphanumeric(self.peek())) {
            _ = self.next();
        }
        const literal = self.input[self.start..self.current]; // no need alloc, just for checking
        var typ: TokenType = undefined;
        if (isRegister(literal)) {
            typ = .Register;
        } else {
            typ = .Label;
        }
        try self.addToken(typ);
    }

    fn isRegister(literal: []const u8) bool {
        const registers = [_][]const u8{ "x1", "x2", "x3", "pc", "sp", "mepc", "mcause", "mtvec" };
        for (registers) |r| {
            if (std.mem.eql(u8, r, literal)) {
                return true;
            }
        }
        return false;
    }

    fn captureLiteral(self: *Lexer) ![]const u8 {
        const literal = try self.allocator.alloc(u8, self.current - self.start);
        const text = self.input[self.start..self.current];
        @memcpy(literal, text);
        return literal;
    }

    fn number(self: *Lexer) !void {
        if (self.peek() == '0') {
            _ = self.next();

            const next_c = self.peek();
            if (next_c == 'x' or next_c == 'X') {
                _ = self.next();
                while (std.ascii.isHex(self.peek())) {
                    _ = self.next();
                }
                try self.addToken(.ImmHex);
                return;
            } else if (next_c == 'b' or next_c == 'B') {
                _ = self.next(); // binary
                while (self.peek() == '0' or self.peek() == '1') {
                    _ = self.next();
                }

                try self.addToken(.ImmBin);
                return;
            } else if (next_c == 'o' or next_c == 'O') {
                _ = self.next(); // octal
                while (self.peek() >= '0' and self.peek() <= '7') {
                    _ = self.next();
                }

                try self.addToken(.ImmOct);
                return;
            }
        }

        if (!std.ascii.isDigit(self.peek())) {
            return LexerError.InvalidToken;
        }
        while (std.ascii.isDigit(self.peek())) {
            _ = self.next();
        }

        try self.addToken(.ImmDec);
    }
};

test "Scan" {
    const str: []const u8 = ", x1 _start:";
    const allocator = std.testing.allocator;
    var lex = Lexer.init(allocator, str);
    const tokens = try lex.tokenize();
    defer lex.deinit();

    const expected = [_]Token{
        .{ .type = .Comma, .literal = ",", .pos = .{ .line = 1, .col = 1 } },
        .{ .type = .Register, .literal = "x1", .pos = .{ .line = 1, .col = 1 } },
        .{ .type = .Label, .literal = "_start", .pos = .{ .line = 1, .col = 1 } },
        .{ .type = .Colon, .literal = ":", .pos = .{ .line = 1, .col = 1 } },
        .{ .type = .EOF, .literal = "", .pos = .{ .line = 1, .col = 1 } },
    };
    for (expected, tokens.items) |exp, act| {
        try std.testing.expectEqual(exp.type, act.type);
        try std.testing.expectEqualSlices(u8, exp.literal, act.literal);
    }
}

test "Scan immediate" {
    const str: []const u8 = "#123 #0xFA #0o12 #0b101";
    const allocator = std.testing.allocator;
    var lex = Lexer.init(allocator, str);
    const tokens = try lex.tokenize();
    defer lex.deinit();

    const expected = [_]Token{
        .{ .type = .ImmDec, .literal = "#123", .pos = .{ .line = 1, .col = 1 } },
        .{ .type = .ImmHex, .literal = "#0xFA", .pos = .{ .line = 1, .col = 1 } },
        .{ .type = .ImmOct, .literal = "#0o12", .pos = .{ .line = 1, .col = 1 } },
        .{ .type = .ImmBin, .literal = "#0b101", .pos = .{ .line = 1, .col = 1 } },
        .{ .type = .EOF, .literal = "", .pos = .{ .line = 1, .col = 1 } },
    };
    for (expected, tokens.items) |exp, act| {
        try std.testing.expectEqual(exp.type, act.type);
        try std.testing.expectEqualSlices(u8, exp.literal, act.literal);
    }
}

test "is register" {
    try std.testing.expect(Lexer.isRegister("x1"));
    try std.testing.expect(!Lexer.isRegister("_start"));
}
