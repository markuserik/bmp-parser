const std = @import("std");
const fs = std.fs;

pub fn main() !void {
    try get_args();
    defer free_args();

    if (args.len != 2) {
        std.debug.print("Expected: {s} input.bmp\n", .{args[0]});
        return;
    }

    const file = try fs.cwd().openFile(args[1], .{});
    defer file.close();

    const file_size = (try file.stat()).size;
    const contents = try file.reader().readAllAlloc(allocator, file_size);
    defer allocator.free(contents);
    for (contents) |byte| {
        std.debug.print("{x}", .{byte});
    }

    std.debug.print("\nLen: {}\n", .{contents.len});
}

var allocator: std.mem.Allocator = undefined;
var args: [][:0]u8 = undefined;

fn get_args() !void {
    allocator = std.heap.c_allocator;
    args = try std.process.argsAlloc(allocator);
}

fn free_args() void {
    std.process.argsFree(allocator, args);
}
