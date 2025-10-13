const std = @import("std");
const fs = std.fs;

const endianness: std.builtin.Endian = @import("bmp.zig").endianness;

const File_header = @This();

identifier: [2]u8,
file_size: u32,
reserved1: [2]u8,
reserved2: [2]u8,
offset: u32,

pub fn parse_file_header(reader: *std.io.Reader) !File_header {
    return File_header{
        .identifier = (try reader.takeArray(2)).*,
        .file_size = try reader.takeInt(u32, endianness),
        .reserved1 = (try reader.takeArray(2)).*,
        .reserved2 = (try reader.takeArray(2)).*,
        .offset = try reader.takeInt(u32, endianness)
    };
}
