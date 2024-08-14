const std = @import("std");
const testing = @import("std").testing;
const process = std.process;
const ERROR_CODES = @import("./error-codes.zig").ERROR_CODES;

pub fn help(string: []const u8) ERROR_CODES {
    const stdout = std.io.getStdOut().writer();
    stdout.print("{s}", .{string}) catch {
        return ERROR_CODES.WRITE_FAULT;
    };

    return ERROR_CODES.SUCCESS;
}
