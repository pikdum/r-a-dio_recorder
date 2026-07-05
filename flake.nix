{
  description = "r/a/dio recorder";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs =
    { nixpkgs, ... }:
    let
      lib = nixpkgs.lib;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems =
        f:
        lib.genAttrs systems (
          system:
          let
            pkgs = import nixpkgs { inherit system; };
          in
          f pkgs
        );
      mkPackage =
        pkgs:
        pkgs.writeShellApplication {
          name = "r-a-dio-recorder";
          runtimeInputs = with pkgs; [
            coreutils
            curl
            gawk
            jq
            procps
            wget
          ];
          text = builtins.readFile ./record-stream.sh;
          meta = {
            description = "Daemon to record the live r/a/dio stream";
            mainProgram = "r-a-dio-recorder";
            platforms = lib.platforms.linux;
          };
        };
    in
    {
      packages = forAllSystems (pkgs: {
        default = mkPackage pkgs;
      });

      apps = forAllSystems (
        pkgs:
        let
          package = mkPackage pkgs;
        in
        {
          default = {
            type = "app";
            program = "${package}/bin/r-a-dio-recorder";
            meta.description = package.meta.description;
          };
        }
      );

      formatter = forAllSystems (pkgs: pkgs.nixfmt-rfc-style);
    };
}
