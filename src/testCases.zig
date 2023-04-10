const std = @import("std");

const TestCase = struct {
    const Self = @This();
    const testDataText = @embedFile("./markdown.json");
    const json = std.json;
    // {
    //   "markdown": "\tfoo\tbaz\t\tbim\n",
    //   "html": "<pre><code>foo\tbaz\t\tbim\n</code></pre>\n",
    //   "example": 1,
    //   "start_line": 356,
    //   "end_line": 361,
    //   "section": "Tabs"
    // },
    const TestCaseItem = struct {
        markdown: []const u8,
        html: []const u8,
        example: usize,
        section: []const u8,
    };
    const TestCaseArray = json.Array(TestCaseItem);
    const testData = data: {
        var stream = json.TokenStream.init(testDataText);
        const res = json.parse(TestCaseArray, &stream, .{});
        break :data res catch unreachable;
    };
};
