const std = @import("std");
const fs = std.fs;

pub const File_header = @import("file_header.zig");

pub const DIB_header = @import("dib_header.zig").DIB_header;

pub const Extra_bit_masks = @import("extra_bitmasks.zig");

pub const Pixel = @import("pixels.zig");

pub const bmp = struct {
    file_header: File_header,
    dib_header: DIB_header,
    extra_bit_masks: ?Extra_bit_masks,
    pixels: [][]Pixel,
    arena: std.heap.ArenaAllocator,

    pub fn deinit(self: *const bmp) void {
        self.arena.deinit();
    }
};

pub const endianness: std.builtin.Endian = std.builtin.Endian.little;

pub fn parse(file_path: []const u8) !bmp {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator: std.mem.Allocator = arena.allocator();

    const file: fs.File = try fs.cwd().openFile(file_path, .{});
    defer file.close();
    var reader: fs.File.Reader = file.reader();

    const file_header: File_header = try File_header.parse_file_header(reader);

    const dib_header_type: DIB_header.DIB_header_type = @enumFromInt(try reader.readInt(u32, endianness));
    const dib_header: DIB_header = try DIB_header.parse_dib_header(reader, dib_header_type);

    var extra_bit_masks: ?Extra_bit_masks = null;

    if (dib_header == DIB_header.DIB_header_type.BITMAPINFOHEADER) {
        if (dib_header.BITMAPINFOHEADER.compression_type == DIB_header.DIB_compression_type.BI_BITFIELDS) {
            extra_bit_masks = try Extra_bit_masks.parse_extra_bit_masks(reader, false);
        }
        else if (dib_header.BITMAPINFOHEADER.compression_type == DIB_header.DIB_compression_type.BI_ALPHABITFIELDS) {
            extra_bit_masks = try Extra_bit_masks.parse_extra_bit_masks(reader, true);
        }
    }

    var height: u32 = 0;
    var width: u32 = 0;
    var bit_count: u16 = 0;
    var alpha_mask: u32 = 0;
    var compression_type: ?DIB_header.DIB_compression_type = null;
    
    switch (dib_header) {
        DIB_header.BITMAPCOREHEADER => |header| { height = @as(u32, header.height); width = @as(u32, header.width); bit_count = header.bit_count; },
        DIB_header.BITMAPINFOHEADER => |header| { height = header.height; width = header.width; bit_count = header.bit_count; compression_type = header.compression_type; },
        DIB_header.BITMAPV4HEADER => |header| { height = header.height; width = header.width; bit_count = header.bit_count; alpha_mask = header.alpha_mask; compression_type = header.compression_type; },
        DIB_header.BITMAPV5HEADER => |header| { height = header.height; width = header.width; bit_count = header.bit_count; alpha_mask = header.alpha_mask; compression_type = header.compression_type; },
        else => unreachable
    }

    if (bit_count <= 8) {
        std.debug.print("Color table not implemented, bit counts of 8 or lower not supported\n", .{});
        unreachable;
    }

    const gap1: u32 = file_header.offset - (14 + @intFromEnum(dib_header_type));
    try reader.skipBytes(gap1, .{});
    
    const has_alpha: bool = check_alpha(compression_type, bit_count, alpha_mask);
    
    const pixels: [][]Pixel = try Pixel.parse_pixels(reader, height, width, bit_count, has_alpha, allocator);

    return bmp{
        .file_header = file_header,
        .dib_header = dib_header,
        .extra_bit_masks = extra_bit_masks,
        .pixels = pixels,
        .arena = arena
    };
}


fn check_alpha(compression_type: ?DIB_header.DIB_compression_type, bit_count: u16, alpha_mask: u32) bool {
    if (compression_type == null) return false;
    if (bit_count != 32) return false;
    if (compression_type == DIB_header.DIB_compression_type.BI_RGB) return true;
    if (alpha_mask != 0xFF000000) return false;
    if (compression_type == DIB_header.DIB_compression_type.BI_BITFIELDS or compression_type == DIB_header.DIB_compression_type.BI_ALPHABITFIELDS) return true;
    return false;
}
