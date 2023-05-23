---
Use `wget` to download from ziglang website.

使用Zig语言时，可以通过 `zig init-exe` 来在当前目录新建项目, 随后 `zig build run`。
如果想要测试src目录下的代码，便可以通过`zig test src/main.zig`。

```Zig
const std = @import("std");
pub fn main() !void {
    const stdout_file = std.io.getStdOut();
    var bw = std.io.bufferedWriter(stdout_file);
    var stdout = bw.writer();
    stdout.print("`hello world!`", .{});
    bw.flush();
}
```
