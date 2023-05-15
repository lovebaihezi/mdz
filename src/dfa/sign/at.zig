const Span = @import("../../utils/lib.zig").Span;
const dfa = @import("../lib.zig");

const ParseError = dfa.ParseError;
const ReturnType = dfa.ReturnType;
const State = dfa.state.State;
/// '@'
pub inline fn f(state: *State, span: Span) ParseError!ReturnType {
    _ = state;
    _ = span;
}
