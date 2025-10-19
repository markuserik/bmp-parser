const std = @import("std");
const fs = std.fs;

const ExtraBitmasks = @This();

r: u32,
g: u32,
b: u32,
a: ?u32,

pub fn parseExtraBitmasks(reader: *std.io.Reader, has_alpha: bool, endianness: std.builtin.Endian) !ExtraBitmasks {
    return ExtraBitmasks{
        .r = try reader.takeInt(u32, endianness),
        .g = try reader.takeInt(u32, endianness),
        .b = try reader.takeInt(u32, endianness),
        .a = if (!has_alpha) null else try reader.takeInt(u32, endianness)
    };
}
