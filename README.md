# r/a/dio recorder

daemon to record r/a/dio dj streams

## requirements

```
sudo apt-get install -y curl wget jq gawk
```

## nix

The flake exposes:

- `packages.<system>.default`
- `apps.<system>.default`
- `nixosModules.default`

Run it directly in any directory where you want recordings to be written:

```bash
nix run github:pikdum/r-a-dio_recorder
```

Use it from a NixOS flake like this:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    r-a-dio-recorder.url = "github:pikdum/r-a-dio_recorder";
  };

  outputs = { nixpkgs, r-a-dio-recorder, ... }: {
    nixosConfigurations.my-host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        r-a-dio-recorder.nixosModules.default
        {
          services.r-a-dio-recorder = {
            enable = true;
            workingDirectory = "/srv/r-a-dio";
          };
        }
      ];
    };
  };
}
```

If `workingDirectory` is omitted, the service writes to `/var/lib/r-a-dio-recorder`.
