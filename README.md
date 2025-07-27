![shell](https://img.shields.io/badge/Shell-121011?style=flat&logo=gnu-bash&logoColor=white)
[![contributions](https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat)](https://github.com/vncsmyrnk/shell-utils/issues)
[![Issue count](https://img.shields.io/github/issues-search?query=repo%3Avncsmyrnk%2Fshell-utils%20is%3Aopen&label=open%20issues)](https://github.com/vncsmyrnk/shell-utils/issues)

# shell-utils 🛠️

Have you ever struggled to locate useful scripts scattered across multiple files when you need them the most? **shell utils** is a shell-agnostic utility tool designed to make your scripts accessible everywhere using the `util` command.

Do you also maintain various run command files for setting up aliases, environment variables, and shell plugins? **shell utils** includes a configuration script that automatically sources all your essential configurations.

Do you manually install apps and maintain scripts to update them? with **shell utils**, you can configure your scripts to run automatically whenever `util update` is executed, streamlining all your update tasks.

## Usage

All the arguments represent the path to script to be executed from `$HOME/.config/util/scripts` without directory separators, like a CLI application. Additional arguments after the path is matched are seamlessly passed to the specified script.

<p align="center">
  <a href="https://asciinema.org/a/kTkzdoHIFRfcLJShWloNHC8vV" target="_blank"><img src="https://asciinema.org/a/kTkzdoHIFRfcLJShWloNHC8vV.svg" /></a>
</p>

```sh
util update # this will execute an script named update.sh
            # in your `$HOME/.config/util/scripts` directory

util git checkout-pr # this will execute an script named checkout-pr.sh
                     # in your `$HOME/.config/util/scripts/git` directory.

util git # considering a `checkout-pr.*` script exists in the
         # `$HOME/.config/util/scripts/git` directory # a "commands available"
         # section will be displayed listing it. A comment starting with "help"
         # will be printed if present on the script.
```

```sh
\. <(util cat setup-zsh)       # sources rc files at `$HOME/.config/util/setup` for zsh
\. <(util cat completions-zsh) # adds completions for the util command for zsh
                               # to make it persistent, add this commands to your `$HOME/.zshrc`
```

For more information: `$ man util`.

> [!NOTE]
> At the moment, the only architecture suported is GNU/Linux.

### Customization

This project includes [default scripts](https://github.com/vncsmyrnk/shell-utils/tree/main/defaults), but you can easily add custom scripts by placing them in `$HOME/.config/util/scripts`. Subfolders within this directory represent subcommands for the `util` command.

Similarly, setup scripts for third-party applications are located in the [utils folder](https://github.com/vncsmyrnk/shell-utils/tree/main/utils). You can add your own by placing them in `$HOME/.config/util/setup`.

To automate update tasks when running `util update`, simply place your scripts in `$HOME/.config/util/scripts/on-update`.

> [!TIP]
> The best practice is to keep your scripts were you already store them and just create symbolic links (stow is a great tool for that) in the folders `$HOME/.config/util/scripts` and `$HOME/.config/util/setup`.

### Completions

This project comes with out-of-the-box support for autocompletion of the scripts accessible to the `util` command. The autocompletion is dynamically generated based on the comments provided in the scripts. A help message can be also added on the script and will be displayed when passing the `--help` option.

```sh
#!/bin/bash

# help: this message will be displayed when running `--help`

# Completions
# -a[Message for the a option]
# -b[Message for the b option]

echo "doing some operations here..."
```

> [!NOTE]
> At the moment, autocompletion is only suported in zsh.

### Real world examples

- [A use case in my dotfiles: sourcing setup folders automatically](https://github.com/vncsmyrnk/zsh-config/blob/ae9b9c00012adaeabe243c6998047a761519d205/.zshrc#L9-L11)
- [Another use case in my dotfiles: adding a custom "on-update" script](https://github.com/vncsmyrnk/zsh-config/blob/ae9b9c00012adaeabe243c6998047a761519d205/justfile#L37)

### Development

**shell-utils** is built on the principle of simplicity, ensuring that it remains lightweight and easy to use. The project avoids unnecessary complexity by leveraging tools that are commonly available on most unix-like systems, such as `sh`, `grep`, `sed`, and `find`.

## Install

```sh
git clone git@github.com:vncsmyrnk/shell-utils.git
cd shell-utils
just install # for uninstalling, run `$ just unset-config`
```
