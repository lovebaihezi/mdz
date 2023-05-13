const std = @import("std");
const diag = @import("diagnose.zig");
const utils = @import("utils.zig");

const Span = utils.Span;
const Diagnose = diag.Diagnose;
const Allocator = std.mem.Allocator;
const UTF8Iterator = std.unicode.Utf8Iterator;

pub const ErrorTag = enum { unexpectedEOF, unexpectedControlCode };

pub const ErrorItem = union(ErrorTag) {
    const Self = @This();

    unexpectedEOF: void,
    unexpectedControlCode: u8,

    pub inline fn unexpectedEOF() Self {
        return Self{ .unexpectedEOF = {} };
    }
    pub inline fn unexpectedControlCode(c: u8) Self {
        return Self{ .unexpectedControlCode = c };
    }
};

pub const TokenItemTag = enum {
    Tab,
    Space,
    LineEnd,
    Sign,
    NumberAscii,
    EOF,
    Str,
};

pub const TokenItem = union(TokenItemTag) {
    const Self = @This();

    Tab: void,
    Space: void,
    LineEnd: void,
    Sign: u21,
    //TODO: Consider remove slice, use span to represent
    NumberAscii: []const u8,
    Str: []const u8,
    EOF: void,

    pub inline fn tab() Self {
        return Self{ .Tab = {} };
    }
    pub inline fn space() Self {
        return Self{ .Space = {} };
    }
    pub inline fn lineEnd() Self {
        return Self{ .LineEnd = {} };
    }
    pub inline fn sign(s: u21) Self {
        return Self{ .Sign = s };
    }
    pub inline fn numberAscii(n: []const u8) Self {
        return Self{ .NumberAscii = n };
    }
    pub inline fn str(s: []const u8) Self {
        return Self{ .Str = s };
    }
    pub inline fn eof() Self {
        return Self{ .EOF = {} };
    }
};

pub const TokenOrErrorTag = enum {
    ok,
    unexpected,
};

pub const TokenOrError = union(TokenOrErrorTag) {
    const Self = @This();

    ok: TokenItem,
    unexpected: ErrorItem,

    pub inline fn tab() Self {
        return Self{ .ok = TokenItem.tab() };
    }
    pub inline fn space() Self {
        return Self{ .ok = TokenItem.space() };
    }
    pub inline fn lineEnd() Self {
        return Self{ .ok = TokenItem.lineEnd() };
    }
    pub inline fn sign(s: u8) Self {
        return Self{ .ok = TokenItem.sign(s) };
    }
    pub inline fn str(s: []const u8) Self {
        return Self{ .ok = TokenItem.str(s) };
    }
    pub inline fn eof() Self {
        return Self{ .ok = TokenItem.eof() };
    }
    pub inline fn numberAscii(n: []const u8) Self {
        return Self{ .ok = TokenItem.numberAscii(n) };
    }
    pub inline fn unexpectedEOF() Self {
        return Self{ .unexpected = ErrorItem.unexpectedEOF() };
    }
    pub inline fn unexpectedControlCode(code: u8) Self {
        return Self{ .unexpected = ErrorItem.unexpectedControlCode(code) };
    }
};

pub const Token = struct {
    const Self = @This();
    const Item = TokenOrError;

    item: TokenOrError,
    span: Span,

    pub inline fn item(self: *const Self) *const TokenOrError {
        return self.item;
    }
    pub inline fn span(self: *const Self) *const Span {
        return self.span;
    }
    pub inline fn new(i: Item, p: Span) Self {
        return Self{ .item = i, .span = p };
    }
    pub inline fn isOk(self: *const Self) bool {
        return @as(TokenOrErrorTag, self.item) == TokenOrErrorTag.ok;
    }
    pub inline fn isUnexpected(self: *const Self) bool {
        return @as(TokenOrErrorTag, self.item) == TokenOrErrorTag.unexpected;
    }
};

pub const LexerError = error{
    noInputBuffer,
};

