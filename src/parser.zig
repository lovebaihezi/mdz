const std = @import("std");
const lexer = @import("lexer.zig");
const mir = @import("mir.zig");
const dfa = @import("dfa.zig");

const Allocator = std.mem.Allocator;
const Lexer = lexer.Lexer;
const Err = lexer.ErrorItem;
const ParseError = dfa.ParseError;
const Block = mir.Block;
const State = dfa.State;
const DFA = dfa.DFA;

pub const Parser = struct {
    const Self = @This();

    lexer: Lexer,
    block: ?Block = null,

    pub inline fn init(source: []const u8) Self {
        return Self{
            .lexer = Lexer.init(source),
        };
    }

    pub fn next(self: *Self) ParseError!?Block {
        var state = State.empty();
        while (self.lexer.next()) |value| {
            switch (value.item) {
                .ok => |token| {
                    try DFA.f(&state, token, value.span);
                },
                .unexpected => |e| {
                    switch (e) {
                        .unexpectedEOF => {
                            dfa.diagnose(Err.unexpectedEOF);
                            break;
                        },
                        .unexpectedControlCode => |c| {
                            std.log.err("unexpected control code: {d}", .{c});
                        },
                    }
                },
            }
        }
        return state.result();
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
    const allocator = std.testing.allocator_instance;
    var parser = Parser.init(title1 ++ title2 ++ title3 ++ title4 ++ title5 ++ title6 ++ codeBlock ++ para ++ blockQuote ++ url ++ imageUrl ++ latex ++ lists ++ themBreak ++ checkLIsts ++ footnote);
    for (seq) |cur| {
        const res = try parser.fetch_one(allocator);
        try std.testing.expectEqualDeep(cur, res);
    }
}
