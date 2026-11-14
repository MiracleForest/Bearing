// Selftests of the server side of Guide (`guide.*`). The client screens are covered by the
// client e2e scenario `guide` (tools/e2e/client/scenarios/guide.ps1).

#include <filesystem>
#include <fstream>

#include "mc/world/actor/player/Player.h"

#include "core/guide/Scene.h"
#include "feature/net/Net.h"
#include "feature/guide/Guide.h"
#include "mod/Main.h"
#include "selftest/SelfTest.h"

namespace br::feature::guide {

using selftest::Context;

BR_REGISTER_SELFTEST("guide.data", [](Context& ctx) {
    auto const& lib = index();
    ctx.check(lib.allComponents().size() >= 150, "the index lists the guide entries (" + std::to_string(lib.allComponents().size()) + ")");
    ctx.check(lib.tags().size() >= 18, "the index has the tags");
    auto dir   = br::Mod::getInstance().getSelf().getModDir() / "guide" / "scenes";
    int  files = 0, bad = 0;
    std::error_code ec;
    for (auto const& e : std::filesystem::directory_iterator(dir, ec)) {
        std::ifstream in(e.path());
        auto          r = core::guide::parseScene(nlohmann::json::parse(in, nullptr, false));
        ++files;
        if (!r.scene) {
            ++bad;
            ctx.info(e.path().filename().string() + ": " + (r.errors.empty() ? "invalid" : r.errors.front()));
        }
    }
    ctx.check(files >= 167 && bad == 0, "every shipped scene parses (" + std::to_string(files) + " files, " + std::to_string(bad) + " invalid)");
});

BR_REGISTER_SELFTEST("guide.resolve", [](Context& ctx) {
    ctx.check(resolve("") == std::string{}, "no id: the index");
    ctx.check(resolve("shaft") == std::string("bearing:shaft"), "short ids get the bearing namespace");
    ctx.check(resolve("bearing:large_cogwheel") == std::string("bearing:large_cogwheel"), "full ids");
    ctx.check(resolve("kinetic_relays") == std::string("kinetic_relays"), "tag ids");
    ctx.check(!resolve("minecraft:dirt").has_value(), "items without scenes are refused");
});

BR_REGISTER_SELFTEST("guide.command", [](Context& ctx) -> ll::coro::CoroTask<> {
    auto& p = ctx.player();
    co_await ctx.ticks(1);
    // a vanilla client: refused, nothing sent
    auto r = request(p, "shaft");
    ctx.check(!r.ok, "players without the client mod are refused");
    // a companion: the client is told to open the entry
    net::setTestCompanion(p, true);
    r         = request(p, "shaft");
    auto msgs = net::takeTestMessages(p);
    ctx.check(r.ok && msgs.size() == 1 && msgs[0].channel == "guide.open" && msgs[0].payload.value("id", "") == "bearing:shaft",
              "guide.open carries the entry");
    r    = request(p, "");
    msgs = net::takeTestMessages(p);
    ctx.check(r.ok && msgs.size() == 1 && msgs[0].payload.value("id", "x").empty(), "no id opens the index");
    r    = request(p, "no_such_thing");
    msgs = net::takeTestMessages(p);
    ctx.check(!r.ok && msgs.empty(), "unknown ids are refused");
    net::setTestCompanion(p, false);
});

} // namespace br::feature::guide
