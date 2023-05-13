const std = @import("std");

const imports = struct {
    const state = @import("state.zig");
    const lexer = @import("lexer.zig");
    const mir = @import("mir.zig");
    const utils = @import("utils.zig");

    const Block = mir.Block;
    const BlockTag = mir.BlockTag;
    const Token = lexer.TokenItem;
    const State = state.State;
    const Span = utils.Span;
    const StateItem = state.StateItem;
    const StateKind = state.StateKind;
    const Paragraph = mir.Paragraph;
};

const Block = imports.Block;
const Token = imports.Token;
const State = imports.State;
const Span = imports.Span;
const StateItem = imports.StateItem;
const StateKind = imports.StateKind;
const Allocator = std.mem.Allocator;
const Container = imports.mir.Container;
const Inner = imports.mir.Inner;
const Paragraph = imports.Paragraph;
const BlockTag = imports.BlockTag;

pub const ParseError = error{OutOfMemory};

/// Left-Most
pub const DFA = struct {
    const Self = @This();
    const ReturnType = void;

    /// '.'
    inline fn period(state: *State, span: Span) ParseError!ReturnType {
        switch (state.state) {
            .Empty => {
                state.toNormalText(span);
            },
            .NormalText => |*s| {
                _ = s.enlarge(1);
            },
            .MaybeParagraphEnd => |s| {
                try state.paragraphAddLine(s);
                state.toNormalText(span);
            },
            else => @panic("todo"),
        }
    }
    /// F for ','
    inline fn comma(state: *State, span: Span) ParseError!ReturnType {
        switch (state.state) {
            .Empty => {
                state.toNormalText(span);
            },
            .NormalText => |*s| {
                _ = s.enlarge(1);
            },
            .MaybeParagraphEnd => |s| {
                try state.paragraphAddLine(s);
                state.toNormalText(span);
            },
            else => @panic("todo"),
        }
    }
    /// '\''
    inline fn apostrophe(state: *State, span: Span) ParseError!ReturnType {
        switch (state.state) {
            .Empty => {
                state.toNormalText(span);
            },
            .NormalText => |*s| {
                _ = s.enlarge(1);
            },
            .MaybeParagraphEnd => |s| {
                try state.paragraphAddLine(s);
                state.toNormalText(span);
            },
            else => @panic("todo"),
        }
    }
    /// '"'
    inline fn quotation(state: *State, span: Span) ParseError!ReturnType {
        switch (state.state) {
            .Empty => {
                state.toNormalText(span);
            },
            .NormalText => |*s| {
                _ = s.enlarge(1);
            },
            .MaybeParagraphEnd => |s| {
                try state.paragraphAddLine(s);
                state.toNormalText(span);
            },
            else => @panic("todo"),
        }
    }
    /// '?'
    inline fn question(state: *State, span: Span) ParseError!ReturnType {
        switch (state.state) {
            .Empty => {
                state.toNormalText(span);
            },
            .NormalText => |*s| {
                _ = s.enlarge(1);
            },
            .MaybeParagraphEnd => |s| {
                try state.paragraphAddLine(s);
                state.toNormalText(span);
            },
            else => @panic("todo"),
        }
    }
    /// '!'
    inline fn exclamation(state: *State, span: Span) ParseError!ReturnType {
        _ = state;
        _ = span;
    }
    /// # F for '['
    /// Every thing between '[' and ']' will be seen as a
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
        switch (state.state) {
            .Empty => {
                state.toNormalText(span);
            },
            else => state.todo(),
        }
    }
    /// '}'
    inline fn rightBrace(state: *State, span: Span) ParseError!ReturnType {
        switch (state.state) {
            .Empty => {
                state.toNormalText(span);
            },
            else => state.todo(),
        }
    }
    /// '('
    inline fn leftParenthesis(state: *State, span: Span) ParseError!ReturnType {
        switch (state.state) {
            .Empty => {
                state.toNormalText(span);
            },
            .NormalText => |*s| {
                _ = s.enlarge(1);
            },
            .MaybeParagraphEnd => |s| {
                try state.paragraphAddLine(s);
                state.toNormalText(span);
            },
            else => @panic("todo"),
        }
    }
    /// ')'
    inline fn rightParenthesis(state: *State, span: Span) ParseError!ReturnType {
        switch (state.state) {
            .Empty => {
                state.toNormalText(span);
            },
            .NormalText => |*s| {
                _ = s.enlarge(1);
            },
            .MaybeParagraphEnd => |s| {
                try state.paragraphAddLine(s);
                state.toNormalText(span);
            },
            else => @panic("todo"),
        }
    }
    /// '.'
    inline fn ellipsis(state: *State, span: Span) ParseError!ReturnType {
        switch (state.state) {
            .Empty => {
                state.toNormalText(span);
            },
            .NormalText => |*s| {
                _ = s.enlarge(1);
            },
            .MaybeParagraphEnd => |s| {
                try state.paragraphAddLine(s);
                state.toNormalText(span);
            },
            else => @panic("todo"),
        }
    }
    /// ':'
    inline fn colon(state: *State, span: Span) ParseError!ReturnType {
        switch (state.state) {
            .Empty => {
                state.toNormalText(span);
            },
            .NormalText => |*s| {
                _ = s.enlarge(1);
            },
            .MaybeParagraphEnd => |s| {
                try state.paragraphAddLine(s);
                state.toNormalText(span);
            },
            else => @panic("todo"),
        }
    }
    /// ';'
    inline fn semicolon(state: *State, span: Span) ParseError!ReturnType {
        switch (state.state) {
            .Empty => {
                state.toNormalText(span);
            },
            .NormalText => |*s| {
                _ = s.enlarge(1);
            },
            .MaybeParagraphEnd => |s| {
                try state.paragraphAddLine(s);
                state.toNormalText(span);
            },
            else => @panic("todo"),
        }
    }
    /// '\\'
    inline fn backslash(state: *State, span: Span) ParseError!ReturnType {
        switch (state.state) {
            .Empty => {
                state.toNormalText(span);
            },
            .NormalText => |*s| {
                _ = s.enlarge(1);
            },
            .MaybeParagraphEnd => |s| {
                try state.paragraphAddLine(s);
                state.toNormalText(span);
            },
            else => @panic("todo"),
        }
    }
    /// # F for '*'
    ///
    /// ## Normal
    ///
    /// To solve text like *Italic**Bold**Italic~StrikeThrough~*, read one '*',
    /// And then whole text maybe an italic text, when read another one, maybe it'
    /// italic and bold, and etc. So, we default use left-most way.
    ///
    /// ## Ambigus
    ///
    /// Maybe we will encounter text like "****Text**", it shall be seen as a normal text
    /// if we are in lazy, like:
    /// ```AST-Text
    /// Block:
    /// ----Bold: "",
    /// ----Plain: "Text",
    /// ----Italic: "",
    /// ```
    /// and for left-most mode, it'll be parsed as something
    /// like:
    /// ```AST-Text
    /// Block:
    /// ----Bold:
    /// --------Italic: "" -> And we also need to provide warn for empty text
    /// --------Plain: "Text"
    /// ```
    inline fn asterisk(state: *State, span: Span) ParseError!ReturnType {
        switch (state.state) {
            .Empty => {
                state.toMaybeBoldOrItalic(span);
            },
            else => state.todo(),
        }
    }
    /// '_'
    inline fn underscore(state: *State, span: Span) ParseError!ReturnType {
        switch (state.state) {
            .Empty => {
                state.toNormalText(span);
            },
            .NormalText => |*s| {
                _ = s.enlarge(1);
            },
            .MaybeParagraphEnd => |s| {
                try state.paragraphAddLine(s);
                state.toNormalText(span);
            },
            else => @panic("todo"),
        }
    }
    /// '~'
    inline fn tilde(state: *State, span: Span) ParseError!ReturnType {
        switch (state.state) {
            .Empty => {
                state.toMaybeStrikeThrough(span);
            },
            .MaybeStrikeThrough => {
                state.done();
            },
            else => state.todo(),
        }
    }
    /// '+'
    inline fn plus(state: *State, span: Span) ParseError!ReturnType {
        switch (state.state) {
            .Empty => {
                state.toNormalText(span);
            },
            .NormalText => |*s| {
                _ = s.enlarge(1);
            },
            .MaybeParagraphEnd => |s| {
                try state.paragraphAddLine(s);
                state.toNormalText(span);
            },
            else => @panic("todo"),
        }
    }
    /// '-'
    inline fn minus(state: *State, span: Span) ParseError!ReturnType {
        _ = state;
        _ = span;
    }
    /// '='
    inline fn equal(state: *State, span: Span) ParseError!ReturnType {
        switch (state.state) {
            .Empty => {
                state.toNormalText(span);
            },
            .NormalText => |*s| {
                _ = s.enlarge(1);
            },
            .MaybeParagraphEnd => |s| {
                try state.paragraphAddLine(s);
                state.toNormalText(span);
            },
            else => @panic("todo"),
        }
    }
    /// '|'
    inline fn pipe(state: *State, span: Span) ParseError!ReturnType {
        _ = span;
        _ = state;
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
        switch (state.state) {
            .Empty => {
                state.toNormalText(span);
            },
            .NormalText => |*s| {
                _ = s.enlarge(1);
            },
            .MaybeParagraphEnd => |s| {
                try state.paragraphAddLine(s);
                state.toNormalText(span);
            },
            else => @panic("todo"),
        }
    }
    /// '$'
    inline fn dollar(state: *State, span: Span) ParseError!ReturnType {
        _ = state;
        _ = span;
    }
    /// # F for '#'
    inline fn hash(state: *State, span: Span) ParseError!ReturnType {
        switch (state.state) {
            .Empty => {
                if (state.value) |*value| {
                    switch (value.*) {
                        else => @panic("todo"),
                    }
                } else {
                    state.maybeTitle();
                }
            },
            .MaybeTitle => |*v| {
                const level = v.*;
                std.debug.assert(level != 0);
                if (level <= 6) {
                    v.* += 1;
                } else {
                    const begin = span.begin;
                    const len = level;
                    const new_span = Span.new(begin - len, len + 1);
                    state.toNormalText(new_span);
                }
            },
            .MaybeTitleContent => |level| {
                std.debug.assert(level <= 6);
                const blockSpan = Span.new(span.begin - 1 - level, 1 + level + 1);
                _ = blockSpan;
                @panic("todo");
            },
            .MaybeThematicBreak => |*s| {
                std.debug.assert(s.* >= 1);
                const newSpan = Span.new(span.begin - 1, s.* + 1);
                state.toNormalText(newSpan);
            },
            .NormalText => |*s| {
                _ = s.enlarge(1);
            },
            else => |s| @panic("todo!" ++ @typeName(@TypeOf(s))),
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
        _ = state;
    }
    /// ' '
    inline fn space(state: *State, span: Span) ParseError!ReturnType {
        switch (state.state) {
            .Empty => {
                //TODO: Maybe sub-level ordered(dot) list.
                if (state.value) |value| {
                    switch (value) {
                        .Title => {
                            state.toNormalText(span);
                        },
                        else => @panic("todo"),
                    }
                }
            },
            .MaybeTitle => |level| {
                std.debug.assert(level <= 6);
                state.maybeTitleContent(level);
            },
            .MaybeTitleContent => |level| {
                try state.initTitleContent(level, Span.new(span.begin - level, span.len + level));
            },
            .NormalText => |*s| {
                _ = s.enlarge(1);
            },
            else => @panic("todo"),
        }
    }
    /// '\n' or '\r\n'
    inline fn lineEnd(state: *State, span: Span) ParseError!ReturnType {
        _ = span;
        switch (state.state) {
            .Empty => {},
            .NormalText => |s| {
                if (state.value) |v| {
                    switch (v) {
                        .Title => {
                            try state.titleAddPlainText(s);
                            state.done();
                        },
                        .Paragraph => {
                            state.maybeParagraphEnd(s);
                        },
                        else => @panic("todo"),
                    }
                } else {
                    try state.initParagraph(s);
                    state.maybeParagraphEnd(s);
                }
            },
            .MaybeParagraphEnd => |s| {
                try state.paragraphAddLine(s);
                state.done();
            },
            else => @panic("todo"),
        }
    }
    /// # F for \d+
    inline fn numberAscii(state: *State, num: []const u8, span: Span) ParseError!ReturnType {
        switch (state.state) {
            .Empty => {
                if (state.value) |value| {
                    switch (value) {
                        else => @panic("todo"),
                    }
                } else {
                    state.maybeOrderedList(num);
                }
            },
            .MaybeTitleContent => |level| {
                try state.initTitleContent(level, span);
                state.toNormalText(span);
            },
            .MaybeParagraphEnd => |s| {
                try state.paragraphAddLine(s);
                state.toNormalText(span);
            },
            else => @panic("todo"),
        }
    }
    /// # F for \unicode+
    inline fn str(state: *State, string: []const u8, span: Span) ParseError!ReturnType {
        _ = string;
        switch (state.state) {
            .Empty => {
                if (state.value) |value| {
                    switch (value) {
                        .Title => {
                            state.toNormalText(span);
                        },
                        else => @panic("todo"),
                    }
                } else {
                    state.toNormalText(span);
                }
            },
            .NormalText => |*s| {
                _ = s.enlarge(span.len);
            },
            .MaybeTitle => |level| {
                state.toNormalText(Span.new(span.begin - level, span.len + level));
            },
            .MaybeParagraphEnd => |s| {
                try state.paragraphAddLine(s);
                state.toNormalText(span);
            },
            .MaybeTitleContent => |level| {
                try state.initTitleContent(level, span);
                state.toNormalText(span);
            },
            else => @panic("todo"),
        }
    }
    /// # F for end of file
    inline fn eof(state: *State, span: Span) ParseError!ReturnType {
        _ = span;
        switch (state.state) {
            .Empty => {
                if (state.value) |_| {
                    @panic("todo");
                }
                state.done();
            },
            .NormalText => |s| {
                if (state.value) |v| {
                    switch (v) {
                        .Title => {
                            try state.titleAddPlainText(s);
                        },
                        .Paragraph => {
                            try state.paragraphAddLine(s);
                        },
                        else => @panic("todo"),
                    }
                } else {
                    try state.initParagraph(s);
                    try state.paragraphAddLine(s);
                }
                state.done();
            },
            .MaybeParagraphEnd => |s| {
                try state.paragraphAddLine(s);
                state.done();
            },
            .Done => {},
            else => {
                std.log.err("{s}\n", .{@tagName(state.state)});
                @panic("todo");
            },
        }
    }

    pub fn f(state: *State, token: Token, span: Span) ParseError!ReturnType {
        try switch (token) {
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
                '(' => leftParenthesis(state, span),
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
        };
    }
};

