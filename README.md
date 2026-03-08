![shell](https://img.shields.io/badge/Shell-121011?style=flat&logo=gnu-bash&logoColor=white)
[![contributions](https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat)](https://github.com/vncsmyrnk/shell-utils/issues)
[![Issue count](https://img.shields.io/github/issues-search?query=repo%3Avncsmyrnk%2Fshell-utils%20is%3Aopen&label=open%20issues)](https://github.com/vncsmyrnk/shell-utils/issues)

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

util config add ~/scripts/example.sh # Creates a symbolic link of the file at
                                     # `$HOME/.config/shell-utils/scripts` making
                                     # the script executable via `$ util example`
```

For more information: `$ man util`.

### Customization

This project includes [default scripts](https://github.com/vncsmyrnk/shell-utils/tree/main/defaults), but you can easily add custom scripts by placing them in `$HOME/.config/shell-utils/scripts`. Subfolders within this directory represent subcommands for the `util` command.

To automate update tasks when running `util update`, simply place your scripts in `$HOME/.config/shell-utils/scripts/on-update`. You can achieve this using `$ util config add`.

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

### Nix profile

```sh
nix profile install github:vncsmyrnk/shell-utils
```

### Nix flake

```nix
inputs = {
  shell-utils = {
    url = "github:vncsmyrnk/shell-utils";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};
```
