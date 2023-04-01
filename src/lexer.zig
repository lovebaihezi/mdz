const std = @import("std");
const Allocator = std.mem.Allocator;
const utils = @import("utils.zig");

pub const Pos = struct {
    const Self = Pos;
    line: usize,
    column: usize,
    pub fn default() Pos {
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
    pub inline fn go_left(self: *Self, left: usize) *Self {
        self.column -= left;
        return self;
    }
    pub inline fn go_right(self: *Self, right: usize) *Self {
        self.column += right;
        return self;
    }
    pub inline fn go_down(self: *Self, down: usize) *Self {
        self.line += down;
        return self;
    }
    pub inline fn go_up(self: *Self, up: usize) *Self {
        self.line -= up;
        return self;
    }
    pub inline fn go_to(self: *Self, line: usize, column: usize) *Self {
        self.line = line;
        self.column = column;
        return self;
    }
    pub inline fn add(self: *Self, pos: Pos) *Self {
        self.line += pos.line;
        self.column += pos.column;
        return self;
    }
};

pub const ErrorTag = enum { unexpectedEOF, unexpectedControlCode };

pub const ErrorItem = union(ErrorTag) {
    const Self = ErrorItem;
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
    const Self = TokenItem;
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
    pub inline fn line_end() Self {
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
    const Self = TokenOrError;
    ok: TokenItem,
    unexpected: ErrorItem,
    pub inline fn tab() Self {
        return Self{ .ok = TokenItem.tab() };
    }
    pub inline fn space() Self {
        return Self{ .ok = TokenItem.space() };
    }
    pub inline fn line_end() Self {
        return Self{ .ok = TokenItem.line_end() };
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
    const Self = Token;
    const Item = TokenOrError;
    item: TokenOrError,
    pos: Pos,
    allocator: ?std.mem.Allocator = null,
    pub inline fn tab(pos: Pos) Self {
        return Self{ .item = Item.tab(), .pos = pos };
    }
    pub inline fn space(pos: Pos) Self {
        return Self{ .item = Item.space(), .pos = pos };
    }
    pub inline fn line_end(pos: Pos) Self {
        return Self{ .item = Item.line_end(), .pos = pos };
    }
    pub inline fn sign(s: u8, pos: Pos) Self {
        return Self{ .item = Item.sign(s), .pos = pos };
    }
    pub inline fn str(s: []const u8, pos: Pos) Self {
        return Self{ .item = Item.str(s), .pos = pos };
    }
    pub inline fn eof(pos: Pos) Self {
        return Self{ .item = Item.eof(), .pos = pos };
    }
    pub inline fn unexpectedEOF(pos: Pos) Self {
        return Self{ .item = Item.unexpectedEOF(), .pos = pos };
    }
    pub inline fn unexpectedControlCode(c: u8, pos: Pos) Self {
        return Self{ .item = Item.unexpectedControlCode(c), .pos = pos };
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
    const Self = Lexer;

    buffer: ?[]const u8 = null,
    pos: Pos = Pos.default(),
    index: usize = 0,
    allocator: std.mem.Allocator,
    state: ?Token = null,

    pub fn initWithAllocator(allocator: Allocator, buffer: []const u8) Self {
        return Self{
            .index = 0,
            .pos = Pos.default(),
            .allocator = allocator,
            .buffer = buffer,
        };
    }

    fn updateIndex(self: *Self, final: usize) *Self {
        self.index = final;
        return self;
    }

    fn swapState(self: *Self, token: *?Token) *Self {
        if (self.state) |state| {
            const tmp = token.*;
            token.* = state;
            self.state = tmp;
        }
        return self;
    }

    pub fn next(self: *Self) ?Token {
        const pos = self.pos;
        var token = if (self.buffer) |buf|
            if (self.index == buf.len)
                Token.eof(pos)
            else if (self.index > buf.len)
                null
            else switch (buf[self.index]) {
                0x0...0x8 => |c| Token.unexpectedControlCode(c, pos),

                0x9 => Token.tab(pos),

                0xA => Token.line_end(pos),

                0xB...0xC => Token.space(pos),

                0xD => result: {
                    const next_c = buf[self.index + 1];
                    if (next_c == 0xD) {
                        self.index += 1;
                        break :result Token.line_end(pos);
                    } else {
                        break :result Token.unexpectedControlCode(0xA, pos);
                    }
                },

                0x10...0x1F => |c| Token.unexpectedControlCode(c, pos),

                0x20 => Token.space(pos),

                0x21...0x2F => |c| Token.sign(c, pos),

                0x3A...0x40 => |c| Token.sign(c, pos),

                0x5B...0x60 => |c| Token.sign(c, pos),

                0x7B...0x7E => |c| Token.sign(c, pos),

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
                    break :other Token.str(buf[begin .. self.index + 1], pos);
                },
            }
        else
            null;
        self.index += 1;
        _ = self.swapState(&token);
        return token;
    }
    pub fn hasNext(self: Self) bool {
        const state = self.state;
        if (state != null) {
            return true;
        }
        if (self.buffer) |buf| {
            return self.index <= buf.len;
        }
        return false;
    }
    pub fn deinit(self: *Self) void {
        _ = self;
    }
};

test "lexer test case 1: \"# hello world!\\n\"" {
    const str = "# hello world!\n";
    const default = Pos.default();
    const token_seq = [_]Token{
        Token.sign('#', default),
        Token.space(default),
        Token.str("hello", default),
        Token.space(default),
        Token.str("world", default),
        Token.sign('!', default),
        Token.line_end(default),
        Token.eof(default),
    };
    const allocator = std.testing.allocator;
    var lex = Lexer.initWithAllocator(allocator, str);
    defer lex.deinit();
    const assert = std.testing.expect;
    std.debug.print("\n", .{});
    for (token_seq) |corr_token| {
        try assert(lex.hasNext());
        const token = lex.next();
        try assert(token != null);
        try assert(token.?.isOk());
        try std.testing.expectEqualDeep(token, corr_token);
    }
}

const testCase2Title = "lexer test case 2" ++ testCase2;

const testCase2 =
    \\# Title 1
    \\## Title 2
    \\### Title 3
    \\ 
    \\Lorem 
    \\ 
    \\asd
;

test testCase2Title {}
