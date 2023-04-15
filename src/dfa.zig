const std = @import("std");
const lexer = @import("lexer.zig");
const mir = @import("mir.zig");
const utils = @import("utils.zig");

const Block = mir.Block;
const Token = lexer.TokenItem;

pub const Span = utils.Span;

pub const ParseError = error{};

pub const StateKind = enum {
    const Self = @This();

    /// Begin State
    Empty,
    /// Middle State
    MaybeTitle,
    MaybeThematicBreak,
    MaybeFencedCode,
    MaybeIndentedCode,
    MaybeBlockQuote,
    MaybeOrderedList,
    MaybeImageUrlBegin,
    MaybeImageUrlAlt,
    MaybeImageUrlHref,
    /// Inf Maybe End
    NormalText,
};

pub const StateItem = union(StateKind) {
    const Self = @This();

    Empty: void,
    MaybeTitle: Span,
    MaybeThematicBreak: Span,
    MaybeFencedCode: Span,
    MaybeIndentedCode: Span,
    MaybeBlockQuote: Span,
    MaybeOrderedList: Span,
    MaybeImageUrlBegin: Span,
    MaybeImageUrlAlt: Span,
    MaybeImageUrlHref: Span,
    NormalText: Span,

    pub inline fn empty() Self {
        return Self{ .Empty = {} };
    }

    /// construct
    pub inline fn maybeTitle(span: Span) Self {
        return Self{ .MaybeTitle = span };
    }

    /// construct
    pub inline fn maybeThematicBreak(span: Span) Self {
        return Self{ .MaybeThematicBreak = span };
    }

    /// construct
    pub inline fn normalText(span: Span) Self {
        return Self{ .normalText = span };
    }

    /// Mutable
    pub inline fn downgradeToNormalText(self: *Self, span: Span) void {
        self.value = Self.normalText(span);
    }
};

pub const State = struct {
    const Self = @This();

    state: StateItem = StateItem.empty(),
    block: ?Block = null,
    pub inline fn empty() Self {
        return Self{};
    }
};

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
        switch (state) {
            .Empty => State.maybeTitle(1),
            .MaybeTitle => |s| if (s.len <= 6) {} else {},
            .NormalText => |s| s.enlarge(span),
            else => |s| s.downgradeNormalText(span),
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
    inline fn str(state: *State, s: []const u8, span: Span) ParseError!ReturnType {
        _ = state;
        _ = s;
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
        token: Token,
        span: Span,
    };
    const tuples = [_]Tuple{ .{
        Token.sign('#'),
        Span.init(0, 1),
    }, .{
        Token.space(),
        Span.init(1, 1),
    }, .{
        Token.str("Title"),
        Span.init(2, 5),
    } };
    var state = State.init();
    for (tuples) |tp| {
        try DFA.f(
            state,
            tp.token,
            tp.span,
        );
    }
    try std.testing.expect(state.isDone());
}
