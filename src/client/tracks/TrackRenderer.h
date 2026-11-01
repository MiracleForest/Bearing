#pragma once

// Client: curved track rendering (client build only).

#include <cstddef>
#include <optional>

#include "core/tracks/Math.h"

namespace br::client::tracks {

#ifdef BR_CLIENT
/// Number of curves the client received from the server (all dimensions).
[[nodiscard]] size_t knownCurves();
/// The smoothing angle of a tilted track the server told us about (nullopt: flat).
[[nodiscard]] std::optional<double> tiltAt(int dim, core::tracks::BlockPos3 const& pos);
#endif

} // namespace br::client::tracks
