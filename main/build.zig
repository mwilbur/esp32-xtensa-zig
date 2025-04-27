const std = @import("std");

pub fn build(b: *std.Build) !void {

    // const target = b.resolveTargetQuery(.{
    //     .cpu_arch = .riscv32,
    //     .os_tag = .freestanding,
    //     .abi = .none,
    //     .cpu_model = .{ .explicit = &std.Target.riscv.cpu.generic_rv32 },
    //     .cpu_features_add = std.Target.riscv.featureSet(&.{
    //         .m, .c,
    //     }),
    //     .cpu_features_sub = std.Target.riscv.featureSet(&.{}),
    // });

    const target = b.resolveTargetQuery(.{
        .cpu_arch = .xtensa,
        .os_tag = .freestanding,
        .abi = .none,
        .cpu_model = .{ .explicit = &std.Target.xtensa.cpu.esp32 },
        .cpu_features_add = std.Target.xtensa.featureSet(&.{}), // default
        .cpu_features_sub = std.Target.xtensa.featureSet(&.{}),
    });

    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "zig",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const include_dirs = std.process.getEnvVarOwned(b.allocator, "INCLUDE_DIRS") catch "";
    if (!std.mem.eql(u8, include_dirs, "")) {
        var it_inc = std.mem.tokenizeAny(u8, include_dirs, ";");
        while (it_inc.next()) |dir| {
            lib.addIncludePath(.{ .cwd_relative = dir });
        }
    }
    lib.linkLibC(); // stubs for libc
    b.installArtifact(lib);
}
