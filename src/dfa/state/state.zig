const utils = @import("../../utils/lib.zig");
const std = @import("std");

const mir = @import("../../mir/lib.zig");
const dfa = @import("../lib.zig");
const smallarr = @import("../../small_arr.zig");

const Block = mir.Block;
const TitleLevel = u8;
const Span = @import("../../utils/lib.zig").Span;
const Allocator = std.mem.Allocator;
const ParseError = dfa.ParseError;
const SmallArray = smallarr.SmallArray;
const Token = @import("../../lexer.zig").Token;
const Line = mir.paragraph.Line;

pub const StateKind = enum {
    const Self = @This();

    /// Begin State
    Empty,

    /// Middle State
    MaybeTitle,
    MaybeTitleContent,
    MaybeTitleId,

    MaybeThematicBreak,

    MaybeBlockQuote,

    MaybeBlockQuoteContent,

    MaybeStrikeThroughBegin,
    MaybeStrikeThroughContent,
    MaybeStrikeThroughEnd,

    MaybeBoldBegin,
    MaybeBoldContent,
    MaybeBoldEnd,

    MaybeItalicBegin,
    MaybeItalicContent,
    MaybeItalicEnd,

    MaybeOrderedList,
    MaybeOrderedListContent,

    MaybeDotList,

    MaybeImageBegin,
    MaybeImageAltBegin,
    MaybeImageAlt,
    MaybeImageAltEnd,
    MaybeImageUrlBegin,
    MaybeImageUrl,
    MaybeImageUrlEnd,

    MaybeHrefTextBegin,
    MaybeHrefText,
    MaybeHrefTextEnd,
    MaybeHrefUrlBegin,
    MaybeHrefUrl,
    MaybeHrefUrlEnd,

    MaybeIndentedCodeBegin,
    MaybeIndentedCodeContent,

    MaybeFencedCodeBegin,
    MaybeFencedCodeMeta,
    MaybeFencedCodeContent,
    // TODO: Lexer should done this for us
    MaybeFencedCodeEnd,

    NormalText,

    MaybeParagraphEnd,

    Done,
};

pub const StateItem = union(StateKind) {
    const Self = @This();

    Empty: void,

    MaybeTitle: usize,
    MaybeTitleContent: usize,
    MaybeTitleId: Span,

    MaybeThematicBreak: usize,

    MaybeBlockQuote: usize,

    MaybeBlockQuoteContent: usize,

    MaybeStrikeThroughBegin: void,
    MaybeStrikeThroughContent: Span,
    MaybeStrikeThroughEnd: void,

    MaybeBoldBegin: void,
    MaybeBoldContent: Span,
    MaybeBoldEnd: void,

    MaybeItalicBegin: void,
    MaybeItalicContent: Span,
    MaybeItalicEnd: void,

    MaybeOrderedList: []const u8,
    MaybeOrderedListContent: void,

    MaybeDotList: void,

    MaybeImageBegin: void,
    MaybeImageAltBegin: void,
    MaybeImageAlt: Span,
    MaybeImageAltEnd: Span,
    MaybeImageUrlBegin: void,
    MaybeImageUrl: Span,
    MaybeImageUrlEnd: void,

    MaybeHrefTextBegin: void,
    MaybeHrefText: Span,
    MaybeHrefTextEnd: void,
    MaybeHrefUrlBegin: void,
    MaybeHrefUrl: Span,
    MaybeHrefUrlEnd: void,

    MaybeIndentedCodeBegin: void,
    MaybeIndentedCodeContent: Span,

    MaybeFencedCodeBegin: usize,
    MaybeFencedCodeMeta: Span,
    MaybeFencedCodeContent: [2]Span,
    // TODO: Lexer should done this for us
    MaybeFencedCodeEnd: struct {
        span: [2]Span,
        count: usize,
        line_end: usize = 0,
    },

    NormalText: Span,

    MaybeParagraphEnd: Span,

    Done: void,

    pub inline fn empty() Self {
        return Self{ .Empty = {} };
    }

    /// construct
    pub inline fn maybeTitle(level: usize) Self {
        return Self{ .MaybeTitle = level };
    }

    /// construct
    pub inline fn maybeThematicBreak(level: u8) Self {
        return Self{ .MaybeThematicBreak = level };
    }

    /// construct
    pub inline fn normalText(span: Span) Self {
        return Self{ .NormalText = span };
    }
};

//TODO: DFA know everyting, store inner info in state, when one inner or some field done, update value content.
pub const State = struct {
    const Self = @This();

    state: StateItem = StateItem.empty(),
    value: ?Block = null,
    allocator: Allocator,
    recover_state: ?StateItem = null,

    pub inline fn kind(self: *const Self) StateKind {
        return @as(StateKind, self.state);
    }

    pub inline fn empty(allocator: Allocator) Self {
        return Self{ .allocator = allocator };
    }

    pub inline fn maybeTitle(self: *Self) void {
        self.state = StateItem.maybeTitle(1);
    }

    pub inline fn maybeTitleContent(self: *Self, level: usize) void {
        self.state = StateItem{ .MaybeTitleContent = level };
    }

    pub inline fn maybeCodeSpan(self: *Self) void {
        self.state = StateItem{ .MaybeFencedCode = {} };
    }

    pub inline fn maybeBlockQuote(self: *Self) void {
        self.state = StateItem{ .MaybeBlockQuote = 1 };
    }

    pub inline fn maybeThematicBreak(self: *Self) void {
        self.state = StateItem.maybeThematicBreak(1);
    }

    pub inline fn maybeImage(self: *Self) void {
        self.state = StateItem{ .MaybeImageBegin = {} };
    }

    pub inline fn toMaybeStrikeThrough(self: *Self, span: Span) void {
        _ = span;
        _ = self;
    }

    pub inline fn toMaybeBoldOrItalic(self: *Self, span: Span) void {
        _ = span;
        _ = self;
    }

    pub inline fn initTitleContent(self: *Self, level: usize, span: Span) ParseError!void {
        std.debug.assert(level <= 6);
        const title = try mir.title.Title.init(self.allocator, @intCast(TitleLevel, level), span);
        self.value = Block{ .Title = title };
        self.state = StateItem.empty();
    }

    pub inline fn initParagraph(self: *Self, span: Span) ParseError!void {
        const paragraph = try mir.paragraph.Paragraph.init(self.allocator, span);
        self.value = Block{ .Paragraph = paragraph };
        self.state = StateItem.empty();
    }

    pub inline fn toNormalText(self: *Self, span: Span) void {
        self.state = StateItem.normalText(span);
    }

    pub inline fn maybeParagraphEnd(self: *Self, span: Span) void {
        self.state = StateItem{ .MaybeParagraphEnd = span };
    }

    pub inline fn maybeOrderedList(self: *Self, num: []const u8) void {
        self.state = StateItem{ .MaybeOrderedList = num };
    }

    pub inline fn done(self: *Self) void {
        self.state = StateItem{ .Done = {} };
    }

    pub inline fn deinit(self: *Self, allocator: Allocator) void {
        if (self.value) |*block| block.deinit(allocator);
    }
};