test "F of #: success parse normal title" {
    const TextKind = imports.mir.TextKind;
    _ = TextKind;
    const InnerKind = imports.mir.InnerKind;
    _ = InnerKind;
    var allocator = std.testing.allocator;
    var state = State.empty(allocator);
    defer state.deinit(allocator);
    const dfa = DFA;
    try std.testing.expectEqual(StateKind.Empty, @as(StateKind, state.state));
    try dfa.f(&state, Token.sign('#'), Span.new(0, 1));
    try std.testing.expectEqual(StateKind.MaybeTitle, @as(StateKind, state.state));
    try dfa.f(&state, Token.sign('#'), Span.new(1, 1));
    try std.testing.expectEqual(StateKind.MaybeTitle, @as(StateKind, state.state));
    try dfa.f(&state, Token.sign('#'), Span.new(2, 1));
    try std.testing.expectEqual(StateKind.MaybeTitle, @as(StateKind, state.state));
    try dfa.f(&state, Token.space(), Span.new(3, 1));
    try std.testing.expectEqual(StateKind.MaybeTitleContent, @as(StateKind, state.state));
    const text1 = "MDZ";
    try dfa.f(&state, Token.str(text1), Span.new(4, text1.len));
    try std.testing.expectEqual(StateKind.NormalText, @as(StateKind, state.state));
    try dfa.f(&state, Token.space(), Span.new(7, 1));
    const text2 = "a";
    try dfa.f(&state, Token.str(text2), Span.new(8, text2.len));
    try std.testing.expectEqual(StateKind.NormalText, @as(StateKind, state.state));
    try dfa.f(&state, Token.lineEnd(), Span.new(9, 1));
    try std.testing.expectEqual(StateKind.Done, @as(StateKind, state.state));
    switch (state.state) {
        .Done => {
            if (state.value) |value| {
                switch (value) {
                    .Title => |title| {
                        try std.testing.expectEqual(@as(usize, 1), title.content.items.len);
                        try std.testing.expectEqual(@as(u8, 3), title.level);
                        const item = title.content.getLast();
                        switch (item) {
                            .Text => |text| {
                                switch (text) {
                                    .Plain => |plain| {
                                        try std.testing.expectEqual(Span.new(4, 5), plain);
                                    },
                                    else => unreachable,
                                }
                            },
                            else => unreachable,
                        }
                    },
                    else => @panic("\"### MDZ a\n\" parse result should be a title block"),
                }
            }
        },
        else => @panic("state type should be done"),
    }
}

