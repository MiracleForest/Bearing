# Bearing

[![Build](https://github.com/MiracleForest/Bearing/actions/workflows/build.yml/badge.svg)](https://github.com/MiracleForest/Bearing/actions/workflows/build.yml)
[![License](https://img.shields.io/github/license/MiracleForest/Bearing)](COPYING.LESSER)

Rotational power, gears, machines and moving contraptions. Bearing brings simibubi and the Creators of Create's Java mod [Create](https://modrinth.com/mod/create) to Bedrock, for dedicated servers and single-player worlds.

> [!NOTE]
> Bearing is in early development. Bedrock limits are listed in [docs/SPEC.md](docs/SPEC.md) §8.

## Install

You need Minecraft Bedrock Edition **1.26.51** for Windows (x64) with LeviLamina **26.51.x** (on a client, installed through [LeviLauncher](https://github.com/LiteLDev/LeviLauncher)).

With [lip](https://github.com/LiteLDev/lip):

```sh
lip install github.com/MiracleForest/Bearing      # dedicated server
lip install github.com/MiracleForest/Bearing#client  # client
```

Or download the zip from the [latest release](https://github.com/MiracleForest/Bearing/releases/latest) and extract it next to `LeviLamina/`:

| Where | Zip | Folder |
| --- | --- | --- |
| Dedicated server | `bearing-server-windows-x64.zip` | `plugins/Bearing/` |
| Client (LeviLauncher) | `bearing-client-windows-x64.zip` | `mods/Bearing/` |

## Commands

| Command | Who | What it does |
| --- | --- | --- |
| `/create reload` | Operators, console | Reloads the configuration and translations. |
| `/create selftest ["glob"]` | Operators, console | Runs the in-game selftests. |
| `/create config [section]` | Everyone (changes: operators) | Opens the configuration screen (a form without the client mod). |
| `/create ponder [id]` | Everyone (client mod) | Opens Ponder. |
| `/create debuginfo` | Everyone | Prints the debug information. |

All commands are listed in [docs/SPEC.md](docs/SPEC.md) §6.

`/bearing` is an alias of `/create`.

## Configuration

Settings live in `config/*.json` inside the mod folder (`plugins/Bearing/` or `mods/Bearing/`). Each file is created with defaults on first start.

| File | Setting | Default | Meaning |
| --- | --- | --- | --- |
| `mod.json` | `language` | `en_US` | Language of server messages when a player's own language has no translation. |
| | `usePlayerLocale` | `true` | Use each player's game language when a translation exists. |
| | `requireResourcePack` | `true` | Dedicated server: players must accept the resource pack to join. |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). [AGENTS.md](AGENTS.md) is the developer guide.

## Credits

Bearing reproduces the behaviour of [Create](https://github.com/Creators-of-Create/Create) by simibubi and the Creators of Create. It copies no code or assets from it.

## License

[LGPL-3.0-or-later](COPYING.LESSER)
