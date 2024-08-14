const std = @import("std");
const testing = @import("std").testing;
const process = std.process;
const ERROR_CODE = @import("./error-codes.zig").ERROR_CODE;

pub fn help(string: []const u8) ERROR_CODE {
    const stdout = std.io.getStdOut().writer();
    stdout.print("{s}", .{string}) catch {
        return ERROR_CODE.WRITE_FAULT;
    };

    return ERROR_CODE.SUCCESS;
}
