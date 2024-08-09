# Printenv

## Overview

An implementation of (a version of) *nix `printenv` for Windows.

## Usage

If you've ever used `printenv` on Linux or iOS, it's probably identical - or at least very similar. For details, run `printenv.exe --help`. See the [main README](../README.md) for information regarding how to build, set aliases, or run the program. In short:

- supports printing all environment variables as `VAR=VAL`, with or without a newline between every pair: `printenv.exe` or `printenv.exe -0`
- supports printing out specific values to given environment variables: `printenv.exe VAR1 VAR2 ...`
