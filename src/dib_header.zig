const std = @import("std");
const fs = std.fs;

pub const DIBheader = struct {
    type: DIBheaderType,
    width: u32,
    height: u32,
    planes: u16,
    bit_count: u16,
    compression_type: ?DIBcompressionType,
    size_image: ?u32,
    xpelspermeter: ?u32,
    ypelspermeter: ?u32,
    clrused: ?u32,
    clrimportant: ?u32,
    redmask: ?u32,
    greenmask: ?u32,
    bluemask: ?u32,
    alpha_mask: ?u32,
    cs_type: ?CS_type,
    endpoints: ?ciexyztriple,
    gamma_red: ?u32,
    gamma_green: ?u32,
    gamma_blue: ?u32,
    rendering_intent: ?Rendering_intent,
    profile_data: ?u32,
    profile_size: ?u32,
    reserved: ?u32,

    // Only implementing the types recognized by microsoft (core, info, v4, v5), at
    // least for now.
    // Will leave the rest in the enum so that they can be recognized despite not
    // being parsable.
    pub const DIBheaderType = enum(u32) {
        BITMAPCOREHEADER = 12,
        OS22XBITMAPHEADER_16 = 16,
        BITMAPINFOHEADER = 40,
        BITMAPV2INFOHEADER = 52,
        BITMAPV3INFOHEADER = 56,
        OS22XBITMAPHEADER_64 = 64,
        BITMAPV4HEADER = 108,
        BITMAPV5HEADER = 124
    };
    
    pub const DIBcompressionType = enum(u32) {
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

    pub fn parseDibHeader(reader: *std.io.Reader, allocator: std.mem.Allocator, endianness: std.builtin.Endian) !DIBheader {
        const header: *DIBheader = try allocator.create(DIBheader);
        header.type = @enumFromInt(try reader.takeInt(u32, endianness));
        
        try parseCommon(reader, header, endianness);

        switch (header.type) {
            .BITMAPCOREHEADER => {},
            .BITMAPINFOHEADER => try parseBITMAPINFOHEADER(reader, header, endianness),
            .BITMAPV4HEADER => try parseBITMAPV4HEADER(reader, header, endianness),
            .BITMAPV5HEADER => try parseBITMAPV5HEADER(reader, header, endianness),
            else => {
                std.debug.print("Header type {s} not implemented\n", .{@tagName(header.type)});
                return error.DIBHeaderTypeNotImplemented;
            }
        }
        return header.*;
    }

    pub fn parseCommon(reader: *std.io.Reader, header: *DIBheader, endianness: std.builtin.Endian) !void {
        header.width = try reader.takeInt(u32, endianness);
        header.height = try reader.takeInt(u32, endianness);
        header.planes = try reader.takeInt(u16, endianness);
        header.bit_count = try reader.takeInt(u16, endianness);
    }
    
    fn parseBITMAPINFOHEADER(reader: *std.io.Reader, header: *DIBheader, endianness: std.builtin.Endian) !void {
        header.compression_type = @enumFromInt(try reader.takeInt(u32, endianness));
        header.size_image = try reader.takeInt(u32, endianness);
        header.xpelspermeter = try reader.takeInt(u32, endianness);
        header.ypelspermeter = try reader.takeInt(u32, endianness);
        header.clrused = try reader.takeInt(u32, endianness);
        header.clrimportant = try reader.takeInt(u32, endianness);
    }
    
    fn parseBITMAPV4HEADER(reader: *std.io.Reader, header: *DIBheader, endianness: std.builtin.Endian) !void {
        header.compression_type = @enumFromInt(try reader.takeInt(u32, endianness));
        header.size_image = try reader.takeInt(u32, endianness);
        header.xpelspermeter = try reader.takeInt(u32, endianness);
        header.ypelspermeter = try reader.takeInt(u32, endianness);
        header.clrused = try reader.takeInt(u32, endianness);
        header.clrimportant = try reader.takeInt(u32, endianness);
        header.redmask = try reader.takeInt(u32, endianness);
        header.greenmask = try reader.takeInt(u32, endianness);
        header.bluemask = try reader.takeInt(u32, endianness);
        header.alpha_mask = try reader.takeInt(u32, endianness);
        header.cs_type = @enumFromInt(try reader.takeInt(u32, endianness));
        header.endpoints = .{
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
        };
        header.gamma_red = try reader.takeInt(u32, endianness);
        header.gamma_green = try reader.takeInt(u32, endianness);
        header.gamma_blue = try reader.takeInt(u32, endianness);
    }
    
    fn parseBITMAPV5HEADER(reader: *std.io.Reader, header: *DIBheader, endianness: std.builtin.Endian) !void {
        header.compression_type = @enumFromInt(try reader.takeInt(u32, endianness));
        header.size_image = try reader.takeInt(u32, endianness);
        header.xpelspermeter = try reader.takeInt(u32, endianness);
        header.ypelspermeter = try reader.takeInt(u32, endianness);
        header.clrused = try reader.takeInt(u32, endianness);
        header.clrimportant = try reader.takeInt(u32, endianness);
        header.redmask = try reader.takeInt(u32, endianness);
        header.greenmask = try reader.takeInt(u32, endianness);
        header.bluemask = try reader.takeInt(u32, endianness);
        header.alpha_mask = try reader.takeInt(u32, endianness);
        header.cs_type = @enumFromInt(try reader.takeInt(u32, endianness));
        header.endpoints = .{
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
        };
        header.gamma_red = try reader.takeInt(u32, endianness);
        header.gamma_green = try reader.takeInt(u32, endianness);
        header.gamma_blue = try reader.takeInt(u32, endianness);
        header.rendering_intent = @enumFromInt(try reader.takeInt(u32, endianness));
        header.profile_data = try reader.takeInt(u32, endianness);
        header.profile_size = try reader.takeInt(u32, endianness);
        header.reserved = try reader.takeInt(u32, endianness);
    }
};
