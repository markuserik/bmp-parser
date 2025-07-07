const std = @import("std");
const fs = std.fs;

pub const bmp = struct {
    file_header: bitmap_file_header,
    dib_header: DIB_header,
    extra_bit_masks: ?extra_bitmasks,
    pixel_array: [][]pixel,
    allocator: std.mem.Allocator,

    pub fn free_bmp(self: *const bmp) void {
        for (0..self.*.pixel_array.len) |i| {
            self.*.allocator.free(self.*.pixel_array[i]);
        }
        self.*.allocator.free(self.*.pixel_array);
    }
};

const bitmap_file_header = struct {
    identifier: [2]u8,
    file_size: u32,
    reserved1: [2]u8,
    reserved2: [2]u8,
    offset: u32
};

pub const DIB_header = union(DIB_header_type) {
    BITMAPCOREHEADER: DIB_header_BITMAPCOREHEADER,
    OS22XBITMAPHEADER_16: DIB_header_OS22XBITMAPHEADER_16,
    BITMAPINFOHEADER: DIB_header_BITMAPINFOHEADER,
    BITMAPV2INFOHEADER: DIB_header_BITMAPV2INFOHEADER,
    BITMAPV3INFOHEADER: DIB_header_BITMAPV3INFOHEADER,
    OS22XBITMAPHEADER_64: DIB_header_OS22XBITMAPHEADER_64,
    BITMAPV4HEADER: DIB_header_BITMAPV4HEADER,
    BITMAPV5HEADER: DIB_header_BITMAPV5HEADER
};
 
const DIB_header_BITMAPCOREHEADER = struct {
    dib_header_size: u32,
    width: u16,
    height: u16,
    planes: u16,
    bit_count: u16
};
const DIB_header_OS22XBITMAPHEADER_16 = struct {
};
const DIB_header_BITMAPINFOHEADER = struct {
    dib_header_size: u32,
    width: u32,
    height: u32,
    planes: u16,
    bit_count: u16,
    compression_type: DIB_compression_type,
    size_image: u32,
    xpelspermeter: u32,
    ypelspermeter: u32,
    clrused: u32,
    clrimportant: u32
};
const DIB_header_BITMAPV2INFOHEADER = struct {
};
const DIB_header_BITMAPV3INFOHEADER = struct {
};
const DIB_header_OS22XBITMAPHEADER_64 = struct {
};
const DIB_header_BITMAPV4HEADER = struct {
    dib_header_size: u32,
    width: u32,
    height: u32,
    planes: u16,
    bit_count: u16,
    compression_type: DIB_compression_type,
    size_image: u32,
    xpelspermeter: u32,
    ypelspermeter: u32,
    clrused: u32,
    clrimportant: u32,
    redmask: u32,
    greenmask: u32,
    bluemask: u32,
    alpha_mask: u32,
    cs_type: CS_type,
    endpoints: ciexyztriple,
    gamma_red: u32,
    gamma_green: u32,
    gamma_blue: u32
};
const DIB_header_BITMAPV5HEADER = struct {
    dib_header_size: u32,
    width: u32,
    height: u32,
    planes: u16,
    bit_count: u16,
    compression_type: DIB_compression_type,
    size_image: u32,
    xpelspermeter: u32,
    ypelspermeter: u32,
    clrused: u32,
    clrimportant: u32,
    redmask: u32,
    greenmask: u32,
    bluemask: u32,
    alpha_mask: u32,
    cs_type: CS_type,
    endpoints: ciexyztriple,
    gamma_red: u32,
    gamma_green: u32,
    gamma_blue: u32,
    intent: rendering_intent,
    profile_data: u32,
    profile_size: u32,
    reserved: u32
};

// Only implementing the types recognized by microsoft (core, info, v4, v5), at
// least for now.
// Will leave the rest in the enum so that they can be recognized despite not
// being parsable.
pub const DIB_header_type = enum(u32) {
    BITMAPCOREHEADER = 12,
    OS22XBITMAPHEADER_16 = 16,
    BITMAPINFOHEADER = 40,
    BITMAPV2INFOHEADER = 52,
    BITMAPV3INFOHEADER = 56,
    OS22XBITMAPHEADER_64 = 64,
    BITMAPV4HEADER = 108,
    BITMAPV5HEADER = 124
};

