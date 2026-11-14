#pragma once

// Goggle overlay contract (U8, docs/SPEC.md §3.6.8): what a block shows next to the crosshair
// (client mod) or in the action bar (vanilla clients) while a player looks at it. The
// IHaveGoggleInformation (only with Engineer's Goggles on), IHaveHoveringInformation (always),
// IHaveCustomOverlayIcon and IProxyHoveringInformation, plus the speed/stress text helpers of
// the IRotate for gauges.
//
// Defaults (Bearing blocks, unless a provider sets `replaceDefaults`): kinetic blocks show
// the kinetic / generator stats and the overstressed / not-fast-enough hints; blocks with
// a fluid capability show their tanks (containedFluidTooltip), with an item capability
// their stored items, with a heat provider their heat level.
//
//     #include "feature/goggles/GoggleInfo.h"
//     namespace goggles = br::feature::goggles;
//     BR_REGISTER_GOGGLE_INFO("bearing:stressometer", {
//         .goggle = [](goggles::InfoContext const& c, goggles::Tooltip& t) {
//             t.push_back(goggles::line(c.tr("bearing.gui.gauge.info_header", "Gauge Information:")));
//             ...
//             return true;
//         },
//     });
//
// Lines are Bedrock text with formatting codes (core/goggles/Tooltip.h `fmt::`), already
// translated for the viewer (`InfoContext::tr`). Server thread only.

#include <functional>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

#include "core/GlobalPos.h"
#include "core/goggles/Tooltip.h"
#include "core/kinetics/Solver.h"
#include "mod/I18n.h"
#include "mod/Registry.h"

class Block;
class BlockSource;
class Player;

namespace br::feature::goggles {

using Tooltip = std::vector<std::string>;

/// The block a player looks at.
struct InfoContext {
    Player&         player;
    BlockSource&    region;
    core::GlobalPos pos;
    Block const&    block;
    bool            sneaking       = false; ///< the isPlayerSneaking
    bool            wearingGoggles = false;

    /// Translation in the viewer's language.
    template <class... Args>
    [[nodiscard]] std::string tr(std::string_view key, std::string_view fallback, Args const&... args) const {
        return trFor(player, key, fallback, args...);
    }
};

struct InfoProvider {
    /// The addToGoggleTooltip: only asked while wearing goggles; true when it added lines.
    std::function<bool(InfoContext const&, Tooltip&)> goggle;
    /// The addToTooltip (IHaveHoveringInformation): asked with or without goggles.
    std::function<bool(InfoContext const&, Tooltip&)> hover;
    /// Item id drawn on the panel (IHaveCustomOverlayIcon; default "bearing:goggles").
    std::function<std::string(InfoContext const&)> icon;
    /// The IProxyHoveringInformation: show the information of another position.
    std::function<std::optional<core::GlobalPos>(InfoContext const&)> proxy;
    /// Don't add Bearing's default lines (kinetic stats, fluids, items, heat) for this block.
    bool replaceDefaults = false;
};

/// Adds a provider for `blockId` (several providers of a block are asked in registration order).
void registerBlock(std::string blockId, InfoProvider provider);

/// The GogglesItem.addIsWearingPredicate (default: Engineer's Goggles in the head slot).
void addWearingPredicate(std::function<bool(Player const&)> predicate);
[[nodiscard]] bool isWearingGoggles(Player const& player);

// ---- kinetic block properties used by the overlay and the item tooltips ----------------------

using core::kinetics::SpeedLevel;
/// The IRotate.getMinimumRequiredSpeedLevel ("not fast enough" hint).
void setSpeedRequirement(std::string blockId, SpeedLevel level);
[[nodiscard]] SpeedLevel speedRequirementOf(std::string_view blockId);
/// The IRotate.hideStressImpact (no impact line in the item tooltip).
void setHideStressImpact(std::string blockId, bool hide = true);
[[nodiscard]] bool hidesStressImpact(std::string_view blockId);
/// The BlockStressValues.setGeneratorSpeed (item tooltip "-> N su"; `mayGenerateLess`
/// prints "Up to N su"). The values for the hand crank, valve handles, water wheels and the
/// creative motor are preset.
struct GeneratorSpeed {
    double rpm             = 0;
    bool   mayGenerateLess = false;
};
void setGeneratorSpeed(std::string blockId, double rpm, bool mayGenerateLess = false);
[[nodiscard]] std::optional<GeneratorSpeed> generatorSpeedOf(std::string_view blockId);

// ---- line helpers (LangBuilder / TooltipHelper / IRotate) ----------------------------

/// The forGoggles: 4 + `indent` spaces, then `text`.
[[nodiscard]] inline std::string line(std::string_view text, int indent = 0) { return core::goggles::forGoggles(text, indent); }
/// The Lang.number.
[[nodiscard]] inline std::string number(double v) { return core::goggles::formatNumber(v); }
/// The TooltipHelper.cutTextComponent(hint, GRAY_AND_WHITE) added with forGoggles.
void addHint(Tooltip& tooltip, std::string const& text);
/// The SpeedLevel.getFormattedSpeedText (gauges).
[[nodiscard]] std::string formattedSpeed(Player const& viewer, float speed, bool overstressed);
/// The StressImpact.getFormattedStressText (gauges; `percent` 0..1+).
[[nodiscard]] std::string formattedStress(Player const& viewer, double percent);

/// The KineticBlockEntity / GeneratingKineticBlockEntity tooltips, for providers that
/// replace the defaults but want them too ("super" calls).
bool kineticGoggleTooltip(InfoContext const& ctx, Tooltip& tooltip);
bool kineticHoverTooltip(InfoContext const& ctx, Tooltip& tooltip);
/// The IHaveGoggleInformation.containedFluidTooltip over the fluid capability.
bool fluidTooltip(InfoContext const& ctx, Tooltip& tooltip);

/// The overlay of the block at `pos` for `player` (what the client mod draws and the action bar
/// shows). Empty lines: nothing to show.
struct Overlay {
    Tooltip     lines;
    std::string icon = "bearing:goggles";
};
[[nodiscard]] Overlay overlayFor(Player& player, core::GlobalPos const& pos);

namespace detail {
struct InfoRegistrar {
    InfoRegistrar(std::string id, InfoProvider p) { registerBlock(std::move(id), std::move(p)); }
};
} // namespace detail

} // namespace br::feature::goggles

/// Registers a goggle info provider at static init: `BR_REGISTER_GOGGLE_INFO("bearing:x", {...});`
#define BR_REGISTER_GOGGLE_INFO(id, ...)                                                                               \
    static ::br::feature::goggles::detail::InfoRegistrar BR_UNIQUE(br_goggle_info_)(id, __VA_ARGS__)
