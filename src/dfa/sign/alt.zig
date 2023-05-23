const std = @import("std");
const State = @import("../state/state.zig").State;
const Span = @import("../../utils/lib.zig").Span;
const Error = @import("../lib.zig").ParseError;
pub fn alt(state: *State, span: Span) Error!void {
    switch (state.state) {
        .Empty => {
            state.state = .{
                .MaybeHrefTextBegin = {},
            };
        },
        .MaybeHrefTextBegin => {
            state.state = .{
                .MaybeHrefText = span,
            };
        },
        .MaybeHrefText => |*s| {
            _ = s.enlarge(span.len);
        },
        else => @panic(@tagName(state.state)),
    }
}
