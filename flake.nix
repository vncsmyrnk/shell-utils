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
        vendorHash = "sha256-Yq64hzbakRzSl3vz0Sn4D2y13wjozQbao7yRX2NkdDk=";

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

      devShell = pkgs.mkShell {
        packages = with pkgs; [
          go
          gnumake
          golangci-lint
          shellcheck
          bash
          coreutils
        ];

        shellHook = ''
          mkdir -p .gocache .gomodcache
          export GOCACHE=$PWD/.gocache
          export GOMODCACHE=$PWD/.gomodcache
          export PATH="$PWD/dist/bin:$PATH"
          export PREFIX=$(realpath ./dist)
        '';
      };
    in
    {
      packages.${system}.default = shellUtils;
      devShells.${system}.default = devShell;
    };
}
