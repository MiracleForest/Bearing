#pragma once

// Pipe flows for other units (added by U58 for the SmartObserverBlockEntity, which watches
// the FluidTransportBehaviour of the pipe it looks at). Server thread only.

#include <vector>

#include "core/GlobalPos.h"
#include "feature/common/Capabilities.h"

namespace br::feature::pipes {

/// Whether the block at `pos` has the FluidTransportBehaviour (fluid / glass / encased /
/// smart pipes, pumps, valves).
[[nodiscard]] bool hasFluidTransport(core::GlobalPos const& pos);
/// The fluids of the complete inbound flows of that block (`getFlow(side)` with
/// `inbound && complete`), one per side that has one.
[[nodiscard]] std::vector<common::fluids::FluidStack> inboundFlows(core::GlobalPos const& pos);

} // namespace br::feature::pipes
