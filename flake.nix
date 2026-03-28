{
  description = "r/a/dio recorder";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs =
    { self, nixpkgs }:
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

      checks = forAllSystems (pkgs: {
        default = mkPackage pkgs;
      });

      formatter = forAllSystems (pkgs: pkgs.nixfmt-rfc-style);

      nixosModules.default =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          cfg = config.services.r-a-dio-recorder;
          user = "r-a-dio-recorder";
          group = user;
        in
        {
          options.services.r-a-dio-recorder = {
            enable = lib.mkEnableOption "the r/a/dio recorder service";

            workingDirectory = lib.mkOption {
              type = lib.types.strMatching "^/.*";
              default = "/var/lib/r-a-dio-recorder";
              example = "/srv/r-a-dio";
              description = "Directory where recordings and logs are written.";
            };
          };

          config = lib.mkIf cfg.enable {
            users.groups.${group} = { };

            users.users.${user} = {
              isSystemUser = true;
              group = group;
              description = "r/a/dio recorder service user";
              home = cfg.workingDirectory;
              createHome = false;
            };

            systemd.tmpfiles.rules = [
              "d ${cfg.workingDirectory} 0750 ${user} ${group} -"
            ];

            systemd.services.r-a-dio-recorder = {
              description = "Record the live r/a/dio stream";
              wantedBy = [ "multi-user.target" ];
              wants = [ "network-online.target" ];
              after = [ "network-online.target" ];

              serviceConfig = {
                Type = "simple";
                ExecStart = "${mkPackage pkgs}/bin/r-a-dio-recorder";
                User = user;
                Group = group;
                WorkingDirectory = cfg.workingDirectory;
                Restart = "always";
                RestartSec = 30;
                UMask = "0027";
                NoNewPrivileges = true;
                PrivateTmp = true;
                ProtectHome = true;
                ProtectSystem = "strict";
                ReadWritePaths = [ cfg.workingDirectory ];
              };
            };
          };
        };

    };
}
