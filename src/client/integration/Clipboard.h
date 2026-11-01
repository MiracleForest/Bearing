#pragma once

// The system clipboard of the game client (client build only). `/create debuginfo` puts its
// report there, as Create's ServerDebugInfoPacket does on the Java client.

#ifdef BR_CLIENT

#include <string_view>

namespace br::client::integration {

/// Replaces the clipboard's text with `utf8`. False when the clipboard is unavailable.
bool copyToClipboard(std::string_view utf8);

} // namespace br::client::integration

#endif
