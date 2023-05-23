const std = @import("std");
const State = @import("../state/state.zig").State;
const Span = @import("../../utils/lib.zig").Span;
const Error = @import("../lib.zig").ParseError;
pub fn thematicBreak(state: *State, span: Span) Error!void {
    _ = span;
    switch (state.state) {
        .Empty => {
            state.maybeThematicBreak();
        },
        .MaybeThematicBreak => |*size| {
            size.* += 1;
        },
        .NormalText => |*s| {
            _ = s.enlarge(1);
        },
        .MaybeIndentedCodeContent => |*s| {
            _ = s.enlarge(1);
        },
        .MaybeFencedCodeMeta => |*s| {
            _ = s.enlarge(1);
        },
        .MaybeFencedCodeContent => |*s| {
            _ = s[1].enlarge(1);
        },
        .MaybeParagraphEnd => {
            state.maybeThematicBreak();
        },
        .MaybeFencedCodeEnd => |*s| {
            _ = s.span[1].enlarge(1);
        },
        else => @panic(@tagName(state.state)),
    }
}
