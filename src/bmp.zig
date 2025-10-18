const std = @import("std");
const fs = std.fs;

pub const Pixel = @import("pixels.zig");

pub const endianness: std.builtin.Endian = std.builtin.Endian.little;

pub const Raw = @import("raw.zig");
pub const Bmp = @This();

width: u32,
height: u32,
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
    const raw_bmp: Raw = try Raw.parseRaw(raw_file);

    return Bmp{
        .width = raw_bmp.dib_common.width,
        .height = raw_bmp.dib_common.height,
        .pixels = raw_bmp.pixels,
        .arena = raw_bmp.arena
    };
}
