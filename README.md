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

Run it directly in any directory where you want recordings to be written:

```bash
nix run github:pikdum/r-a-dio_recorder
```

Service wiring (systemd units, users, working directories) is intentionally
left to the consumer: run `packages.<system>.default` under systemd with
`WorkingDirectory` pointed at the recording directory.
