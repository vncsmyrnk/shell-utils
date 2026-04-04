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
            ./completions
            ./extra
            ./internal
            ./man
            ./go.mod
            ./go.sum
          ];
        };
        version = "0.0.1";
        vendorHash = "sha256-mP5UYLWlnGWCHHObkVvCNNxYzjWf/xg9Eonf7P+JpGQ=";
        doCheck = false;

        subPackages = [
          "cmd/runner"
          "cmd/completion"
          "cmd/config"
        ];

        env = {
          CGO_ENABLED = 1;
        };

        ldflags = [
          "-s"
          "-w"
          "-X shellutils/internal.BaseDefaultScriptsPath=${builtins.placeholder "out"}/share/shell-utils/scripts"
        ];

        postInstall = ''
          mkdir -p $out/share/shell-utils/scripts $out/share/zsh/site-functions $out/share/man/man1

          mv $out/bin/runner $out/bin/util
          mv $out/bin/completion $out/bin/util-complete
          mv $out/bin/config $out/share/shell-utils/scripts/
          cp -a extra/* $out/share/shell-utils/scripts/
          cp -a completions/zsh/_util $out/share/zsh/site-functions/
          cp -a completions/zsh/*.completions.zsh $out/share/shell-utils/scripts/
          cp -a man/* $out/share/man/man1/
        '';
      };
    in
    {
      packages.${system}.default = shellUtils;
    };
}
