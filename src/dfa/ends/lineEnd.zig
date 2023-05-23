const std = @import("std");
const Span = @import("../../utils/lib.zig").Span;
const dfa = @import("../lib.zig");
const State = dfa.state.State;
const ParseError = dfa.ParseError;
const ReturnType = dfa.ReturnType;
const mir = @import("../../mir/lib.zig");

/// '\n' or '\r\n'
pub inline fn f(state: *State, span: Span) ParseError!ReturnType {
    switch (state.state) {
        .Empty => {},
        .NormalText => |s| {
            if (state.value) |*v| {
                switch (v.*) {
                    .Title => {
                        try v.Title.content.addPlainText(state.allocator, s);
                        state.done();
                    },
                    .Paragraph => {
                        state.maybeParagraphEnd(s);
                        try v.Paragraph.addPlainText(state.allocator, s);
                    },
                    else => @panic(@tagName(state.state)),
                }
            } else {
                try state.initParagraph(s);
                try state.value.?.Paragraph.addPlainText(state.allocator, s);
                state.maybeParagraphEnd(Span.new(span.begin + 1, 0));
            }
        },
        .MaybeParagraphEnd => |s| {
            _ = s;
            if (state.value) |v| {
                switch (v) {
                    .Paragraph => {
                        state.done();
                    },
                    else => @panic(@tagName(state.state)),
                }
            } else {
                unreachable;
            }
        },
        .MaybeIndentedCodeBegin => {
            return error.UnexpectedLineEndInIndentCode;
        },
        .MaybeIndentedCodeContent => {
            return error.UnexpectedLineEndInIndentCode;
        },
        .MaybeFencedCodeBegin => |size| {
            if (size == 3) {
                std.debug.assert(state.value == null);
                state.state = .{
                    .MaybeFencedCodeContent = [2]Span{ Span.new(span.begin - size, 0), Span.new(span.begin + span.len, 0) },
                };
            } else {
                if (state.value == null) {
                    const s = Span.new(span.begin - size, span.len);
                    try state.initParagraph(s);
                    try state.value.?.Paragraph.addNewLine(state.allocator, s);
                } else {
                    try state.value.?.Paragraph.addCode(state.allocator, Span.new(span.begin - size, size));
                }
            }
        },
        .MaybeFencedCodeMeta => |s| {
            state.state = .{ .MaybeFencedCodeEnd = .{
                .span = [2]Span{ s, Span.new(span.begin + 1, 0) },
                .count = 0,
            } };
        },
        .MaybeFencedCodeEnd => |*s| {
            _ = s.span[1].enlarge(1);
        },
        .MaybeThematicBreak => {
            state.value = mir.Block{
                .ThematicBreak = {},
            };
            state.done();
        },
        else => @panic(@tagName(state.state)),
    }
}
