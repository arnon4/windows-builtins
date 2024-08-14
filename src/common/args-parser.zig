const std = @import("std");
const Allocator = std.mem.Allocator;
const ArgIterator = std.process.ArgIterator;

const ERROR_CODE = @import("./error-codes.zig").ERROR_CODE;

pub const args = struct {
    short_name: ?[]const u8,
    long_name: ?[]const u8,
    result: *bool,
    on_found: bool,
};

pub const argsHashMap = std.StringHashMap(args);

pub fn ArgsParser() type {
    return struct {
        const Self = @This();

        args_map: argsHashMap,
        allocator: Allocator,

        pub fn init(allocator: Allocator, args_list: []args) !Self {
            var args_map = argsHashMap.init(allocator);

            for (args_list) |arg_struct| {
                if (arg_struct.short_name == null and arg_struct.long_name == null) {
                    return error.InvalidArgument;
                }

                if (arg_struct.short_name != null) {
                    if (args_map.contains(arg_struct.short_name.?)) {
                        return error.DuplicateKey;
                    }

                    try args_map.put(arg_struct.short_name.?, arg_struct);
                }

                if (arg_struct.long_name == null) {
                    continue;
                }

                if (args_map.contains(arg_struct.long_name.?)) {
                    return error.DuplicateKey;
                }

                try args_map.put(arg_struct.long_name.?, arg_struct);
            }

            return Self{ .args_map = args_map, .allocator = allocator };
        }

        pub fn deinit(self: Self) void {
            self.args_map.deinit();
        }

        pub fn parseArgs(self: *Self, argIterator: *ArgIterator) ?[]const u8 {
            if (!argIterator.skip()) {
                return null;
            }

            var current_arg = argIterator.next();

            if (current_arg == null) {
                return null;
            }

            if (current_arg.?[0] != '-') {
                return current_arg;
            }

            while (current_arg != null and current_arg.?[0] == '-') {
                if (current_arg.?.len == 1) {
                    return current_arg;
                }
                // parse long option
                if (current_arg.?[1] == '-') {
                    const arg = self.args_map.get(current_arg.?[2..]);
                    if (arg != null) {
                        arg.?.result.* = arg.?.on_found;
                    }
                } else {
                    // parse short option
                    for (current_arg.?[1..]) |char| {
                        const arg = self.args_map.get(&[_]u8{char});
                        if (arg != null) {
                            arg.?.result.* = arg.?.on_found;
                        }
                    }
                }

                current_arg = argIterator.next();
            }

            return current_arg;
        }
    };
}
