const Span = @import("../../utils/lib.zig").Span;
const dfa = @import("../lib.zig");

const State = dfa.state.State;
const ParseError = dfa.ParseError;
const ReturnType = dfa.ReturnType;
/// # F for '*'
///
/// ## Normal
///
/// To solve text like *Italic**Bold**Italic~StrikeThrough~*, read one '*',
/// And then whole text maybe an italic text, when read another one, maybe it'
/// italic and bold, and etc. So, we default use left-most way.
///
/// ## Ambigus
///
/// Maybe we will encounter text like "****Text**", it shall be seen as a normal text
/// if we are in lazy, like:
/// ```AST-Text
/// Block:
/// ----Bold: "",
/// ----Plain: "Text",
/// ----Italic: "",
/// ```
/// and for left-most mode, it'll be parsed as something
/// like:
/// ```AST-Text
/// Block:
/// ----Bold:
/// --------Italic: "" -> And we also need to provide warn for empty text
/// --------Plain: "Text"
/// ```
pub inline fn f(state: *State, span: Span) ParseError!ReturnType {
    switch (state.state) {
        .Empty => {
            state.toMaybeBoldOrItalic(span);
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
        else => {},
    }
}
