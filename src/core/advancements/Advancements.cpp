#include "core/advancements/Advancements.h"

#include <algorithm>
#include <unordered_map>

namespace br::core::advancements {

namespace {

using enum Type;

// Create 6.0.10's AllAdvancements, in its order. Icons are Bearing's ids (blocks Bearing has no
// port of show the nearest vanilla item).
constexpr Def kDefs[] = {
    {"root", "", "bearing:brass_hand", Silent, {}, true},

    // Andesite - central branch
    {"andesite_alloy", "root", "bearing:andesite_alloy", Normal, {"bearing:andesite_alloy"}},
    {"andesite_casing", "andesite_alloy", "bearing:andesite_casing", Noisy},
    {"mechanical_press", "andesite_casing", "bearing:mechanical_press", Noisy},
    {"encased_fan", "mechanical_press", "bearing:encased_fan", Normal},
    {"fan_processing", "encased_fan", "bearing:propeller", Normal},
    {"saw_processing", "fan_processing", "bearing:mechanical_saw", Normal},
    {"compacting", "saw_processing", "minecraft:iron_block", Normal},
    {"belt", "compacting", "bearing:belt_connector", Normal},
    {"funnel", "belt", "bearing:andesite_funnel", Normal},
    {"chute", "funnel", "bearing:chute", Normal},
    {"mechanical_mixer", "chute", "bearing:mechanical_mixer", Normal},
    {"burner", "mechanical_mixer", "bearing:blaze_burner", Normal, {"bearing:blaze_burner"}},

    // Andesite - top branch
    {"water_wheel", "andesite_alloy", "bearing:water_wheel", Normal},
    {"windmill", "water_wheel", "bearing:sail_frame", Normal},
    {"shifting_gears", "windmill", "bearing:cogwheel", Normal},
    {"millstone", "shifting_gears", "bearing:millstone", Normal},
    {"super_glue", "millstone", "bearing:super_glue", Normal},
    {"contraption_actors", "super_glue", "bearing:mechanical_harvester", Normal},
    {"portable_storage_interface", "contraption_actors", "bearing:portable_storage_interface", Normal},
    {"wrench_goggles", "portable_storage_interface", "bearing:wrench", Normal, {"bearing:wrench", "bearing:goggles"}},
    {"stressometer", "wrench_goggles", "bearing:stressometer", Normal},
    {"cuckoo_clock", "stressometer", "minecraft:clock", Noisy},

    // Andesite - expert branch
    {"windmill_maxed", "andesite_alloy", "bearing:white_sail", Expert},
    {"ejector_maxed", "windmill_maxed", "bearing:weighted_ejector", Expert},
    {"pulley_maxed", "ejector_maxed", "bearing:rope_pulley", Expert},
    {"cart_pickup", "pulley_maxed", "bearing:minecart_contraption", Expert},
    {"anvil_plough", "cart_pickup", "minecraft:chipped_anvil", Expert},

    // Andesite - hidden
    {"lava_wheel_00000", "mechanical_mixer", "bearing:water_wheel", Secret},
    {"hand_crank_000", "mechanical_mixer", "bearing:hand_crank", Secret},
    {"belt_funnel_kiss", "mechanical_mixer", "bearing:brass_funnel", Secret},
    {"stressometer_maxed", "mechanical_mixer", "bearing:stressometer", Secret},

    // Logistics
    {"cardboard", "mechanical_mixer", "bearing:cardboard", Normal, {"bearing:cardboard"}},
    {"packager", "cardboard", "bearing:packager", Normal},
    {"stock_ticker", "packager", "bearing:stock_ticker", Noisy},
    {"frogport", "stock_ticker", "bearing:package_frogport", Noisy},
    {"table_cloth_shop", "frogport", "bearing:red_table_cloth", Noisy},
    {"factory_gauge", "table_cloth_shop", "bearing:factory_gauge", Noisy},
    {"cardboard_armor", "factory_gauge", "bearing:cardboard_chestplate", Normal},

    // Logistics - secret
    {"package_chute_throw", "cardboard_armor", "bearing:cardboard_package_12x12", Secret},
    {"cardboard_armor_trim", "cardboard_armor", "bearing:cardboard_chestplate", Secret},

    // Copper - central branch
    {"copper", "burner", "minecraft:copper_ingot", Silent, {"minecraft:copper_ingot"}},
    {"copper_casing", "copper", "bearing:copper_casing", Normal},
    {"spout", "copper_casing", "bearing:spout", Normal},
    {"drain", "spout", "bearing:item_drain", Normal},
    {"steam_engine", "drain", "bearing:steam_engine", Normal},
    {"steam_whistle", "steam_engine", "bearing:steam_whistle", Normal},
    {"backtank", "steam_whistle", "bearing:copper_backtank", Normal},
    {"diving_suit", "backtank", "bearing:copper_diving_helmet", Normal},

    // Copper - top branch
    {"mechanical_pump_0", "copper", "bearing:mechanical_pump", Normal},
    {"glass_pipe", "mechanical_pump_0", "bearing:fluid_pipe", Normal},
    {"water_supply", "glass_pipe", "minecraft:water_bucket", Normal},
    {"hose_pulley", "water_supply", "bearing:hose_pulley", Normal},
    {"chocolate_bucket", "hose_pulley", "bearing:chocolate_bucket", Normal, {"bearing:chocolate_bucket"}},
    {"honey_drain", "chocolate_bucket", "minecraft:beehive", Normal},

    // Copper - expert branch
    {"hose_pulley_lava", "copper", "bearing:hose_pulley", Expert},
    {"steam_engine_maxed", "hose_pulley_lava", "bearing:steam_engine", Expert},
    {"foods", "steam_engine_maxed", "bearing:chocolate_glazed_berries", Expert},
    {"diving_suit_lava", "foods", "bearing:netherite_diving_helmet", Expert},

    // Copper - hidden
    {"chained_drain", "backtank", "bearing:item_drain", Secret},
    {"cross_streams", "backtank", "minecraft:cobblestone", Secret},
    {"pipe_organ", "backtank", "bearing:steam_whistle", Secret},

    // Brass - central branch
    {"brass", "diving_suit", "bearing:brass_ingot", Normal, {"bearing:brass_ingot"}},
    {"brass_casing", "brass", "bearing:brass_casing", Noisy},
    {"rose_quartz", "brass_casing", "bearing:polished_rose_quartz", Normal, {"bearing:polished_rose_quartz"}},
    {"deployer", "rose_quartz", "bearing:deployer", Normal},
    {"precision_mechanism", "deployer", "bearing:precision_mechanism", Noisy, {"bearing:precision_mechanism"}},
    {"speed_controller", "precision_mechanism", "bearing:rotation_speed_controller", Normal},
    {"mechanical_arm", "speed_controller", "bearing:mechanical_arm", Noisy},
    {"mechanical_crafter", "mechanical_arm", "bearing:mechanical_crafter", Normal},
    {"crushing_wheel", "mechanical_crafter", "bearing:crushing_wheel", Noisy},

    // Brass - top branch
    {"haunted_bell", "brass", "bearing:haunted_bell", Noisy},
    {"clockwork_bearing", "haunted_bell", "bearing:clockwork_bearing", Noisy},
    {"display_link", "clockwork_bearing", "bearing:display_link", Normal},
    {"potato_cannon", "display_link", "bearing:potato_cannon", Noisy},
    {"extendo_grip", "potato_cannon", "bearing:extendo_grip", Normal},
    {"linked_controller", "extendo_grip", "bearing:linked_controller", Normal},
    {"arm_blaze_burner", "linked_controller", "bearing:blaze_burner", Normal},

    // Brass - expert branch
    {"crusher_maxed_0000", "brass", "bearing:crushing_wheel", Expert},
    {"arm_many_targets", "crusher_maxed_0000", "bearing:mechanical_arm", Expert},
    {"potato_cannon_collide", "arm_many_targets", "minecraft:carrot", Expert},
    {"self_deploying", "potato_cannon_collide", "minecraft:rail", Expert},

    // Brass - hidden
    {"fist_bump", "mechanical_crafter", "bearing:deployer", Secret},
    {"crafter_lazy_000", "mechanical_crafter", "bearing:mechanical_crafter", Secret},
    {"extendo_grip_dual", "mechanical_crafter", "bearing:extendo_grip", Secret},
    {"musical_arm", "mechanical_crafter", "minecraft:jukebox", Secret},

    // Trains - central branch
    {"sturdy_sheet", "crushing_wheel", "bearing:sturdy_sheet", Normal, {"bearing:sturdy_sheet"}},
    {"train_casing_00", "sturdy_sheet", "bearing:railway_casing", Normal},
    {"train", "train_casing_00", "bearing:track_station", Noisy},
    {"conductor", "train", "bearing:schedule", Normal},
    {"track_signal", "conductor", "bearing:track_signal", Normal},
    {"display_board_0", "track_signal", "bearing:display_board", Noisy},

    // Trains - top branch
    {"track_0", "sturdy_sheet", "bearing:track", Normal, {"bearing:track"}},
    {"train_whistle", "track_0", "bearing:steam_whistle", Normal},
    {"train_portal", "train_whistle", "minecraft:amethyst_block", Noisy},

    // Trains - expert branch
    {"track_crafting_factory", "sturdy_sheet", "bearing:mechanical_press", Expert},
    {"long_train", "track_crafting_factory", "minecraft:minecart", Expert},
    {"long_travel", "long_train", "bearing:green_seat", Expert},

    // Trains - hidden
    {"train_roadkill", "track_signal", "minecraft:diamond_sword", Secret},
    {"red_signal", "track_signal", "bearing:track_signal", Secret},
    {"train_crash", "track_signal", "bearing:incomplete_track", Secret},
    {"train_crash_backwards", "track_signal", "bearing:incomplete_track", Secret},
};

std::unordered_map<std::string_view, int> const& indexMap() {
    static std::unordered_map<std::string_view, int> const m = [] {
        std::unordered_map<std::string_view, int> r;
        for (int i = 0; i < static_cast<int>(std::size(kDefs)); ++i) r.emplace(kDefs[i].id, i);
        return r;
    }();
    return m;
}

std::vector<std::vector<int>> const& children() {
    static std::vector<std::vector<int>> const c = [] {
        std::vector<std::vector<int>> r(std::size(kDefs));
        for (std::size_t i = 0; i < std::size(kDefs); ++i) {
            int p = parentOf(i);
            if (p >= 0) r[static_cast<std::size_t>(p)].push_back(static_cast<int>(i));
        }
        return r;
    }();
    return c;
}

/// Vanilla's VisibilityRule of one entry.
enum class Rule { Show, Hide, NoChange };

bool evaluate(int i, std::vector<Rule>& stack, std::function<bool(std::string_view)> const& done, std::vector<bool>& out) {
    auto const& d    = kDefs[i];
    bool        isDone = done(d.id);
    Rule        rule   = isDone ? Rule::Show : (hidden(d.type) ? Rule::Hide : Rule::NoChange);
    stack.push_back(rule);
    bool any = isDone;
    for (int c : children()[static_cast<std::size_t>(i)]) any |= evaluate(c, stack, done, out);
    bool visible = any;
    if (!visible) {
        // the nearest of self, parent, grandparent that is not NoChange decides
        for (std::size_t k = 0; k <= 2 && k < stack.size(); ++k) {
            Rule r = stack[stack.size() - 1 - k];
            if (r == Rule::Show) {
                visible = true;
                break;
            }
            if (r == Rule::Hide) break;
        }
    }
    stack.pop_back();
    out[static_cast<std::size_t>(i)] = visible;
    return any;
}

/// Lays out the subtree of `i` from row `next`; returns the entry's row.
float place(int i, int depth, float& next, std::vector<Placement>& out) {
    auto const& kids = children()[static_cast<std::size_t>(i)];
    float       y;
    if (kids.empty()) {
        y = next;
        next += 1;
    } else {
        float first = 0, last = 0;
        for (std::size_t k = 0; k < kids.size(); ++k) {
            float cy = place(kids[k], depth + 1, next, out);
            if (k == 0) first = cy;
            last = cy;
        }
        y = (first + last) / 2;
    }
    out[static_cast<std::size_t>(i)] = Placement{static_cast<float>(depth), y};
    return y;
}

} // namespace

std::span<Def const> all() { return {kDefs, std::size(kDefs)}; }

int indexOf(std::string_view id) {
    auto const& m  = indexMap();
    auto        it = m.find(id);
    return it == m.end() ? -1 : it->second;
}

Def const* find(std::string_view id) {
    int i = indexOf(id);
    return i < 0 ? nullptr : &kDefs[i];
}

int parentOf(std::size_t index) {
    if (index >= std::size(kDefs) || kDefs[index].parent.empty()) return -1;
    return indexOf(kDefs[index].parent);
}

std::vector<bool> visibility(std::function<bool(std::string_view)> const& done) {
    std::vector<bool> out(std::size(kDefs), false);
    std::vector<Rule> stack(3, Rule::NoChange);
    evaluate(0, stack, done, out);
    return out;
}

std::vector<Placement> const& layout() {
    static std::vector<Placement> const l = [] {
        std::vector<Placement> out(std::size(kDefs));
        float next = 0;
        place(0, 0, next, out);
        return out;
    }();
    return l;
}

} // namespace br::core::advancements
