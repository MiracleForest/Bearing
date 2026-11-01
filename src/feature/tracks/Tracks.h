#pragma once

// Train tracks (U5): the `bearing:track` block, curved tracks and the track graph.
//
// Contract for later units (trains U27, signals/observers U28, stations U27, wrench U8):
//
//   auto& rail = br::feature::tracks::railways();          // every track graph of the world
//   auto  at   = br::feature::tracks::locate(dim, pos);    // nearest graph location
//   rail.findPath({...});                                    // A* over directed edges
//   rail.addPoint({...});                                    // signals / stations / observers
//   br::feature::tracks::onGraphChanged([] { ... });        // after every batch of changes
//
// Everything runs on the server thread and is valid while a world is loaded
// (`game::db::onWorldReady` … `onWorldClosed`). Graph types live in `core/tracks/Graph.h`.

#include <functional>
#include <optional>
#include <string_view>

#include "core/GlobalPos.h"
#include "core/tracks/CurveStore.h"
#include "core/tracks/Graph.h"

class Block;
class BlockPos;
class BlockSource;
class Player;
class Vec3;

namespace br::feature::tracks {

inline constexpr std::string_view kTrackId     = "bearing:track";
inline constexpr std::string_view kFakeTrackId = "bearing:fake_track";
/// Block states of `bearing:track`.
/// core::tracks::Shape = shape + 16 * shape_hi (Bedrock allows at most 16 values per state)
inline constexpr std::string_view kShapeState   = "bearing:shape";
inline constexpr std::string_view kShapeHiState = "bearing:shape_hi";
inline constexpr std::string_view kTurnState    = "bearing:turn"; ///< 1 while curves start here (Create's HAS_BE)

/// The world's track graphs.
[[nodiscard]] core::tracks::Railways& railways();
/// The world's curves (indexed by end blocks and by the blocks they pass through).
[[nodiscard]] core::tracks::CurveStore const& curves();

[[nodiscard]] bool isTrack(Block const& block);
[[nodiscard]] bool isFakeTrack(Block const& block);
/// Shape of the track at `pos` (nullopt if it isn't a track or the chunk isn't loaded).
[[nodiscard]] std::optional<core::tracks::Shape> shapeAt(BlockSource& region, BlockPos const& pos);

/// Nearest graph location to a world position in `dim` (within `maxDistance` blocks).
[[nodiscard]] std::optional<core::tracks::GraphLocation> locate(int dim, Vec3 const& pos, double maxDistance = 2);
/// The graph location at the centre of the track block `pos`, travelling along its axis in the
/// direction closest to `facing` (what a signal / station / observer placed against the track
/// targets: Create's TrackTargetingBehaviour).
[[nodiscard]] std::optional<core::tracks::GraphLocation> targetAt(core::GlobalPos const& pos, Vec3 const& facing);

/// Called after the graph changed (once per tick at most).
void onGraphChanged(std::function<void()> fn);

/// Removes the curves of the track at `pos` and gives their items (tracks, girders) to `player`
/// instead of dropping them (Create: sneak-wrenching a track in survival). Returns the number of
/// curves removed. The block itself is left to the caller.
int dismantleCurves(Player& player, core::GlobalPos const& pos);

} // namespace br::feature::tracks
