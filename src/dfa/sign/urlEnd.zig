const std = @import("std");
const State = @import("../state/state.zig").State;
const Span = @import("../../utils/lib.zig").Span;
const Error = @import("../lib.zig").ParseError;
pub fn urlEnd(state: *State, span: Span) Error!void {
    _ = span;
    _ = state;
}
