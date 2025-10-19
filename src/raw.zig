const std = @import("std");
const fs = std.fs;

pub const Root = @import("bmp.zig");
const endianness = Root.endianness;

pub const FileHeader = @import("file_header.zig");
pub const DIBheader = @import("dib_header.zig").DIBheader;
pub const ExtraBitmasks = @import("extra_bitmasks.zig");
pub const Pixel = @import("pixels.zig");

pub const Bmp = @This();

file_header: FileHeader,
dib_common: DIBheader.Common,
dib_header: DIBheader,
extra_bit_masks: ?ExtraBitmasks,
pixels: [][]Pixel,
arena: std.heap.ArenaAllocator,

pub fn deinit(self: *const Bmp) void {
    self.arena.deinit();
}

pub fn parseFileFromPath(file_path: []const u8) !Bmp {
    const file: fs.File = try fs.cwd().openFile(file_path, .{});
    defer file.close();

    return try parseFile(file);
}

pub fn parseFile(file: fs.File) !Bmp {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator: std.mem.Allocator = gpa.allocator();

    const raw_file: []u8 = try allocator.alloc(u8, (try file.stat()).size);
    _ = try file.read(raw_file);
    defer allocator.free(raw_file);

    return parseRaw(raw_file);
}

pub fn parseRaw(raw_file: []u8) !Bmp {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator: std.mem.Allocator = arena.allocator();

    var reader: std.io.Reader = std.io.Reader.fixed(raw_file);

    const file_header: FileHeader = try FileHeader.parseFileHeader(&reader, endianness);

    const dib_header_type: DIBheader.DIBheaderType = @enumFromInt(try reader.takeInt(u32, endianness));
    const dib_common: DIBheader.Common = try DIBheader.Common.parse(&reader, dib_header_type, endianness);
    const dib_header: DIBheader = try DIBheader.parseDibHeader(&reader, dib_header_type, endianness);

    const extra_bit_masks: ?ExtraBitmasks = try getExtraBitmasks(&reader, dib_header);

    var alpha_mask: u32 = 0;
    var compression_type: ?DIBheader.DIBcompressionType = null;
    
    switch (dib_header) {
        DIBheader.BITMAPCOREHEADER => {},
        DIBheader.BITMAPINFOHEADER => |header| { compression_type = header.compression_type; },
        DIBheader.BITMAPV4HEADER => |header| { alpha_mask = header.alpha_mask; compression_type = header.compression_type; },
        DIBheader.BITMAPV5HEADER => |header| { alpha_mask = header.alpha_mask; compression_type = header.compression_type; },
        else => unreachable
    }

    if (dib_common.bit_count <= 8) {
        std.debug.print("Color table not implemented, bit counts of 8 or lower not supported\n", .{});
        unreachable;
    }

    const gap1: u32 = file_header.offset - (14 + @intFromEnum(dib_header_type));
    _ = try reader.take(gap1);
    
    const has_alpha: bool = checkAlpha(compression_type, dib_common.bit_count, alpha_mask);
    
    const pixels: [][]Pixel = try Pixel.parsePixels(&reader, dib_common.height, dib_common.width, dib_common.bit_count, has_alpha, allocator);

    return Bmp{
        .file_header = file_header,
        .dib_common = dib_common,
        .dib_header = dib_header,
        .extra_bit_masks = extra_bit_masks,
        .pixels = pixels,
        .arena = arena
    };
}

fn checkAlpha(compression_type: ?DIBheader.DIBcompressionType, bit_count: u16, alpha_mask: u32) bool {
    if (compression_type == null) return false;
    if (bit_count != 32) return false;
    if (compression_type == DIBheader.DIBcompressionType.BI_RGB) return true;
    if (alpha_mask != 0xFF000000) return false;
    if (compression_type == DIBheader.DIBcompressionType.BI_BITFIELDS or compression_type == DIBheader.DIBcompressionType.BI_ALPHABITFIELDS) return true;
    return false;
}

fn getExtraBitmasks(reader: *std.io.Reader, dib_header: DIBheader) !?ExtraBitmasks {
    if (dib_header == DIBheader.DIBheaderType.BITMAPINFOHEADER) {
        if (dib_header.BITMAPINFOHEADER.compression_type == DIBheader.DIBcompressionType.BI_BITFIELDS) {
            return try ExtraBitmasks.parseExtraBitmasks(reader, false, endianness);
        }
        else if (dib_header.BITMAPINFOHEADER.compression_type == DIBheader.DIBcompressionType.BI_ALPHABITFIELDS) {
            return try ExtraBitmasks.parseExtraBitmasks(reader, true, endianness);
        }
    }
    return null;
}
