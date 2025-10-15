# bmp-parser

A zig parsing library for .bmp files.

# Usage

Add it to your project via this command
```sh
zig fetch --save=bmp_parser git+https://github.com/markuserik/bmp-parser
```

Then add these lines to your build.zig
```zig
const bmp_dep = b.dependency("bmp_parser", .{ .target = target, .optimize = optimize });
exe.root_module.addImport("bmp_parser", bmp_dep.module("bmp_parser"));
```

After that use it like this in your code
```zig
const std = @import("std");
const bmp_parser = @import("bmp_parser");

pub fn main() !void {
    const bmp: bmp_parser.bmp = try bmp_parser.parse("images/test.bmp");
    defer bmp.deinit();

    std.debug.print("Height: {}, Width: {}\n", .{bmp.dib_common.height, bmp.dib_common.width});
}
```
