# shell-utils 🛠

An attempt to be a shell-agnostic custom utilities tool.

## Usage

```sh
util update # this will execute an script named update.sh
            # in your $HOME/.config/utils/scripts directory
```

The `util` command takes a name argument, which corresponds to the script you want to run from `$HOME/.config/util/scripts`. Any additional arguments provided will be passed directly to that script.

### Customization

This project have [default scripts](https://github.com/vncsmyrnk/shell-utils/tree/main/defaults) but it is possible to add custom scripts but just adding more to `$HOME/.config/util/scripts`.

Adding completions is also possible, via `$HOME/.config/util/completions` files.

### A real world example

[A use case in my dotfiles](https://github.com/vncsmyrnk/dotfiles).

## Install

```sh
curl -L https://github.com/vncsmyrnk/shell-utils/raw/refs/heads/main/installer.sh | sh
```

## Completions

### zsh

```sh
# Add this to your .zshrc file
[ -d "$HOME/.config/util/completions" ] && fpath=($HOME/.config/util/completions $fpath)
```
