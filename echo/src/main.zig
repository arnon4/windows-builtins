const std = @import("std");
const help = @import("./help.zig");
const windows = std.os.windows;
const exit = windows.kernel32.ExitProcess;

const ERROR_CODES = help.ERROR_CODES;

pub fn main() void {
    _ = windows.kernel32.SetConsoleOutputCP(65001);
    var print_newline = true;
    var print_escapes = false;
    const stdout = std.io.getStdOut().writer();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var args = std.process.argsWithAllocator(allocator) catch {
        exit(@intFromEnum(ERROR_CODES.NOT_ENOUGH_MEMORY));
    };

    defer args.deinit();

    if (!args.skip()) {
        exit(@intFromEnum(ERROR_CODES.SUCCESS));
    }

    var current_arg = args.next();
    if (std.mem.eql(u8, current_arg.?, "--help")) {
        current_arg = args.next();
        if (current_arg == null) {
            const code = help.help();
            exit(@intFromEnum(code));
        } else {
            stdout.print("--help ", .{}) catch {
                exit(@intFromEnum(ERROR_CODES.WRITE_FAULT));
            };
        }
    }

    var i: usize = 0;
    while (current_arg != null) : (i += 1) {
        if (current_arg.?[0] != '-') {
            break;
        }

        for (current_arg.?[1..]) |char| {
            switch (char) {
                'e' => print_escapes = true,
                'E' => print_escapes = false,
                'n' => print_newline = false,
                else => {
                    break;
                },
            }
        }

        current_arg = args.next();
    }

    if (!print_escapes) {
        while (current_arg != null) {
            stdout.print("{s}", .{current_arg.?}) catch {
                exit(@intFromEnum(ERROR_CODES.WRITE_FAULT));
            };

            current_arg = args.next();
            if (current_arg != null) {
                stdout.print(" ", .{}) catch {
                    exit(@intFromEnum(ERROR_CODES.WRITE_FAULT));
                };
            }
        }

        if (print_newline) {
            stdout.print("\n", .{}) catch {
                exit(@intFromEnum(ERROR_CODES.WRITE_FAULT));
            };
        }

        exit(@intFromEnum(ERROR_CODES.SUCCESS));
    }

    i = 0;
    var char: u8 = undefined;
    var escape: bool = true;
    while (current_arg != null) {
        while (i < current_arg.?.len) : (i += 1) {
            char = current_arg.?[i];
            if (char == '\\' and i + 1 < current_arg.?.len) {
                i += 1;
                switch (current_arg.?[i]) {
                    'a' => char = 7,
                    'b' => char = 8,
                    'c' => exit(@intFromEnum(ERROR_CODES.SUCCESS)),
                    'e', 'E' => char = 27,
                    'f' => char = 12,
                    'n' => char = 10,
                    'r' => char = 13,
                    't' => char = 9,
                    'v' => char = 11,
                    'x' => {
                        var digit: u8 = current_arg.?[i + 1];
                        if (!std.ascii.isHex(digit)) {
                            escape = false;
                            break;
                        }

                        char = hexToBinary(digit);
                        i += 1;
                        if (i >= current_arg.?.len) {
                            break;
                        }

                        digit = current_arg.?[i + 1];
                        if (std.ascii.isHex(digit)) {
                            char = char * 16 + hexToBinary(digit);
                            i += 1;
                        }
                    },
                    '0' => {
                        char = 0;
                        if (!('0' <= current_arg.?[i + 1] and current_arg.?[i + 1] <= '7')) {
                            escape = false;
                            break;
                        }

                        i += 1;
                        switch (current_arg.?[i + 1]) {
                            '1'...'7' => {
                                char = current_arg.?[i + 1] - '0';
                                if ('0' <= current_arg.?[i + 1] and current_arg.?[i + 1] <= '7') {
                                    char = char * 8 + current_arg.?[i + 1] - '0';
                                    i += 1;
                                }

                                if ('0' <= current_arg.?[i + 1] and current_arg.?[i + 1] <= '7') {
                                    char = char * 8 + current_arg.?[i + 1] - '0';
                                    i += 1;
                                }

                                break;
                            },
                            else => {
                                escape = false;
                                break;
                            },
                        }
                    },
                    'u' => {
                        var utf8: u21 = 0;
                        for (0..4) |_| {
                            if (current_arg.?.len <= i + 1 or !std.ascii.isHex(current_arg.?[i + 1])) {
                                break;
                            }

                            utf8 = utf8 * 16 + hexToBinary(current_arg.?[i + 1]);
                            i += 1;
                        }

                        stdout.print("{u}", .{utf8}) catch {
                            exit(@intFromEnum(ERROR_CODES.WRITE_FAULT));
                        };
                        continue;
                    },
                    'U' => {
                        var utf8: u21 = 0;
                        for (0..8) |_| {
                            if (current_arg.?.len <= i + 1 or !std.ascii.isHex(current_arg.?[i + 1])) {
                                break;
                            }

                            utf8 = utf8 * 16 + hexToBinary(current_arg.?[i + 1]);
                            i += 1;
                        }

                        if (utf8 > 0x10FFFF) {
                            stdout.print("", .{}) catch {
                                exit(@intFromEnum(ERROR_CODES.WRITE_FAULT));
                            };
                        } else {
                            stdout.print("{u}", .{utf8}) catch {
                                exit(@intFromEnum(ERROR_CODES.WRITE_FAULT));
                            };
                        }
                        continue;
                    },
                    else => break,
                }
            }
            if (!escape) {
                stdout.print("{s}", .{&[_]u8{char}}) catch {
                    exit(@intFromEnum(ERROR_CODES.WRITE_FAULT));
                };
                escape = true;
                continue;
            }

            stdout.print("{c}", .{char}) catch {
                exit(@intFromEnum(ERROR_CODES.WRITE_FAULT));
            };
        }

        current_arg = args.next();
        if (current_arg != null) {
            stdout.print(" ", .{}) catch {
                exit(@intFromEnum(ERROR_CODES.WRITE_FAULT));
            };
        }
    }

    if (print_newline) {
        stdout.print("\n", .{}) catch {
            exit(@intFromEnum(ERROR_CODES.WRITE_FAULT));
        };
    }

    exit(@intFromEnum(ERROR_CODES.SUCCESS));
}

fn hexToBinary(char: u8) u8 {
    switch (char) {
        'a', 'A' => return 10,
        'b', 'B' => return 11,
        'c', 'C' => return 12,
        'd', 'D' => return 13,
        'e', 'E' => return 14,
        'f', 'F' => return 15,
        else => return char - '0',
    }
}
