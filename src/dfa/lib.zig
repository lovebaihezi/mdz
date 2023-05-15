const std = @import("std");
const Lexer = @import("../lexer.zig").Lexer;
const Utils = @import("../mdz.zig").utils;

const Token = @import("../lexer.zig").TokenItem;
const Span = @import("../utils/lib.zig").Span;

const Allocator = std.mem.Allocator;

pub const ParseError = error{OutOfMemory};
pub const ReturnType = void;
pub const state = @import("state/state.zig");

/// Right-Most
pub const DFA = struct {
    const Self = @This();

    const Sign = @import("sign/lib.zig");
    const Ends = @import("ends/lib.zig");
    const unicodes = @import("unicodes.zig").f;
    const asciiNumbers = @import("asciiNumbers.zig").f;
    const State = state.State;

    pub fn f(s: *State, token: Token, span: Span) ParseError!ReturnType {
        try switch (token) {
            .Sign => |sign| switch (sign) {
                '`' => Sign.backtick(s, span),
                '~' => Sign.tilde(s, span),
                '!' => Sign.exclamation(s, span),
                '@' => Sign.at(s, span),
                '#' => Sign.hash(s, span),
                '$' => Sign.dollar(s, span),
                '%' => Sign.percent(s, span),
                '^' => Sign.caret(s, span),
                '&' => Sign.ampersand(s, span),
                '*' => Sign.asterisk(s, span),
                '(' => Sign.leftParenthesis(s, span),
                ')' => Sign.rightParenthesis(s, span),
                '-' => Sign.minus(s, span),
                '_' => Sign.underscore(s, span),
                '=' => Sign.equal(s, span),
                '+' => Sign.plus(s, span),
                '[' => Sign.leftBracket(s, span),
                '{' => Sign.leftBrace(s, span),
                ']' => Sign.rightBracket(s, span),
                '}' => Sign.rightBrace(s, span),
                '\\' => Sign.backslash(s, span),
                '|' => Sign.pipe(s, span),
                ';' => Sign.semicolon(s, span),
                ':' => Sign.colon(s, span),
                '\'' => Sign.apostrophe(s, span),
                '"' => Sign.quotation(s, span),
                ',' => Sign.comma(s, span),
                '<' => Sign.less(s, span),
                '.' => Sign.period(s, span),
                '>' => Sign.greater(s, span),
                '/' => Sign.slash(s, span),
                '?' => Sign.question(s, span),
                else => unreachable,
            },
            .Tab => Ends.tab(s, span),
            .Space => Ends.space(s, span),
            .LineEnd => Ends.lineEnd(s, span),
            .EOF => Ends.eof(s, span),
            .AsciiNumber => |n| asciiNumbers(s, n, span),
            .Str => |str| unicodes(s, str, span),
        };
    }
};
pub fn allocErrorToParseError(e: Allocator.Error) ParseError {
    return switch (e) {
        Allocator.Error.OutOfMemory => ParseError.OutOfMemory,
    };
}
