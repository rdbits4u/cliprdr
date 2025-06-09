const std = @import("std");

pub fn build(b: *std.Build) void
{
    // build options
    const do_strip = b.option(
        bool,
        "strip",
        "Strip the executabes"
    ) orelse false;
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    // libcliprdr
    const libcliprdr = b.addSharedLibrary(.{
        .name = "cliprdr",
        .root_source_file = b.path("src/libcliprdr.zig"),
        .target = target,
        .optimize = optimize,
        .strip = do_strip,
    });
    libcliprdr.linkLibC();
    libcliprdr.addIncludePath(b.path("../common"));
    libcliprdr.addIncludePath(b.path("include"));
    libcliprdr.root_module.addImport("parse", b.createModule(.{
        .root_source_file = b.path("../common/parse.zig"),
    }));
    libcliprdr.root_module.addImport("hexdump", b.createModule(.{
        .root_source_file = b.path("../common/hexdump.zig"),
    }));
    libcliprdr.root_module.addImport("strings", b.createModule(.{
        .root_source_file = b.path("../common/strings.zig"),
    }));
    b.installArtifact(libcliprdr);
}
