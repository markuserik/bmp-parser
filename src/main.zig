const std = @import("std");

pub fn main() !void {
    try get_args();
    defer free_args();

    if (args.len != 2) {
        std.debug.print("Expected: {s} input.bmp\n", .{args[0]});
        return;
    }
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
