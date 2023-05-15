const std = @import("std");
const State = dfa.state.State;
const Span = @import("../utils/lib.zig").Span;
const dfa = @import("lib.zig");
const mir = @import("../mir/lib.zig");
const ParseError = dfa.ParseError;
const ReturnType = dfa.ReturnType;
const allocErrorToParseError = dfa.allocErrorToParseError;

/// # F for \unicode+
pub inline fn f(state: *State, string: []const u8, span: Span) ParseError!ReturnType {
    _ = string;
    switch (state.state) {
        .Empty => {
            std.debug.assert(state.value == null);
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
        },
        .TitleContent => {
            try state.titleAddPlainText(span);
        },
        else => @panic(@tagName(state.state)),
    }
}
