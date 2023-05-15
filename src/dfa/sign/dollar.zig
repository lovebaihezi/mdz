const State = dfa.state.State;
const Span = @import("../../utils/lib.zig").Span;
const dfa = @import("../lib.zig");
const ParseError = dfa.ParseError;
const ReturnType = dfa.ReturnType;

/// '$'
pub inline fn f(state: *State, span: Span) ParseError!ReturnType {
    _ = state;
    _ = span;
}
