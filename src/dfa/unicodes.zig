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
    // std.log.info("handle unicodes: {s} from {d} to {d}\n", .{ string, span.begin, span.begin + span.len });
    std.debug.assert(string.len == span.len);
    switch (state.state) {
        .Empty => {
            state.toNormalText(span);
        },
        .NormalText => |*s| {
            _ = s.enlarge(span.len);
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
                s.count = 0;
            }
        },
        else => @panic(@tagName(state.state)),
    }
}
