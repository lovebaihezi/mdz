const std = @import("std");
const State = @import("state/state.zig").State;
const Span = @import("../utils/lib.zig").Span;
const Error = @import("lib.zig").ParseError;
const Token = @import("../lexer.zig").TokenItem;
const mir = @import("../mir/lib.zig");

pub fn f(state: *State, token: Token, span: Span) Error!void {
    switch (state.state) {
        .MaybeFrontmatterContent => |*s| {
            switch (token) {
                .LineEnd => {
                    // We hit a newline. The NEXT chars could be `---`.
                    _ = s.enlarge(span.len);
                    state.state = .{ .MaybeFrontmatterEnd = .{ .span = s.*, .count = 0 } };
                },
                else => {
                    _ = s.enlarge(span.len);
                },
            }
        },
        .MaybeFrontmatterEnd => |*s| {
            switch (token) {
                .Sign => |sign| {
                    if (sign == '-') {
                        s.count += 1;
                    } else {
                        // Not a dash, revert to content
                        _ = s.span.enlarge(s.count + span.len);
                        state.state = .{ .MaybeFrontmatterContent = s.span };
                    }
                },
                .LineEnd => {
                    if (s.count == 3) {
                        // Done!
                        state.value = mir.Block{
                            .Frontmatter = mir.frontmatter.Frontmatter.init(s.span),
                        };
                        state.done();
                    } else {
                        // Not the end, consume what we saw as content
                        _ = s.span.enlarge(s.count + span.len);
                        state.state = .{ .MaybeFrontmatterContent = s.span };
                    }
                },
                else => {
                    // Space, Tab, Str, AsciiNumber...
                    _ = s.span.enlarge(s.count + span.len);
                    state.state = .{ .MaybeFrontmatterContent = s.span };
                },
            }
        },
        else => unreachable,
    }
}
