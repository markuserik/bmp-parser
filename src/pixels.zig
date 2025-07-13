const std = @import("std");
const fs = std.fs;

const Pixel = @This();

r: u8,
g: u8,
b: u8,
a: ?u8,

pub fn parse_pixels(reader: fs.File.Reader, height: u32, width: u32, bit_count: u16, has_alpha: bool, allocator: std.mem.Allocator) ![][]Pixel {
    var pixels: [][]Pixel = try allocator.alloc([]Pixel, height);
    for (0..pixels.len) |i| {
        pixels[i] = try allocator.alloc(Pixel, width);
    }
    const row_len: u32 = (bit_count / 8) * width;
    const remainder: u32 = row_len % 4;
    const padding: u32 = (4 - remainder) * @intFromBool(remainder != 0);
    for (0..height) |y| {
        for (0..width) |x| {
            if (has_alpha) {
                const raw_pixel: [4]u8 = try reader.readBytesNoEof(4);
                pixels[y][x].r = raw_pixel[0];
                pixels[y][x].g = raw_pixel[1];
                pixels[y][x].b = raw_pixel[2];
                pixels[y][x].a = raw_pixel[3];
            }
            else {
                switch (bit_count) {
                    24 => {
                        const raw_pixel: [3]u8 = try reader.readBytesNoEof(3);
                        pixels[y][x].r = raw_pixel[0];
                        pixels[y][x].g = raw_pixel[1];
                        pixels[y][x].b = raw_pixel[2];
                        pixels[y][x].a = null;
                    },
                    32 => {
                        const raw_pixel: [4]u8 = try reader.readBytesNoEof(4);
                        pixels[y][x].r = raw_pixel[0];
                        pixels[y][x].g = raw_pixel[1];
                        pixels[y][x].b = raw_pixel[2];
                        pixels[y][x].a = null;
                    },
                    else => { std.debug.print("Bit count not supported\n", .{}); unreachable; }
                }
            }
        }
        _ = try reader.skipBytes(padding, .{});
    }

    const len: usize = pixels.len / 2;
    for (0..len) |i| {
        const temp = pixels[i];
        pixels[i] = pixels[pixels.len - i - 1];
        pixels[pixels.len - i - 1] = temp;
    }
    
    return pixels;
}
