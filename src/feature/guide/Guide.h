#pragma once

// Server side of Guide (U30): `/bearing guide [id]` asks a companion client to open Guide.

#include <optional>
#include <string>

#include "core/guide/Scene.h"

class Player;

namespace br::feature::guide {

struct Result {
    bool        ok = false;
    std::string message;
};

/// The Guide index and scenes shipped in the mod folder (`guide/`), loaded once.
[[nodiscard]] core::guide::Library const& index();
/// A typed id as the client opens it: "" (the index), a tag id, or a namespaced component id;
/// nullopt when unknown.
[[nodiscard]] std::optional<std::string> resolve(std::string const& id);
/// Sends `guide.open` to the player's client mod (what `/bearing guide` does).
Result request(Player& player, std::string const& id);

} // namespace br::feature::guide
