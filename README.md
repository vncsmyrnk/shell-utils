# shell-utils 🛠️

Have you ever struggled to locate useful scripts scattered across multiple files when you need them the most? _shell utils_ is a shell-agnostic utility tool designed to make your scripts accessible everywhere using the `util` command.

Do you also maintain various run command files for setting up aliases, environment variables, and shell plugins? _shell utils_ includes a configuration script that automatically sources all your essential configurations.

do you manually install apps and maintain scripts to update them? with _shell utils_, you can configure your scripts to run automatically whenever `util update` is executed, streamlining all your update tasks.

## Usage

```sh
util update # this will execute an script named update.sh
            # in your $HOME/.config/util/scripts directory

util git checkout-pr # this will execute an script named checkout-pr.sh
                     # in your $HOME/.config/util/git directory
```

The `util` command accepts a name argument, representing the script to execute from `$HOME/.config/util/scripts`. Any additional arguments are seamlessly passed to the specified script.

```sh
\. <(util cat setup-zsh)       # sources rc files at `$HOME/.config/util/setup` for zsh
\. <(util cat completions-zsh) # adds completions for the util command for zsh
                               # to make it persistent, add this commands to your `$HOME/.zshrc`
```

### Customization

This project includes [default scripts](https://github.com/vncsmyrnk/shell-utils/tree/main/defaults), but you can easily add custom scripts by placing them in `$HOME/.config/util/scripts`. Subfolders within this directory represent subcommands for the `util` command.

Similarly, setup scripts for third-party applications are located in the [utils folder](https://github.com/vncsmyrnk/shell-utils/tree/main/utils). You can add your own by placing them in `$HOME/.config/util/setup`.

To automate update tasks when running `util update`, simply place your scripts in `$HOME/.config/util/scripts/on-update`.

> [!TIP]
> The best practice is to keep your scripts were you already store them and just create symbolic links (stow is a great tool for that) in the folders `$HOME/.config/util/scripts` and `$HOME/.config/util/setup`.

### A real world example

[A use case in my dotfiles](https://github.com/vncsmyrnk/dotfiles).

## Install

```sh
git clone git@github.com:vncsmyrnk/shell-utils.git
just install # for uninstalling, run `$ just unset-config`
```

> [!NOTE]
> Only avaiable for zsh for now, but open to implemenations in other shells.
