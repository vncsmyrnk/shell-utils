![shell](https://img.shields.io/badge/Shell-121011?style=plastic&logo=gnu-bash&logoColor=white)
[![Go Version](https://img.shields.io/badge/dynamic/regex?url=https%3A%2F%2Fraw.githubusercontent.com%2Fvncsmyrnk%2Fshell-utils%2Frefs%2Fheads%2Fmain%2Fgo.mod&search=go%20(.*)&replace=%241&style=plastic&logo=go&label=Go&color=blue)](https://go.dev/)
[![AUR Version](https://img.shields.io/aur/version/shell-utils-git?style=plastic&label=AUR&logo=archlinux)](https://aur.archlinux.org/packages/shell-utils-git)
[![APT Version](https://img.shields.io/badge/dynamic/regex?url=https%3A%2F%2Ffuryous.vncsmyrnk.dev%2F%3Fuser%3Dvncsmyrnk%26pkg%3Dshell-utils&search=.*&style=plastic&logo=debian&label=apt&color=d70a53)](https://repo.fury.io/vncsmyrnk/)
<br>
[![CI/CD workflow](https://github.com/vncsmyrnk/shell-utils/actions/workflows/ci-cd.yaml/badge.svg)](https://github.com/vncsmyrnk/shell-utils/actions/workflows/ci-cd.yaml)
[![contributions](https://img.shields.io/badge/contributions-welcome-brightgreen?labelColor=384047&color=33cb56)](https://github.com/vncsmyrnk/shell-utils/issues)

# shell-utils 🛠️

Have you ever struggled to locate useful scripts scattered across multiple files when you need them the most? **shell utils** is a shell-agnostic utility tool designed to make your scripts accessible everywhere using the `util` command.

Do you manually install apps and maintain scripts to update them? **shell utils** lets you configure your scripts to run automatically whenever `util update` is executed, streamlining all your update tasks.

## Usage

All the arguments represent the path to script to be executed from `$HOME/.config/shell-utils/scripts` without directory separators, like a CLI application. Additional arguments after the path is matched are seamlessly passed to the specified script.

```sh
util update # this will execute an script named update.*
            # in your `$HOME/.config/shell-utils/scripts` directory

util random generate -l 20 # this will execute an script named generate.*
                           # in your `$HOME/.config/shell-utils/scripts/random/generate` directory,
                           # automatically forwarding all arguments.

util random # considering a `generate.*` script exists in the
            # `$HOME/.config/shell-utils/scripts/random/generate` directory, a "commands available"
            # section will be displayed listing it. A comment starting with "help"
            # will be printed if present on the script.

util packages sync # Synchronizes all GitHub repositories listed in your
                   # `$HOME/.config/shell-utils/config.json` and automatically
                   # trusts the downloaded scripts.

util config add ~/scripts/example.sh # Copies a local file to
                                     # `$HOME/.config/shell-utils/scripts` making
                                     # the script executable via `$ util example`
```

For more information: `$ man util`.

### Security

**shell-utils** implements a script integrity verification system. Every script (both global and user-added) must be hashed and recorded in a signed manifest.

When using `util packages sync`, scripts are automatically signed. For manual additions, use `util config trust` to sign your scripts.

### Customization

This project includes [default extra scripts](https://github.com/vncsmyrnk/shell-utils/tree/main/extra), but you can easily add third-party scripts using the **Packages** system. By creating a `$HOME/.config/shell-utils/config.json` file, third-party scripts can be downloaded and automatically added via `util packages sync`. They will be available as subcommands to the `util` command. Refer to the manual for more information: [util.1](./man1/util.1)

You can also manually add local scripts by placing them in `$HOME/.config/shell-utils/scripts`. Subfolders within this directory represent subcommands for the `util` command.

To automate update tasks when running `util update`, simply place your scripts in `$HOME/.config/shell-utils/scripts/on-update`. You can achieve this using the `on_update_scripts_path` field in your packages config or manually via `$ util config add`.

> [!TIP]
> `util packages sync` is the recommended way to manage collections of scripts, providing parallel downloads, version pinning, and automatic integrity verification.

### Completions and help messages

This project comes with out-of-the-box support for autocompletion of the scripts accessible to the `util` command. The autocompletion is dynamically generated based on special completions file that can be defined per script. A help message can be also added on the script and will be displayed when passing the `--help` option.

```sh
#!/bin/bash

# [help]
# This message will be displayed when running `--help`

echo "doing some operations here..."
```

## Install

### AUR

Install it with your favorite AUR helper.

```sh
yay -S shell-utils-git
```

### APT (Debian and its derivatives)

```sh
echo "deb [trusted=yes] https://apt.fury.io/vncsmyrnk /" | sudo tee /etc/apt/sources.list.d/vncsmyrnk.list
sudo apt update && sudo apt install shell-utils
```

### Nix


```sh
nix profile install github:vncsmyrnk/shell-utils
```

```nix
{
  inputs = {
    shell-utils = {
      url = "github:vncsmyrnk/shell-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```

### From source

shell-utils follows the standard GNU directives for make targets.

```sh
make install
```

## Development

Use `nix develop` to get a Nix shell with all expected dependencies.