test "F for str, numberAscii, space, tab, eof, eol" {
    var allocator = std.testing.allocator;
    var state = State.empty(allocator);
    defer state.deinit(allocator);
    const buffer = "MDZ is a  markdown parser\n";
    try DFA.f(&state, Token.str(buffer[0..3]), Span.new(0, 3));
    try std.testing.expectEqual(StateKind.NormalText, @as(StateKind, state.state));
    try DFA.f(&state, Token.space(), Span.new(3, 1));
    try std.testing.expectEqual(StateKind.NormalText, @as(StateKind, state.state));
    try DFA.f(&state, Token.str("is"), Span.new(4, 2));
    try DFA.f(&state, Token.space(), Span.new(6, 1));
    try std.testing.expectEqual(StateKind.NormalText, @as(StateKind, state.state));
    try DFA.f(&state, Token.str("a"), Span.new(7, 1));
    try DFA.f(&state, Token.space(), Span.new(8, 1));
    try std.testing.expectEqual(StateKind.NormalText, @as(StateKind, state.state));
    try DFA.f(&state, Token.space(), Span.new(17, 1));
    try DFA.f(&state, Token.str("Markdown"), Span.new(9, 8));
    try std.testing.expectEqual(StateKind.NormalText, @as(StateKind, state.state));
    try DFA.f(&state, Token.str("parser"), Span.new(18, 6));
    try DFA.f(&state, Token.lineEnd(), Span.new(24, 1));
    try DFA.f(&state, Token.lineEnd(), Span.new(24, 1));
    try std.testing.expectEqual(StateKind.Done, @as(StateKind, state.state));
    try DFA.f(&state, Token.eof(), Span.new(24, 1));
    try std.testing.expect(state.value != null);
    if (state.value) |value| {
        try std.testing.expectEqual(BlockTag.Paragraph, @as(BlockTag, value));
        try std.testing.expectEqual(@as(usize, 1), value.Paragraph.content.items.len);
        const item: Inner = value.Paragraph.content.items[0];
        try std.testing.expectEqual(@as(usize, 0), item.Text.Plain.begin);
        try std.testing.expectEqual(@as(usize, 24), item.Text.Plain.len);
    }
}

