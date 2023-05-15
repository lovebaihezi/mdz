const std = @import("std");
const State = dfa.state.State;
const Span = @import("../../utils/lib.zig").Span;
const dfa = @import("../lib.zig");
const ParseError = dfa.ParseError;
const ReturnType = dfa.ReturnType;
/// # F for '#'
pub inline fn f(state: *State, span: Span) ParseError!ReturnType {
    switch (state.state) {
        .Empty => {
            if (state.value) |*value| {
                switch (value.*) {
                    else => @panic(@tagName(state.state)),
                }
            } else {
                state.maybeTitle();
            }
        },
        .MaybeTitle => |*v| {
            const level = v.*;
            std.debug.assert(level != 0);
            if (level < 6) {
                v.* += 1;
            } else {
                const begin = span.begin;
                const len = level;
                const new_span = Span.new(begin - len, len + 1);
                state.toNormalText(new_span);
            }
        },
        .MaybeTitleContent => {
            try state.titleAddPlainText(span);
        },
        .MaybeThematicBreak => |*s| {
            std.debug.assert(s.* >= 1);
            const newSpan = Span.new(span.begin - 1, s.* + 1);
            state.toNormalText(newSpan);
        },
        .NormalText => |*s| {
            _ = s.enlarge(1);
        },
        else => @panic(@tagName(state.state)),
    }
}

// test "F of #: success parse normal title" {
//     const TextKind = imports.mir.TextKind;
//     _ = TextKind;
//     const InnerKind = imports.mir.InnerKind;
//     _ = InnerKind;
//     var allocator = std.testing.allocator;
//     var state = State.empty(allocator);
//     defer state.deinit(allocator);
//     const dfa = @import("../lib.zig");
//     try std.testing.expectEqual(StateKind.Empty, @as(StateKind, state.state));
//     try dfa.f(&state, Token.sign('#'), Span.new(0, 1));
//     try std.testing.expectEqual(StateKind.MaybeTitle, @as(StateKind, state.state));
//     try dfa.f(&state, Token.sign('#'), Span.new(1, 1));
//     try std.testing.expectEqual(StateKind.MaybeTitle, @as(StateKind, state.state));
//     try dfa.f(&state, Token.sign('#'), Span.new(2, 1));
//     try std.testing.expectEqual(StateKind.MaybeTitle, @as(StateKind, state.state));
//     try dfa.f(&state, Token.space(), Span.new(3, 1));
//     try std.testing.expectEqual(StateKind.MaybeTitleContent, @as(StateKind, state.state));
//     const text1 = "MDZ";
//     try dfa.f(&state, Token.str(text1), Span.new(4, text1.len));
//     try std.testing.expectEqual(StateKind.NormalText, @as(StateKind, state.state));
//     try dfa.f(&state, Token.space(), Span.new(7, 1));
//     const text2 = "a";
//     try dfa.f(&state, Token.str(text2), Span.new(8, text2.len));
//     try std.testing.expectEqual(StateKind.NormalText, @as(StateKind, state.state));
//     try dfa.f(&state, Token.lineEnd(), Span.new(9, 1));
//     try std.testing.expectEqual(StateKind.Done, @as(StateKind, state.state));
//     switch (state.state) {
//         .Done => {
//             if (state.value) |value| {
//                 switch (value) {
//                     .Title => |title| {
//                         try std.testing.expectEqual(@as(usize, 1), title.content.items.len);
//                         try std.testing.expectEqual(@as(u8, 3), title.level);
//                         const item = title.content.getLast();
//                         switch (item) {
//                             .Text => |text| {
//                                 switch (text) {
//                                     .Plain => |plain| {
//                                         try std.testing.expectEqual(Span.new(4, 5), plain);
//                                     },
//                                     else => unreachable,
//                                 }
//                             },
//                             else => unreachable,
//                         }
//                     },
//                     else => unreachable,
//                 }
//             }
//         },
//         else => unreachable,
//     }
// }
