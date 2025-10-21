const std = @import("std");
const fs = std.fs;

const DIBheader = @import("dib_header.zig").DIBheader;

const ExtraBitmasks = @This();

r: u32,
g: u32,
b: u32,
a: ?u32,

pub fn parseExtraBitmasks(reader: *std.io.Reader, dib_header: DIBheader, endianness: std.builtin.Endian) !?ExtraBitmasks {
    if (dib_header.type == .BITMAPINFOHEADER) {
        if (dib_header.compression_type.? == .BI_BITFIELDS) {
            return ExtraBitmasks{
                .r = try reader.takeInt(u32, endianness),
                .g = try reader.takeInt(u32, endianness),
                .b = try reader.takeInt(u32, endianness),
                .a = null
            };
        }
        else if (dib_header.compression_type.? == .BI_ALPHABITFIELDS) {
            return ExtraBitmasks{
                .r = try reader.takeInt(u32, endianness),
                .g = try reader.takeInt(u32, endianness),
                .b = try reader.takeInt(u32, endianness),
                .a = try reader.takeInt(u32, endianness)
            };
        }
    }
    return null;
}
