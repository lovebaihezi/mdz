const std = @import("std");
const State = @import("../state/state.zig").State;
const Span = @import("../../utils/lib.zig").Span;
const Error = @import("../lib.zig").ParseError;
pub fn boldItalic(state: *State, span: Span) Error!void {
    _ = span;
    switch (state.state) {
        else => @panic(@tagName(state.state)),
    }
}
