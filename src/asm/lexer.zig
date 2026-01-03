const std = @import("std");

pub const Token = struct {
    type: TokenType,
    literal: []const u8,
    pos: Position,
    pub fn print(self: *Token) void {
        std.debug.print("{}\n", .{self.type});
    }
};

pub const TokenType = enum {
    Identifier,
    ImmVal,
    Comma,
    Colon,
    Newline,
    EOF,
};

pub const LexerError = error{
    InvalidToken,
};

pub const Position = struct {
    line: u32,
    col: u32,
};

pub const Lexer = struct {
    start: usize,
    current: usize,
    pos: Position,
    allocator: std.mem.Allocator,
    input: []const u8,
    tokens: std.ArrayList(Token),

    pub fn init(allocator: std.mem.Allocator, input: []const u8) Lexer {
        return Lexer{
            .allocator = allocator,
            .start = 0,
            .current = 0,
            .pos = .{
                .line = 1,
                .col = 0,
            },
            .input = input,
            .tokens = std.ArrayList(Token).empty,
        };
    }

    pub fn deinit(self: *Lexer) void {
        for (self.tokens.items) |item| {
            self.allocator.free(item.literal);
        }
        self.tokens.deinit(self.allocator);
    }

    pub fn tokenize(self: *Lexer) !std.ArrayList(Token) {
        while (!self.isAtEnd()) {
            self.start = self.current;
            try self.scanToken();
        }
        // set position at the end of input
        self.start = self.input.len - 1;
        self.current = self.start;
        try self.addToken(.EOF);

        return self.tokens;
    }

    fn scanToken(self: *Lexer) !void {
        const c = self.next();
        switch (c) {
            ' ', '\t', '/' => {},
            '\n' => {
                try self.newline();
                self.pos.line += 1;
                self.pos.col = 0;
            },
            'A'...'Z', 'a'...'z', '_' => try self.identifier(),
            '#' => try self.number(),
            ',' => try self.addToken(.Comma),
            ':' => try self.addToken(.Colon),
            else => return LexerError.InvalidToken,
        }
    }

    fn next(self: *Lexer) u8 {
        const c = self.input[self.current];
        self.current += 1;
        self.pos.col += 1;
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
            .pos = self.pos,
        };
        try self.tokens.append(self.allocator, token);
    }

    fn identifier(self: *Lexer) !void {
        while (std.ascii.isAlphanumeric(self.peek())) {
            _ = self.next();
        }
        try self.addToken(.Identifier);
    }

    fn newline(self: *Lexer) !void {
        try self.addToken(.Newline);
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
            switch (next_c) {
                'x', 'X', 'b', 'B', 'o', 'O' => {
                    _ = self.next();
                    while (std.ascii.isHex(self.peek())) {
                        _ = self.next();
                    }
                    try self.addToken(.ImmVal);
                },
                else => {},
            }
            return;
        }

        if (!std.ascii.isDigit(self.peek())) {
            return LexerError.InvalidToken;
        }
        while (std.ascii.isDigit(self.peek())) {
            _ = self.next();
        }

        try self.addToken(.ImmVal);
    }
};

test "Scan ignore position" {
    const str: []const u8 = ", x1 _start:";
    const allocator = std.testing.allocator;
    var lex = Lexer.init(allocator, str);
    const tokens = try lex.tokenize();
    defer lex.deinit();

    const expected = [_]Token{
        .{ .type = .Comma, .literal = ",", .pos = .{ .line = 1, .col = 1 } },
        .{ .type = .Identifier, .literal = "x1", .pos = .{ .line = 1, .col = 1 } },
        .{ .type = .Identifier, .literal = "_start", .pos = .{ .line = 1, .col = 1 } },
        .{ .type = .Colon, .literal = ":", .pos = .{ .line = 1, .col = 1 } },
        .{ .type = .EOF, .literal = "", .pos = .{ .line = 1, .col = 1 } },
    };
    for (expected, tokens.items) |exp, act| {
        try std.testing.expectEqual(exp.type, act.type);
        try std.testing.expectEqualSlices(u8, exp.literal, act.literal);
    }
}

test "Scan immediate ignore position" {
    const str: []const u8 = "#123 #0xFA #0o12 #0b101";
    const allocator = std.testing.allocator;
    var lex = Lexer.init(allocator, str);
    const tokens = try lex.tokenize();
    defer lex.deinit();

    const expected = [_]Token{
        .{ .type = .ImmVal, .literal = "#123", .pos = .{ .line = 1, .col = 1 } },
        .{ .type = .ImmVal, .literal = "#0xFA", .pos = .{ .line = 1, .col = 1 } },
        .{ .type = .ImmVal, .literal = "#0o12", .pos = .{ .line = 1, .col = 1 } },
        .{ .type = .ImmVal, .literal = "#0b101", .pos = .{ .line = 1, .col = 1 } },
        .{ .type = .EOF, .literal = "", .pos = .{ .line = 1, .col = 1 } },
    };
    for (expected, tokens.items) |exp, act| {
        try std.testing.expectEqual(exp.type, act.type);
        try std.testing.expectEqualSlices(u8, exp.literal, act.literal);
    }
}

test "Scan identifier ignore position" {
    const str = "lw sw halt";
    const allocator = std.testing.allocator;
    var lex = Lexer.init(allocator, str);
    const tokens = try lex.tokenize();
    defer lex.deinit();

    const expected = [_]Token{
        .{ .type = .Identifier, .literal = "lw", .pos = .{ .line = 1, .col = 1 } },
        .{ .type = .Identifier, .literal = "sw", .pos = .{ .line = 1, .col = 1 } },
        .{ .type = .Identifier, .literal = "halt", .pos = .{ .line = 1, .col = 1 } },
        .{ .type = .EOF, .literal = "", .pos = .{ .line = 1, .col = 1 } },
    };
    for (expected, tokens.items) |exp, act| {
        try std.testing.expectEqual(exp.type, act.type);
        try std.testing.expectEqualSlices(u8, exp.literal, act.literal);
    }
}

test "Scan newline" {
    const str = "lw sw\nlw\n";
    const allocator = std.testing.allocator;
    var lex = Lexer.init(allocator, str);
    const tokens = try lex.tokenize();
    defer lex.deinit();

    const expected = [_]Token{
        .{ .type = .Identifier, .literal = "lw", .pos = .{ .line = 1, .col = 2 } },
        .{ .type = .Identifier, .literal = "sw", .pos = .{ .line = 1, .col = 5 } },
        .{ .type = .Newline, .literal = "\n", .pos = .{ .line = 1, .col = 6 } },
        .{ .type = .Identifier, .literal = "lw", .pos = .{ .line = 2, .col = 2 } },
        .{ .type = .Newline, .literal = "\n", .pos = .{ .line = 2, .col = 3 } },
        .{ .type = .EOF, .literal = "", .pos = .{ .line = 3, .col = 0 } },
    };
    for (expected, tokens.items) |exp, act| {
        try std.testing.expectEqual(exp.type, act.type);
        try std.testing.expectEqual(exp.pos.line, act.pos.line);
        try std.testing.expectEqual(exp.pos.col, act.pos.col);
        try std.testing.expectEqualSlices(u8, exp.literal, act.literal);
    }
}
