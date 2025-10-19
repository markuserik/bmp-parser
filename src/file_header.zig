const std = @import("std");
const fs = std.fs;

const FileHeader = @This();

file_size: u32,
reserved1: [2]u8,
reserved2: [2]u8,
offset: u32,

pub fn parseFileHeader(reader: *std.io.Reader, endianness: std.builtin.Endian) !FileHeader {
    // Discard identifier
    _ = try reader.take(2);

    return FileHeader{
        .file_size = try reader.takeInt(u32, endianness),
        .reserved1 = (try reader.takeArray(2)).*,
        .reserved2 = (try reader.takeArray(2)).*,
        .offset = try reader.takeInt(u32, endianness)
    };
}
