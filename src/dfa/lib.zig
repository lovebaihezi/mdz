const std = @import("std");
const Lexer = @import("../lexer.zig").Lexer;
const Utils = @import("../mdz.zig").utils;

const Token = @import("../lexer.zig").TokenItem;
const TokenTag = @import("../lexer.zig").TokenItemTag;
const Span = @import("../utils/lib.zig").Span;

const Allocator = std.mem.Allocator;

pub const SyntaxError = error{
    UnexpectedCodeBlockEndContent,
    UnexpectedLineEndInIndentCode,
    UnexpectedEOFOfIndentCode,
    UnexpectedEOFOfCodeBlock,
    CodeBlockNotClosed,
};
pub const ParseError = error{ OutOfMemory, Overflow } || Allocator.Error || SyntaxError;
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
        // std.debug.print("{s}", .{@tagName(@as(state.StateKind, s.state))});
        // std.debug.print("\t{s}\t{d} + {d} = {d}..{d}\n", .{ @tagName(@as(TokenTag, token)), span.begin, span.len, span.begin, span.begin + span.len });
        try switch (token) {
            .Sign => |sign| switch (sign) {
                '`' => Sign.code(s, span),
                '~' => Sign.strikeThrough(s, span),
                '!' => Sign.image(s, span),
                '#' => Sign.title(s, span),
                '$' => Sign.laTex(s, span),
                '*' => Sign.boldItalic(s, span),
                '(' => Sign.urlBegin(s, span),
                ')' => Sign.urlEnd(s, span),
                '-' => Sign.thematicBreak(s, span),
                '_' => Sign.thematicBreak(s, span),
                '=' => Sign.thematicBreak(s, span),
                '+' => Sign.orderedList(s, span),
                '[' => Sign.alt(s, span),
                ']' => Sign.altEnd(s, span),
                '@', '%', '^', '&', '{', '}', '\\', '|', ';', ':', '\'', '"', ',', '<', '.', '>', '/', '?' => Sign.normal(s, span),
                else => @panic("unreachable"),
            },
            .Tab => Ends.tab(s, span),
            .Space => Ends.space(s, span),
            .LineEnd => Ends.lineEnd(s, span),
            .EOF => Ends.eof(s, span),
            .AsciiNumber => |n| asciiNumbers(s, n, span),
            .Str => |str| unicodes(s, str, span),
        };
        // std.debug.print("--->{s}\n", .{@tagName(@as(state.StateKind, s.state))});
    }
};
