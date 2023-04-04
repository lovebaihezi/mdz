const std = @import("std");
const Allocator = std.mem.Allocator;
const lexer = @import("lexer.zig");
const Lexer = lexer.Lexer;

const SyntaxTreeNodeTag = enum {};

const SyntaxTreeNode = union(SyntaxTreeNodeTag) {};

const SyntaxTree = struct {
    const Self = @This();
    const TokenItem = lexer.TokenItem;
    const array = std.ArrayListUnmanaged(SyntaxTreeNode);

    synSeq: array,
    allocator: Allocator,

    pub fn initWithAllocator(allocator: Allocator) !Self {
        return Self{
            .synSeq = array.initCapacity(allocator, 1),
        };
    }
};

const ParseError = error{};

const Parser = struct {
    const Self = @This();

    lexer: Lexer,

    pub fn init(source: []const u8) Self {
        return Self{
            .lexer = Lexer.init(source),
        };
    }

    pub fn parse(self: *Self, allocator: Allocator) ParseError!SyntaxTree {
        var tree = SyntaxTree.initWithAllocator(allocator);
        while (self.lexer.next()) |value| {
            switch (value.item()) {
                .ok => |item| {
                    _ = try tree.addToken(item);
                },
                .unexpected => |e| {
                    _ = e;
                },
            }
        }
        return tree;
    }
};
