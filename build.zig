const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const help = b.addStaticLibrary(.{
        .name = "help",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = b.path("src/common/help.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(help);

    const error_codes = b.addStaticLibrary(.{
        .name = "error-codes",
        .root_source_file = b.path("src/common/error-codes.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(error_codes);

    // This declares intent for the library to be installed into the standard
    // location when the user invokes the "install" step (the default step when
    // running `zig build`).

    const echo = b.addExecutable(.{
        .name = "echo",
        .root_source_file = b.path("src/echo.zig"),
        .target = target,
        .optimize = optimize,
    });

    const printenv = b.addExecutable(.{
        .name = "printenv",
        .root_source_file = b.path("src/printenv.zig"),
        .target = target,
        .optimize = optimize,
    });

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(echo);
    b.installArtifact(printenv);
}
