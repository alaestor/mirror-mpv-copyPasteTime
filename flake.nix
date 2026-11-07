{
  description = "mpv script for copying and pasting timestamps";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      perSystem = { pkgs, self', ... }: let
        clipboard = pkgs.stdenvNoCC.mkDerivation {
          pname = "mpv-clipboard";
          version = "0-unstable-2022-11-10";
          src = pkgs.fetchFromGitHub {
            owner = "CogentRedTester";
            repo = "mpv-clipboard";
            rev = "d5cb11094da23a2153370964b65dbbc44c3058df";
            hash = "sha256-426WEPd/hfvngAIzNuQOLhcXgpP5ekX7EmtlFCbHhAM=";
            sparseCheckout = [ "clipboard.lua" ];
          };
          dontUnpack = true;
          installPhase = ''
            install -Dm444 "$src/clipboard.lua" "$out/share/mpv/scripts/clipboard.lua"
          '';
          passthru.scriptName = "clipboard.lua";
          meta = {
            description = "Clipboard commands for mpv scripts";
            homepage = "https://github.com/CogentRedTester/mpv-clipboard";
            license = pkgs.lib.licenses.mit;
            platforms = pkgs.lib.platforms.all;
          };
        };
      in {
        checks.unit = pkgs.runCommand "mpv-copyPasteTime-unit-tests" {
          nativeBuildInputs = [ pkgs.luajit ];
        } ''
          cd ${./.}
          luajit tests/unit.lua
          touch "$out"
        '';
        packages.mpv-clipboard = clipboard;
        packages.mpv-copyPasteTime = pkgs.stdenvNoCC.mkDerivation {
          pname = "mpv-copyPasteTime";
          version = "0.1.0";
          src = ./.;
          dontUnpack = true;
          installPhase = ''
            install -Dm444 "$src/copyPasteTime.lua" "$out/share/mpv/scripts/copyPasteTime.lua"
          '';
          passthru = {
            scriptName = "copyPasteTime.lua";
            dependencies = [ clipboard ];
          };
          meta = {
            description = "Copy and paste timestamps and copy frame numbers in mpv";
            homepage = "https://git.0x04.cc/alaestor/mpv-copyPasteTime";
            license = pkgs.lib.licenses.gpl3;
            platforms = pkgs.lib.platforms.all;
          };
        };
        packages.default = self'.packages.mpv-copyPasteTime;
      };
    };
}
