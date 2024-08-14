const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const exes = [_][]const u8{ "echo", "printenv" };
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    for (exes) |exe| {
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
