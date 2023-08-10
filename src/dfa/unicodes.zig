const std = @import("std");
const State = dfa.state.State;
const Span = @import("../utils/lib.zig").Span;
const dfa = @import("lib.zig");
const mir = @import("../mir/lib.zig");
const ParseError = dfa.ParseError;
const ReturnType = dfa.ReturnType;
const allocErrorToParseError = dfa.allocErrorToParseError;

/// # F for \unicode+
pub inline fn f(state: *State, string: []const u8, span: Span) ParseError!ReturnType {
    std.debug.assert(string.len == span.len);
    switch (state.state) {
        .Empty => {
            state.toNormalText(span);
        },
        .NormalText => |*s| {
            _ = s.enlarge(span.len);
        },
        .MaybeTitle => |level| {
            state.toNormalText(Span.new(span.begin - level, span.len + level));
        },
        .MaybeTitleContent => |s| {
            if (s > 6) {
                state.toNormalText(Span.new(span.begin - s, span.len + s));
            } else {
                state.value = mir.Block{
                    .Title = try mir.title.Title.init(state.allocator, @intCast(s), span),
                };
                state.toNormalText(span);
            }
        },
        .MaybeIndentedLaTex => {
            state.state = .{
                .MaybeIndentedLaTexContent = span,
            };
        },
        .MaybeIndentedLaTexContent => |*s| {
            _ = s.enlarge(string.len);
        },
        .MaybeParagraphEnd => |s| {
            if (state.value == null) {
                try state.initParagraph(s);
            }
            try state.value.?.Paragraph.addNewLine(state.allocator, s);
            state.toNormalText(span);
        },
        .MaybeIndentedCodeBegin => {
            state.state = .{
                .MaybeIndentedCodeContent = span,
            };
        },
        .MaybeIndentedCodeContent => |*s| {
            _ = s.enlarge(string.len);
        },
        .MaybeFencedCodeMeta => |*s| {
            _ = s.enlarge(string.len);
        },
        .MaybeFencedCodeContent => |*s| {
            _ = s[1].enlarge(string.len);
        },
        .MaybeFencedCodeEnd => |*s| {
            if (s.count == 3) {
                return error.UnexpectedCodeBlockEndContent;
            } else {
                _ = s.span[1].enlarge(s.count);
                _ = s.span[1].enlarge(string.len);
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
