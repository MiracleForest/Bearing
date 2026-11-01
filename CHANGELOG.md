# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- The repository moved to [MiracleForest/Levitate](https://github.com/MiracleForest/Levitate).
- The lip package is now `github.com/MiracleForest/Levitate` (was `github.com/LiteLDev/Levitate`).
  Installing by the new path needs lip 0.35.0 or later. To move an existing install, run `lip update`
  with a lip that follows renamed packages, or `lip uninstall github.com/LiteLDev/Levitate[#client]`
  and then `lip install github.com/MiracleForest/Levitate[#client]`; `plugins/Levitate/config/` (server)
  and `mods/Levitate/config/` (client) are kept. Versions up to 0.1.0 stay installable at the old path.

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

[Unreleased]: https://github.com/MiracleForest/Levitate/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/MiracleForest/Levitate/releases/tag/v0.1.0
