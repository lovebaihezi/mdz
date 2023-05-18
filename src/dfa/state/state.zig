const utils = @import("../../utils/lib.zig");
const std = @import("std");

const mir = @import("../../mir/lib.zig");
const dfa = @import("../lib.zig");
const smallarr = @import("../../small_arr.zig");

const Block = mir.Block;
const TitleLevel = u8;
const Span = @import("../../utils/lib.zig").Span;
const Allocator = std.mem.Allocator;
const Texts = mir.Texts;
const ParseError = dfa.ParseError;
const allocErrorToParseError = dfa.allocErrorToParseError;
const SmallArray = smallarr.SmallArray;

pub const StateKind = enum {
    const Self = @This();

    /// Begin State
    Empty,

    /// Block content begin state
    Content,

    /// Middle State
    MaybeTitle,
    MaybeTitleContent,
    TitleContent,
    MaybeTitleId,
    TitleId,

    MaybeThematicBreak,

    MaybeBlockQuote,

    MaybeBlockQuoteContent,

    MaybeStrikeThrough,

    MaybeBold,

    MaybeItalic,

    MaybeOrderedList,

    MaybeDotList,

    MaybeImage,

    MaybeHref,

    MaybeIndentedCode,

    MaybeFencedCode,

    NormalText,

    MaybeParagraphEnd,

    Done,
};

pub const StateItem = union(StateKind) {
    const Self = @This();

    Empty: void,

    Content: void,

    MaybeTitle: usize,
    MaybeTitleContent: usize,
    TitleContent: void,
    MaybeTitleId: Span,
    TitleId: void,

    MaybeThematicBreak: usize,

    MaybeBlockQuote: usize,

    MaybeBlockQuoteContent: usize,

    //TODO: Paint DFA for Image processing, Url Processing
    //TODO: Fill the Type

    MaybeStrikeThrough: void,

    MaybeBold: void,

    MaybeItalic: void,

    MaybeOrderedList: []const u8,

    MaybeDotList: bool,

    MaybeImage: void,

    MaybeHref: void,

    MaybeIndentedCode: Span,

    MaybeFencedCode: void,

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

    pub inline fn titleContent() Self {
        return Self{
            .TitleContent = {},
        };
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
    stack: SmallArray(StateKind, 128) = undefined,
    allocator: Allocator,

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
        const title = mir.Title.initWithAllocator(self.allocator, @intCast(TitleLevel, level), span) catch |e| {
            return dfa.allocErrorToParseError(e);
        };
        self.value = Block.title(title);
        self.state = StateItem.titleContent();
    }

    pub inline fn initParagraph(self: *Self, span: Span) ParseError!void {
        const paragraph = mir.Paragraph.initWithAllocator(self.allocator, span) catch |e| {
            return allocErrorToParseError(e);
        };
        self.value = Block.paragraph(paragraph);
    }

    pub inline fn toNormalText(self: *Self, span: Span) void {
        self.state = StateItem.normalText(span);
    }

    pub inline fn titleAddPlainText(self: *Self, span: Span) ParseError!void {
        self.value.?.Title.addContent(self.allocator, mir.Inner.plainText(span)) catch |e| {
            return dfa.allocErrorToParseError(e);
        };
    }

    pub inline fn maybeParagraphEnd(self: *Self, span: Span) void {
        self.state = StateItem{ .MaybeParagraphEnd = span };
    }

    pub inline fn paragraphAddLine(self: *Self, span: Span) ParseError!void {
        self.value.?.Paragraph.addPlainText(self.allocator, span) catch |e| {
            return dfa.allocErrorToParseError(e);
        };
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
