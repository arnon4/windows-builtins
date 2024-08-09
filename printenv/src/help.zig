const std = @import("std");
const process = std.process;
const windows = std.os.windows;

pub const ERROR_CODES = enum(u8) {
    SUCCESS = 0,
    NOT_ENOUGH_MEMORY = 8,
    BAD_ENVIRONMENT = 10,
    WRITE_FAULT = 29,
};

pub fn help() ERROR_CODES {
    const help_string =
        \\       printenv - print all or part of environment
        \\
        \\       printenv [OPTION]... [VARIABLE]...
        \\
        \\       Print the values of the specified environment VARIABLE(s).  If no VARIABLE is specified, print name and value pairs for them all.
        \\
        \\       -0, --null
        \\              end each output line with NUL, not newline
        \\
        \\       --help display this help and exit
        \\
        \\COPYRIGHT
        \\       Copyright © 2024 Arnon Tzori.
    ;

    const stdout = std.io.getStdOut().writer();
    stdout.print("{s}", .{help_string}) catch {
        return ERROR_CODES.WRITE_FAULT;
    };

    return ERROR_CODES.SUCCESS;
}
