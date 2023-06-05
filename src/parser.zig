const std = @import("std");
const Lexer = @import("lexer.zig").Lexer;
const dfa = @import("dfa/lib.zig");
const mir = @import("mir/lib.zig");

const Allocator = std.mem.Allocator;
const ParseError = dfa.ParseError;
const Block = mir.Block;
const State = dfa.state.State;
const DFA = dfa.DFA;

pub const Parser = struct {
    const Self = @This();

    lexer: Lexer,
    recover_state: ?dfa.state.StateItem = null,

    pub inline fn init(source: []const u8) Self {
        return Self{
            .lexer = Lexer.init(source),
        };
    }

    pub fn next(self: *Self, allocator: Allocator) ParseError!?Block {
        var state = if (self.recover_state) |state| val: {
            const S = State{ .state = state, .allocator = allocator };
            break :val S;
        } else State.empty(allocator);
        while (self.lexer.next()) |value| {
            switch (value.item) {
                .ok => |token| {
                    try DFA.f(&state, token, value.span);
                    switch (state.state) {
                        .Done => {
                            self.recover_state = state.recover_state;
                            return state.value;
                        },
                        else => {
                            continue;
                        },
                    }
                },
                .unexpected => |e| {
                    switch (e) {
                        .unexpectedEOF => {
                            // TODO: Add diagnostic info from lexer
                            break;
                        },
                        .unexpectedControlCode => |c| {
                            std.log.err("unexpected control code: {d}", .{c});
                        },
                    }
                },
            }
        }
        return null;
    }
};

const title1 =
    \\# Title 1
    \\
;
const title2 =
    \\## Title 2
    \\
;
const title3 =
    \\### Title 3 with **bold** and *italic*
    \\
;
const title4 =
    \\#### Title 4 with `code`
    \\
;
const title5 =
    \\##### Title 5 with `code` and **bold**
    \\
;
const title6 =
    \\###### Title 6 with $x \neq y$
    \\
;
const codeBlock =
    \\``` haskell
    \\fib :: Int -> Int
    \\fib 0 = 0
    \\fib 1 = 1
    \\fib n = fib (n - 1) + fib (n - 2)
    \\```
    \\
;

const blockQuote =
    \\> A block quote
    \\
    \\>> A nested block quote
    \\
;
const para =
    \\Lorem[^1] ipsum dolor sit amet, officia excepteur ex fugiat reprehenderit enim labore culpa 
    \\sint ad nisi Lorem pariatur mollit ex esse exercitation amet. Nisi anim cupidatat 
    \\excepteur officia. Reprehenderit nostrud nostrud ipsum Lorem est aliquip amet voluptate 
    \\voluptate dolor minim nulla est proident. Nostrud officia pariatur ut officia. Sit irure 
    \\elit esse ea nulla sunt ex occaecat reprehenderit commodo officia dolor Lorem duis laboris 
    \\cupidatat officia voluptate. Culpa proident adipisicing id nulla nisi laboris ex in Lorem 
    \\sunt duis officia eiusmod. Aliqua reprehenderit commodo ex non excepteur duis sunt velit enim. 
    \\Voluptate laboris sint cupidatat ullamco ut ea consectetur et est culpa et culpa duis.
    \\
;
const table =
    \\|    |Col2|Col3|
    \\|----|----|----|
    \\|Row1|Item|Item|
    \\
;
const url =
    \\Github url is [Github](https://github.com/).
    \\
;
const imageUrl =
    \\Github Icon is ![\[\[Github Icon\]\]](https://github.com).
    \\
;
const latex =
    \\Some LaTex code: $x \times y$
    \\
;
const lists =
    \\1. list 1
    \\2. list 2
    \\3. list 3
    \\    - b list 1
    \\    - a list 2
    \\
;
const themBreak =
    \\---
    \\
;
const checkLIsts =
    \\- [ ] check list 1
    \\- [ ] check list 2
    \\
;
const themBreak2 =
    \\- - - - - - - 
    \\
;
const footnote =
    \\[^1]: Lorem is a placeholder text.
;

const test1Title = "parser test case 1";

test test1Title {
    const seq = [_]Block{};
    const allocator = std.testing.allocator;
    var parser = Parser.init(title1 ++ title2 ++ title3 ++ title4 ++ title5 ++ title6 ++ codeBlock ++ para ++ blockQuote ++ url ++ imageUrl ++ latex ++ lists ++ themBreak ++ checkLIsts ++ footnote);
    for (seq) |cur| {
        const res = try parser.fetch_one(allocator);
        try std.testing.expectEqualDeep(cur, res);
    }
}
