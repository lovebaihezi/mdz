const std = @import("std");
const State = @import("../state/state.zig").State;
const Span = @import("../../utils/lib.zig").Span;
const Error = @import("../lib.zig").ParseError;
pub fn normal(state: *State, span: Span) Error!void {
    switch (state.state) {
        .Empty => {
            state.toNormalText(span);
        },
        .NormalText => |*s| {
            _ = s.enlarge(span.len);
        },
        .MaybeIndentedCodeBegin => {
            state.initParagraph(Span.new(span.begin + 1, span.len + 1));
            state.state = .{
                .MaybeCodeContent = {},
            };
        },
        .MaybeCodeContent => |*s| {
            _ = s.enlarge(span.len);
        },
        .MaybeCodeEnd => {
            state.state = .Empty;
        },
        else => {},
    }
}
