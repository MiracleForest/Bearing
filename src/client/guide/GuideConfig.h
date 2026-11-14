#pragma once

// `config/guide.json` (client mod, SPEC §5): the Guide client options plus the renderer's.

#ifdef BR_CLIENT

#include "mod/Config.h"

namespace br::client::guide {

struct GuideConfig {
    int version = 1;
    /// The "Comfy Reading" default: scenes slow down while a text is shown.
    bool comfyReading = false;
    /// Hold time scale of the Guide key (1 = the ~11 ticks).
    float holdSpeed = 1.0f;
    /// The Guide key (Windows virtual-key code; 0x57 = W, the default). Rebound in game with
    /// the "Guide Key" button of the Guide welcome screen.
    int guideKey = 0x57;
    /// Depth of a scene block in the UI pass, as a fraction of its on-screen size.
    float depthScale = 0.1f;
    /// Colour of the placeholder drawn for blocks that are not registered (ARGB).
    unsigned placeholderColour = 0xFFFF55FF;
};

[[nodiscard]] inline GuideConfig const& config() { return br::config::get<GuideConfig>(); }

} // namespace br::client::guide

#endif // BR_CLIENT
