const std = @import("std");
const State = @import("../state/state.zig").State;
const Span = @import("../../utils/lib.zig").Span;
const Error = @import("../lib.zig").ParseError;
pub fn altEnd(state: *State, span: Span) Error!void {
    switch (state.state) {
        .Empty => {
            if (state.value) |value| {
                _ = value;
            } else {
                state.toNormalText(span);
            }
        },
        .NormalText => |*s| {
            _ = s.enlarge(1);
        },
        .MaybeImageAlt => |s| {
            state.state = .{
                .MaybeImageAltEnd = s,
            };
        },
        .MaybeImageAltEnd => |*s| {
            _ = s.enlarge(1);
        },
        else => @panic(@tagName(state.state)),
    }
}
