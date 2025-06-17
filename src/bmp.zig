const std = @import("std");

pub const bmp = struct {
    file_header: bitmap_file_header,
};

const bitmap_file_header = struct {
    identifier: [2]u8,
    file_size: u32,
    reserved1: [2]u8,
    reserved2: [2]u8,
    offset: u32
};

pub fn parse(file_contents: []u8) !bmp {
    const file_header_size: u8 = 14;
    const file_header: bitmap_file_header = try parse_file_header(file_contents[0..file_header_size]);
    return bmp{
        .file_header = file_header
    };
}

fn parse_file_header(file_header_raw: []u8) !bitmap_file_header {
    return bitmap_file_header{
        .identifier = file_header_raw[0..2].*,
        .file_size = try parse_hex(file_header_raw[2..6]),
        .reserved1 = file_header_raw[6..8].*,
        .reserved2 = file_header_raw[8..10].*,
        .offset = try parse_hex(file_header_raw[10..14])
    };
}

fn parse_hex(slice: []u8) !u32 {
    return @as(u32, slice[0]) | @as(u32, slice[1]) << 8 | @as(u32, slice[2]) << 16 | @as(u32, slice[3]) << 24;
}
