#pragma once

#include "ll/api/io/Logger.h"

namespace br {

/// The mod's logger (LeviLamina console + log file, prefixed "Bearing").
/// Every message is flushed immediately so e2e harnesses can tail the log.
[[nodiscard]] ll::io::Logger& log();

} // namespace br
