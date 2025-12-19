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
                    .Title => {
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
            switch (s.line_end) {
                0 => {
                    if (s.count == 3) {
                        s.line_end += span.len;
                    } else {
                        _ = s.span[1].enlarge(s.count + span.len);
                        s.count = 0;
                    }
                },
                else => {
                    if (s.count == 3) {
                        std.debug.assert(state.value == null);
                        state.value = mir.Block{
                            .Code = .{
                                .metadata = s.span[0],
                                // TODO: store line end length to make sure take correct str
                                .codes = s.span[1],
                                .span = Span.new(s.span[0].begin - 3, s.span[1].len + s.span[0].len + s.line_end + span.len + 3),
                            },
                        };
                        state.done();
                    } else {
                        _ = s.span[1].enlarge(s.count + span.len);
                        s.count = 0;
                    }
                },
            }
        },
        .MaybeThematicBreak => |size| {
            if (state.is_document_start and size == 3) {
                // Transition to Frontmatter content
                // The content starts AFTER the newline, so we will set the span begin to next char
                // But `span` here is the LineEnd token.
                // The next token will be handled by next call.
                // We should initialize MaybeFrontmatterContent with a zero-length span at the end of this LineEnd.
                state.state = .{ .MaybeFrontmatterContent = Span.new(span.begin + span.len, 0) };
            } else {
                state.value = mir.Block{
                    .ThematicBreak = {},
                };
                state.done();
            }
        },
        .MaybeFrontmatterContent => |s| {
            // Newline inside frontmatter.
            // Potentially starting the end fence on the next line.
            var new_s = s;
            _ = new_s.enlarge(span.len);
            state.state = .{ .MaybeFrontmatterEnd = .{ .span = new_s, .count = 0 } };
        },
        .MaybeFrontmatterEnd => |*s| {
            if (s.count == 3) {
                // Done!
                state.value = mir.Block{
                    .Frontmatter = mir.frontmatter.Frontmatter.init(s.span),
                };
                state.done();
            } else {
                // Not the end, consume what we saw as content
                _ = s.span.enlarge(s.count + span.len);
                // Back to content state, but actually we can just stay in End state or reset count?
                // Easier to go back to Content state to avoid complexity
                state.state = .{ .MaybeFrontmatterContent = s.span };
            }
        },
        else => @panic(@tagName(state.state)),
    }
}
