const std = @import("std");
const Lexer = @import("lexer.zig").Lexer;
const Parser = @import("parser.zig").Parser;
const mir = @import("mir/lib.zig");

test "Frontmatter Parsing" {
    const markdown =
        \\---
        \\title: Make Zig Avaliable in Jules Env
        \\author: BoWen Chai
        \\pubDatetime: 2025-12-17T08:45:15.742Z
        \\slug: make-zig-avaliable-in-jules
        \\featured: true
        \\draft: false
        \\tags:
        \\    - Zig
        \\    - Jules
        \\description: How to add Zig programming language compiler to Jules environment
        \\---
        \\# Copy This to Your Jules Env Setup Script
    ;

    var lexer = Lexer.init(markdown);
    var parser = Parser.init(std.testing.allocator);

    // 1. Parse Frontmatter
    const block1 = (try parser.next(&lexer)).?;
    switch (block1) {
        .Frontmatter => |f| {
            // Check span.
            // The content should be everything between the `---` and `---`.
            const content = markdown[f.span.begin .. f.span.begin + f.span.len];
            // std.debug.print("Content: '{s}'\n", .{content});

            try std.testing.expect(std.mem.startsWith(u8, content, "title:"));
            try std.testing.expect(std.mem.endsWith(u8, content, "description: How to add Zig programming language compiler to Jules environment\n"));
        },
        else => {
             std.debug.print("Expected Frontmatter, got {}\n", .{block1});
             try std.testing.expect(false);
        }
    }

    // 2. Parse Title
    const block2 = (try parser.next(&lexer)).?;
    switch (block2) {
        .Title => |t| {
             _ = t;
        },
        else => {
             std.debug.print("Expected Title, got {}\n", .{block2});
             try std.testing.expect(false);
        }
    }
}
