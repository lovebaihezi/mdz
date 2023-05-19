const std = @import("std");
const Span = @import("../../utils/lib.zig").Span;
const dfa = @import("../lib.zig");
const State = dfa.state.State;
const ParseError = dfa.ParseError;
const ReturnType = dfa.ReturnType;

/// '\n' or '\r\n'
pub inline fn f(state: *State, span: Span) ParseError!ReturnType {
    _ = span;
    switch (state.state) {
        .Empty => {},
        .NormalText => |s| {
            if (state.value) |v| {
                switch (v) {
                    .Title => {
                        state.done();
                    },
                    .Paragraph => {
                        state.maybeParagraphEnd(s);
                    },
                    else => @panic(@tagName(state.state)),
                }
            } else {
                try state.initParagraph(s);
                state.maybeParagraphEnd(s);
            }
        },
        .MaybeParagraphEnd => |s| {
            if (state.value) |v| {
                switch (v) {
                    .Paragraph => {
                        state.done();
                    },
                    else => @panic(@tagName(state.state)),
                }
            } else {
                try state.initParagraph(s);
                state.maybeParagraphEnd(s);
            }
            state.done();
        },
        else => @panic(@tagName(state.state)),
    }
}
