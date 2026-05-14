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
            ./Makefile
            ./.shellcheckrc
          ];
        };
        version = "0.0.1";
        vendorHash = "sha256-mP5UYLWlnGWCHHObkVvCNNxYzjWf/xg9Eonf7P+JpGQ=";

        doCheck = true;
        nativeCheckInputs = [
          pkgs.shellcheck
          pkgs.golangci-lint
        ];
        checkPhase = ''
          make check
        '';

        buildPhase = ''
          make PREFIX=${builtins.placeholder "out"}
        '';

        installPhase = ''
          make install PREFIX=$out
        '';

        doInstallCheck = true;
        nativeInstallCheckInputs = [
          pkgs.ripgrep
        ];
        installCheckPhase = ''
          make installcheck PREFIX=$out DESTDIR=""
        '';
      };
    in
    {
      packages.${system}.default = shellUtils;
    };
}