pub const Lexer = struct {
    const Self = @This();
    const Item = TokenOrError;

    buffer: ?[]const u8 = null,
    index: usize = 0,
    utf8_iterator: UTF8Iterator,
    // state: ?Token = null,

    inline fn tab(self: *Self) Token {
        const span = Span.new(self.index, 1);
        return Token.new(Item.tab(), span);
    }
    inline fn space(self: *Self) Token {
        const span = Span.new(self.index, 1);
        return Token.new(Item.space(), span);
    }
    inline fn lineEnd(self: *Self, isLRLF: bool) Token {
        const span = Span.new(self.index, if (isLRLF) 2 else 1);
        return Token.new(Item.lineEnd(), span);
    }
    inline fn sign(
        self: *Self,
        s: u8,
    ) Token {
        const span = Span.new(self.index, 1);
        return Token.new(Item.sign(s), span);
    }
    inline fn numberAscii(
        self: *Self,
        n: []const u8,
    ) Token {
        const span = Span.new(self.index - n.len + 1, n.len);
        return Token.new(Item.numberAscii(n), span);
    }
    inline fn str(
        self: *Self,
        s: []const u8,
    ) Token {
        const span = Span.new(self.index - s.len + 1, s.len);
        return Token.new(Item.str(s), span);
    }
    inline fn eof(self: *Self) Token {
        const span = Span.new(self.index, 0);
        return Token.new(Item.eof(), span);
    }
    inline fn unexpectedEOF(self: *Self) Token {
        const span = Span.new(self.index, 0);
        return Token.new(Item.unexpectedEOF(), span);
    }
    inline fn unexpectedControlCode(self: *Self, code: u21) Token {
        const span = Span.new(self.index, self.utf8_iterator.i - self.index);
        return Token.new(Item.unexpectedControlCode(code), span);
    }

    pub inline fn init(buffer: []const u8) Self {
        return Self{ .index = 0, .buffer = buffer, .utf8_iterator = std.unicode.Utf8Iterator{ .bytes = buffer, .i = 0 } };
    }

    fn next_code(self: *Self) ?u21 {
        return self.utf8_iterator.nextCodepoint();
    }

    fn next_slice(self: *Self) ?[]const u8 {
        return self.utf8_iterator.nextCodepointSlice();
    }

    fn peek(self: *Self, len: usize) ?u21 {
        _ = len;
        return self.utf8_iterator.peek(1);
    }

    pub fn next(self: *Self) ?Token {
        var token = if (self.buffer) |buf|
            if (self.index == buf.len)
                self.eof()
            else if (self.index > buf.len)
                self.eof()
            else if (self.next_code()) |code|
                switch (code) {
                    0x0...0x8 => |c| self.unexpectedControlCode(c),

                    0x9 => self.tab(),

                    '\n' => self.lineEnd(false),

                    0xB...0xC => self.space(),

                    '0'...'9' => num: {
                        const begin = self.index;
                        self.index += 1;
                        while (self.index < buf.len) {
                            const c = buf[self.index];
                            switch (c) {
                                '0'...'9' => {
                                    self.index += 1;
                                },
                                else => {
                                    self.index -= 1;
                                    break;
                                },
                            }
                        }
                        if (self.index == buf.len) {
                            // a hack to avoid when last character of buffer,
                            // which is a normal unicode, then buffer will out of index
                            // and lexer won't return eof
                            self.index -= 1;
                            const t = self.numberAscii(buf[begin..]);
                            break :num t;
                        } else {
                            break :num self.numberAscii(buf[begin .. self.index + 1]);
                        }
                    },

                    0xD => result: {
                        if (self.peek(1)) |next_c| {
                            if (next_c == 0xD) {
                                _ = self.next_code();
                                break :result self.lineEnd(true);
                            } else {
                                break :result self.unexpectedControlCode(0xD);
                            }
                        }
                    },

                    0x10...0x1F => |c| self.unexpectedControlCode(c),

                    0x20 => self.space(),

                    0x21...0x2F, 0x3A...0x40, 0x5B...0x60, 0x7B...0x7E => |c| self.sign(@truncate(u8, c)),

                    else => other: {
                        const begin = self.index;
                        while (self.utf8_iterator.nextCodepoint()) |c| {
                            if (utils.notControlCode(c) and utils.notPunctuationCode(c) and utils.notWhiteSpaceCode(c)) {} else {
                                break;
                            }
                        }
                        if (self.index == buf.len) {
                            // a hack to avoid when last character of buffer,
                            // which is a normal unicode, then buffer will out of index
                            // and lexer won't return eof
                            self.index -= 1;
                            const t = self.str(buf[begin..]);
                            break :other t;
                        } else {
                            break :other self.str(buf[begin .. self.index + 1]);
                        }
                    },
                }
            else
                null
        else
            null;
        self.index += 1;
        return token;
    }

    pub inline fn hasNext(self: Self) bool {
        if (self.buffer) |buf| {
            return self.index <= buf.len;
        }
        return false;
    }

    pub inline fn get(self: Self, span: Span) []const u8 {
        return self.buffer.?[span.begin .. span.begin + span.len];
    }

    pub fn diagnose(self: Self, span: Span) Diagnose {
        return Diagnose.init(self, span);
    }
};