pub const DIB_compression_type = enum(u32) {
    BI_RGB = 0,
    BI_RLE8 = 1,
    BI_RLE4 = 2,
    BI_BITFIELDS = 3,
    BI_JPEG = 4,
    BI_PNG = 5,
    BI_ALPHABITFIELDS = 6,
    BI_CMYK = 11,
    BI_CMYKRLE8 = 12,
    BI_CMYKRLE4 = 13
};

pub const CS_type = enum(u32) {
    LCS_CALIBRATED_RGB = 0x00000000,
    LCS_sRGB = 0x73524742,
    LCS_WINDOWS_COLOR_SPACE = 0x57696E20,
    PROFILE_LINKED = 0x4C494E4B,
    PROFILE_EMBEDDED = 0x4D424544
};

pub const pixel = struct {
    r: u8,
    g: u8,
    b: u8,
    a: ?u8
};

pub const ciexyztriple = struct {
    red: ciexyz,
    green: ciexyz,
    blue: ciexyz
};

pub const ciexyz = struct {
    x: u32,
    y: u32,
    z: u32
};

pub const rendering_intent = enum(u32) {
    LCS_GM_ABSOLUTECOLORIMETRIC = 8,
    LCS_GM_BUSINESS = 1,
    LCS_GM_GRAPHICS = 2,
    LCS_GM_IMAGES = 4
};

const extra_bitmasks = struct {
    r: u32,
    g: u32,
    b: u32,
    a: ?u32 = null
};

const endianness: std.builtin.Endian = std.builtin.Endian.little;

pub fn parse(file_path: []u8, allocator: std.mem.Allocator) !bmp {
    const file: fs.File = try fs.cwd().openFile(file_path, .{});
    defer file.close();
    var reader: fs.File.Reader = file.reader();

    const file_header: bitmap_file_header = try parse_file_header(reader);

    const dib_header_type: DIB_header_type = @enumFromInt(try reader.readInt(u32, endianness));
    const dib_header: DIB_header = try parse_dib_header(reader, dib_header_type);

    var extra_bit_masks: ?extra_bitmasks = null;

    if (dib_header == DIB_header_type.BITMAPINFOHEADER) {
        if (dib_header.BITMAPINFOHEADER.compression_type == DIB_compression_type.BI_BITFIELDS) {
            extra_bit_masks = try parse_extra_bitmasks(reader, false);
        }
        else if (dib_header.BITMAPINFOHEADER.compression_type == DIB_compression_type.BI_ALPHABITFIELDS) {
            extra_bit_masks = try parse_extra_bitmasks(reader, true);
        }
    }

    var height: u32 = 0;
    var width: u32 = 0;
    var bit_count: u16 = 0;
    var alpha_mask: u32 = 0;
    var compression_type: ?DIB_compression_type = null;
    
    switch (dib_header) {
        DIB_header.BITMAPCOREHEADER => |header| { height = @as(u32, header.height); width = @as(u32, header.width); bit_count = header.bit_count; },
        DIB_header.BITMAPINFOHEADER => |header| { height = header.height; width = header.width; bit_count = header.bit_count; compression_type = header.compression_type; },
        DIB_header.BITMAPV4HEADER => |header| { height = header.height; width = header.width; bit_count = header.bit_count; alpha_mask = header.alpha_mask; compression_type = header.compression_type; },
        DIB_header.BITMAPV5HEADER => |header| { height = header.height; width = header.width; bit_count = header.bit_count; alpha_mask = header.alpha_mask; compression_type = header.compression_type; },
        else => unreachable
    }
    const has_alpha: bool = check_alpha(compression_type, bit_count, alpha_mask);
    
    const pixel_array: [][]pixel = try parse_pixel_array(reader, height, width, bit_count, has_alpha, allocator);

    return bmp{
        .file_header = file_header,
        .dib_header = dib_header,
        .extra_bit_masks = extra_bit_masks,
        .pixel_array = pixel_array,
        .allocator = allocator
    };
}

fn parse_file_header(reader: fs.File.Reader) !bitmap_file_header {
    return bitmap_file_header{
        .identifier = try reader.readBytesNoEof(2),
        .file_size = try reader.readInt(u32, endianness),
        .reserved1 = try reader.readBytesNoEof(2),
        .reserved2 = try reader.readBytesNoEof(2),
        .offset = try reader.readInt(u32, endianness)
    };
}

