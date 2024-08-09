const std = @import("std");
const help = @import("./help.zig");
const windows = std.os.windows;
const exit = windows.kernel32.ExitProcess;

const ERROR_CODES = help.ERROR_CODES;
const BUFFER_SIZE = 4096; // TODO use dynamic sizing or allocation if needed

pub fn main() void {
    _ = windows.kernel32.SetConsoleOutputCP(65001);
    var print_newline = true;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var args = std.process.argsWithAllocator(allocator) catch {
        exit(@intFromEnum(ERROR_CODES.NOT_ENOUGH_MEMORY));
    };

    defer args.deinit();
    _ = args.skip(); // skip the executable name

    var current_arg = args.next();
    if (current_arg == null) {
        printAllEnvWithNewline();
    }

    if (std.mem.eql(u8, current_arg.?, "--help")) {
        const code = help.help();
        exit(@intFromEnum(code));
    }

    if (std.mem.eql(u8, current_arg.?, "-0") or std.mem.eql(u8, current_arg.?, "--null")) {
        print_newline = false;
        current_arg = args.next();
    }

    if (current_arg == null) {
        if (print_newline) {
            printAllEnvWithNewline();
        }

        printAllEnvWithoutNewline();
    }

    var current_arg_nonull: [:0]u8 = undefined;
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

    exit(@intFromEnum(ERROR_CODES.SUCCESS));
}

fn printEnvVarWithoutNewline(arg: [:0]u8, allocator: std.mem.Allocator) void {
    const stdout = std.io.getStdOut().writer();

    const arg_u16 = std.unicode.utf8ToUtf16LeAllocZ(allocator, arg) catch |err| {
        switch (err) {
            error.InvalidUtf8 => {
                exit(@intFromEnum(ERROR_CODES.BAD_ENVIRONMENT));
            },
            error.OutOfMemory => {
                exit(@intFromEnum(ERROR_CODES.NOT_ENOUGH_MEMORY));
            },
        }
    };

    defer allocator.free(arg_u16);

    var lpbuffer: [BUFFER_SIZE]u16 = undefined;
    const u16_len = windows.GetEnvironmentVariableW(arg_u16.ptr, &lpbuffer, BUFFER_SIZE) catch {
        exit(@intFromEnum(ERROR_CODES.BAD_ENVIRONMENT));
    };

    var val_u8: [BUFFER_SIZE]u8 = undefined;
    const u8_len = std.unicode.utf16LeToUtf8(&val_u8, lpbuffer[0..u16_len]) catch {
        exit(@intFromEnum(ERROR_CODES.BAD_ENVIRONMENT));
    };

    stdout.print("{s}", .{val_u8[0..u8_len]}) catch {
        exit(@intFromEnum(ERROR_CODES.WRITE_FAULT));
    };
}

fn printEnvVarWithNewline(arg: [:0]u8, allocator: std.mem.Allocator) void {
    const stdout = std.io.getStdOut().writer();

    const arg_u16 = std.unicode.utf8ToUtf16LeAllocZ(allocator, arg) catch |err| {
        switch (err) {
            error.InvalidUtf8 => {
                exit(@intFromEnum(ERROR_CODES.BAD_ENVIRONMENT));
            },
            error.OutOfMemory => {
                exit(@intFromEnum(ERROR_CODES.NOT_ENOUGH_MEMORY));
            },
        }
    };

    defer allocator.free(arg_u16);

    var lpbuffer: [BUFFER_SIZE]u16 = undefined;
    const u16_len = windows.GetEnvironmentVariableW(arg_u16.ptr, &lpbuffer, BUFFER_SIZE) catch {
        exit(@intFromEnum(ERROR_CODES.BAD_ENVIRONMENT));
    };

    var val_u8: [BUFFER_SIZE]u8 = undefined;
    const u8_len = std.unicode.utf16LeToUtf8(&val_u8, lpbuffer[0..u16_len]) catch {
        exit(@intFromEnum(ERROR_CODES.BAD_ENVIRONMENT));
    };

    stdout.print("{s}\n", .{val_u8[0..u8_len]}) catch {
        exit(@intFromEnum(ERROR_CODES.WRITE_FAULT));
    };
}

fn printAllEnvWithoutNewline() void {
    const stdout = std.io.getStdOut().writer();
    const env = windows.GetEnvironmentStringsW() catch {
        exit(@intFromEnum(ERROR_CODES.BAD_ENVIRONMENT));
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
            exit(@intFromEnum(ERROR_CODES.BAD_ENVIRONMENT));
        };

        stdout.print("{s}", .{out[0..count]}) catch {
            exit(@intFromEnum(ERROR_CODES.WRITE_FAULT));
        };

        // string ends in "\0\0"
        i += 1;
        if (env[i] == 0) {
            break;
        }
    }

    exit(@intFromEnum(ERROR_CODES.SUCCESS));
}

fn printAllEnvWithNewline() void {
    const stdout = std.io.getStdOut().writer();
    const env = windows.GetEnvironmentStringsW() catch {
        exit(@intFromEnum(ERROR_CODES.BAD_ENVIRONMENT));
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
            exit(@intFromEnum(ERROR_CODES.BAD_ENVIRONMENT));
        };

        stdout.print("{s}\n", .{out[0..count]}) catch {
            exit(@intFromEnum(ERROR_CODES.WRITE_FAULT));
        };

        // string ends in "\0\0"
        i += 1;
        if (env[i] == 0) {
            break;
        }
    }

    exit(@intFromEnum(ERROR_CODES.SUCCESS));
}

fn printEnvWithoutNewline(str: []u8) void {
    const stdout = std.io.getStdOut().writer();
    stdout.print("{s}", .{str}) catch {
        exit(@intFromEnum(ERROR_CODES.WRITE_FAULT));
    };
}
