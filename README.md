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

> [!WARNING]
> shell-utils does not keep track if the default or user scripts were maliciously manipulated yet. Issue tracking this problem: [shell-utils#72](https://github.com/vncsmyrnk/shell-utils/issues/72).
>
> Until this problem is completely fixed, proceed with caution if you still decide to install and use it.

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

util config add ~/scripts/example.sh # Creates a symbolic link of the file at
                                     # `$HOME/.config/shell-utils/scripts` making
                                     # the script executable via `$ util example`
```

For more information: `$ man util`.

### Customization

This project includes [default extra scripts](https://github.com/vncsmyrnk/shell-utils/tree/main/extra), but you can easily add custom scripts by placing them in `$HOME/.config/shell-utils/scripts`. Subfolders within this directory represent subcommands for the `util` command. The dependencies for the extra scripts are not specified, so their successful execution depends on your runtime environment.

To automate update tasks when running `util update`, simply place your scripts in `$HOME/.config/shell-utils/scripts/on-update`. You can achieve this using `$ util config add`.

You can also add scripts from a GitHub repo using `$ util config add github:username/repo`.

> [!TIP]
> The best practice is to keep your scripts were you already store them and just create symbolic links in the folder `$HOME/.config/shell-utils/scripts`. This can be done via `$ util config add`.

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

[Example](https://github.com/vncsmyrnk/dotfiles/blob/4b86eca56bdf638990011b9ea4dc578beb2743b0/flake.nix#L13)
