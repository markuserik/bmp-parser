const std = @import("std");
const fs = std.fs;

pub const File_header = @import("file_header.zig");

pub const DIB_header = @import("dib_header.zig").DIB_header;

pub const Extra_bit_masks = @import("extra_bitmasks.zig");

pub const Pixel = @import("pixels.zig");

pub const bmp = struct {
    file_header: File_header,
    dib_common: DIB_header.common,
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

    var buffer: [1024]u8 = undefined;
    var reader_wrapper = file.reader(&buffer);
    const reader: *std.io.Reader = &reader_wrapper.interface;

    const file_header: File_header = try File_header.parseFileHeader(reader, endianness);

    const dib_header_type: DIB_header.DIB_header_type = @enumFromInt(try reader.takeInt(u32, endianness));
    const dib_common: DIB_header.common = try DIB_header.common.parse(reader, dib_header_type, endianness);
    const dib_header: DIB_header = try DIB_header.parseDibHeader(reader, dib_header_type, endianness);

    var extra_bit_masks: ?Extra_bit_masks = null;

    if (dib_header == DIB_header.DIB_header_type.BITMAPINFOHEADER) {
        if (dib_header.BITMAPINFOHEADER.compression_type == DIB_header.DIB_compression_type.BI_BITFIELDS) {
            extra_bit_masks = try Extra_bit_masks.parseExtraBitMasks(reader, false, endianness);
        }
        else if (dib_header.BITMAPINFOHEADER.compression_type == DIB_header.DIB_compression_type.BI_ALPHABITFIELDS) {
            extra_bit_masks = try Extra_bit_masks.parseExtraBitMasks(reader, true, endianness);
        }
    }

    var alpha_mask: u32 = 0;
    var compression_type: ?DIB_header.DIB_compression_type = null;
    
    switch (dib_header) {
        DIB_header.BITMAPCOREHEADER => {},
        DIB_header.BITMAPINFOHEADER => |header| { compression_type = header.compression_type; },
        DIB_header.BITMAPV4HEADER => |header| { alpha_mask = header.alpha_mask; compression_type = header.compression_type; },
        DIB_header.BITMAPV5HEADER => |header| { alpha_mask = header.alpha_mask; compression_type = header.compression_type; },
        else => unreachable
    }

    if (dib_common.bit_count <= 8) {
        std.debug.print("Color table not implemented, bit counts of 8 or lower not supported\n", .{});
        unreachable;
    }

    const gap1: u32 = file_header.offset - (14 + @intFromEnum(dib_header_type));
    _ = try reader.take(gap1);
    
    const has_alpha: bool = checkAlpha(compression_type, dib_common.bit_count, alpha_mask);
    
    const pixels: [][]Pixel = try Pixel.parsePixels(reader, dib_common.height, dib_common.width, dib_common.bit_count, has_alpha, allocator);

    return bmp{
        .file_header = file_header,
        .dib_common = dib_common,
        .dib_header = dib_header,
        .extra_bit_masks = extra_bit_masks,
        .pixels = pixels,
        .arena = arena
    };
}

fn checkAlpha(compression_type: ?DIB_header.DIB_compression_type, bit_count: u16, alpha_mask: u32) bool {
    if (compression_type == null) return false;
    if (bit_count != 32) return false;
    if (compression_type == DIB_header.DIB_compression_type.BI_RGB) return true;
    if (alpha_mask != 0xFF000000) return false;
    if (compression_type == DIB_header.DIB_compression_type.BI_BITFIELDS or compression_type == DIB_header.DIB_compression_type.BI_ALPHABITFIELDS) return true;
    return false;
}
