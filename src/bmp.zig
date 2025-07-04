const std = @import("std");
const fs = std.fs;

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

pub fn parse(file_path: []u8) !bmp {
    const file: fs.File = try fs.cwd().openFile(file_path, .{});
    defer file.close();
    var reader: fs.File.Reader = file.reader();

    const file_header: bitmap_file_header = try parse_file_header(reader);

    const dib_header_type: DIB_header_type = @enumFromInt(try reader.readInt(u32, std.builtin.Endian.little));
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

    return bmp{
        .file_header = file_header,
        .dib_header = dib_header,
        .extra_bit_masks = extra_bit_masks
    };
}

fn parse_file_header(reader: fs.File.Reader) !bitmap_file_header {
    return bitmap_file_header{
        .identifier = try reader.readBytesNoEof(2),
        .file_size = try reader.readInt(u32, std.builtin.Endian.little),
        .reserved1 = try reader.readBytesNoEof(2),
        .reserved2 = try reader.readBytesNoEof(2),
        .offset = try reader.readInt(u32, std.builtin.Endian.little)
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
        .width = try reader.readInt(u16, std.builtin.Endian.little),
        .height = try reader.readInt(u16, std.builtin.Endian.little),
        .planes = try reader.readInt(u16, std.builtin.Endian.little),
        .bit_count = try reader.readInt(u16, std.builtin.Endian.little)
    }};
}

fn parse_BITMAPINFOHEADER(reader: fs.File.Reader) !DIB_header {
    return DIB_header{ .BITMAPINFOHEADER = DIB_header_BITMAPINFOHEADER{
        .dib_header_size = @intFromEnum(DIB_header_type.BITMAPINFOHEADER),
        .width = try reader.readInt(u32, std.builtin.Endian.little),
        .height = try reader.readInt(u32, std.builtin.Endian.little),
        .planes = try reader.readInt(u16, std.builtin.Endian.little),
        .bit_count = try reader.readInt(u16, std.builtin.Endian.little),
        .compression_type = @enumFromInt(try reader.readInt(u32, std.builtin.Endian.little)),
        .size_image = try reader.readInt(u32, std.builtin.Endian.little),
        .xpelspermeter = try reader.readInt(u32, std.builtin.Endian.little),
        .ypelspermeter = try reader.readInt(u32, std.builtin.Endian.little),
        .clrused = try reader.readInt(u32, std.builtin.Endian.little),
        .clrimportant = try reader.readInt(u32, std.builtin.Endian.little)
    }};
}

fn parse_BITMAPV4HEADER(reader: fs.File.Reader) !DIB_header {
    return DIB_header{ .BITMAPV4HEADER = DIB_header_BITMAPV4HEADER{
        .dib_header_size = @intFromEnum(DIB_header_type.BITMAPV4HEADER),
        .width = try reader.readInt(u32, std.builtin.Endian.little),
        .height = try reader.readInt(u32, std.builtin.Endian.little),
        .planes = try reader.readInt(u16, std.builtin.Endian.little),
        .bit_count = try reader.readInt(u16, std.builtin.Endian.little),
        .compression_type = @enumFromInt(try reader.readInt(u32, std.builtin.Endian.little)),
        .size_image = try reader.readInt(u32, std.builtin.Endian.little),
        .xpelspermeter = try reader.readInt(u32, std.builtin.Endian.little),
        .ypelspermeter = try reader.readInt(u32, std.builtin.Endian.little),
        .clrused = try reader.readInt(u32, std.builtin.Endian.little),
        .clrimportant = try reader.readInt(u32, std.builtin.Endian.little),
        .redmask = try reader.readInt(u32, std.builtin.Endian.little),
        .greenmask = try reader.readInt(u32, std.builtin.Endian.little),
        .bluemask = try reader.readInt(u32, std.builtin.Endian.little),
        .alphamask = try reader.readInt(u32, std.builtin.Endian.little),
        .cs_type = @enumFromInt(try reader.readInt(u32, std.builtin.Endian.little)),
        .endpoints = .{
            .red = .{
                .x = try reader.readInt(u32, std.builtin.Endian.little),
                .y = try reader.readInt(u32, std.builtin.Endian.little),
                .z = try reader.readInt(u32, std.builtin.Endian.little)
            },
            .green = .{
                .x = try reader.readInt(u32, std.builtin.Endian.little),
                .y = try reader.readInt(u32, std.builtin.Endian.little),
                .z = try reader.readInt(u32, std.builtin.Endian.little)
            },
            .blue = .{
                .x = try reader.readInt(u32, std.builtin.Endian.little),
                .y = try reader.readInt(u32, std.builtin.Endian.little),
                .z = try reader.readInt(u32, std.builtin.Endian.little)
            }
        },
        .gamma_red = try reader.readInt(u32, std.builtin.Endian.little),
        .gamma_green = try reader.readInt(u32, std.builtin.Endian.little),
        .gamma_blue = try reader.readInt(u32, std.builtin.Endian.little),
    }};
}

