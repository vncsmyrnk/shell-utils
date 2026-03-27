{
  description = "A shell-agnostic utility tool designed to make your scripts accessible everywhere";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      shellUtils = pkgs.buildGoModule {
        name = "util";
        src = pkgs.lib.fileset.toSource {
          root = ./.;
          fileset = pkgs.lib.fileset.unions [
            ./cmd
            ./defaults
            ./extra
            ./completions
            ./man
            ./go.mod
          ];
        };
        version = "0.0.1";
        vendorHash = null;
        doCheck = false;

        subPackages = [
          "cmd/runner"
        ];

        env = {
          CGO_ENABLED = 1;
        };

        ldflags = [
          "-s"
          "-w"
          "-X main.baseDefaultScriptsPath=${builtins.placeholder "out"}/share/shell-utils/scripts"
        ];

        postInstall = ''
          mkdir -p $out/share/shell-utils/scripts $out/share/zsh/site-functions $out/share/man/man1

          mv $out/bin/runner $out/bin/util
          cp -a defaults/* $out/share/shell-utils/scripts/
          cp -a extra/* $out/share/shell-utils/scripts/
          cp -a completions/zsh/* $out/share/zsh/site-functions/
          cp -a man/* $out/share/man/man1/
        '';
      };
    in
    {
      packages.${system}.default = shellUtils;
    };
}