fn parse_dib_header(reader: fs.File.Reader, dib_header_type: DIB_header_type) !DIB_header {
    switch (dib_header_type) {
        DIB_header_type.BITMAPCOREHEADER => return parse_BITMAPCOREHEADER(reader),
        DIB_header_type.BITMAPINFOHEADER => return parse_BITMAPINFOHEADER(reader),
        DIB_header_type.BITMAPV4HEADER => return parse_BITMAPV4HEADER(reader),
        DIB_header_type.BITMAPV5HEADER => return parse_BITMAPV5HEADER(reader),
        else => {
            std.debug.print("Header type {s} not implemented\n", .{@tagName(dib_header_type)});
            return error.DIBHeaderTypeNotImplemented;
        }
    }
}

fn parse_BITMAPCOREHEADER(reader: fs.File.Reader) !DIB_header {
    return DIB_header{ .BITMAPCOREHEADER = DIB_header_BITMAPCOREHEADER{
        .dib_header_size = @intFromEnum(DIB_header_type.BITMAPCOREHEADER),
        .width = try reader.readInt(u16, endianness),
        .height = try reader.readInt(u16, endianness),
        .planes = try reader.readInt(u16, endianness),
        .bit_count = try reader.readInt(u16, endianness)
    }};
}

fn parse_BITMAPINFOHEADER(reader: fs.File.Reader) !DIB_header {
    return DIB_header{ .BITMAPINFOHEADER = DIB_header_BITMAPINFOHEADER{
        .dib_header_size = @intFromEnum(DIB_header_type.BITMAPINFOHEADER),
        .width = try reader.readInt(u32, endianness),
        .height = try reader.readInt(u32, endianness),
        .planes = try reader.readInt(u16, endianness),
        .bit_count = try reader.readInt(u16, endianness),
        .compression_type = @enumFromInt(try reader.readInt(u32, endianness)),
        .size_image = try reader.readInt(u32, endianness),
        .xpelspermeter = try reader.readInt(u32, endianness),
        .ypelspermeter = try reader.readInt(u32, endianness),
        .clrused = try reader.readInt(u32, endianness),
        .clrimportant = try reader.readInt(u32, endianness)
    }};
}

fn parse_BITMAPV4HEADER(reader: fs.File.Reader) !DIB_header {
    return DIB_header{ .BITMAPV4HEADER = DIB_header_BITMAPV4HEADER{
        .dib_header_size = @intFromEnum(DIB_header_type.BITMAPV4HEADER),
        .width = try reader.readInt(u32, endianness),
        .height = try reader.readInt(u32, endianness),
        .planes = try reader.readInt(u16, endianness),
        .bit_count = try reader.readInt(u16, endianness),
        .compression_type = @enumFromInt(try reader.readInt(u32, endianness)),
        .size_image = try reader.readInt(u32, endianness),
        .xpelspermeter = try reader.readInt(u32, endianness),
        .ypelspermeter = try reader.readInt(u32, endianness),
        .clrused = try reader.readInt(u32, endianness),
        .clrimportant = try reader.readInt(u32, endianness),
        .redmask = try reader.readInt(u32, endianness),
        .greenmask = try reader.readInt(u32, endianness),
        .bluemask = try reader.readInt(u32, endianness),
        .alpha_mask = try reader.readInt(u32, endianness),
        .cs_type = @enumFromInt(try reader.readInt(u32, endianness)),
        .endpoints = .{
            .red = .{
                .x = try reader.readInt(u32, endianness),
                .y = try reader.readInt(u32, endianness),
                .z = try reader.readInt(u32, endianness)
            },
            .green = .{
                .x = try reader.readInt(u32, endianness),
                .y = try reader.readInt(u32, endianness),
                .z = try reader.readInt(u32, endianness)
            },
            .blue = .{
                .x = try reader.readInt(u32, endianness),
                .y = try reader.readInt(u32, endianness),
                .z = try reader.readInt(u32, endianness)
            }
        },
        .gamma_red = try reader.readInt(u32, endianness),
        .gamma_green = try reader.readInt(u32, endianness),
        .gamma_blue = try reader.readInt(u32, endianness),
    }};
}

