const State = dfa.state.State;
const Span = @import("../../utils/lib.zig").Span;
const dfa = @import("../lib.zig");
const ParseError = dfa.ParseError;
const ReturnType = dfa.ReturnType;

/// F for '.'
pub inline fn f(state: *State, span: Span) ParseError!ReturnType {
    switch (state.state) {
        .Empty => {
            state.toNormalText(span);
        },
        .NormalText => |*s| {
            _ = s.enlarge(1);
        },
        .MaybeParagraphEnd => |s| {
            try state.paragraphAddLine(s);
            state.toNormalText(span);
        },
        .MaybeTitleContent => |level| {
            try state.initTitleContent(level, span);
            state.toNormalText(span);
        },
        else => @panic(@tagName(state.state)),
    }
}
