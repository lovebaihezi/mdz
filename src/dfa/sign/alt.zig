const std = @import("std");
const State = @import("../state/state.zig").State;
const Span = @import("../../utils/lib.zig").Span;
const Error = @import("../lib.zig").ParseError;
pub fn alt(state: *State, span: Span) Error!void {
    switch (state.state) {
        .Empty => {
            state.state = .{
                .MaybeHrefTextBegin = {},
            };
        },
        .MaybeHrefTextBegin => {
            state.state = .{
                .MaybeHrefText = span,
            };
        },
        .MaybeHrefText => |*s| {
            _ = s.enlarge(span.len);
        },

        .MaybeIndentedLaTex => {
            state.state = .{
                .MaybeIndentedLaTexContent = span,
            };
        },
        .MaybeIndentedLaTexContent => |*s| {
            _ = s.enlarge(1);
        },
        .MaybeIndentedCodeBegin => {
            state.state = .{
                .MaybeIndentedCodeContent = span,
            };
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
        .MaybeFencedCodeEnd => |*s| {
            if (s.count == 3) {
                return error.UnexpectedCodeBlockEndContent;
            } else {
                _ = s.span[1].enlarge(s.count);
                _ = s.span[1].enlarge(1);
                s.count = 0;
            }
        },
        .MaybeFencedCodeBegin => |size| {
            const whole = Span.new(span.begin - size, 0);
            if (state.value == null) {
                try state.initParagraph(whole);
                try state.value.?.Paragraph.addNewLine(state.allocator, whole);
            }
            switch (state.value.?) {
                .Title => |*t| {
                    try t.content.addPlainText(state.allocator, Span.new(span.begin - size, size));
                },
                .Paragraph => |*p| {
                    try p.addPlainText(state.allocator, Span.new(span.begin, size));
                },
                else => |v| @panic(@tagName(v)),
            }
        },
        else => @panic(@tagName(state.state)),
    }
}
