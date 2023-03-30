const std = @import("std");

pub const Pos = struct {
    const Self = Pos;
    line: usize,
    column: usize,
    pub fn default() Pos {
        return Self{
            .line = 0,
            .column = 0,
        };
    }
    pub fn new(line: usize, column: usize) Pos {
        return Self{
            .line = line,
            .column = column,
        };
    }
    pub fn go_left(self: *Self, left: usize) *Self {
        self.column -= left;
        return self;
    }
    pub fn go_right(self: *Self, right: usize) *Self {
        self.column += right;
        return self;
    }
    pub fn go_down(self: *Self, down: usize) *Self {
        self.line += down;
        return self;
    }
    pub fn go_up(self: *Self, up: usize) *Self {
        self.line -= up;
        return self;
    }
    pub fn go_to(self: *Self, line: usize, column: usize) *Self {
        self.line = line;
        self.column = column;
        return self;
    }
    pub fn add(self: *Self, pos: Pos) *Self {
        self.line += pos.line;
        self.column += pos.column;
        return self;
    }
};

pub const Lexer = struct {
    const Self = Lexer;
    buffer: ?*[]const u8,
    pos: Pos,
    index: usize,
    pub fn next_token(self: *self) LexcialError!Token {}
};
