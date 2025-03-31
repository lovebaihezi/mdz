const std = @import("std");
const stateLib = @import("../state/state.zig");
const Span = @import("../../utils/lib.zig").Span;
const Error = @import("../lib.zig").ParseError;
const Decorations = @import("../../mir/lib.zig").Decorations;

const State = stateLib.State;

pub fn code(state: *State, span: Span) Error!void {
    std.debug.assert(span.len == 1);
    switch (state.state) {
        .Empty => {
            state.state = .{
                .MaybeIndentedCodeBegin = {},
            };
        },
        .MaybeIndentedCodeBegin => {
            // state.state = .{
            //     .Empty = {},
            // };
            // const s = Span.new(span.begin - 1, 2);
            // if (state.value == null) {
            //     try state.initParagraph(s);
            //     try state.value.?.Paragraph.addNewLine(state.allocator, s);
            // }
            // var arr = try Decorations.init(state.allocator, 0);
            // try arr.append(state.allocator, .Code);
            // try state.value.?.Paragraph.lines.last_mut().?.contents.append(state.allocator, .{
            //     .Text = .{ .decorations = arr, .span = s },
            // });
            state.state = .{
                .MaybeFencedCodeBegin = 2,
            };
        },
        .MaybeIndentedCodeContent => |s| {
            const whole_span = Span.new(s.begin - 1, s.len + 1);
            if (state.value == null) {
                try state.initParagraph(whole_span);
                try state.value.?.Paragraph.addNewLine(state.allocator, whole_span);
            }
            try state.value.?.addCode(state.allocator, s);
            state.state = .{
                .Empty = {},
            };
        },
        .MaybeFencedCodeBegin => |*size| {
            size.* += 1;
            if (size.* == 3) {
                if (state.value == null) {
                    state.state = .{
                        .MaybeFencedCodeMeta = Span.new(span.begin + 1, 0),
                    };
                } else {
                    state.done();
                    state.recover_state = .{
                        .MaybeFencedCodeMeta = Span.new(span.begin + 1, 0),
                    };
                }
            }
        },
        .MaybeFencedCodeContent => |s| {
            state.state = .{ .MaybeFencedCodeEnd = .{ .span = s, .count = @as(usize, 1) } };
        },
        .MaybeFencedCodeMeta => |*s| {
            _ = s.enlarge(1);
        },
        .MaybeFencedCodeEnd => |*t| {
            const len = t.count;
            if (len >= 3) {
                return error.UnexpectedCodeBlockEndContent;
            } else {
                t.count += 1;
            }
        },
        .MaybeTitle => |level| {
            state.toNormalText(Span.new(span.begin - level, span.len + level));
        },
        .MaybeTitleContent => |level| {
            std.debug.assert(state.value == null);
            try state.initTitleContent(level, span);
            state.state = .{
                .MaybeIndentedCodeBegin = {},
            };
        },
        .NormalText => |s| {
            if (state.value == null) {
                try state.initParagraph(s);
                try state.value.?.Paragraph.addNewLine(state.allocator, s);
            }
            if (state.value) |*v| {
                switch (v.*) {
                    .Title => |*t| {
                        try t.content.addPlainText(state.allocator, s);
                    },
                    .Paragraph => |*p| {
                        try p.addPlainText(state.allocator, s);
                    },
                    else => @panic(@tagName(v.*)),
                }
            }
            state.state = .{
                .MaybeIndentedCodeBegin = {},
            };
        },
        else => @panic(@tagName(state.state)),
    }
}

const Parser = @import("../../parser.zig").Parser;
const mir = @import("../../mir/lib.zig");

//test "indented code test" {
//    const allocator = std.testing.allocator;
//    const buffer = "To import std in zig, just type `const std = @import(\"std\");`";
//    var parser = Parser.init(buffer);
//    var block = try parser.next(allocator);
//    try std.testing.expect(block != null);
//    if (block) |*b| {
//        defer b.deinit(allocator);
//        try std.testing.expectEqual(mir.BlockTag.Paragraph, @as(mir.BlockTag, b.*));
//        const lines = b.Paragraph.lines;
//        try std.testing.expectEqual(@as(usize, 1), lines.len());
//        const line = lines.last();
//        try std.testing.expect(line != null);
//        if (line) |last| {
//            const text = last.contents.last();
//            try std.testing.expect(text != null);
//            const t = text.?.*.Text;
//            const e_t = mir.text.Text.code(Span.new(33, 27));
//            try std.testing.expectEqualStrings("const std = @import(\"std\");", buffer[33 .. 33 + 27]);
//            try std.testing.expectEqual(e_t, t);
//        }
//    }
//}

const d = @import("../../dfa/state/state.zig");
test "empty indented code" {
    const allocator = std.testing.allocator;
    var state = State.empty(allocator);
    try std.testing.expectEqual(d.StateKind.Empty, @as(d.StateKind, state.state));
    try code(&state, Span.new(0, 1));
    try std.testing.expectEqual(d.StateKind.MaybeIndentedCodeBegin, @as(d.StateKind, state.state));
    try code(&state, Span.new(1, 1));
    try std.testing.expectEqual(d.StateKind.MaybeFencedCodeBegin, @as(d.StateKind, state.state));
}
