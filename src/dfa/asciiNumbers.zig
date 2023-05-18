const std = @import("std");
const State = dfa.state.State;
const Kind = dfa.state.StateKind;
const Span = @import("../utils/lib.zig").Span;
const dfa = @import("lib.zig");
const Lexer = @import("../lexer.zig").Lexer;
const ParseError = dfa.ParseError;
const ReturnType = dfa.ReturnType;

/// # F for \d+
pub inline fn f(state: *State, num: []const u8, span: Span) ParseError!ReturnType {
    switch (state.state) {
        .Empty => {
            if (state.value) |_| {
                unreachable;
            } else {
                state.maybeOrderedList(num);
            }
        },
        .MaybeBlockQuote, .MaybeThematicBreak, .MaybeTitle => |level| {
            state.toNormalText(Span.new(span.begin - level, span.len + level));
        },
        .MaybeTitleContent => |level| {
            try state.initTitleContent(level, span);
        },
        .NormalText => |*s| {
            _ = s.enlarge(span.len);
        },
        .MaybeParagraphEnd => |s| {
            try state.paragraphAddLine(s);
            state.maybeOrderedList(num);
        },
        .TitleContent => {
            try state.titleAddPlainText(span);
        },
        else => @panic(@tagName(state.state)),
    }
}

const TokenItem = @import("../lexer.zig").TokenItem;
test "test f for number line" {
    var lexer = Lexer.init("123 123");
    _ = lexer;
}
fn c(lexer: *Lexer, state: *State) void {
    while (lexer.next()) |value| {
        switch (value.item) {
            .ok => |token| {
                const t: TokenItem = token;
                _ = f(state, t.AsciiNumber, value.span) catch |e| {
                    @panic(@errorName(e));
                };
            },
            .unexpected => |e| {
                @panic(@tagName(e));
            },
        }
    }
}

test "test f for order list " {
    const assertEq = std.testing.expectEqual;
    var lexer = Lexer.init("1. 12345 345245 23452345. 23452345 2345234.");
    const allocator = std.testing.allocator;
    var state = State.empty(allocator);
    c(&lexer, &state);
    try assertEq(state.kind(), Kind.MaybeOrderedList);
}
