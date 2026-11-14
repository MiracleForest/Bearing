// `/bearing guide [id]` (SPEC §6, anyone): opens Guide on the player's client mod. Without an id
// it opens the Guide index; the id is an item (`shaft`, `bearing:shaft`, `minecraft:chest`) or
// a tag (`kinetic_relays`). Players without the client mod get a message (Guide is client-side,
// SPEC §8). Runs on BDS and on the integrated server of local worlds.

#include <filesystem>
#include <fstream>

#include "ll/api/command/CommandHandle.h"

#include "mc/server/commands/CommandOrigin.h"
#include "mc/server/commands/CommandOutput.h"
#include "mc/world/actor/player/Player.h"

#include "core/guide/Scene.h"
#include "feature/net/Net.h"
#include "feature/guide/Guide.h"
#include "mod/Commands.h"
#include "mod/I18n.h"
#include "mod/Log.h"
#include "mod/Main.h"

namespace br::feature::guide {

// Command parameter types need external linkage.
struct GuideParams {
    std::string id;
};

core::guide::Library const& index() {
    static core::guide::Library lib = [] {
        core::guide::Library l;
        auto                  dir = br::Mod::getInstance().getSelf().getModDir() / "guide";
        std::ifstream         in(dir / "index.json");
        auto                  j = nlohmann::json::parse(in, nullptr, false);
        for (auto const& e : l.setIndex(j)) log().warn("guide: {}", e);
        // the scenes too: an entry is only offered when its scenes load (as on the client)
        std::error_code ec;
        for (auto const& entry : std::filesystem::directory_iterator(dir / "scenes", ec)) {
            std::ifstream sin(entry.path());
            if (auto r = core::guide::parseScene(nlohmann::json::parse(sin, nullptr, false)); r.scene) l.add(std::move(*r.scene));
        }
        return l;
    }();
    return lib;
}

std::optional<std::string> resolve(std::string const& id) {
    if (id.empty()) return std::string{};
    auto const& lib = index();
    if (lib.tag(id)) return id;
    auto full = core::guide::normaliseId(id);
    if (lib.has(full)) return full;
    return std::nullopt;
}

Result request(Player& player, std::string const& id) {
    auto target = resolve(id);
    if (!target) return {false, trFor(player, "br.guide.unknown", "There is no guide for {0}.", id)};
    if (!net::isCompanion(player)) return {false, trFor(player, "br.guide.no_client", "Guide needs the Bearing client mod.")};
    net::send(player, "guide.open", {{"id", *target}});
    log().info("guide: {} opens {}", player.getRealName(), target->empty() ? "the index" : *target);
    return {true, trFor(player, "br.guide.opening", "Opening Guide: {0}", target->empty() ? trFor(player, "bearing.guide.ui.index_title", "Guide Catalogue") : *target)};
}

namespace {
void run(CommandOrigin const& origin, CommandOutput& output, std::string const& id) {
    auto* player = commands::playerOf(origin);
    if (!player) return output.error(tr("br.guide.players_only", "Only players can open the guide."));
    auto r = request(*player, id);
    if (r.ok) output.success(r.message);
    else output.error(r.message);
}
} // namespace

BR_REGISTER_SUBCOMMAND([](ll::command::CommandHandle& cmd) {
    cmd.overload().text("guide").execute([](CommandOrigin const& origin, CommandOutput& output) { run(origin, output, ""); });
    cmd.overload<GuideParams>().text("guide").required("id").execute(
        [](CommandOrigin const& origin, CommandOutput& output, GuideParams const& params) { run(origin, output, params.id); }
    );
});

} // namespace br::feature::guide
