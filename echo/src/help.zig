const std = @import("std");
const testing = @import("std").testing;
const process = std.process;

pub const ERROR_CODES = enum(u8) {
    SUCCESS = 0,
    NOT_ENOUGH_MEMORY = 8,
    WRITE_FAULT = 29,
};

pub fn help() ERROR_CODES {
    const help_string =
        \\       echo --help display this help and exit
        \\
        \\       echo [-neE] [arg ...]
        \\              Output  the  args, separated by spaces, followed by a newline.  The return status is 0 unless a write error occurs.  If -n is specified, the trailing newline is
        \\              suppressed.  If the -e option is given, interpretation of the following backslash-escaped characters is enabled.  The -E option disables the  interpretation  of
        \\              these  escape  characters, even on systems where they are interpreted by default.  The xpg_echo shell option may be used to dynamically determine whether or not
        \\              echo expands these escape characters by default.  echo does not interpret -- to mean the end of options.  echo interprets the following escape sequences:
        \\              \a     alert (bell)
        \\              \b     backspace
        \\              \c     suppress further output
        \\              \e
        \\              \E     an escape character
        \\              \f     form feed
        \\              \n     new line
        \\              \r     carriage return
        \\              \t     horizontal tab
        \\              \v     vertical tab
        \\              \\     backslash
        \\              \0nnn  the eight-bit character whose value is the octal value nnn (zero to three octal digits)
        \\              \xHH   the eight-bit character whose value is the hexadecimal value HH (one or two hex digits)
        \\              \uHHHH the Unicode (ISO/IEC 10646) character whose value is the hexadecimal value HHHH (one to four hex digits)
        \\              \UHHHHHHHH
        \\                     the Unicode (ISO/IEC 10646) character whose value is the hexadecimal value HHHHHHHH (one to eight hex digits)
        \\
        \\COPYRIGHT
        \\              Copyright © 2024 Arnon Tzori.
    ;

    const stdout = std.io.getStdOut().writer();
    stdout.print("{s}", .{help_string}) catch {
        return ERROR_CODES.WRITE_FAULT;
    };

    return ERROR_CODES.SUCCESS;
}
