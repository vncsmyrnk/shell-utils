{
  description =
    "A shell-agnostic utility tool designed to make your scripts accessible everywhere";

  inputs = { nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages.${system}.default = pkgs.stdenv.mkDerivation {
        name = "shell-utils";

        src = ./.;

        nativeBuildInputs = [ pkgs.makeWrapper ];

        installPhase = ''
          mkdir -p $out/bin $out/share/shell-utils/scripts $out/share/zsh/site-functions $out/share/man/man1

          cp -a bin/* $out/bin/
          cp -a defaults/* $out/share/shell-utils/scripts/
          cp -a extra/* $out/share/shell-utils/scripts/
          cp -a completions/zsh/* $out/share/zsh/site-functions/
          cp -a man/* $out/share/man/man1/

          wrapProgram $out/bin/util \
            --prefix PATH : ${
              pkgs.lib.makeBinPath [
                pkgs.fd
                pkgs.gnugrep
                pkgs.gnused
                pkgs.findutils
                pkgs.coreutils
                pkgs.bash
                pkgs.openssl
              ]
            } \
            --set SHELL_UTILS_SCRIPTS $out/share/shell-utils/scripts
        '';
      };

      apps.${system}.default = {
        type = "app";
        program = "${self.packages.${system}.default}/bin/util";
      };
    };
}
