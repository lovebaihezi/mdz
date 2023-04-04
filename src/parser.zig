const std = @import("std");
const Allocator = std.mem.Allocator;
const lexer = @import("lexer.zig");
const Lexer = lexer.Lexer;

const SyntaxTreeNodeTag = enum {};

const SyntaxTreeNode = union(SyntaxTreeNodeTag) {};

const ParseResultTag = enum {
    BlockDone,
};

const ParseResult = union(ParseResultTag) {
    BlockDone: void,
};

const ParseError = error{};

const SyntaxTree = struct {
    const Self = @This();
    const Token = lexer.TokenItem;
    // DFA-like function for punctuations:
    // period, comma, apostrophe, quotation, question, exclamation, brackets, braces, parenthesis, dash, hyphen, ellipsis, colon, semicolon
    // '.'
    inline fn period(self: *Self) ParseError!ParseResult {}
    // ','
    inline fn comma(self: *Self) ParseError!ParseResult {}
    // '\''
    inline fn apostrophe(self: *Self) ParseError!ParseResult {}
    // '"'
    inline fn quotation(self: *Self) ParseError!ParseResult {}
    // '?'
    inline fn question(self: *Self) ParseError!ParseResult {}
    // '!'
    inline fn exclamation(self: *Self) ParseError!ParseResult {}
    // '['
    inline fn leftBracket(self: *Self) ParseError!ParseResult {}
    // ']'
    inline fn rightBracket(self: *Self) ParseError!ParseResult {}
    // '{'
    inline fn leftBrace(self: *Self) ParseError!ParseResult {}
    // '}'
    inline fn rightBrace(self: *Self) ParseError!ParseResult {}
    // '('
    inline fn leftParenthesis(self: *Self) ParseError!ParseResult {}
    // ')'
    inline fn rightParenthesis(self: *Self) ParseError!ParseResult {}
    // '.'
    inline fn ellipsis(self: *Self) ParseError!ParseResult {}
    // ':'
    inline fn colon(self: *Self) ParseError!ParseResult {}
    // ';'
    inline fn semicolon(self: *Self) ParseError!ParseResult {}
    // '\\'
    inline fn backslash(self: *Self) ParseError!ParseResult {}
    // '*'
    inline fn asterisk(self: *Self) ParseError!ParseResult {}
    // '_'
    inline fn underscore(self: *Self) ParseError!ParseResult {}
    // ''
    inline fn tilde(self: *Self) ParseError!ParseResult {}
    // '+'
    inline fn plus(self: *Self) ParseError!ParseResult {}
    // '-'
    inline fn minus(self: *Self) ParseError!ParseResult {}
    // '='
    inline fn equal(self: *Self) ParseError!ParseResult {}
    // '|'
    inline fn pipe(self: *Self) ParseError!ParseResult {}
    // '>'
    inline fn greater(self: *Self) ParseError!ParseResult {}
    // '<'
    inline fn less(self: *Self) ParseError!ParseResult {}
    // '&'
    inline fn ampersand(self: *Self) ParseError!ParseResult {}
    // '^'
    inline fn caret(self: *Self) ParseError!ParseResult {}
    // '%'
    inline fn percent(self: *Self) ParseError!ParseResult {}
    // '$'
    inline fn dollar(self: *Self) ParseError!ParseResult {}
    // '#'
    inline fn hash(self: *Self) ParseError!ParseResult {}
    // '@'
    inline fn at(self: *Self) ParseError!ParseResult {}
    // '`'
    inline fn backtick(self: *Self) ParseError!ParseResult {}
    // '/'
    inline fn slash(self: *Self) ParseError!ParseResult {}
    // '~'
    inline fn wave(self: *Self) ParseError!ParseResult {}

    inline fn tab(self: *Self) ParseError!ParseResult {}
    inline fn space(self: *Self) ParseError!ParseResult {}
    inline fn lineEnd(self: *Self) ParseError!ParseResult {}
    inline fn str(self: *Self, str: []const u8) ParseError!ParseResult {}
    inline fn eof(self: *Self) ParseError!ParseResult {}

    pub fn accept(self: *Self, token: Token) ParseError!ParseResult {
        switch (token) {
            .Sign => |sign| switch (sign) {
                '`' => self.backtick(),
                '~' => self.wave(),
                '!' => self.exclamation(),
                '@' => self.at(),
                '#' => self.hash(),
                '$' => self.dollar(),
                '%' => self.percent(),
                '^' => self.caret(),
                '&' => self.ampersand(),
                '*' => self.asterisk(),
                '(' => self.leftParenthesis(),
                ')' => self.rightParenthesis(),
                '-' => self.minus(),
                '_' => self.underscore(),
                '=' => self.equal(),
                '+' => self.plus(),
                '[' => self.leftBracket(),
                '{' => self.leftBrace(),
                ']' => self.rightBracket(),
                '}' => self.rightBrace(),
                '\\' => self.backslash(),
                '|' => self.pipe(),
                ';' => self.semicolon(),
                ':' => self.colon(),
                '\'' => self.apostrophe(),
                '"' => self.quotation(),
                ',' => self.comma(),
                '<' => self.less(),
                '.' => self.period(),
                '>' => self.greater(),
                '/' => self.slash(),
                '?' => self.question(),
                else => unreachable,
            },
            .Tab => self.tab(),
            .Space => self.space(),
            .LineEnd => self.lineEnd(),
            .Str => |s| self.str(s),
            .EOF => self.eof(),
        }
    }
};

const Parser = struct {
    const Self = @This();

    lexer: Lexer,

    pub inline fn initWithAllocator(source: []const u8) Self {
        return Self{
            .lexer = Lexer.init(source),
        };
    }

    pub fn fetch_one(self: *Self, allocator: Allocator) ParseError!SyntaxTree {
        var tree = SyntaxTree.initWithAllocator(allocator);
        while (self.lexer.next()) |value| {
            switch (value.item()) {
                .ok => |token| {
                    const result = try tree.accept(token);
                    switch (result) {
                        .BlockDone => {
                            break;
                        },
                    }
                },
                .unexpected => |e| {
                    switch (e) {
                        .unexpectedEOF => {
                            tree.diagnoseEOF();
                            break;
                        },
                        .unexpectedControlCode => |c| {
                            std.log.err("unexpected control code: {d}", .{c});
                        },
                    }
                },
            }
        }
        return tree;
    }
};

const markdownTitleTestCase =
    \\# Title 1
    \\## Title 2
    \\### Title 3 with **bold** and *italic*
    \\#### Title 4 with `code`
    \\##### Title 5 with `code` and **bold**
    \\###### Title 6 with $x \neq y$
;

const test1Title = "parser test case 1: " ++ markdownTitleTestCase;

test test1Title {
    const synTreeSeq = [_]SyntaxTree{};
    const allocator = std.testing.allocator_instance;
    var parser = Parser.init(markdownTitleTestCase);
    for (synTreeSeq) |cur_tree| {
        const tree = try parser.fetch_one(allocator);
        try std.testing.expectEqualDeep(tree, cur_tree);
    }
}
