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
            state.toNormalText(span);
        },
        .NormalText => |*s| {
            _ = s.enlarge(span.len);
        },
        else => @panic(@tagName(state.state)),
    }
}
