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
    switch (bmp_file.dib_header) {
        bmp.DIB_header.BITMAPCOREHEADER => |*header| { dib_header_size = header.*.dib_header_size; },
        bmp.DIB_header.BITMAPV5HEADER => |*header| {
            std.debug.print("DIB Header:\nDIB Header Size: {}\nWidth: {}\nHeight: {}\nPlanes: {}\nBit count: {}\nCompression type: {s}\nSize image: {}\nXpelspermeter: {}\nYpelspermeter: {}\nClrused: {}\nClrimportant: {}\nRed mask: {X}\nGreen mask: {X}\nBlue mask:{X}\nAlpha mask: {X}\nCS Type: {s}\nciexyz red: x: {} y: {} z: {}\nciexyz green: x: {} y: {} z: {}\nciexyz blue: x: {} y: {} z: {}\nGamma red: {}\nGamma green: {}\nGamma blue: {}\nIntent: {s}\n", .{
            header.*.dib_header_size,
            header.*.width,
            header.*.height,
            header.*.planes,
            header.*.bit_count,
            @tagName(header.*.compression_type),
            header.*.size_image,
            header.*.xpelspermeter,
            header.*.ypelspermeter,
            header.*.clrused,
            header.*.clrimportant,
            header.*.redmask,
            header.*.greenmask,
            header.*.bluemask,
            header.*.alphamask,
            @tagName(header.*.cs_type),
            header.*.endpoints.red.x,
            header.*.endpoints.red.y,
            header.*.endpoints.red.z,
            header.*.endpoints.green.x,
            header.*.endpoints.green.y,
            header.*.endpoints.green.z,
            header.*.endpoints.blue.x,
            header.*.endpoints.blue.y,
            header.*.endpoints.blue.z,
            header.*.gamma_red,
            header.*.gamma_green,
            header.*.gamma_blue,
            @tagName(header.*.intent)
            });
        },
        else => {}
    }
}
