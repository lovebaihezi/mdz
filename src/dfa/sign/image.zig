const std = @import("std");
const State = @import("../state/state.zig").State;
const Span = @import("../../utils/lib.zig").Span;
const Error = @import("../lib.zig").ParseError;
pub fn image(state: *State, span: Span) Error!void {
    switch (state.state) {
        .Empty => {
            if (state.value) |value| {
                _ = value;
            } else {
                state.maybeImage();
            }
        },
        .MaybeFencedCodeEnd => |*s| {
            _ = s.span[1].enlarge(span.len);
        },
        .MaybeIndentedCodeContent => |*s| {
            _ = s.enlarge(1);
        },
        else => @panic(@tagName(state.state)),
    }
}
