const State = dfa.state.State;
const Span = @import("../../utils/lib.zig").Span;
const dfa = @import("../lib.zig");
const ParseError = dfa.ParseError;
const ReturnType = dfa.ReturnType;
/// # F for '['
/// Every thing between '[' and ']' will be seen as a
pub inline fn f(state: *State, span: Span) ParseError!ReturnType {
    switch (state.state) {
        .MaybeTitleContent => |level| {
            try state.initTitleContent(level, span);
            try state.titleAddPlainText(span);
        },
        else => @panic(@tagName(state.state)),
    }
}
