const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const exes = [_][]const u8{ "echo", "printenv" };
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const exe_name = b.option([]const u8, "exe_name", "Name of the executable to build");

    for (exes) |exe| {
        if (exe_name) |name| {
            if (std.mem.eql(u8, exe, name)) {
                const root_source_file = try std.mem.join(allocator, "", &[_][]const u8{ "src\\", exe, ".zig" });

                const executable = b.addExecutable(.{
                    .name = exe,
                    .root_source_file = b.path(root_source_file),
                    .target = target,
                    .optimize = optimize,
                });

                b.installArtifact(executable);
            }
        } else {
            const root_source_file = try std.mem.join(allocator, "", &[_][]const u8{ "src\\", exe, ".zig" });

            const executable = b.addExecutable(.{
                .name = exe,
                .root_source_file = b.path(root_source_file),
                .target = target,
                .optimize = optimize,
            });

            b.installArtifact(executable);
        }
    }
}
