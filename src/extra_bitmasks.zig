const std = @import("std");
const fs = std.fs;

const endianness: std.builtin.Endian = @import("bmp.zig").endianness;

const Extra_bit_masks = @This();

r: u32,
g: u32,
b: u32,
a: ?u32 = null,

pub fn parse_extra_bit_masks(reader: fs.File.Reader, has_alpha: bool) !Extra_bit_masks {
    if (!has_alpha) {
        return Extra_bit_masks{
            .r = try reader.readInt(u32, endianness),
            .g = try reader.readInt(u32, endianness),
            .b = try reader.readInt(u32, endianness)
        };
    }
    return Extra_bit_masks{
        .r = try reader.readInt(u32, endianness),
        .g = try reader.readInt(u32, endianness),
        .b = try reader.readInt(u32, endianness),
        .a = try reader.readInt(u32, endianness)
    };
}
