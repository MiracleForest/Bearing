// Goggle information of the crafting tools: Create's mechanical crafter and saw are plain kinetic
// blocks (kinetic stats only, no contents line).

#include <string>

#include "feature/crafter/Internal.h"
#include "feature/goggles/GoggleInfo.h"

namespace br::feature::crafter {

namespace goggles = feature::goggles;

BR_REGISTER_GOGGLE_INFO(std::string(kCrafter), {.goggle = goggles::kineticGoggleTooltip, .hover = goggles::kineticHoverTooltip, .replaceDefaults = true});
BR_REGISTER_GOGGLE_INFO(std::string(kSaw), {.goggle = goggles::kineticGoggleTooltip, .hover = goggles::kineticHoverTooltip, .replaceDefaults = true});

} // namespace br::feature::crafter
