const std = @import("std");

const TestCase = struct {
    const Self = @This();
    const json = std.json;
    //{
    //  "markdown": "### Title {#id-1}",
    //  "result": [],
    //  "section": "Tabs"
    //},
    const TestCaseItem = struct {
        markdown: []const u8,
        section: []const u8,
    };
    const TestCaseArray = json.Array(TestCaseItem);
};
