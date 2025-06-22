const std = @import("std");

pub const bmp = struct {
    file_header: bitmap_file_header,
    dib_header: DIB_header
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
    dib_header_size: u32
};
const DIB_header_OS22XBITMAPHEADER_16 = struct {
};
const DIB_header_BITMAPINFOHEADER = struct {
    dib_header_size: u32
};
const DIB_header_BITMAPV2INFOHEADER = struct {
};
const DIB_header_BITMAPV3INFOHEADER = struct {
};
const DIB_header_OS22XBITMAPHEADER_64 = struct {
};
const DIB_header_BITMAPV4HEADER = struct {
    dib_header_size: u32
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
    cs_type: CS_type
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

pub fn parse(file_contents_raw: []u8) !bmp {
    const file_header_size: u8 = 14;
    const file_header: bitmap_file_header = try parse_file_header(file_contents_raw[0..file_header_size]);

    const dib_header_type: DIB_header_type = @enumFromInt(try parse_raw_u32(file_contents_raw[file_header_size..file_header_size+4]));
    const dib_header: DIB_header = try parse_dib_header(file_contents_raw, dib_header_type, file_header_size);

    return bmp{
        .file_header = file_header,
        .dib_header = dib_header
    };
}

fn parse_file_header(file_header_raw: []u8) !bitmap_file_header {
    return bitmap_file_header{
        .identifier = file_header_raw[0..2].*,
        .file_size = try parse_raw_u32(file_header_raw[2..6]),
        .reserved1 = file_header_raw[6..8].*,
        .reserved2 = file_header_raw[8..10].*,
        .offset = try parse_raw_u32(file_header_raw[10..14])
    };
}

fn parse_dib_header(file_contents_raw: []u8, dib_header_type: DIB_header_type, file_header_size: u8) !DIB_header {
    const header_content_raw = file_contents_raw[file_header_size..@intFromEnum(dib_header_type)+file_header_size];
    switch (dib_header_type) {
        DIB_header_type.BITMAPCOREHEADER => return parse_BITMAPCOREHEADER(header_content_raw),
        DIB_header_type.BITMAPV5HEADER => return parse_BITMAPV5HEADER(header_content_raw),
        else => {
            std.debug.print("Header type {s} not implemented\n", .{@tagName(dib_header_type)});
            return error.DIBHeaderTypeNotImplemented;
        }
    }
}

fn parse_BITMAPCOREHEADER(dib_header_raw: []u8) !DIB_header {
    _ = dib_header_raw;
    return DIB_header{ .BITMAPCOREHEADER = DIB_header_BITMAPCOREHEADER{
        .dib_header_size = @intFromEnum(DIB_header_type.BITMAPCOREHEADER)
    }};
}

fn parse_BITMAPV5HEADER(dib_header_raw: []u8) !DIB_header {
    return DIB_header{ .BITMAPV5HEADER = DIB_header_BITMAPV5HEADER{
        .dib_header_size = @intFromEnum(DIB_header_type.BITMAPV5HEADER),
        .width = try parse_raw_u32(dib_header_raw[4..8]),
        .height = try parse_raw_u32(dib_header_raw[8..12]),
        .planes = try parse_raw_u16(dib_header_raw[12..14]),
        .bit_count = try parse_raw_u16(dib_header_raw[14..16]),
        .compression_type = @enumFromInt(try parse_raw_u32(dib_header_raw[16..20])),
        .size_image = try parse_raw_u32(dib_header_raw[20..24]),
        .xpelspermeter = try parse_raw_u32(dib_header_raw[24..28]),
        .ypelspermeter = try parse_raw_u32(dib_header_raw[28..32]),
        .clrused = try parse_raw_u32(dib_header_raw[32..36]),
        .clrimportant = try parse_raw_u32(dib_header_raw[36..40]),
        .redmask = try parse_raw_u32(dib_header_raw[40..44]),
        .greenmask = try parse_raw_u32(dib_header_raw[44..48]),
        .bluemask = try parse_raw_u32(dib_header_raw[48..52]),
        .alphamask = try parse_raw_u32(dib_header_raw[52..56]),
        .cs_type = @enumFromInt(try parse_raw_u32(dib_header_raw[56..60]))
    }};
}

fn parse_raw_u32(slice: []u8) !u32 {
    if (slice.len != 4) return error.IncorrectByteCount;
    return @as(u32, slice[0]) | @as(u32, slice[1]) << 8 | @as(u32, slice[2]) << 16 | @as(u32, slice[3]) << 24;
}

fn parse_raw_u16(slice: []u8) !u16 {
    if (slice.len != 2) return error.IncorrectByteCount;
    return @as(u16, slice[0]) | @as(u16, slice[1]) << 8;
}