test "F for str, numberAscii, space, tab, eof, eol with one lineEnd" {
    var allocator = std.testing.allocator;
    var state = State.empty(allocator);
    defer state.deinit(allocator);
    const buffer = "MDZ is a  markdown parser\n";
    try DFA.f(&state, Token.str(buffer[0..3]), Span.new(0, 3));
    try std.testing.expectEqual(StateKind.NormalText, @as(StateKind, state.state));
    try DFA.f(&state, Token.space(), Span.new(3, 1));
    try std.testing.expectEqual(StateKind.NormalText, @as(StateKind, state.state));
    try DFA.f(&state, Token.str("is"), Span.new(4, 2));
    try DFA.f(&state, Token.space(), Span.new(6, 1));
    try std.testing.expectEqual(StateKind.NormalText, @as(StateKind, state.state));
    try DFA.f(&state, Token.str("a"), Span.new(7, 1));
    try DFA.f(&state, Token.space(), Span.new(8, 1));
    try std.testing.expectEqual(StateKind.NormalText, @as(StateKind, state.state));
    try DFA.f(&state, Token.space(), Span.new(17, 1));
    try DFA.f(&state, Token.str("Markdown"), Span.new(9, 8));
    try std.testing.expectEqual(StateKind.NormalText, @as(StateKind, state.state));
    try DFA.f(&state, Token.str("parser"), Span.new(18, 6));
    try DFA.f(&state, Token.lineEnd(), Span.new(24, 1));
    try std.testing.expectEqual(StateKind.MaybeParagraphEnd, @as(StateKind, state.state));
    try DFA.f(&state, Token.str("powered"), Span.new(25, 7));
    try DFA.f(&state, Token.str("by"), Span.new(32, 2));
    try DFA.f(&state, Token.str("Zig"), Span.new(34, 3));
    try std.testing.expectEqual(StateKind.NormalText, @as(StateKind, state.state));
    try DFA.f(&state, Token.eof(), Span.new(24, 1));
    try std.testing.expectEqual(StateKind.Done, @as(StateKind, state.state));
    try std.testing.expect(state.value != null);
    if (state.value) |value| {
        try std.testing.expectEqual(BlockTag.Paragraph, @as(BlockTag, value));
        try std.testing.expectEqual(@as(usize, 2), value.Paragraph.content.items.len);
    }
}

