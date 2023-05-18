const std = @import("std");
const Span = @import("../../utils/lib.zig").Span;
const dfa = @import("../lib.zig");

const State = dfa.state.State;
const ParseError = dfa.ParseError;
const ReturnType = dfa.ReturnType;

/// # F for end of file
pub inline fn f(state: *State, span: Span) ParseError!ReturnType {
    _ = span;
    switch (state.state) {
        .Empty => {
            state.done();
        },
        .NormalText => |s| {
            if (state.value) |v| {
                switch (v) {
                    .Title => {
                        try state.titleAddPlainText(s);
                    },
                    .Paragraph => {
                        try state.paragraphAddLine(s);
                    },
                    else => @panic(@tagName(state.state)),
                }
            } else {
                try state.initParagraph(s);
                try state.paragraphAddLine(s);
            }
            state.done();
        },
        .MaybeParagraphEnd => |s| {
            try state.paragraphAddLine(s);
            state.done();
        },
        .Done => {},
        else => {
            @panic(@tagName(state.state));
        },
    }
}
