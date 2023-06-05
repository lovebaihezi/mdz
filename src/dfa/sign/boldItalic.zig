const std = @import("std");
const State = @import("../state/state.zig").State;
const Span = @import("../../utils/lib.zig").Span;
const Error = @import("../lib.zig").ParseError;

pub fn boldItalic(state: *State, span: Span) Error!void {
    switch (state.state) {
        .Empty => {
            state.state = .{
                .MaybeItalicBegin = {},
            };
        },
        .MaybeItalicBegin => {
            state.state = .{
                .MaybeBoldBegin = {},
            };
        },
        .MaybeIndentedCodeBegin => {
            state.state = .{
                .MaybeIndentedCodeContent = span,
            };
        },
        .MaybeFencedCodeContent => |*s| {
            _ = s[1].enlarge(1);
        },
        .MaybeIndentedCodeContent => |*s| {
            _ = s.enlarge(1);
        },
        else => @panic(@tagName(state.state)),
    }
}
