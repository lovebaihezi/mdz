const std = @import("std");
const diag = @import("diagnose.zig");
const utils = @import("utils/lib.zig");

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
    AsciiNumber,
    EOF,
    Str,
};

pub const TokenItem = union(TokenItemTag) {
    const Self = @This();

    Tab: void,
    Space: void,
    LineEnd: void,
    Sign: u8,
    //TODO: Consider remove slice, use span to represent
    AsciiNumber: []const u8,
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
    pub inline fn sign(s: u8) Self {
        return Self{ .Sign = s };
    }
    pub inline fn asciiNumber(n: []const u8) Self {
        return Self{ .AsciiNumber = n };
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
    pub inline fn asciiNumber(n: []const u8) Self {
        return Self{ .ok = TokenItem.asciiNumber(n) };
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

    buffer: []const u8,
    index: usize = 0,
    utf8_iterator: UTF8Iterator,
    // state: ?Token = null,

    inline fn noInputBuffer() LexerError {
        return error.noInputBuffer;
    }

    inline fn tab(self: *const Self) Token {
        const span = Span.new(self.index, 1);
        return Token.new(Item.tab(), span);
    }
    inline fn space(self: *const Self) Token {
        const span = Span.new(self.index, 1);
        return Token.new(Item.space(), span);
    }
    inline fn lineEnd(self: *const Self, isLRLF: bool) Token {
        const span = Span.new(self.index, if (isLRLF) 2 else 1);
        return Token.new(Item.lineEnd(), span);
    }
    inline fn sign(
        self: *const Self,
        s: u8,
    ) Token {
        const span = Span.new(self.index, 1);
        return Token.new(Item.sign(s), span);
    }
    inline fn asciiNumber(
        self: *const Self,
        n: []const u8,
    ) Token {
        const span = Span.new(self.index + 1 - n.len, n.len);
        return Token.new(Item.asciiNumber(n), span);
    }
    inline fn str(
        self: *const Self,
        s: []const u8,
    ) Token {
        const span = Span.new(self.index, s.len);
        return Token.new(Item.str(s), span);
    }
    inline fn eof(self: *const Self) Token {
        const span = Span.new(self.index, 0);
        return Token.new(Item.eof(), span);
    }
    inline fn unexpectedEOF(self: *const Self) Token {
        const span = Span.new(self.index, 0);
        return Token.new(Item.unexpectedEOF(), span);
    }
    inline fn unexpectedControlCode(self: *const Self, code: u8) Token {
        const span = Span.new(self.index, 1);
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

    fn peek_slice(self: *Self, len: usize) ?[]const u8 {
        return self.utf8_iterator.peek(len);
    }

    fn peek_one_code(self: *Self) ?u21 {
        const slice = self.utf8_iterator.peek(1);
        return std.unicode.utf8Decode(slice) catch return null;
    }

    pub fn next(self: *Self) ?Token {
        const buf = self.buffer;
        var token = if (self.index >= buf.len)
            self.eof()
        else if (self.next_code()) |code|
            switch (code) {
                0x0...0x8 => |c| self.unexpectedControlCode(@intCast(u8, c)),

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
                        const t = self.asciiNumber(buf[begin..]);
                        self.utf8_iterator.i = self.index;
                        break :num t;
                    } else {
                        self.utf8_iterator.i = self.index + 1;
                        break :num self.asciiNumber(buf[begin .. self.index + 1]);
                    }
                },

                0xD => result: {
                    if (self.peek_slice(1)) |next_c| {
                        if (next_c[0] == 0xD) {
                            _ = self.next_code();
                            break :result self.lineEnd(true);
                        } else {
                            break :result self.unexpectedControlCode(0xD);
                        }
                    } else {
                        break :result null;
                    }
                },

                0x10...0x1F => |c| self.unexpectedControlCode(@intCast(u8, c)),

                0x20 => self.space(),

                0x21...0x2F, 0x3A...0x40, 0x5B...0x60, 0x7B...0x7E => |c| self.sign(@intCast(u8, c)),

                else => other: {
                    const begin = self.index;
                    while (self.peek_slice(1)) |s| {
                        // std.debug.print("{d}\t{d}\t{d}\t{d}\n", .{ s.len, self.index, self.utf8_iterator.i, buf.len });
                        if (s.len == 0) {
                            break;
                        }
                        const c = s[0];
                        if (utils.notControlCode(c) and utils.notAsciiPunctuationCode(c) and utils.notWhiteSpaceCode(c) and utils.notAsciiNumberCode(c)) {
                            self.utf8_iterator.i += s.len;
                        } else {
                            break;
                        }
                    }
                    if (self.utf8_iterator.i >= buf.len) {
                        // a hack to avoid when last character of buffer,
                        // which is a normal unicode, then buffer will out of index
                        // and lexer won't return eof
                        const t = self.str(buf[begin..]);
                        break :other t;
                    } else {
                        break :other self.str(buf[begin..self.utf8_iterator.i]);
                    }
                },
            }
        else
            null;
        self.index = self.utf8_iterator.i;
        return token;
    }

    pub inline fn get(self: *const Self, span: Span) []const u8 {
        return self.buffer[span.begin .. span.begin + span.len];
    }

    pub fn diagnose(self: *const Self, span: Span) Diagnose {
        return Diagnose.init(self, span);
    }
};

test "utf 8 string len" {
    const str = "h಄ll಄";
    try std.testing.expectEqual(9, str.len);
}

test "lexer test case 1: \"# hello world!\"" {
    const str = "# h಄ll಄123 w಄rl಄!";
    const token_seq = [_]Token{
        Token.new(TokenOrError.sign('#'), Span.new(0, 1)),
        Token.new(TokenOrError.space(), Span.new(1, 1)),
        Token.new(TokenOrError.str("h಄ll಄"), Span.new(2, 9)),
        Token.new(TokenOrError.asciiNumber("123"), Span.new(11, 3)),
        Token.new(TokenOrError.space(), Span.new(14, 1)),
        Token.new(TokenOrError.str("w಄rl಄"), Span.new(15, 9)),
        Token.new(TokenOrError.sign('!'), Span.new(24, 1)),
        Token.new(TokenOrError.eof(), Span.new(25, 0)),
    };
    var lex = Lexer.init(str);
    const assert = std.testing.expect;
    for (token_seq) |corr_token| {
        const token = lex.next();
        try assert(token != null);
        try assert(token.?.isOk());
        try std.testing.expectEqualDeep(corr_token, token.?);
    }
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
        Token.new(TokenOrError.asciiNumber("1"), Span.new(8, 1)),
        Token.new(TokenOrError.lineEnd(), Span.new(9, 1)),
        Token.new(TokenOrError.sign('#'), Span.new(10, 1)),
        Token.new(TokenOrError.sign('#'), Span.new(11, 1)),
        Token.new(TokenOrError.space(), Span.new(12, 1)),
        Token.new(TokenOrError.str("Title"), Span.new(13, 5)),
        Token.new(TokenOrError.space(), Span.new(18, 1)),
        Token.new(TokenOrError.asciiNumber("2"), Span.new(19, 1)),
        Token.new(TokenOrError.lineEnd(), Span.new(20, 1)),
        Token.new(TokenOrError.sign('#'), Span.new(21, 1)),
        Token.new(TokenOrError.sign('#'), Span.new(22, 1)),
        Token.new(TokenOrError.sign('#'), Span.new(23, 1)),
        Token.new(TokenOrError.space(), Span.new(24, 1)),
        Token.new(TokenOrError.str("Title"), Span.new(25, 5)),
        Token.new(TokenOrError.space(), Span.new(30, 1)),
        Token.new(TokenOrError.asciiNumber("3"), Span.new(31, 1)),
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
        const token = lex.next();
        try assert(token.?.isOk());
        try std.testing.expectEqualDeep(corr_token, token.?);
    }
}

test "utf8 iterator usage" {
    const buffer = "asd ಄ ಅ ಆ 123ಇ ಈ ಉ ಊ ಋ ";
    var utf8_iterator = UTF8Iterator{ .bytes = buffer, .i = 0 };
    var i: usize = 0;
    while (utf8_iterator.nextCodepoint()) |code| {
        const len = utf8_iterator.i - i;
        std.log.info("{u} {d}", .{ code, len });
    }
}

// test "uft iterator facing numbers and unicode" {
//     const assert = std.testing.expect;
//     const buffer = "಄ ಅ 123 456 ಄ ಅ ";
//     var lexer = Lexer.init(buffer);
//     const token_seq = []Token {
//         Token.new(TokenOrError.str("಄"), Span.new(0, 3)),
//     };
//     for (token_seq) |token| {
//         const next = lexer.next();
//         assert(next.isOk());
//     }
// }
