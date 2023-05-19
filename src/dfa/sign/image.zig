const std = @import("std");
const State = @import("../state/state.zig").State;
const Span = @import("../../utils/lib.zig").Span;
const Error = @import("../lib.zig").ParseError;
pub fn image(state: *State, span: Span) Error!void {
    _ = span;
    switch (state.state) {
        .Empty => {
            if (state.value) |value| {
                _ = value;
            } else {
                state.maybeImage();
            }
        },
        else => {},
    }
}
