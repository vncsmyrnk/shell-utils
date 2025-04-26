# shell-utils 🛠️

An attempt to be a shell-agnostic custom utilities tool.

## Usage

```sh
util update # this will execute an script named update.sh
            # in your $HOME/.config/util/scripts directory
```

The `util` command takes a name argument, which corresponds to the script you want to run from `$HOME/.config/util/scripts`. Any additional arguments should be explicitly passed after the end of command-line options (e.g. `$ util script -- arg1 arg2`).

### Customization

This project have [default scripts](https://github.com/vncsmyrnk/shell-utils/tree/main/defaults) but it is possible to add custom scripts by just adding more to `$HOME/.config/util/scripts`.

Scripts specific to other applications are located at [utils folder](https://github.com/vncsmyrnk/shell-utils/tree/main/utils).

Adding completions is also possible, via `$HOME/.config/util/completions` files.

### A real world example

[A use case in my dotfiles](https://github.com/vncsmyrnk/dotfiles).

## Install

```sh
git clone git@github.com:vncsmyrnk/shell-utils.git
just install
```

### Uninstall

```sh
just unset-config
```

## Completions

### zsh

```sh
# Add this to your .zshrc file
[ -d "$HOME/.config/util/completions" ] && fpath=($HOME/.config/util/completions $fpath)
```
