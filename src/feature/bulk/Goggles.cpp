// Goggle information of the bulk processing blocks: Create's millstone is a plain kinetic block
// (kinetic stats only, no contents line) and the crushing wheel controller has none.

#include <string>

#include "feature/bulk/Bulk.h"
#include "feature/goggles/GoggleInfo.h"

namespace br::feature::bulk {

namespace goggles = feature::goggles;

BR_REGISTER_GOGGLE_INFO(std::string(kMillstone), {.goggle = goggles::kineticGoggleTooltip, .hover = goggles::kineticHoverTooltip, .replaceDefaults = true});
BR_REGISTER_GOGGLE_INFO(std::string(kController), {.replaceDefaults = true});

} // namespace br::feature::bulk
