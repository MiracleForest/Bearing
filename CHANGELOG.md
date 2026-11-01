# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-11-01

Levitate is now Bearing, published by MiracleForest. This release is **breaking**: the namespace changed
from `levitate:` to `bearing:`, so worlds saved with 0.1.0 do not carry over (see *Removed*).

### Changed

- Levitate is now **Bearing**. The repository is [MiracleForest/Bearing](https://github.com/MiracleForest/Bearing)
  (it was LiteLDev/Levitate, then MiracleForest/Levitate; GitHub redirects the old URLs).
- The lip package is now `github.com/MiracleForest/Bearing` (was `github.com/LiteLDev/Levitate`).
  Installing by the new path needs lip 0.35.0 or later. To move an existing install, run
  `lip uninstall github.com/LiteLDev/Levitate[#client]` and then `lip install github.com/MiracleForest/Bearing[#client]`.
  Versions up to 0.1.0 stay installable at the old path.
- The mod folder is now `plugins/Bearing/` (server) and `mods/Bearing/` (client), and the release zips are
  `bearing-server-windows-x64.zip` and `bearing-client-windows-x64.zip`. To keep your settings, move
  `config/` from the old `Levitate/` folder into the new one.
- **Breaking:** the block, item and entity namespace is now `bearing:` (was `levitate:`), the resource and behaviour
  packs are named Bearing, and `/bearing` is the alias of `/create` (was `/levitate`).

### Removed

- Worlds saved with 0.1.0 do not carry over: their `levitate:` blocks, items and entities are not
  recognised under the new namespace.

## [0.1.0] - 2026-11-01

The first release: the behaviour of Create 6.0.10 on Bedrock 1.26.51 (LeviLamina 26.51.x), for
dedicated servers and for local worlds on the client. Players without the client mod can join a
server and play with forms in place of Create's screens. `docs/SPEC.md` §8 lists what Bedrock cannot do.

### Added

- Kinetic networks: speed and direction through shafts, cogwheels, gearboxes, clutches, gearshifts,
  chain drives and belts, with stress capacity, stress impact and overstress. Generators: hand crank,
  valve handles, water wheels, windmills, the creative motor and steam engines.
- Tools and info: the wrench, engineer's goggles with the goggle overlay, kinetic tooltips, the
  speedometer and the stressometer.
- Materials and world generation: zinc, brass, andesite alloy, rose quartz, the crafting components,
  food, and the decorative stone palettes. Building blocks: casings, windows, copper, scaffolds,
  ladders, bars, doors, girders, brackets and placards.
- Item logistics: belts, depots, weighted ejectors, funnels, tunnels, chutes, smart chutes, item
  vaults, filters and attribute filters, and value boxes with Create's click and hold.
- Processing: the millstone, crushing wheels, the encased fan's bulk processing, the basin with press,
  mixer and blaze burner, the deployer, the mechanical arm, sequenced assembly, the mechanical crafter,
  the saw and the drill, with Create's recipes.
- Fluids: pipes, pumps, valves, smart pipes, tanks, boilers, the steam whistle, the spout, the item
  drain, the hose pulley, the portable fluid interface, honey and chocolate.
- Contraptions: pistons, pulleys, elevators, the gantry, bearings, windmills, clockwork bearings,
  minecart contraptions, chassis, super glue, the sticker and the contraption actors (harvester,
  plough, roller, storage interfaces, contraption controls, seats).
- Redstone: redstone links, the analog lever, pulse repeaters, extenders and timers, latches, the
  smart observer, the threshold switch, contacts, comparator outputs and the display link with
  display boards, nixie tubes and the clipboard.
- Packages and stock: the packager, repackager, frogport, chain conveyor, postboxes, stock links,
  the stock ticker, factory gauges, redstone requesters and table cloth shops.
- Trains: tracks with curves, stations, bogeys, train controls, schedules, signals, track observers
  and the train map.
- Schematics: the schematic table, schematicannon, schematic and quill, and the crafting blueprint.
- Equipment: the toolbox, backtanks, diving gear, the extendo grip, the potato cannon, the wand of
  symmetry, the worldshaper, the linked controller, sand paper and the tree fertilizer.
- Ponder scenes, Create's advancements, the in-game config screen (`/create config`) and Create's
  commands (`/create clone`, `debuginfo`, `util`, `killtrain`, `glue` and more).
- English and Simplified Chinese translations.

[Unreleased]: https://github.com/MiracleForest/Bearing/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/MiracleForest/Bearing/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/MiracleForest/Bearing/releases/tag/v0.1.0
