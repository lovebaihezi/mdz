const std = @import("std");

const imports = struct {
    const state = @import("state.zig");
    const lexer = @import("lexer.zig");
    const mir = @import("mir.zig");
    const utils = @import("utils.zig");

    const Block = mir.Block;
    const Token = lexer.TokenItem;
    const State = state.State;
    const Span = utils.Span;
    const StateItem = state.StateItem;
};

const Block = imports.Block;
const Token = imports.Token;
const State = imports.State;
const Span = imports.Span;
const StateItem = imports.StateItem;

pub const ParseError = error{};

pub const DFA = struct {
    const Self = @This();
    const ReturnType = void;

    /// '.'
    inline fn period(state: *State, span: Span) ParseError!ReturnType {
        switch (state.state) {
            .MaybeOrderedListBegin => |s| s.maybeOrderedListDot(span),
            else => {},
        }
    }
    /// ','
    inline fn comma(state: *State, span: Span) ParseError!ReturnType {
        _ = state;
        _ = span;
    }
    /// '\''
    inline fn apostrophe(state: *State, span: Span) ParseError!ReturnType {
        _ = state;
        _ = span;
    }
    /// '"'
    inline fn quotation(state: *State, span: Span) ParseError!ReturnType {
        _ = state;
        _ = span;
    }
    /// '?'
    inline fn question(state: *State, span: Span) ParseError!ReturnType {
        _ = state;
        _ = span;
    }
    /// '!'
    inline fn exclamation(state: *State, span: Span) ParseError!ReturnType {
        _ = state;
        _ = span;
    }
    /// '['
    inline fn leftBracket(state: *State, span: Span) ParseError!ReturnType {
        _ = state;
        _ = span;
    }
    /// ']'
    inline fn rightBracket(state: *State, span: Span) ParseError!ReturnType {
        _ = state;
        _ = span;
    }
    /// '{'
    inline fn leftBrace(state: *State, span: Span) ParseError!ReturnType {
        _ = state;
        _ = span;
    }
    /// '}'
    inline fn rightBrace(state: *State, span: Span) ParseError!ReturnType {
        _ = state;
        _ = span;
    }
    /// '('
    inline fn leftParenthesis(state: *State, span: Span) ParseError!ReturnType {
        _ = state;
        _ = span;
    }
    /// ')'
    inline fn rightParenthesis(state: *State, span: Span) ParseError!ReturnType {
        _ = state;
        _ = span;
    }
    /// '.'
    inline fn ellipsis(state: *State, span: Span) ParseError!ReturnType {
        _ = state;
        _ = span;
    }
    /// ':'
    inline fn colon(state: *State, span: Span) ParseError!ReturnType {
        _ = state;
        _ = span;
    }
    /// ';'
    inline fn semicolon(state: *State, span: Span) ParseError!ReturnType {
        _ = state;
        _ = span;
    }
    /// '\\'
    inline fn backslash(state: *State, span: Span) ParseError!ReturnType {
        _ = state;
        _ = span;
    }
    /// '*'
    inline fn asterisk(state: *State, span: Span) ParseError!ReturnType {
        _ = state;
        _ = span;
    }
    /// '_'
    inline fn underscore(state: *State, span: Span) ParseError!ReturnType {
        _ = state;
        _ = span;
    }
    /// '~'
    inline fn tilde(state: *State, span: Span) ParseError!ReturnType {
        _ = state;
        _ = span;
    }
    /// '+'
    inline fn plus(state: *State, span: Span) ParseError!ReturnType {
        _ = state;
        _ = span;
    }
    /// '-'
    inline fn minus(state: *State, span: Span) ParseError!ReturnType {
        _ = state;
        _ = span;
    }
    /// '='
    inline fn equal(state: *State, span: Span) ParseError!ReturnType {
        _ = state;
        _ = span;
    }
    /// '|'
    inline fn pipe(state: *State, span: Span) ParseError!ReturnType {
        switch (state.value) {
            .Empty => State.MaybeTableBeginOr,
        }
        _ = span;
    }
    /// '>'
    inline fn greater(state: *State, span: Span) ParseError!ReturnType {
        _ = state;
        _ = span;
    }
    /// '<'
    inline fn less(state: *State, span: Span) ParseError!ReturnType {
        _ = state;
        _ = span;
    }
    /// '&'
    inline fn ampersand(state: *State, span: Span) ParseError!ReturnType {
        _ = state;
        _ = span;
    }
    /// '^'
    inline fn caret(state: *State, span: Span) ParseError!ReturnType {
        _ = state;
        _ = span;
    }
    /// '%'
    inline fn percent(state: *State, span: Span) ParseError!ReturnType {
        _ = state;
        _ = span;
    }
    /// '$'
    inline fn dollar(state: *State, span: Span) ParseError!ReturnType {
        _ = state;
        _ = span;
    }
    /// '#'
    inline fn hash(state: *State, span: Span) ParseError!ReturnType {
        switch (state.state) {
            .Empty => StateItem.maybeTitle(span),
            .MaybeTitle => |*s| {
                // TODO: Finish Setup
                std.debug.assert(s[0].len != 0);
                if (s[0].len <= 6) {
                    _ = s.enlarge(1);
                } else {
                    state.toNormalText(s[0].enlarge(1).clone());
                }
            },
            .MaybeThematicBreak => |*s| {
                std.debug.assert(s.len >= 1);
                state.toNormalText(s.enlarge(1).clone());
            },
            .MaybeBlockQuote, .MaybeOrderedList, .MaybeDotList => |*arr| {
                std.debug.assert(arr.len == 2);
                state.toNormalText(arr[0].enlarge(1).clone());
            },
            .MaybeImageUrl => |*arr| {
                std.debug.assert(arr.len == 3);
            },
            .MaybeUrl => |*arr| {
                std.debug.assert(arr.len == 3);
            },
            .MaybeIndentedCode => |*slice| {
                std.debug.assert(slice.len == 3);
                std.debug.assert(slice[0] != undefined);
                std.debug.assert(slice[2] == undefined);
                if (slice[1] == undefined) {
                    slice[1] = span;
                } else {
                    slice[1].enlarge(1);
                }
            },
            .MaybeFencedCode => |*slice| {
                std.debug.assert(slice.len == 3 or slice.len == 4);
                if (slice[0].len != 3) {
                    state.toNormalText(slice[0].enlarge(1).clone());
                } else if (slice[2] == undefined) {
                    slice[2] = span;
                } else {
                    slice[2].enlarge(1);
                }
            },
            .NormalText => |*s| {
                _ = s.enlarge(1);
            },
        }
    }
    /// '@'
    inline fn at(state: *State, span: Span) ParseError!ReturnType {
        _ = state;
        _ = span;
    }
    /// '`'
    inline fn backtick(state: *State, span: Span) ParseError!ReturnType {
        _ = state;
        _ = span;
    }
    /// '/'
    inline fn slash(state: *State, span: Span) ParseError!ReturnType {
        _ = state;
        _ = span;
    }
    /// '\t'
    inline fn tab(state: *State, span: Span) ParseError!ReturnType {
        _ = span;
        switch (state) {
            .MaybeTitle => |c| State.done(Block.title(c)),
        }
    }
    /// ' '
    inline fn space(state: *State, span: Span) ParseError!ReturnType {
        _ = span;
        switch (state) {
            .MaybeTitle => |c| State.done(Block.title(c)),
        }
    }
    /// '\n' or '\r\n'
    inline fn lineEnd(state: *State, span: Span) ParseError!ReturnType {
        _ = span;
        _ = state;
    }
    inline fn numberAscii(state: *State, num: []const u8, span: Span) ParseError!ReturnType {
        _ = state;
        _ = num;
        _ = span;
    }
    inline fn str(state: *State, string: []const u8, span: Span) ParseError!ReturnType {
        _ = state;
        _ = string;
        _ = span;
    }
    inline fn eof(state: *State, span: Span) ParseError!ReturnType {
        _ = state;
        _ = span;
    }

    pub fn f(state: *State, token: Token, span: Span) ParseError!ReturnType {
        switch (token) {
            .Sign => |sign| switch (sign) {
                '`' => backtick(state, span),
                '~' => tilde(state, span),
                '!' => exclamation(state, span),
                '@' => at(state, span),
                '#' => hash(state, span),
                '$' => dollar(state, span),
                '%' => percent(state, span),
                '^' => caret(state, span),
                '&' => ampersand(state, span),
                '*' => asterisk(state, span),
                '(' => leftParenthesis(span),
                ')' => rightParenthesis(state, span),
                '-' => minus(state, span),
                '_' => underscore(state, span),
                '=' => equal(state, span),
                '+' => plus(state, span),
                '[' => leftBracket(state, span),
                '{' => leftBrace(state, span),
                ']' => rightBracket(state, span),
                '}' => rightBrace(state, span),
                '\\' => backslash(state, span),
                '|' => pipe(state, span),
                ';' => semicolon(state, span),
                ':' => colon(state, span),
                '\'' => apostrophe(state, span),
                '"' => quotation(state, span),
                ',' => comma(state, span),
                '<' => less(state, span),
                '.' => period(state, span),
                '>' => greater(state, span),
                '/' => slash(state, span),
                '?' => question(state, span),
                else => unreachable,
            },
            .NumberAscii => |n| numberAscii(state, n, span),
            .Tab => tab(state, span),
            .Space => space(state, span),
            .LineEnd => lineEnd(state, span),
            .Str => |s| str(state, s, span),
            .EOF => eof(state, span),
        }
    }
};

test "dfa on Titles" {
    const Tuple = struct {
        const Self = @This();
        token: Token,
        span: Span,

        pub inline fn new(token: Token, span: Span) Self {
            return Self{
                .token = token,
                .span = span,
            };
        }
    };
    const tuples = [_]Tuple{ Tuple.new(
        Token.sign('#'),
        Span.new(0, 1),
    ), Tuple.new(
        Token.space(),
        Span.new(1, 1),
    ), Tuple.new(
        Token.str("Title"),
        Span.new(2, 5),
    ) };
    var state = State.empty();
    for (tuples) |tp| {
        try DFA.f(
            &state,
            tp.token,
            tp.span,
        );
    }
    try std.testing.expect(state.block != null);
}
