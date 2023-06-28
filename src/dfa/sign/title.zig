const std = @import("std");
const State = @import("../state/state.zig").State;
const Span = @import("../../utils/lib.zig").Span;
const Error = @import("../lib.zig").ParseError;
pub fn title(state: *State, span: Span) Error!void {
    switch (state.state) {
        .Empty => {
            state.state = .{
                .MaybeTitle = 1,
            };
        },
        .MaybeTitle => |*size| {
            size.* += 1;
        },
        .MaybeIndentedCodeBegin => {
            state.state = .{
                .MaybeIndentedCodeContent = span,
            };
        },
        .MaybeFencedCodeBegin => |s| {
            if (state.value == null) {
                try state.initParagraph(Span.new(span.begin - s, span.len + s));
            }
            try state.value.?.Paragraph.addCode(state.allocator, Span.new(span.begin - s + 1, 0));
            state.toNormalText(span);
        },
        .MaybeTitleContent => |level| {
            std.debug.assert(state.value == null);
            try state.initTitleContent(level, span);
            state.toNormalText(span);
        },
        .NormalText => |*s| {
            _ = s.enlarge(span.len);
        },
        .MaybeFencedCodeEnd => |*s| {
            _ = s.span[1].enlarge(1);
        },
        .MaybeParagraphEnd => {
            state.done();
            state.recover_state = .{ .MaybeTitle = span.len };
        },
        else => @panic(@tagName(state.state)),
    }
}
