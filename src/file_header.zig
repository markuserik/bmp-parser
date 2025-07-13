const std = @import("std");
const fs = std.fs;

const endianness: std.builtin.Endian = @import("bmp.zig").endianness;

const File_header = @This();

identifier: [2]u8,
file_size: u32,
reserved1: [2]u8,
reserved2: [2]u8,
offset: u32,

pub fn parse_file_header(reader: fs.File.Reader) !File_header {
    return File_header{
        .identifier = try reader.readBytesNoEof(2),
        .file_size = try reader.readInt(u32, endianness),
        .reserved1 = try reader.readBytesNoEof(2),
        .reserved2 = try reader.readBytesNoEof(2),
        .offset = try reader.readInt(u32, endianness)
    };
}
