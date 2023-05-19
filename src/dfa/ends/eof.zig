const std = @import("std");
const Span = @import("../../utils/lib.zig").Span;
const dfa = @import("../lib.zig");

const State = dfa.state.State;
const ParseError = dfa.ParseError;
const ReturnType = dfa.ReturnType;

/// # F for end of file
pub inline fn f(state: *State, span: Span) ParseError!ReturnType {
    _ = span;
    switch (state.state) {
        .Empty => {
            state.done();
        },
        .Done => {},
        else => {
            @panic(@tagName(state.state));
        },
    }
}