fn parse_BITMAPV5HEADER(reader: fs.File.Reader) !DIB_header {
    return DIB_header{ .BITMAPV5HEADER = DIB_header_BITMAPV5HEADER{
        .dib_header_size = @intFromEnum(DIB_header_type.BITMAPV5HEADER),
        .width = try reader.readInt(u32, std.builtin.Endian.little),
        .height = try reader.readInt(u32, std.builtin.Endian.little),
        .planes = try reader.readInt(u16, std.builtin.Endian.little),
        .bit_count = try reader.readInt(u16, std.builtin.Endian.little),
        .compression_type = @enumFromInt(try reader.readInt(u32, std.builtin.Endian.little)),
        .size_image = try reader.readInt(u32, std.builtin.Endian.little),
        .xpelspermeter = try reader.readInt(u32, std.builtin.Endian.little),
        .ypelspermeter = try reader.readInt(u32, std.builtin.Endian.little),
        .clrused = try reader.readInt(u32, std.builtin.Endian.little),
        .clrimportant = try reader.readInt(u32, std.builtin.Endian.little),
        .redmask = try reader.readInt(u32, std.builtin.Endian.little),
        .greenmask = try reader.readInt(u32, std.builtin.Endian.little),
        .bluemask = try reader.readInt(u32, std.builtin.Endian.little),
        .alphamask = try reader.readInt(u32, std.builtin.Endian.little),
        .cs_type = @enumFromInt(try reader.readInt(u32, std.builtin.Endian.little)),
        .endpoints = .{
            .red = .{
                .x = try reader.readInt(u32, std.builtin.Endian.little),
                .y = try reader.readInt(u32, std.builtin.Endian.little),
                .z = try reader.readInt(u32, std.builtin.Endian.little)
            },
            .green = .{
                .x = try reader.readInt(u32, std.builtin.Endian.little),
                .y = try reader.readInt(u32, std.builtin.Endian.little),
                .z = try reader.readInt(u32, std.builtin.Endian.little)
            },
            .blue = .{
                .x = try reader.readInt(u32, std.builtin.Endian.little),
                .y = try reader.readInt(u32, std.builtin.Endian.little),
                .z = try reader.readInt(u32, std.builtin.Endian.little)
            }
        },
        .gamma_red = try reader.readInt(u32, std.builtin.Endian.little),
        .gamma_green = try reader.readInt(u32, std.builtin.Endian.little),
        .gamma_blue = try reader.readInt(u32, std.builtin.Endian.little),
        .intent = @enumFromInt(try reader.readInt(u32, std.builtin.Endian.little)),
        .profile_data = try reader.readInt(u32, std.builtin.Endian.little),
        .profile_size = try reader.readInt(u32, std.builtin.Endian.little),
        .reserved = try reader.readInt(u32, std.builtin.Endian.little)
    }};
}

fn parse_extra_bitmasks(reader: fs.File.Reader, alpha: bool) !extra_bitmasks {
    if (!alpha) {
        return extra_bitmasks{
            .r = try reader.readInt(u32, std.builtin.Endian.little),
            .g = try reader.readInt(u32, std.builtin.Endian.little),
            .b = try reader.readInt(u32, std.builtin.Endian.little)
        };
    }
    return extra_bitmasks{
        .r = try reader.readInt(u32, std.builtin.Endian.little),
        .g = try reader.readInt(u32, std.builtin.Endian.little),
        .b = try reader.readInt(u32, std.builtin.Endian.little),
        .a = try reader.readInt(u32, std.builtin.Endian.little)
    };
}