fn parse_BITMAPV5HEADER(reader: fs.File.Reader) !DIB_header {
    return DIB_header{ .BITMAPV5HEADER = DIB_header_BITMAPV5HEADER{
        .dib_header_size = @intFromEnum(DIB_header_type.BITMAPV5HEADER),
        .width = try reader.readInt(u32, endianness),
        .height = try reader.readInt(u32, endianness),
        .planes = try reader.readInt(u16, endianness),
        .bit_count = try reader.readInt(u16, endianness),
        .compression_type = @enumFromInt(try reader.readInt(u32, endianness)),
        .size_image = try reader.readInt(u32, endianness),
        .xpelspermeter = try reader.readInt(u32, endianness),
        .ypelspermeter = try reader.readInt(u32, endianness),
        .clrused = try reader.readInt(u32, endianness),
        .clrimportant = try reader.readInt(u32, endianness),
        .redmask = try reader.readInt(u32, endianness),
        .greenmask = try reader.readInt(u32, endianness),
        .bluemask = try reader.readInt(u32, endianness),
        .alpha_mask = try reader.readInt(u32, endianness),
        .cs_type = @enumFromInt(try reader.readInt(u32, endianness)),
        .endpoints = .{
            .red = .{
                .x = try reader.readInt(u32, endianness),
                .y = try reader.readInt(u32, endianness),
                .z = try reader.readInt(u32, endianness)
            },
            .green = .{
                .x = try reader.readInt(u32, endianness),
                .y = try reader.readInt(u32, endianness),
                .z = try reader.readInt(u32, endianness)
            },
            .blue = .{
                .x = try reader.readInt(u32, endianness),
                .y = try reader.readInt(u32, endianness),
                .z = try reader.readInt(u32, endianness)
            }
        },
        .gamma_red = try reader.readInt(u32, endianness),
        .gamma_green = try reader.readInt(u32, endianness),
        .gamma_blue = try reader.readInt(u32, endianness),
        .intent = @enumFromInt(try reader.readInt(u32, endianness)),
        .profile_data = try reader.readInt(u32, endianness),
        .profile_size = try reader.readInt(u32, endianness),
        .reserved = try reader.readInt(u32, endianness)
    }};
}

fn parse_extra_bitmasks(reader: fs.File.Reader, has_alpha: bool) !extra_bitmasks {
    if (!has_alpha) {
        return extra_bitmasks{
            .r = try reader.readInt(u32, endianness),
            .g = try reader.readInt(u32, endianness),
            .b = try reader.readInt(u32, endianness)
        };
    }
    return extra_bitmasks{
        .r = try reader.readInt(u32, endianness),
        .g = try reader.readInt(u32, endianness),
        .b = try reader.readInt(u32, endianness),
        .a = try reader.readInt(u32, endianness)
    };
}

fn parse_pixel_array(reader: fs.File.Reader, height: u32, width: u32, bit_count: u16, has_alpha: bool, allocator: std.mem.Allocator) ![][]pixel {
    var pixel_array: [][]pixel = try allocator.alloc([]pixel, height);
    for (0..pixel_array.len) |i| {
        pixel_array[i] = try allocator.alloc(pixel, width);
    }
    const row_len: u32 = (bit_count / 8) * width;
    const remainder: u32 = row_len % 4;
    const padding: u32 = (4 - remainder) * @intFromBool(remainder != 0);
    for (0..height) |y| {
        for (0..width) |x| {
            if (has_alpha) {
                const raw_pixel: [4]u8 = try reader.readBytesNoEof(4);
                pixel_array[y][x].r = raw_pixel[0];
                pixel_array[y][x].g = raw_pixel[1];
                pixel_array[y][x].b = raw_pixel[2];
                pixel_array[y][x].a = raw_pixel[3];
            }
            else {
                switch (bit_count) {
                    24 => {
                        const raw_pixel: [3]u8 = try reader.readBytesNoEof(3);
                        pixel_array[y][x].r = raw_pixel[0];
                        pixel_array[y][x].g = raw_pixel[1];
                        pixel_array[y][x].b = raw_pixel[2];
                        pixel_array[y][x].a = null;
                    },
                    32 => {
                        const raw_pixel: [4]u8 = try reader.readBytesNoEof(4);
                        pixel_array[y][x].r = raw_pixel[0];
                        pixel_array[y][x].g = raw_pixel[1];
                        pixel_array[y][x].b = raw_pixel[2];
                        pixel_array[y][x].a = null;
                    },
                    else => { std.debug.print("Bit count not supported\n", .{}); unreachable; }
                }
            }
        }
        _ = try reader.skipBytes(padding, .{});
    }
    return pixel_array;
}

fn check_alpha(compression_type: ?DIB_compression_type, bit_count: u16, alpha_mask: u32) bool {
    if (compression_type == null) return false;
    if (bit_count != 32) return false;
    if (compression_type == DIB_compression_type.BI_RGB) return true;
    if (alpha_mask != 0xFF000000) return false;
    if (compression_type == DIB_compression_type.BI_BITFIELDS or compression_type == DIB_compression_type.BI_ALPHABITFIELDS) return true;
    return false;
}
