const State = dfa.state.State;
const Span = @import("../../utils/lib.zig").Span;
const dfa = @import("../lib.zig");
const ParseError = dfa.ParseError;
const ReturnType = dfa.ReturnType;
/// ':'
pub inline fn f(state: *State, span: Span) ParseError!ReturnType {
    switch (state.state) {
        .Empty => {
            state.toNormalText(span);
        },
        .MaybeParagraphEnd => |s| {
            try state.paragraphAddLine(s);
            state.toNormalText(span);
        },
        .MaybeBlockQuote, .MaybeThematicBreak, .MaybeTitle => |level| {
            state.toNormalText(Span.new(span.begin - level, span.len + level));
        },
        .MaybeTitleContent => |level| {
            try state.initTitleContent(level, span);
        },
        .TitleContent => {
            try state.titleAddPlainText(span);
        },
        .NormalText => |*s| {
            _ = s.enlarge(span.len);
        },
        else => {},
    }
}
