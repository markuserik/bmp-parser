const std = @import("std");
const fs = std.fs;
const bmp_reader = @import("bmp_reader.zig");

pub const bmp = struct {
    file_header: bitmap_file_header,
    dib_header: DIB_header,
    extra_bit_masks: ?extra_bitmasks
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
    alphamask: u32,
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
    alphamask: u32,
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

pub fn parse(file_path: []u8, allocator: std.mem.Allocator) !bmp {
    const file: fs.File = try fs.cwd().openFile(file_path, .{});
    defer file.close();

    const file_size: u64 = (try file.stat()).size;
    const file_contents_raw: []u8 = try file.reader().readAllAlloc(allocator, file_size);
    defer allocator.free(file_contents_raw);

    var reader: *bmp_reader.bmp_reader = try bmp_reader.create_reader(file_contents_raw, allocator);
    defer allocator.destroy(reader);

    const file_header: bitmap_file_header = try parse_file_header(reader);

    const dib_header_type: DIB_header_type = @enumFromInt(parse_raw_u32(reader.read4()));
    const dib_header: DIB_header = try parse_dib_header(reader, dib_header_type);

    var extra_bit_masks: ?extra_bitmasks = null;

    if (dib_header == DIB_header_type.BITMAPINFOHEADER) {
        if (dib_header.BITMAPINFOHEADER.compression_type == DIB_compression_type.BI_BITFIELDS) {
            extra_bit_masks = parse_extra_bitmasks(reader, false);
        }
        else if (dib_header.BITMAPINFOHEADER.compression_type == DIB_compression_type.BI_ALPHABITFIELDS) {
            extra_bit_masks = parse_extra_bitmasks(reader, true);
        }
    }

    return bmp{
        .file_header = file_header,
        .dib_header = dib_header,
        .extra_bit_masks = extra_bit_masks
    };
}

fn parse_file_header(reader: *bmp_reader.bmp_reader) !bitmap_file_header {
    return bitmap_file_header{
        .identifier = reader.read2(),
        .file_size = parse_raw_u32(reader.read4()),
        .reserved1 = reader.read2(),
        .reserved2 = reader.read2(),
        .offset = parse_raw_u32(reader.read4())
    };
}

fn parse_dib_header(reader: *bmp_reader.bmp_reader, dib_header_type: DIB_header_type) !DIB_header {
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

fn parse_BITMAPCOREHEADER(reader: *bmp_reader.bmp_reader) !DIB_header {
    return DIB_header{ .BITMAPCOREHEADER = DIB_header_BITMAPCOREHEADER{
        .dib_header_size = @intFromEnum(DIB_header_type.BITMAPCOREHEADER),
        .width = parse_raw_u16(reader.read2()),
        .height = parse_raw_u16(reader.read2()),
        .planes = parse_raw_u16(reader.read2()),
        .bit_count = parse_raw_u16(reader.read2())
    }};
}

fn parse_BITMAPINFOHEADER(reader: *bmp_reader.bmp_reader) !DIB_header {
    return DIB_header{ .BITMAPINFOHEADER = DIB_header_BITMAPINFOHEADER{
        .dib_header_size = @intFromEnum(DIB_header_type.BITMAPINFOHEADER),
        .width = parse_raw_u32(reader.read4()),
        .height = parse_raw_u32(reader.read4()),
        .planes = parse_raw_u16(reader.read2()),
        .bit_count = parse_raw_u16(reader.read2()),
        .compression_type = @enumFromInt(parse_raw_u32(reader.read4())),
        .size_image = parse_raw_u32(reader.read4()),
        .xpelspermeter = parse_raw_u32(reader.read4()),
        .ypelspermeter = parse_raw_u32(reader.read4()),
        .clrused = parse_raw_u32(reader.read4()),
        .clrimportant = parse_raw_u32(reader.read4())
    }};
}

fn parse_BITMAPV4HEADER(reader: *bmp_reader.bmp_reader) !DIB_header {
    return DIB_header{ .BITMAPV4HEADER = DIB_header_BITMAPV4HEADER{
        .dib_header_size = @intFromEnum(DIB_header_type.BITMAPV4HEADER),
        .width = parse_raw_u32(reader.read4()),
        .height = parse_raw_u32(reader.read4()),
        .planes = parse_raw_u16(reader.read2()),
        .bit_count = parse_raw_u16(reader.read2()),
        .compression_type = @enumFromInt(parse_raw_u32(reader.read4())),
        .size_image = parse_raw_u32(reader.read4()),
        .xpelspermeter = parse_raw_u32(reader.read4()),
        .ypelspermeter = parse_raw_u32(reader.read4()),
        .clrused = parse_raw_u32(reader.read4()),
        .clrimportant = parse_raw_u32(reader.read4()),
        .redmask = parse_raw_u32(reader.read4()),
        .greenmask = parse_raw_u32(reader.read4()),
        .bluemask = parse_raw_u32(reader.read4()),
        .alphamask = parse_raw_u32(reader.read4()),
        .cs_type = @enumFromInt(parse_raw_u32(reader.read4())),
        .endpoints = .{
            .red = .{
                .x = parse_raw_u32(reader.read4()),
                .y = parse_raw_u32(reader.read4()),
                .z = parse_raw_u32(reader.read4())
            },
            .green = .{
                .x = parse_raw_u32(reader.read4()),
                .y = parse_raw_u32(reader.read4()),
                .z = parse_raw_u32(reader.read4())
            },
            .blue = .{
                .x = parse_raw_u32(reader.read4()),
                .y = parse_raw_u32(reader.read4()),
                .z = parse_raw_u32(reader.read4())
            }
        },
        .gamma_red = parse_raw_u32(reader.read4()),
        .gamma_green = parse_raw_u32(reader.read4()),
        .gamma_blue = parse_raw_u32(reader.read4()),
    }};
}

fn parse_BITMAPV5HEADER(reader: *bmp_reader.bmp_reader) !DIB_header {
    return DIB_header{ .BITMAPV5HEADER = DIB_header_BITMAPV5HEADER{
        .dib_header_size = @intFromEnum(DIB_header_type.BITMAPV5HEADER),
        .width = parse_raw_u32(reader.read4()),
        .height = parse_raw_u32(reader.read4()),
        .planes = parse_raw_u16(reader.read2()),
        .bit_count = parse_raw_u16(reader.read2()),
        .compression_type = @enumFromInt(parse_raw_u32(reader.read4())),
        .size_image = parse_raw_u32(reader.read4()),
        .xpelspermeter = parse_raw_u32(reader.read4()),
        .ypelspermeter = parse_raw_u32(reader.read4()),
        .clrused = parse_raw_u32(reader.read4()),
        .clrimportant = parse_raw_u32(reader.read4()),
        .redmask = parse_raw_u32(reader.read4()),
        .greenmask = parse_raw_u32(reader.read4()),
        .bluemask = parse_raw_u32(reader.read4()),
        .alphamask = parse_raw_u32(reader.read4()),
        .cs_type = @enumFromInt(parse_raw_u32(reader.read4())),
        .endpoints = .{
            .red = .{
                .x = parse_raw_u32(reader.read4()),
                .y = parse_raw_u32(reader.read4()),
                .z = parse_raw_u32(reader.read4())
            },
            .green = .{
                .x = parse_raw_u32(reader.read4()),
                .y = parse_raw_u32(reader.read4()),
                .z = parse_raw_u32(reader.read4())
            },
            .blue = .{
                .x = parse_raw_u32(reader.read4()),
                .y = parse_raw_u32(reader.read4()),
                .z = parse_raw_u32(reader.read4())
            }
        },
        .gamma_red = parse_raw_u32(reader.read4()),
        .gamma_green = parse_raw_u32(reader.read4()),
        .gamma_blue = parse_raw_u32(reader.read4()),
        .intent = @enumFromInt(parse_raw_u32(reader.read4())),
        .profile_data = parse_raw_u32(reader.read4()),
        .profile_size = parse_raw_u32(reader.read4()),
        .reserved = parse_raw_u32(reader.read4())
    }};
}

fn parse_extra_bitmasks(reader: *bmp_reader.bmp_reader, alpha: bool) extra_bitmasks {
    if (!alpha) {
        return extra_bitmasks{
            .r = parse_raw_u32(reader.read4()),
            .g = parse_raw_u32(reader.read4()),
            .b = parse_raw_u32(reader.read4())
        };
    }
    return extra_bitmasks{
        .r = parse_raw_u32(reader.read4()),
        .g = parse_raw_u32(reader.read4()),
        .b = parse_raw_u32(reader.read4()),
        .a = parse_raw_u32(reader.read4())
    };
}

fn parse_raw_u32(slice: [4]u8) u32 {
    return @as(u32, slice[0]) | @as(u32, slice[1]) << 8 | @as(u32, slice[2]) << 16 | @as(u32, slice[3]) << 24;
}

fn parse_raw_u16(slice: [2]u8) u16 {
    return @as(u16, slice[0]) | @as(u16, slice[1]) << 8;
}
