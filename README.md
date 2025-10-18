# bmp-parser

A zig parsing library for .bmp files.

# Supported functionality

This library currently only supports the following DIB header types:
```
BITMAPCOREHEADER 
BITMAPINFOHEADER
BITMAPV4HEADER
BITMAPV5HEADER
```

Color table has also not been implemented so bit counts of 8 or lower is not
supported

# Usage

Add it to your project via this command
```sh
zig fetch --save=bmp_parser https://github.com/markuserik/bmp-parser/archive/0.1.0.tar.gz
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
    const bmp: bmp_parser.Bmp = try bmp_parser.parseFileFromPath("images/test.bmp");
    defer bmp.deinit();

    std.debug.print("Height: {}, Width: {}\n", .{bmp.height, bmp.width});
}
```
This way the parser will handle the bmp logic and provide a struct containing only a 2d array of pixels (plus both height and width for convenience).

Alternatively, use bmp_parser.Raw to get a raw struct with all the raw values.
```zig
const std = @import("std");
const bmp_parser = @import("bmp_parser").Raw;

pub fn main() !void {
    const bmp: bmp_parser.Bmp = try bmp_parser.parseFileFromPath("images/test.bmp");
    defer bmp.deinit();

    std.debug.print("Height: {}, Width: {}\n", .{bmp.dib_common.height, bmp.dib_common.width});
}
```
