const std = @import("std");
const Allocator = std.mem.Allocator;
const utils = @import("utils.zig");

pub const Pos = struct {
    const Self = @This();

    line: usize,
    column: usize,

    pub inline fn default() Pos {
        return Self{
            .line = 0,
            .column = 0,
        };
    }
    pub inline fn new(line: usize, column: usize) Pos {
        return Self{
            .line = line,
            .column = column,
        };
    }
    pub inline fn goLeft(self: *Self, left: usize) *Self {
        self.column -= left;
        return self;
    }
    pub inline fn goRight(self: *Self, right: usize) *Self {
        self.column += right;
        return self;
    }
    pub inline fn goDown(self: *Self, down: usize) *Self {
        self.line += down;
        return self;
    }
    pub inline fn goUp(self: *Self, up: usize) *Self {
        self.line -= up;
        return self;
    }
    pub inline fn backToBegin(self: *Self) *Self {
        self.column = 0;
        return self;
    }
    pub inline fn goTo(self: *Self, line: usize, column: usize) *Self {
        self.line = line;
        self.column = column;
        return self;
    }
    pub inline fn add(self: *Self, pos: Pos) *Self {
        self.line += pos.line;
        self.column += pos.column;
        return self;
    }
    pub inline fn clone(self: *Self) Self {
        return Self{
            .line = self.line,
            .column = self.column,
        };
    }
};

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
    pos: Pos,

    pub inline fn item(self: *const Self) *const TokenOrError {
        return self.item;
    }
    pub inline fn pos(self: *const Self) *const Pos {
        return self.pos;
    }

    pub inline fn new(i: Item, p: Pos) Self {
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
    pos: Pos = Pos.default(),
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
            .pos = Pos.default(),
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

                0x21...0x2F => |c| self.sign(c),

                0x3A...0x40 => |c| self.sign(c),

                0x5B...0x60 => |c| self.sign(c),

                0x7B...0x7E => |c| self.sign(c),

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
        // _ = self.swapState(&token);
        return token;
    }

    pub inline fn hasNext(self: Self) bool {
        // const state = self.state;
        // if (state != null) {
        //     return true;
        // }
        if (self.buffer) |buf| {
            return self.index <= buf.len;
        }
        return false;
    }
};

test "lexer test case 1: \"# hello world!\"" {
    const str = "# hello world!";
    const token_seq = [_]Token{
        Token.new(TokenOrError.sign('#'), Pos.new(0, 1)),
        Token.new(TokenOrError.space(), Pos.new(0, 2)),
        Token.new(TokenOrError.str("hello"), Pos.new(0, 7)),
        Token.new(TokenOrError.space(), Pos.new(0, 8)),
        Token.new(TokenOrError.str("world"), Pos.new(0, 13)),
        Token.new(TokenOrError.sign('!'), Pos.new(0, 14)),
        Token.new(TokenOrError.eof(), Pos.new(0, 15)),
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
        Token.new(TokenOrError.sign('#'), Pos.new(0, 1)),
        Token.new(TokenOrError.space(), Pos.new(0, 2)),
        Token.new(TokenOrError.str("Title"), Pos.new(0, 7)),
        Token.new(TokenOrError.space(), Pos.new(0, 8)),
        Token.new(TokenOrError.str("1"), Pos.new(0, 9)),
        Token.new(TokenOrError.lineEnd(), Pos.new(0, 10)),
        Token.new(TokenOrError.sign('#'), Pos.new(1, 1)),
        Token.new(TokenOrError.sign('#'), Pos.new(1, 2)),
        Token.new(TokenOrError.space(), Pos.new(1, 3)),
        Token.new(TokenOrError.str("Title"), Pos.new(1, 8)),
        Token.new(TokenOrError.space(), Pos.new(1, 9)),
        Token.new(TokenOrError.str("2"), Pos.new(1, 10)),
        Token.new(TokenOrError.lineEnd(), Pos.new(1, 11)),
        Token.new(TokenOrError.sign('#'), Pos.new(2, 1)),
        Token.new(TokenOrError.sign('#'), Pos.new(2, 2)),
        Token.new(TokenOrError.sign('#'), Pos.new(2, 3)),
        Token.new(TokenOrError.space(), Pos.new(2, 4)),
        Token.new(TokenOrError.str("Title"), Pos.new(2, 9)),
        Token.new(TokenOrError.space(), Pos.new(2, 10)),
        Token.new(TokenOrError.str("3"), Pos.new(2, 11)),
        Token.new(TokenOrError.lineEnd(), Pos.new(2, 12)),
        Token.new(TokenOrError.space(), Pos.new(3, 1)),
        Token.new(TokenOrError.lineEnd(), Pos.new(3, 2)),
        Token.new(TokenOrError.str("Lorem"), Pos.new(4, 5)),
        Token.new(TokenOrError.space(), Pos.new(4, 6)),
        Token.new(TokenOrError.lineEnd(), Pos.new(4, 7)),
        Token.new(TokenOrError.str("asd"), Pos.new(5, 3)),
        Token.new(TokenOrError.eof(), Pos.new(5, 4)),
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
