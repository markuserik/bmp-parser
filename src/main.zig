const std = @import("std");
const fs = std.fs;
const bmp = @import("bmp.zig");

pub fn main() !void {
    try get_args();
    defer free_args();

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
    std.debug.print("Identifier: {s}\nFile size: {}\nReserved1: {s}\nReserved2: {s}\nOffset: {}\n", .{
        bmp_file.file_header.identifier,
        bmp_file.file_header.file_size,
        bmp_file.file_header.reserved1,
        bmp_file.file_header.reserved2,
        bmp_file.file_header.offset
    });
}

var allocator: std.mem.Allocator = std.heap.c_allocator;
var args: [][:0]u8 = undefined;

fn get_args() !void {
    args = try std.process.argsAlloc(allocator);
}

fn free_args() void {
    std.process.argsFree(allocator, args);
}
