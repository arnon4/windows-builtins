# Echo

## Overview

An implementation of (a version of) *nix `echo` for Windows.

## Usage

If you've ever used `echo` on Linux or iOS, it's probably identical - or at least very similar. For details, run `echo.exe --help`. See the [main README](../README.md) for information regarding how to build, set aliases, or run the program. In short:

- supports various escape sequences with the -e flag:
  - bell: `echo.exe -e "\a"`
  - newline/carriage return: `echo.exe -e "\n\r"`
  - unicode: `echo.exe -e "\u1f635"`
  - ANSI escape sequences: `echo.exe -e "\e[91mR\e[92mG\e[94mB\e[0m"`
  - and more
- supports disabling final newline with `-n`
