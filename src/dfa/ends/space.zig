const std = @import("std");
const Span = @import("../../utils/lib.zig").Span;
const dfa = @import("../lib.zig");
const State = dfa.state.State;
const ParseError = dfa.ParseError;
const ReturnType = dfa.ReturnType;

/// ' '
pub inline fn f(state: *State, span: Span) ParseError!ReturnType {
    switch (state.state) {
        .Empty => {
            //TODO: Maybe sub-level ordered(dot) list.
            if (state.value) |*value| {
                switch (value.*) {
                    .Title => {
                        state.toNormalText(span);
                    },
                    .Paragraph => {
                        state.toNormalText(span);
                    },
                    else => @panic(@tagName(state.state)),
                }
            }
        },
        .MaybeTitle => |level| {
            if (level > 6) {
                state.toNormalText(Span.new(span.begin - level, span.len + level));
            } else {
                state.maybeTitleContent(level);
            }
        },
        .MaybeTitleContent => |level| {
            try state.initTitleContent(level, Span.new(span.begin - level, span.len + level));
        },
        .MaybeIndentedCodeBegin => {
            state.state = .{ .MaybeIndentedCodeContent = span };
        },
        .MaybeIndentedCodeContent => |*s| {
            _ = s.enlarge(1);
        },
        .MaybeFencedCodeEnd => |*s| {
            _ = s.span[1].enlarge(1);
        },
        .NormalText => |*s| {
            _ = s.enlarge(1);
        },
        else => @panic(@tagName(state.state)),
    }
}
