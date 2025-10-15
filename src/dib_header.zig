const std = @import("std");
const fs = std.fs;

pub const DIB_header = union(DIB_header_type) {
    BITMAPCOREHEADER: DIB_header_BITMAPCOREHEADER,
    OS22XBITMAPHEADER_16: DIB_header_OS22XBITMAPHEADER_16,
    BITMAPINFOHEADER: DIB_header_BITMAPINFOHEADER,
    BITMAPV2INFOHEADER: DIB_header_BITMAPV2INFOHEADER,
    BITMAPV3INFOHEADER: DIB_header_BITMAPV3INFOHEADER,
    OS22XBITMAPHEADER_64: DIB_header_OS22XBITMAPHEADER_64,
    BITMAPV4HEADER: DIB_header_BITMAPV4HEADER,
    BITMAPV5HEADER: DIB_header_BITMAPV5HEADER,

    pub const DIB_header_BITMAPCOREHEADER = struct {
    };
    pub const DIB_header_OS22XBITMAPHEADER_16 = struct {
    };
    pub const DIB_header_BITMAPINFOHEADER = struct {
        compression_type: DIB_compression_type,
        size_image: u32,
        xpelspermeter: u32,
        ypelspermeter: u32,
        clrused: u32,
        clrimportant: u32
    };
    pub const DIB_header_BITMAPV2INFOHEADER = struct {
    };
    pub const DIB_header_BITMAPV3INFOHEADER = struct {
    };
    pub const DIB_header_OS22XBITMAPHEADER_64 = struct {
    };
    pub const DIB_header_BITMAPV4HEADER = struct {
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
    pub const DIB_header_BITMAPV5HEADER = struct {
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
        rendering_intent: Rendering_intent,
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
    
    pub const Rendering_intent = enum(u32) {
        LCS_GM_ABSOLUTECOLORIMETRIC = 8,
        LCS_GM_BUSINESS = 1,
        LCS_GM_GRAPHICS = 2,
        LCS_GM_IMAGES = 4
    };

    pub const common = struct {
        dib_header_size: u32,
        width: u32,
        height: u32,
        planes: u16,
        bit_count: u16,
        
        pub fn parse(reader: *std.io.Reader, dib_header_type: DIB_header_type, endianness: std.builtin.Endian) !common {
            return common{
                .dib_header_size = @intFromEnum(dib_header_type),
                .width = try reader.takeInt(u32, endianness),
                .height = try reader.takeInt(u32, endianness),
                .planes = try reader.takeInt(u16, endianness),
                .bit_count = try reader.takeInt(u16, endianness)
            };
        }
    };
    
    pub fn parse_dib_header(reader: *std.io.Reader, dib_header_type: DIB_header_type, endianness: std.builtin.Endian) !DIB_header {
        switch (dib_header_type) {
            DIB_header_type.BITMAPCOREHEADER => return DIB_header{ .BITMAPCOREHEADER = DIB_header_BITMAPCOREHEADER{}},
            DIB_header_type.BITMAPINFOHEADER => return parse_BITMAPINFOHEADER(reader, endianness),
            DIB_header_type.BITMAPV4HEADER => return parse_BITMAPV4HEADER(reader, endianness),
            DIB_header_type.BITMAPV5HEADER => return parse_BITMAPV5HEADER(reader, endianness),
            else => {
                std.debug.print("Header type {s} not implemented\n", .{@tagName(dib_header_type)});
                return error.DIBHeaderTypeNotImplemented;
            }
        }
    }
    
    fn parse_BITMAPINFOHEADER(reader: *std.io.Reader, endianness: std.builtin.Endian) !DIB_header {
        return DIB_header{ .BITMAPINFOHEADER = DIB_header_BITMAPINFOHEADER{
            .compression_type = @enumFromInt(try reader.takeInt(u32, endianness)),
            .size_image = try reader.takeInt(u32, endianness),
            .xpelspermeter = try reader.takeInt(u32, endianness),
            .ypelspermeter = try reader.takeInt(u32, endianness),
            .clrused = try reader.takeInt(u32, endianness),
            .clrimportant = try reader.takeInt(u32, endianness)
        }};
    }
    
    fn parse_BITMAPV4HEADER(reader: *std.io.Reader, endianness: std.builtin.Endian) !DIB_header {
        return DIB_header{ .BITMAPV4HEADER = DIB_header_BITMAPV4HEADER{
            .compression_type = @enumFromInt(try reader.takeInt(u32, endianness)),
            .size_image = try reader.takeInt(u32, endianness),
            .xpelspermeter = try reader.takeInt(u32, endianness),
            .ypelspermeter = try reader.takeInt(u32, endianness),
            .clrused = try reader.takeInt(u32, endianness),
            .clrimportant = try reader.takeInt(u32, endianness),
            .redmask = try reader.takeInt(u32, endianness),
            .greenmask = try reader.takeInt(u32, endianness),
            .bluemask = try reader.takeInt(u32, endianness),
            .alpha_mask = try reader.takeInt(u32, endianness),
            .cs_type = @enumFromInt(try reader.takeInt(u32, endianness)),
            .endpoints = .{
                .red = .{
                    .x = try reader.takeInt(u32, endianness),
                    .y = try reader.takeInt(u32, endianness),
                    .z = try reader.takeInt(u32, endianness)
                },
                .green = .{
                    .x = try reader.takeInt(u32, endianness),
                    .y = try reader.takeInt(u32, endianness),
                    .z = try reader.takeInt(u32, endianness)
                },
                .blue = .{
                    .x = try reader.takeInt(u32, endianness),
                    .y = try reader.takeInt(u32, endianness),
                    .z = try reader.takeInt(u32, endianness)
                }
            },
            .gamma_red = try reader.takeInt(u32, endianness),
            .gamma_green = try reader.takeInt(u32, endianness),
            .gamma_blue = try reader.takeInt(u32, endianness),
        }};
    }
    
    fn parse_BITMAPV5HEADER(reader: *std.io.Reader, endianness: std.builtin.Endian) !DIB_header {
        return DIB_header{ .BITMAPV5HEADER = DIB_header_BITMAPV5HEADER{
            .compression_type = @enumFromInt(try reader.takeInt(u32, endianness)),
            .size_image = try reader.takeInt(u32, endianness),
            .xpelspermeter = try reader.takeInt(u32, endianness),
            .ypelspermeter = try reader.takeInt(u32, endianness),
            .clrused = try reader.takeInt(u32, endianness),
            .clrimportant = try reader.takeInt(u32, endianness),
            .redmask = try reader.takeInt(u32, endianness),
            .greenmask = try reader.takeInt(u32, endianness),
            .bluemask = try reader.takeInt(u32, endianness),
            .alpha_mask = try reader.takeInt(u32, endianness),
            .cs_type = @enumFromInt(try reader.takeInt(u32, endianness)),
            .endpoints = .{
                .red = .{
                    .x = try reader.takeInt(u32, endianness),
                    .y = try reader.takeInt(u32, endianness),
                    .z = try reader.takeInt(u32, endianness)
                },
                .green = .{
                    .x = try reader.takeInt(u32, endianness),
                    .y = try reader.takeInt(u32, endianness),
                    .z = try reader.takeInt(u32, endianness)
                },
                .blue = .{
                    .x = try reader.takeInt(u32, endianness),
                    .y = try reader.takeInt(u32, endianness),
                    .z = try reader.takeInt(u32, endianness)
                }
            },
            .gamma_red = try reader.takeInt(u32, endianness),
            .gamma_green = try reader.takeInt(u32, endianness),
            .gamma_blue = try reader.takeInt(u32, endianness),
            .rendering_intent = @enumFromInt(try reader.takeInt(u32, endianness)),
            .profile_data = try reader.takeInt(u32, endianness),
            .profile_size = try reader.takeInt(u32, endianness),
            .reserved = try reader.takeInt(u32, endianness)
        }};
    }
};
