const std = @import("std");
const State = @import("../state/state.zig").State;
const Span = @import("../../utils/lib.zig").Span;
const Error = @import("../lib.zig").ParseError;
pub fn laTex(state: *State, span: Span) Error!void {
    switch (state.state) {
        .Empty => {
            state.state = .{
                .MaybeIndentedLaTex = {},
            };
        },
        .NormalText => |*s| {
            if (state.value == null) {
                try state.initParagraph(s.*);
                try state.value.?.Paragraph.addNewLine(state.allocator, s.clone());
            }
            if (state.value) |*v| {
                switch (v.*) {
                    .Paragraph => |*p| try p.addLaTex(state.allocator, s.clone()),
                    .Title => |*t| try t.content.addLaTex(state.allocator, s.clone()),
                    else => unreachable,
                }
            }
            state.state = .{ .Empty = {} };
        },
        .MaybeIndentedCodeBegin => {
            state.state = .{
                .MaybeIndentedCodeContent = span,
            };
        },
        .MaybeIndentedCodeContent => |*s| {
            _ = s.enlarge(1);
        },
        .MaybeIndentedLaTex => {
            if (state.value == null) {
                try state.initParagraph(Span.new(span.begin - 1, 2));
                try state.initParagraph(Span.new(span.begin - 1, 2));
            }
            if (state.value) |*v| {
                switch (v.*) {
                    .Title => |*t| try t.content.addLaTex(state.allocator, span),
                    .Paragraph => |*p| try p.addLaTex(state.allocator, span),
                    else => unreachable,
                }
            }
        },
        .MaybeIndentedLaTexContent => |s| {
            if (state.value == null) {
                try state.initParagraph(s);
                try state.value.?.Paragraph.addNewLine(state.allocator, s);
            }
            if (state.value) |*v| {
                switch (v.*) {
                    .Paragraph => |*p| try p.addLaTex(state.allocator, s),
                    .Title => |*t| try t.content.addLaTex(state.allocator, s),
                    else => unreachable,
                }
            }
        },
        else => @panic(@tagName(state.state)),
    }
}