test "F for str, numberAscii, space, tab, eof, eol with two lineEnd" {
    var allocator = std.testing.allocator;
    var state = State.empty(allocator);
    const buffer = "MDZ is a  markdown parser\n";
    try DFA.f(&state, Token.str(buffer[0..3]), Span.new(0, 3));
    try std.testing.expectEqual(StateKind.NormalText, @as(StateKind, state.state));
    try DFA.f(&state, Token.space(), Span.new(3, 1));
    try std.testing.expectEqual(StateKind.NormalText, @as(StateKind, state.state));
    try DFA.f(&state, Token.str("is"), Span.new(4, 2));
    try DFA.f(&state, Token.space(), Span.new(6, 1));
    try std.testing.expectEqual(StateKind.NormalText, @as(StateKind, state.state));
    try DFA.f(&state, Token.str("a"), Span.new(7, 1));
    try DFA.f(&state, Token.space(), Span.new(8, 1));
    try std.testing.expectEqual(StateKind.NormalText, @as(StateKind, state.state));
    try DFA.f(&state, Token.space(), Span.new(17, 1));
    try DFA.f(&state, Token.str("Markdown"), Span.new(9, 8));
    try std.testing.expectEqual(StateKind.NormalText, @as(StateKind, state.state));
    try DFA.f(&state, Token.str("parser"), Span.new(18, 6));
    try DFA.f(&state, Token.lineEnd(), Span.new(24, 1));
    try std.testing.expectEqual(StateKind.MaybeParagraphEnd, @as(StateKind, state.state));
    try DFA.f(&state, Token.lineEnd(), Span.new(24, 1));
    try std.testing.expectEqual(StateKind.Done, @as(StateKind, state.state));
    if (state.value) |value| {
        try std.testing.expectEqual(BlockTag.Paragraph, @as(BlockTag, value));
        try std.testing.expectEqual(@as(usize, 1), value.Paragraph.content.items.len);
    }
    state.deinit(allocator);
    state = State.empty(allocator);
    defer state.deinit(allocator);
    try DFA.f(&state, Token.str("powered"), Span.new(25, 7));
    try DFA.f(&state, Token.str("by"), Span.new(32, 2));
    try DFA.f(&state, Token.str("Zig"), Span.new(34, 3));
    try std.testing.expectEqual(StateKind.NormalText, @as(StateKind, state.state));
    try DFA.f(&state, Token.eof(), Span.new(24, 1));
    try std.testing.expectEqual(StateKind.Done, @as(StateKind, state.state));
    try std.testing.expect(state.value != null);
    if (state.value) |value| {
        try std.testing.expectEqual(BlockTag.Paragraph, @as(BlockTag, value));
        try std.testing.expectEqual(@as(usize, 1), value.Paragraph.content.items.len);
    }
}
