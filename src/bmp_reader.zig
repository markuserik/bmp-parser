const std = @import("std");

pub const bmp_reader = struct {
    raw_content: []u8,
    cursor: u32,
    pub fn read2(self: *bmp_reader) [2]u8 {
        defer self.cursor += 2;
        const arr: [2]u8 = .{ self.raw_content[self.cursor], self.raw_content[self.cursor+1] };
        return arr;
    }
    pub fn read4(self: *bmp_reader) [4]u8 {
        defer self.cursor += 4;
        const arr: [4]u8 = .{ self.raw_content[self.cursor], self.raw_content[self.cursor+1], self.raw_content[self.cursor+2], self.raw_content[self.cursor+3] };
        return arr;
    }
};

pub fn create_reader(raw_content: []u8, allocator: std.mem.Allocator) !*bmp_reader {
    const reader: *bmp_reader = try allocator.create(bmp_reader);
    reader.raw_content = raw_content;
    reader.cursor = 0;
    return reader;
}
