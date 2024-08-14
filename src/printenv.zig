const std = @import("std");
const windows = std.os.windows;
const exit = windows.kernel32.ExitProcess;

const help = @import("./common/help.zig");
const Parser = @import("./common/args-parser.zig");
const ArgsParser = Parser.ArgsParser;
const ERROR_CODE = @import("./common/error-codes.zig").ERROR_CODE;

const BUFFER_SIZE = 4096; // TODO use dynamic sizing or allocation if needed

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

pub fn main() void {
    _ = windows.kernel32.SetConsoleOutputCP(65001);
    var print_newline = true;
    var print_help = false;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var args = std.process.argsWithAllocator(allocator) catch {
        exit(@intFromEnum(ERROR_CODE.NOT_ENOUGH_MEMORY));
    };

    defer args.deinit();
    var possible_args = [_]Parser.args{
        .{ .short_name = "0", .long_name = "null", .result = &print_newline, .on_found = false },
        .{ .short_name = null, .long_name = "help", .result = &print_help, .on_found = true },
    };

    var args_parser = ArgsParser().init(allocator, possible_args[0..]) catch {
        exit(@intFromEnum(ERROR_CODE.NOT_ENOUGH_MEMORY));
    };

    defer args_parser.deinit();

    var current_arg = args_parser.parseArgs(&args);

    if (print_help) {
        const code = help.help(help_string);
        exit(@intFromEnum(code));
    }

    if (current_arg == null) {
        if (print_newline) {
            printAllEnvWithNewline();
        }

        printAllEnvWithoutNewline();
    }

    var current_arg_nonull: []u8 = undefined;
    if (print_newline) {
        while (current_arg != null) {
            current_arg_nonull = @constCast(current_arg.?);
            printEnvVarWithNewline(current_arg_nonull, allocator);
            current_arg = args.next();
        }
    } else {
        while (current_arg != null) {
            current_arg_nonull = @constCast(current_arg.?);
            printEnvVarWithoutNewline(current_arg_nonull, allocator);
            current_arg = args.next();
        }
    }

    exit(@intFromEnum(ERROR_CODE.SUCCESS));
}

fn printEnvVarWithoutNewline(arg: []u8, allocator: std.mem.Allocator) void {
    const stdout = std.io.getStdOut().writer();

    const arg_u16 = std.unicode.utf8ToUtf16LeAllocZ(allocator, arg) catch |err| {
        switch (err) {
            error.InvalidUtf8 => {
                exit(@intFromEnum(ERROR_CODE.BAD_ENVIRONMENT));
            },
            error.OutOfMemory => {
                exit(@intFromEnum(ERROR_CODE.NOT_ENOUGH_MEMORY));
            },
        }
    };

    defer allocator.free(arg_u16);

    var lpbuffer: [BUFFER_SIZE]u16 = undefined;
    const u16_len = windows.GetEnvironmentVariableW(arg_u16.ptr, &lpbuffer, BUFFER_SIZE) catch {
        exit(@intFromEnum(ERROR_CODE.BAD_ENVIRONMENT));
    };

    var val_u8: [BUFFER_SIZE]u8 = undefined;
    const u8_len = std.unicode.utf16LeToUtf8(&val_u8, lpbuffer[0..u16_len]) catch {
        exit(@intFromEnum(ERROR_CODE.BAD_ENVIRONMENT));
    };

    stdout.print("{s}", .{val_u8[0..u8_len]}) catch {
        exit(@intFromEnum(ERROR_CODE.WRITE_FAULT));
    };
}

fn printEnvVarWithNewline(arg: []u8, allocator: std.mem.Allocator) void {
    const stdout = std.io.getStdOut().writer();

    const arg_u16 = std.unicode.utf8ToUtf16LeAllocZ(allocator, arg) catch |err| {
        switch (err) {
            error.InvalidUtf8 => {
                exit(@intFromEnum(ERROR_CODE.BAD_ENVIRONMENT));
            },
            error.OutOfMemory => {
                exit(@intFromEnum(ERROR_CODE.NOT_ENOUGH_MEMORY));
            },
        }
    };

    defer allocator.free(arg_u16);

    var lpbuffer: [BUFFER_SIZE]u16 = undefined;
    const u16_len = windows.GetEnvironmentVariableW(arg_u16.ptr, &lpbuffer, BUFFER_SIZE) catch {
        exit(@intFromEnum(ERROR_CODE.BAD_ENVIRONMENT));
    };

    var val_u8: [BUFFER_SIZE]u8 = undefined;
    const u8_len = std.unicode.utf16LeToUtf8(&val_u8, lpbuffer[0..u16_len]) catch {
        exit(@intFromEnum(ERROR_CODE.BAD_ENVIRONMENT));
    };

    stdout.print("{s}\n", .{val_u8[0..u8_len]}) catch {
        exit(@intFromEnum(ERROR_CODE.WRITE_FAULT));
    };
}

fn printAllEnvWithoutNewline() void {
    const stdout = std.io.getStdOut().writer();
    const env = windows.GetEnvironmentStringsW() catch {
        exit(@intFromEnum(ERROR_CODE.BAD_ENVIRONMENT));
    };

    defer windows.FreeEnvironmentStringsW(env);

    var i: usize = 0;
    var j: usize = i;
    var out: [BUFFER_SIZE]u8 = undefined;
    var count: usize = undefined;
    while (true) : (j = i) {
        while (env[i] != 0) : (i += 1) {
            continue;
        }

        count = std.unicode.utf16LeToUtf8(&out, env[j..i]) catch {
            exit(@intFromEnum(ERROR_CODE.BAD_ENVIRONMENT));
        };

        stdout.print("{s}", .{out[0..count]}) catch {
            exit(@intFromEnum(ERROR_CODE.WRITE_FAULT));
        };

        // string ends in "\0\0"
        i += 1;
        if (env[i] == 0) {
            break;
        }
    }

    exit(@intFromEnum(ERROR_CODE.SUCCESS));
}

fn printAllEnvWithNewline() void {
    const stdout = std.io.getStdOut().writer();
    const env = windows.GetEnvironmentStringsW() catch {
        exit(@intFromEnum(ERROR_CODE.BAD_ENVIRONMENT));
    };

    defer windows.FreeEnvironmentStringsW(env);

    var i: usize = 0;
    var j: usize = i;
    var out: [BUFFER_SIZE]u8 = undefined;
    var count: usize = undefined;
    while (true) : (j = i) {
        while (env[i] != 0) : (i += 1) {
            continue;
        }

        count = std.unicode.utf16LeToUtf8(&out, env[j..i]) catch {
            exit(@intFromEnum(ERROR_CODE.BAD_ENVIRONMENT));
        };

        stdout.print("{s}\n", .{out[0..count]}) catch {
            exit(@intFromEnum(ERROR_CODE.WRITE_FAULT));
        };

        // string ends in "\0\0"
        i += 1;
        if (env[i] == 0) {
            break;
        }
    }

    exit(@intFromEnum(ERROR_CODE.SUCCESS));
}

fn printEnvWithoutNewline(str: []u8) void {
    const stdout = std.io.getStdOut().writer();
    stdout.print("{s}", .{str}) catch {
        exit(@intFromEnum(ERROR_CODE.WRITE_FAULT));
    };
}
