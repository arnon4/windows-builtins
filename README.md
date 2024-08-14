# Windows Builtins

## Table of Contents

- [Windows Builtins](#windows-builtins)
  - [Table of Contents](#table-of-contents)
  - [About](#about)
  - [How to build](#how-to-build)
  - [License](#license)
  - [Contact](#contact)

## About

**Windows Builtins** is a Zig implementation of various GNU/Linux builtins and coreutils for Windows. The goal of this project is to provide commonly used *nix utilities to Windows users *without* providing a full POSIX compatibility layer. This project is not intended to be a full replacement for WSL or Cygwin, but rather a lightweight alternative for users who only need a few utilities.

Because this project is not meant to be a true POSIX compatibility layer, some features of the original utilities may be missing or behave differently. For example, `ls -i` will display ID numbers instead of inode numbers.

## How to build

The project contains standalone programs. In order to build them, you will need to have Zig installed. You can download Zig from the [official website](https://ziglang.org/download/), or install it via `winget`:

```powershell
winget install -e --id zig.zig
```

You can build the desired program by running `zig build`, specifying the target with the `exe_name` option. For example, to build `echo`:

```powershell
zig build -Dexe_name=echo --release=small
```

This will produce an executable named `echo.exe` in the `zig-out/bin` directory. You can then run this executable from the command line:

```powershell
.\zig-out\bin\echo.exe -e "\e[31mHello, world!\e[0m"
```

If you want to use this program globally, copy the executable to a directory in your PATH, such as `C:\Windows\System32`. Alternatively, you can create a new directory and add it to your PATH:

```powershell
mkdir C:\bin
mv .\zig-out\bin\echo.exe C:\bin

[Environment]::SetEnvironmentVariable(
   "Path",
   [Environment]::GetEnvironmentVariable("Path", "Machine") + ";C:\bin", "Machine")
```

Finally, you can add an alias to your PowerShell profile to make the program easier to use:

```powershell
echo "Set-Alias -Name win-echo -Value C:\bin\echo.exe" >> $PROFILE

. $PROFILE
```

While you can override the built-in `echo` command with the alias, it is not recommended, as it may break scripts that rely on the original behavior of `echo`. If you do wish to do so, you can add the alias to your profile like so:

```powershell
echo @"del alias:echo -Force
Set-Alias -Name echo -Value C:\bin\echo.exe"@ >> $PROFILE

. $PROFILE
```

## License

This project is licensed under the GNU General Public License v3.0. See the [LICENSE](LICENSE) file for details.

## Contact

If you have any questions or suggestions, feel free to open an issue.
