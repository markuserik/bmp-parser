const std = @import("std");
const fs = std.fs;
const bmp = @import("bmp.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator: std.mem.Allocator = gpa.allocator();
    const args: [][:0]u8 = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len != 2) {
        std.debug.print("Expected: {s} input.bmp\n", .{args[0]});
        return;
    }

    const file: fs.File = try fs.cwd().openFile(args[1], .{});
    defer file.close();

    const file_size: u64 = (try file.stat()).size;
    const contents: []u8 = try file.reader().readAllAlloc(allocator, file_size);
    defer allocator.free(contents);

    const bmp_file: bmp.bmp = try bmp.parse(contents);
    std.debug.print("File Header:\nIdentifier: {s}\nFile size: {}\nReserved1: {s}\nReserved2: {s}\nOffset: {}\n\n", .{
        bmp_file.file_header.identifier,
        bmp_file.file_header.file_size,
        bmp_file.file_header.reserved1,
        bmp_file.file_header.reserved2,
        bmp_file.file_header.offset
    });
    
    var dib_header_size: u32 = 0;
    var width: u32 = 0;
    var height: u32 = 0;
    var planes: u16 = 0;
    var bit_count: u16 = 0;
    switch (bmp_file.dib_header) {
        bmp.DIB_header.BITMAPCOREHEADER => |*header| { dib_header_size = header.*.dib_header_size; },
        bmp.DIB_header.BITMAPV5HEADER => |*header| {
            dib_header_size = header.*.dib_header_size; 
            width = header.*.width;
            height = header.*.height;
            planes = header.*.planes;
            bit_count = header.*.bit_count;
        },
        else => {}
    }

    std.debug.print("DIB Header:\nDIB Header Size: {}\nWidth: {}\nHeight: {}\nPlanes: {}\nBit count: {}\n", .{
        dib_header_size,
        width,
        height,
        planes,
        bit_count
    });
}
