const utils = @import("utils.zig");
const mir = @import("mir.zig");

const Block = mir.Block;
const Span = utils.Span;

pub const StateKind = enum {
    const Self = @This();

    /// Begin State
    Empty,
    /// Middle State
    MaybeTitle,

    MaybeThematicBreak,

    MaybeBlockQuote,

    MaybeStrikeThrough,

    MaybeBold,

    MaybeItalic,

    MaybeItalicAndBold,

    MaybeOrderedList,

    MaybeDotList,

    MaybeImageUrl,

    MaybeUrl,

    MaybeIndentedCode,

    MaybeFencedCode,

    /// Inf Maybe End
    NormalText,
};

pub const StateItem = union(StateKind) {
    const Self = @This();

    Empty: void,

    MaybeTitle: mir.Title,

    MaybeThematicBreak: Span,

    MaybeBlockQuote: mir.Quote,

    MaybeOrderedList: mir.Block,

    MaybeDotList: mir.Block,

    MaybeImage: mir.Image,

    MaybeHref: mir.Href,

    MaybeCodeSpan: Span,

    MaybeFencedCode: mir.CodeBlock,

    NormalText: Span,

    pub inline fn empty() Self {
        return Self{ .Empty = {} };
    }

    /// construct
    pub inline fn maybeTitle(span: Span) Self {
        return Self{ .MaybeTitle = [3]Span{ span, undefined, undefined } };
    }

    /// construct
    pub inline fn maybeThematicBreak(span: Span) Self {
        return Self{ .MaybeThematicBreak = span };
    }

    /// construct
    pub inline fn normalText(span: Span) Self {
        return Self{ .NormalText = span };
    }
};

pub const State = struct {
    const Self = @This();

    state: StateItem = StateItem.empty(),
    block: ?Block = null,

    pub inline fn empty() Self {
        return Self{};
    }
    pub inline fn fromItem(item: StateItem) Self {
        return Self{
            .state = item,
        };
    }
    pub inline fn toNormalText(self: *Self, span: Span) void {
        self.state = StateItem.normalText(span);
    }
};
