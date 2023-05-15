const Span = @import("../../utils/lib.zig").Span;
const dfa = @import("../lib.zig");

const State = dfa.state.State;
const ParseError = dfa.ParseError;
const ReturnType = dfa.ReturnType;

/// '&'
pub inline fn f(state: *State, span: Span) ParseError!ReturnType {
    switch (state.state) {
        .Empty => {
            state.maybeBlockQuote();
        },
        .NormalText => |*s| {
            _ = s.enlarge(1);
        },
        .MaybeBlockQuote, .MaybeThematicBreak, .MaybeTitle => |level| {
            state.toNormalText(Span.new(span.begin - level, span.len + level));
        },
        .MaybeTitleContent => |level| {
            try state.initTitleContent(level, span);
            try state.titleAddPlainText(span);
        },
        else => @panic(@tagName(state.state)),
    }
}
