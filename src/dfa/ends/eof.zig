const std = @import("std");
const Span = @import("../../utils/lib.zig").Span;
const dfa = @import("../lib.zig");

const State = dfa.state.State;
const ParseError = dfa.ParseError;
const ReturnType = dfa.ReturnType;
const mir = @import("../../mir/lib.zig");

/// # F for end of file
pub inline fn f(state: *State, span: Span) ParseError!ReturnType {
    _ = span;
    switch (state.state) {
        .Empty => {
            state.done();
        },
        .Done => {},
        .NormalText => |s| {
            if (state.value) |*value| {
                try value.Paragraph.addNewLine(state.allocator, s);
                try value.Paragraph.addPlainText(state.allocator, s);
            } else {
                try state.initParagraph(s);
                try state.value.?.Paragraph.addNewLine(state.allocator, s);
                try state.value.?.Paragraph.addPlainText(state.allocator, s);
            }
        },
        .MaybeIndentedCodeContent => {
            return error.UnexpectedEOFOfIndentCode;
        },
        .MaybeFencedCodeEnd => |s| {
            if (s.count == 3) {
                state.done();
                state.value = mir.Block{ .Code = .{
                    .metadata = s.span[0],
                    .codes = s.span[1],
                    .span = Span.new(s.span[0].begin - 3, s.span[0].len + s.span[1].len + 7),
                } };
            } else {
                return error.CodeBlockNotClosed;
            }
        },
        .MaybeParagraphEnd => {
            state.done();
        },
        else => {
            @panic(@tagName(state.state));
        },
    }
}
