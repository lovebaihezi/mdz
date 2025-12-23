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
            state.state = .{
                .MaybeOrderedList = num,
            };
        },
        .NormalText => |*s| {
            _ = s.enlarge(span.len);
        },
        .MaybeIndentedCodeBegin => {
            if (state.value == null) {
                try state.initParagraph(Span.new(span.begin + 1, span.len + 1));
            }
            state.state = .{ .MaybeIndentedCodeContent = span };
        },
        .MaybeIndentedCodeContent => |*s| {
            _ = s.enlarge(1);
        },
        .MaybeIndentedLaTex => {
            state.state = .{
                .MaybeIndentedLaTexContent = span,
            };
        },
        .MaybeIndentedLaTexContent => |*s| {
            _ = s.enlarge(span.len);
        },
        .MaybeFencedCodeBegin => |s| {
            if (state.value == null) {
                try state.initParagraph(Span.new(span.begin - s, span.len + s));
            }
            try state.value.?.Paragraph.addCode(state.allocator, Span.new(span.begin - s + 1, 0));
            state.toNormalText(span);
        },
        .MaybeFencedCodeEnd => |*s| {
            _ = s.span[1].enlarge(span.len);
        },
        else => @panic(@tagName(state.state)),
    }
}

const TokenItem = @import("../lexer.zig").TokenItem;

test "test f for number line" {
    _ = Lexer.init("123 123");
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
    _ = assertEq;
    const lexer = Lexer.init("1 12345 345245 23452345. 23452345 2345234.");
    _ = lexer;
    const allocator = std.testing.allocator;
    const state = State.empty(allocator, false);
    _ = state;
    // c(&lexer, &state);
    // try assertEq(state.kind(), Kind.MaybeOrderedList);
}
