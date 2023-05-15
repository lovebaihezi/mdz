const std = @import("std");
const State = dfa.state.State;
const Span = @import("../utils/lib.zig").Span;
const dfa = @import("lib.zig");
const ParseError = dfa.ParseError;
const ReturnType = dfa.ReturnType;

/// # F for \d+
pub inline fn f(state: *State, num: []const u8, span: Span) ParseError!ReturnType {
    switch (state.state) {
        .Empty => {
            if (state.value) |value| {
                switch (value) {
                    else => @panic(@tagName(state.state)),
                }
            } else {
                state.maybeOrderedList(num);
            }
        },
        .MaybeTitleContent => |level| {
            try state.initTitleContent(level, span);
        },
        .MaybeParagraphEnd => |s| {
            try state.paragraphAddLine(s);
            state.toNormalText(span);
        },
        .NormalText => |*s| {
            _ = s.enlarge(span.len);
        },
        else => @panic(@tagName(state.state)),
    }
}
