const std = @import("std");
const diag = @import("diagnose.zig");
const utils = @import("utils.zig");

const Span = utils.Span;
const Diagnose = diag.Diagnose;
const Allocator = std.mem.Allocator;

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
    EOF,
    Str,
};

pub const TokenItem = union(TokenItemTag) {
    const Self = @This();

    Tab: void,
    Space: void,
    LineEnd: void,
    Sign: u8,
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
    pos: Span,

    pub inline fn item(self: *const Self) *const TokenOrError {
        return self.item;
    }
    pub inline fn pos(self: *const Self) *const Span {
        return self.pos;
    }

    pub inline fn new(i: Item, p: Span) Self {
        return Self{ .item = i, .pos = p };
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
    pos: Span = Span.default(),
    index: usize = 0,
    // state: ?Token = null,

    inline fn tab(self: *Self) Token {
        const pos = self.pos.goRight(1).clone();
        return Token.new(Item.tab(), pos);
    }
    inline fn space(self: *Self) Token {
        const pos = self.pos.goRight(1).clone();
        return Token.new(Item.space(), pos);
    }
    inline fn lineEnd(self: *Self) Token {
        const pos = self.pos.goRight(1).clone();
        const token = Token.new(Item.lineEnd(), pos);
        _ = self.pos.goDown(1).backToBegin();
        return token;
    }
    inline fn sign(
        self: *Self,
        s: u8,
    ) Token {
        const pos = self.pos.goRight(1).clone();
        return Token.new(Item.sign(s), pos);
    }
    inline fn str(
        self: *Self,
        s: []const u8,
    ) Token {
        const pos = self.pos.goRight(s.len).clone();
        return Token.new(Item.str(s), pos);
    }
    inline fn eof(self: *Self) Token {
        const pos = self.pos.goRight(1).clone();
        return Token.new(Item.eof(), pos);
    }
    inline fn unexpectedEOF(self: *Self) Token {
        const pos = self.pos.goRight(1).clone();
        return Token.new(Item.unexpectedEOF(), pos);
    }
    inline fn unexpectedControlCode(self: *Self, code: u8) Token {
        const pos = self.pos.goRight(1).clone();
        return Token.new(Item.unexpectedControlCode(code), pos);
    }
    inline fn updateIndex(self: *Self, final: usize) *Self {
        self.index = final;
        return self;
    }
    // inline fn swapState(self: *Self, token: *?Token) *Self {
    //     if (self.state) |state| {
    //         const tmp = token.*;
    //         token.* = state;
    //         self.state = tmp;
    //     }
    //     return self;
    // }

    pub inline fn init(buffer: []const u8) Self {
        return Self{
            .index = 0,
            .pos = Span.default(),
            .buffer = buffer,
        };
    }

    pub fn next(self: *Self) ?Token {
        var token = if (self.buffer) |buf|
            if (self.index == buf.len)
                self.eof()
            else if (self.index > buf.len)
                null
            else switch (buf[self.index]) {
                0x0...0x8 => |c| self.unexpectedControlCode(c),

                0x9 => self.tab(),

                0xA => self.lineEnd(),

                0xB...0xC => self.space(),

                0xD => result: {
                    const next_c = buf[self.index + 1];
                    if (next_c == 0xD) {
                        self.index += 1;
                        break :result self.lineEnd();
                    } else {
                        break :result self.unexpectedControlCode(0xD);
                    }
                },

                0x10...0x1F => |c| self.unexpectedControlCode(c),

                0x20 => self.space(),

                0x21...0x2F, 0x3A...0x40, 0x5B...0x60, 0x7B...0x7E => |c| self.sign(c),

                else => other: {
                    const begin = self.index;
                    while (self.index < buf.len) {
                        const c = buf[self.index];
                        if (utils.notControlCode(c) and utils.notPunctuationCode(c) and utils.notWhiteSpaceCode(c)) {
                            self.index += 1;
                        } else {
                            self.index -= 1;
                            break;
                        }
                    }
                    if (self.index == buf.len) {
                        // a hack to avoid when last character of buffer,
                        // which is a normal unicode, then buffer will out of index
                        // and lexer won't return eof
                        const t = self.str(buf[begin..self.index]);
                        self.index -= 1;
                        break :other t;
                    } else {
                        break :other self.str(buf[begin .. self.index + 1]);
                    }
                },
            }
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
        Token.new(TokenOrError.eof(), Span.new(14, 1)),
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

const testCase2Title = "lexer test case 2" ++ testCase2;

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
        Token.new(TokenOrError.str("1"), Span.new(8, 1)),
        Token.new(TokenOrError.lineEnd(), Span.new(9, 1)),
        Token.new(TokenOrError.sign('#'), Span.new(10, 1)),
        Token.new(TokenOrError.sign('#'), Span.new(11, 1)),
        Token.new(TokenOrError.space(), Span.new(12, 1)),
        Token.new(TokenOrError.str("Title"), Span.new(13, 5)),
        Token.new(TokenOrError.space(), Span.new(18, 1)),
        Token.new(TokenOrError.str("2"), Span.new(19, 1)),
        Token.new(TokenOrError.lineEnd(), Span.new(20, 1)),
        Token.new(TokenOrError.sign('#'), Span.new(21, 1)),
        Token.new(TokenOrError.sign('#'), Span.new(22, 1)),
        Token.new(TokenOrError.sign('#'), Span.new(23, 1)),
        Token.new(TokenOrError.space(), Span.new(24, 1)),
        Token.new(TokenOrError.str("Title"), Span.new(25, 5)),
        Token.new(TokenOrError.space(), Span.new(30, 1)),
        Token.new(TokenOrError.str("3"), Span.new(31, 1)),
        Token.new(TokenOrError.lineEnd(), Span.new(32, 1)),
        Token.new(TokenOrError.space(), Span.new(33, 1)),
        Token.new(TokenOrError.lineEnd(), Span.new(34, 1)),
        Token.new(TokenOrError.str("Lorem"), Span.new(35, 5)),
        Token.new(TokenOrError.lineEnd(), Span.new(40, 1)),
        Token.new(TokenOrError.str("asd"), Span.new(41, 3)),
        Token.new(TokenOrError.lineEnd(), Span.new(44, 1)),
        Token.new(TokenOrError.eof(), Span.new(45, 1)),
    };
    var lex = Lexer.init(testCase2);
    const assert = std.testing.expect;
    for (tk_seq) |corr_token| {
        try assert(lex.hasNext());
        const token = lex.next();
        try assert(token != null);
        try assert(token.?.isOk());
        try std.testing.expectEqualDeep(token, corr_token);
    }
    try assert(!lex.hasNext());
}
