#pragma once

// Vanilla hoppers and Bearing blocks (U54, SPEC §3.2). On NeoForge a hopper uses the item
// capability of the block it points into (insert) and of the block above it (extract): a hopper
// feeds a millstone, basin, depot, crushing wheel or deployer, and a hopper under a millstone or
// basin empties it. Bearing blocks have no vanilla container, so the game's hopper code is hooked:
// when the block a hopper pushes into, or pulls from, is a `bearing:` block with an item handler
// (`items::registerBlock`), the hopper moves one item through that handler instead (insert from
// the side it points into, extract from the bottom face), with the hopper's own 8-tick cooldown.
//
// Blocks whose Create counterpart has no item capability are excluded (funnels, blaze burners), as
// is the portable storage interface, which drives the hoppers next to it itself (U22). A unit can
// exclude more blocks:
//
//     common::hoppers::exclude("bearing:my_block");

#include <string>
#include <string_view>

namespace br::feature::common::hoppers {

/// Hoppers don't use the item handler of `blockId`.
void exclude(std::string blockId);
/// Whether hoppers use the item handler of `blockId` (a `bearing:` block that is not excluded;
/// whether it has a handler is checked at the block).
[[nodiscard]] bool reaches(std::string_view blockId);

} // namespace br::feature::common::hoppers