test "lexer test case 1: \"# hello world!\"" {
    const str = "# hello world!";
    const token_seq = [_]Token{
        Token.new(TokenOrError.sign('#'), Span.new(0, 1)),
        Token.new(TokenOrError.space(), Span.new(1, 1)),
        Token.new(TokenOrError.str("hello"), Span.new(2, 5)),
        Token.new(TokenOrError.space(), Span.new(7, 1)),
        Token.new(TokenOrError.str("world"), Span.new(8, 5)),
        Token.new(TokenOrError.sign('!'), Span.new(13, 1)),
        Token.new(TokenOrError.eof(), Span.new(14, 0)),
    };
    var lex = Lexer.init(str);
    const assert = std.testing.expect;
    for (token_seq) |corr_token| {
        try assert(lex.hasNext());
        const token = lex.next();
        try assert(token != null);
        try assert(token.?.isOk());
        try std.testing.expectEqualDeep(token, corr_token);
    }
    try assert(!lex.hasNext());
}

const testCase2Title = "lexer test case 2";

const testCase2 =
    \\# Title 1
    \\## Title 2
    \\### Title 3
    \\ 
    \\Lorem 
    \\asd
;

test testCase2Title {
    const tk_seq = [_]Token{
        Token.new(TokenOrError.sign('#'), Span.new(0, 1)),
        Token.new(TokenOrError.space(), Span.new(1, 1)),
        Token.new(TokenOrError.str("Title"), Span.new(2, 5)),
        Token.new(TokenOrError.space(), Span.new(7, 1)),
        Token.new(TokenOrError.numberAscii("1"), Span.new(8, 1)),
        Token.new(TokenOrError.lineEnd(), Span.new(9, 1)),
        Token.new(TokenOrError.sign('#'), Span.new(10, 1)),
        Token.new(TokenOrError.sign('#'), Span.new(11, 1)),
        Token.new(TokenOrError.space(), Span.new(12, 1)),
        Token.new(TokenOrError.str("Title"), Span.new(13, 5)),
        Token.new(TokenOrError.space(), Span.new(18, 1)),
        Token.new(TokenOrError.numberAscii("2"), Span.new(19, 1)),
        Token.new(TokenOrError.lineEnd(), Span.new(20, 1)),
        Token.new(TokenOrError.sign('#'), Span.new(21, 1)),
        Token.new(TokenOrError.sign('#'), Span.new(22, 1)),
        Token.new(TokenOrError.sign('#'), Span.new(23, 1)),
        Token.new(TokenOrError.space(), Span.new(24, 1)),
        Token.new(TokenOrError.str("Title"), Span.new(25, 5)),
        Token.new(TokenOrError.space(), Span.new(30, 1)),
        Token.new(TokenOrError.numberAscii("3"), Span.new(31, 1)),
        Token.new(TokenOrError.lineEnd(), Span.new(32, 1)),
        Token.new(TokenOrError.space(), Span.new(33, 1)),
        Token.new(TokenOrError.lineEnd(), Span.new(34, 1)),
        Token.new(TokenOrError.str("Lorem"), Span.new(35, 5)),
        Token.new(TokenOrError.space(), Span.new(40, 1)),
        Token.new(TokenOrError.lineEnd(), Span.new(41, 1)),
        Token.new(TokenOrError.str("asd"), Span.new(42, 3)),
        Token.new(TokenOrError.eof(), Span.new(45, 0)),
    };
    var lex = Lexer.init(testCase2);
    const assert = std.testing.expect;
    for (tk_seq) |corr_token| {
        try assert(lex.hasNext());
        const token = lex.next() orelse unreachable;
        try assert(token.isOk());
        try std.testing.expectEqualDeep(corr_token, token);
    }
    try assert(!lex.hasNext());
}

test "utf8 iterator usage" {
    const buffer = "asd ಄ ಅ ಆ ಇ ಈ ಉ ಊ ಋ ";
    var utf8_iterator = UTF8Iterator{ .bytes = buffer, .i = 0 };
    var i: usize = 0;
    while (utf8_iterator.nextCodepoint()) |code| {
        const len = utf8_iterator.i - i;
        std.log.info("{c} {d}", .{ code, len });
    }
}
