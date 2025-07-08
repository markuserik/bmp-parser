const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const module = b.addModule("bmp_parser", .{ .root_source_file = b.path("src/bmp.zig")});

    const test_step = b.step("test", "Run unit tests");
    const bmp_test = b.addTest(.{
        .root_source_file = b.path("src/bmp.zig"),
        .optimize = optimize,
        .target = target
    });
    const run_test = b.addRunArtifact(bmp_test);
    bmp_test.root_module.addImport("bmp_parser", module);
    test_step.dependOn(&run_test.step);
    b.default_step.dependOn(test_step);
}
