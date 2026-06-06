![shell](https://img.shields.io/badge/Shell-121011?style=plastic&logo=gnu-bash&logoColor=white)
[![Go Version](https://img.shields.io/badge/dynamic/regex?url=https%3A%2F%2Fraw.githubusercontent.com%2Fvncsmyrnk%2Fshell-utils%2Frefs%2Fheads%2Fmain%2Fgo.mod&search=go%20(.*)&replace=%241&style=plastic&logo=go&label=Go&color=blue)](https://go.dev/)
[![AUR Version](https://img.shields.io/aur/version/shell-utils-git?style=plastic&label=AUR&logo=archlinux)](https://aur.archlinux.org/packages/shell-utils-git)
[![APT Version](https://img.shields.io/badge/dynamic/regex?url=https%3A%2F%2Ffuryous.vncsmyrnk.dev%2F%3Fuser%3Dvncsmyrnk%26pkg%3Dshell-utils&search=.*&style=plastic&logo=debian&label=apt&color=d70a53)](https://repo.fury.io/vncsmyrnk/)
<br>
[![CI/CD workflow](https://github.com/vncsmyrnk/shell-utils/actions/workflows/ci-cd.yaml/badge.svg)](https://github.com/vncsmyrnk/shell-utils/actions/workflows/ci-cd.yaml)
[![contributions](https://img.shields.io/badge/contributions-welcome-brightgreen?labelColor=384047&color=33cb56)](https://github.com/vncsmyrnk/shell-utils/issues)

# shell-utils 🛠️

A collection of useful shell scripts and wrappers for common shell interactions.

It provides the `util` command, which acts as a router to find and execute each individual script according to a query. All arguments are automatically forwarded to the scripts. It ships with autocompletion and global `--help` and `--to-stdout` flags.

For security reasons, the `util` router sets a predefined set of environment variables, including a strict `$PATH`.

## Usage


```sh
util random generate -l 20 # this will execute ./scripts/random/generate.sh
                           # automatically forwarding all arguments.
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
