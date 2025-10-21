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
    errdefer arena.deinit();

    var reader: std.io.Reader = std.io.Reader.fixed(raw_file);

    const file_header: FileHeader = try FileHeader.parseFileHeader(&reader, endianness);

    const dib_header: DIBheader = try DIBheader.parseDibHeader(&reader, allocator, endianness);

    const extra_bit_masks: ?ExtraBitmasks = try ExtraBitmasks.parseExtraBitmasks(&reader, dib_header, endianness);

    if (dib_header.bit_count <= 8) {
        std.debug.print("Color table not implemented, bit counts of 8 or lower not supported\n", .{});
        return error.ColorTableNotImplemented;
    }

    const gap1: u32 = file_header.offset - (14 + @intFromEnum(dib_header.type));
    _ = try reader.take(gap1);
    
    const has_alpha: bool = checkAlpha(dib_header.compression_type, dib_header.bit_count, dib_header.alpha_mask);
    
    const pixels: [][]Pixel = try Pixel.parsePixels(&reader, dib_header.height, dib_header.width, dib_header.bit_count, has_alpha, allocator);

    return Bmp{
        .file_header = file_header,
        .dib_header = dib_header,
        .extra_bit_masks = extra_bit_masks,
        .pixels = pixels,
        .arena = arena
    };
}

fn checkAlpha(compression_type: ?DIBheader.DIBcompressionType, bit_count: u16, alpha_mask: ?u32) bool {
    if (compression_type == null) return false;
    if (bit_count != 32) return false;
    if (compression_type == .BI_RGB) return true;
    if (alpha_mask != 0xFF000000) return false;
    if (compression_type == .BI_BITFIELDS or compression_type == .BI_ALPHABITFIELDS) return true;
    return false;
}
