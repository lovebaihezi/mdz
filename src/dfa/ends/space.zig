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
            if (state.value) |value| {
                switch (value) {
                    .Title => {
                        state.toNormalText(span);
                    },
                    else => @panic(@tagName(state.state)),
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
        .TitleContent => {
            try state.titleAddPlainText(span);
        },
        .NormalText => |*s| {
            _ = s.enlarge(1);
        },
        else => @panic(@tagName(state.state)),
    }
}
