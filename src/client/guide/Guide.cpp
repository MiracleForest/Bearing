#ifdef BR_CLIENT

// Guide on the client mod: scene library, hold-[W]-over-an-item, `/bearing guide` and the module.
//
// Hovered item: the vanilla container screens (inventory, creative inventory, chests, ...) report
// the slot under the pointer (`ContainerScreenController::_onContainerSlotHovered`); while an
// item with Guide scenes is hovered, its tooltip says "Hold [W] to open Guide" below the name
// (`ItemStackBase::getFormattedHovertext` hook). Bedrock builds the hover text once per hover, so
// while the key is held the progress bar of `|` characters is drawn in a tooltip box at the
// top of the screen; holding the key (W,
// the default, rebindable: `config/guide.json` guideKey, or the button of the welcome
// screen) opens the item's Guide (GuideTooltipHandler: ~11 ticks with its
// accelerating progress).

#include <atomic>
#include <chrono>
#include <deque>
#include <filesystem>
#include <fstream>
#include <mutex>

#include "ll/api/event/EventBus.h"
#include "ll/api/event/client/ClientExitLevelEvent.h"
#include "ll/api/event/input/KeyInputEvent.h"
#include "ll/api/event/input/MouseInputEvent.h"
#include "ll/api/event/render/UIRenderEvent.h"
#include "ll/api/memory/Hook.h"

#include "mc/client/game/ClientInstance.h"
#include "mc/client/gui/screens/ScreenView.h"
#include "mc/client/gui/screens/controllers/ContainerScreenController.h"
#include "mc/client/gui/screens/controllers/CraftingScreenController.h"
#include "mc/client/gui/screens/interfaces/ISceneStack.h"
#include "mc/client/gui/ViewRequest.h"
#include "mc/safety/RedactableString.h"
#include "mc/world/item/ItemStackBase.h"
#include "mc/world/level/Level.h"

#include "client/Client.h"
#include "client/guide/Guide.h"
#include "client/guide/GuideConfig.h"
#include "client/screen/Screen.h"
#include "feature/net/Net.h"
#include "mod/Config.h"
#include "mod/Log.h"
#include "mod/Main.h"
#include "mod/Module.h"

BR_REGISTER_CONFIG("guide", br::client::guide::GuideConfig);

namespace br::client::guide {

namespace {

constexpr int kVkEscape = 0x1B;

struct State {
    std::mutex                          mutex;   ///< hovered item (set from UI callbacks)
    std::string                         hovered; ///< item id under the pointer in a container screen
    std::string                         hoveredSlot; ///< "<collection>#<index>" of that slot
    // client thread
    bool                                keyDown   = false;
    bool                                afterSeen = false;
    bool                                leftDown  = false;
    std::atomic<float>                  progress  = 0; ///< read by the hover text hook
    std::function<void(int)>            rebind;        ///< set while waiting for a new Guide key
    float                               tickAcc   = 0;
    std::chrono::steady_clock::time_point last{};
    std::deque<std::function<void()>>   deferred;
    std::vector<std::function<void()>>  history;
};
State& state() {
    static State s;
    return s;
}

/// `slot` = "<collection>#<index>"; an unhover only clears its own slot (the game may report the
/// new slot before it leaves the old one).
void setHovered(std::string id, std::string slot = {}) {
    auto& s = state();
    {
        std::lock_guard lock(s.mutex);
        s.hoveredSlot = std::move(slot);
        if (s.hovered == id) return;
        s.hovered = id;
    }
    // one line per hovered entry (e2e scenarios find the slot with it)
    if (!id.empty() && library().has(id)) log().info("guide: hovering {}", id);
}

std::string hovered() {
    auto&           s = state();
    std::lock_guard lock(s.mutex);
    return s.hovered;
}

/// Screen changes happen between frames: a widget's click handler must not destroy its screen.
void defer(std::function<void()> fn) { state().deferred.push_back(std::move(fn)); }
} // namespace
void deferUi(std::function<void()> fn) { defer(std::move(fn)); }
namespace {

std::unique_ptr<cp::Library> loadLibrary() {
    auto lib  = std::make_unique<cp::Library>();
    auto dir  = br::Mod::getInstance().getSelf().getModDir() / "guide";
    auto read = [](std::filesystem::path const& p) {
        std::ifstream in(p);
        return nlohmann::json::parse(in, nullptr, false);
    };
    for (auto const& e : lib->setIndex(read(dir / "index.json"))) log().warn("guide: {}", e);
    std::error_code ec;
    int             bad = 0;
    for (auto const& entry : std::filesystem::directory_iterator(dir / "scenes", ec)) {
        if (entry.path().extension() != ".json") continue;
        auto r = cp::parseScene(read(entry.path()));
        if (!r.scene) {
            ++bad;
            log().warn("guide: {}: {}", entry.path().filename().string(), r.errors.empty() ? "invalid" : r.errors.front());
            continue;
        }
        lib->add(std::move(*r.scene));
    }
    log().info("guide: loaded {} scenes for {} entries ({} invalid)", lib->sceneCount(), lib->components().size(), bad);
    return lib;
}

/// Width of a text in the game's default font (the reference design measures the hint with the font to size the
/// progress bar): narrow / wide glyphs of the ASCII range, 9 px for other characters.
int fontWidth(std::string const& text) {
    int w = 0;
    for (std::size_t i = 0; i < text.size(); ++i) {
        unsigned char ch = static_cast<unsigned char>(text[i]);
        if (ch == 0xC2 && i + 1 < text.size() && static_cast<unsigned char>(text[i + 1]) == 0xA7) { // section sign + code
            i += 2;
            continue;
        }
        if (ch >= 0x80) {
            if ((ch & 0xC0) == 0xC0) w += 9; // one per code point
            continue;
        }
        switch (ch) {
        case '!': case '\'': case ',': case '.': case ':': case ';': case '|': case 'i': w += 2; break;
        case '`': case 'l': w += 3; break;
        case ' ': case 'I': case '[': case ']': case 't': w += 4; break;
        case '"': case '(': case ')': case '*': case '<': case '>': case 'f': case 'k': case '{': case '}': w += 5; break;
        case '@': case '~': w += 7; break;
        default: w += 6; break;
        }
    }
    return w;
}

/// The GuideTooltipHandler.makeProgressBar: "Hold [W] to open Guide" (dark gray, the key in
/// gray) and, once the key is held, as many `|` as fit under that text, the done part gray.
std::string holdLine(float progress) {
    auto hint = "§8" + ctr("bearing.guide.ui.hold_to_guide", "Hold [{0}] to open Guide", "§7" + keyName(guideKeyCode()) + "§8");
    if (progress <= 0) return hint;
    int total   = fontWidth(hint) / 2; // the width of "|"
    int current = static_cast<int>(progress * total);
    std::string bars = "§7" + std::string(static_cast<std::size_t>(current), '|');
    if (progress < 1) bars += "§8" + std::string(static_cast<std::size_t>(std::max(0, total - current)), '|');
    return bars;
}

/// Per UI layer: advances the hold progress with the clock (several layers per frame don't speed
/// it up) and draws the hint (after the layer when the game reports it, else before).
void holdFrame(MinecraftUIRenderContext& ctx, bool after) {
    auto& s = state();
    if (screen::current()) {
        s.progress = 0;
        return;
    }
    auto id = hovered();
    if (id.empty() || !library().has(id)) {
        s.progress = 0;
        s.last     = {};
        return;
    }
    auto  now = std::chrono::steady_clock::now();
    float dt  = s.last.time_since_epoch().count() == 0 ? 0.f : std::chrono::duration<float>(now - s.last).count();
    s.last    = now;
    s.tickAcc += std::min(dt, 0.25f) * 20.f * config().holdSpeed;
    while (s.tickAcc >= 1.f) {
        s.tickAcc -= 1.f;
        s.progress = cp::holdProgressStep(s.progress, s.keyDown && !s.rebind);
    }
    // Bedrock builds an item's hover text once per hover, so the tooltip keeps the hint: while the
    // key is held the bar of `|` is drawn in a tooltip box at the top of the screen
    if (s.progress.load() > 0 && (after || !s.afterSeen)) {
        auto [sw, sh] = screen::guiSize();
        (void)sh;
        screen::Canvas c(ctx);
        auto           bar = holdLine(s.progress.load());
        float          w   = c.textWidth(bar) + 8;
        screen::Rect   box{(sw - w) / 2, 6, w, 14};
        c.fill(box, 0xF0100010);
        c.frame(box, 0xFF5000FF);
        c.text(box.x + 4, box.y + 3, bar, 0xFFFFFFFF);
    }
    if (s.progress >= 1.f) {
        s.progress = 0;
        log().info("guide: held {} over {}", keyName(guideKeyCode()), id);
        clearHistory();
        defer([id] { openComponent(id); });
    }
}
} // namespace

cp::Library const& library() {
    static std::unique_ptr<cp::Library> lib = loadLibrary();
    return *lib;
}

bool leftMouseDown() { return state().leftDown; }

int guideKeyCode() {
    int vk = config().guideKey;
    return vk > 0 && vk < 256 ? vk : 0x57;
}

std::string keyName(int vk) {
    if ((vk >= '0' && vk <= '9') || (vk >= 'A' && vk <= 'Z')) return std::string(1, static_cast<char>(vk));
    if (vk >= 0x70 && vk <= 0x87) return "F" + std::to_string(vk - 0x6F);
    if (vk >= 0x60 && vk <= 0x69) return "Num " + std::to_string(vk - 0x60);
    switch (vk) {
    case 0x09: return "Tab";
    case 0x10: return "Shift";
    case 0x11: return "Ctrl";
    case 0x12: return "Alt";
    case 0x14: return "Caps Lock";
    case 0x20: return "Space";
    case 0x25: return "Left";
    case 0x26: return "Up";
    case 0x27: return "Right";
    case 0x28: return "Down";
    case 0xBA: return ";";
    case 0xBB: return "=";
    case 0xBC: return ",";
    case 0xBD: return "-";
    case 0xBE: return ".";
    case 0xBF: return "/";
    case 0xC0: return "`";
    case 0xDB: return "[";
    case 0xDC: return "\\";
    case 0xDD: return "]";
    case 0xDE: return "'";
    default: return "Key " + std::to_string(vk);
    }
}

void rebindGuideKey(std::function<void(int)> done) {
    state().rebind = std::move(done);
    log().info("guide: waiting for a new Guide key");
}

bool rebinding() { return static_cast<bool>(state().rebind); }

void cancelRebind() { state().rebind = {}; }

void pushHistory(std::function<void()> reopen) {
    auto& h = state().history;
    h.push_back(std::move(reopen));
    if (h.size() > 32) h.erase(h.begin());
}
void clearHistory() { state().history.clear(); }
bool canThinkBack() { return !state().history.empty(); }
bool thinkBack() {
    auto& h = state().history;
    if (h.empty()) return false;
    auto fn = std::move(h.back());
    h.pop_back();
    defer([fn = std::move(fn)] {
        // the reopened screen must not push itself again
        fn();
    });
    log().info("guide: think back");
    return true;
}

// ---- hooks: the slot under the pointer in container screens ------------------------------------

LL_TYPE_INSTANCE_HOOK(
    GuideSlotHoverHook,
    ll::memory::HookPriority::Normal,
    ContainerScreenController,
    &ContainerScreenController::$_onContainerSlotHovered,
    ui::ViewRequest,
    std::string const& collectionName,
    int                index
) {
    auto r = origin(collectionName, index);
    try {
        auto const& stack = this->_getVisualItemStack(collectionName, index);
        setHovered(stack.isNull() ? std::string{} : stack.getTypeName(), collectionName + "#" + std::to_string(index));
    } catch (...) {}
    return r;
}

LL_TYPE_INSTANCE_HOOK(
    GuideCraftingHoverHook,
    ll::memory::HookPriority::Normal,
    CraftingScreenController,
    &CraftingScreenController::$_onContainerSlotHovered,
    ui::ViewRequest,
    std::string const& collectionName,
    int                index
) {
    auto r = origin(collectionName, index);
    try {
        auto const& stack = this->_getVisualItemStack(collectionName, index);
        setHovered(stack.isNull() ? std::string{} : stack.getTypeName(), collectionName + "#" + std::to_string(index));
    } catch (...) {}
    return r;
}

LL_TYPE_INSTANCE_HOOK(
    GuideSlotUnhoverHook,
    ll::memory::HookPriority::Normal,
    ContainerScreenController,
    &ContainerScreenController::$_onContainerSlotUnhovered,
    ui::ViewRequest,
    std::string const& collectionName,
    int                index
) {
    {
        auto&           s = state();
        std::lock_guard lock(s.mutex);
        if (s.hoveredSlot == collectionName + "#" + std::to_string(index)) {
            s.hovered.clear();
            s.hoveredSlot.clear();
        }
    }
    return origin(collectionName, index);
}

LL_TYPE_INSTANCE_HOOK(GuideContainerLeaveHook, ll::memory::HookPriority::Normal, ContainerScreenController, &ContainerScreenController::$onLeave, void) {
    setHovered({});
    origin();
}

// ---- the hint in the item tooltip ----------------------------------------------------------------

LL_TYPE_INSTANCE_HOOK(
    GuideHovertextHook,
    ll::memory::HookPriority::Normal,
    ItemStackBase,
    &ItemStackBase::getFormattedHovertext,
    Bedrock::Safety::RedactableString,
    Level& level,
    bool   showCategory
) {
    auto r = origin(level, showCategory);
    try {
        if (isNull() || screen::current()) return r;
        auto id = getTypeName();
        // only the hovered slot's tooltip (the item under the mouse)
        if (id != hovered() || !library().has(id)) return r;
        auto line   = holdLine(state().progress.load());
        auto insert = [&line](std::string& text) {
            auto nl = text.find('\n');
            text    = nl == std::string::npos ? text + "\n" + line : text.substr(0, nl) + "\n" + line + text.substr(nl);
        };
        insert(r.mUnredactedString);
        if (r.mRedactedString) insert(*r.mRedactedString);
    } catch (...) {}
    return r;
}

// ---- module ------------------------------------------------------------------------------------

class GuideModule {
public:
    // input / render listeners at mod load (see screen::ScreenModule; again after a disable), hooks at enable
    void load() { registerListeners(); }
    void install() {
        if (mListeners.empty()) registerListeners();
        GuideSlotHoverHook::hook();
        GuideCraftingHoverHook::hook();
        GuideSlotUnhoverHook::hook();
        GuideContainerLeaveHook::hook();
        GuideHovertextHook::hook();
    }

private:
    void registerListeners() {
        auto& bus = ll::event::EventBus::getInstance();
        mListeners.push_back(bus.emplaceListener<ll::event::KeyInputEvent>(
            [](ll::event::KeyInputEvent& ev) {
                auto& s  = state();
                int   vk = ev.keyCode();
                if (s.rebind && ev.isDown()) {
                    // The key mapping screen: the next key becomes the Guide key, Esc cancels
                    auto done = std::move(s.rebind);
                    s.rebind  = {};
                    int  key  = vk == kVkEscape ? 0 : vk;
                    if (key) {
                        br::config::mut<GuideConfig>().guideKey = key;
                        br::config::saveAll();
                        log().info("guide: Guide key set to {}", keyName(key));
                    }
                    deferUi([done = std::move(done), key] { done(key); });
                    ev.cancel();
                    return;
                }
                if (vk == guideKeyCode()) {
                    if (ev.isDown() && !s.keyDown && !screen::current()) {
                        auto id = hovered();
                        if (!id.empty() && library().has(id)) log().info("guide: holding {} over {}", keyName(vk), id);
                    }
                    s.keyDown = ev.isDown();
                }
                if (ev.isDown() && screen::current() && guideKey(vk)) ev.cancel();
                if (vk == kVkEscape && ev.isDown() && guideScreenOpen()) {
                    deferUi([] { screen::close(); });
                    ev.cancel();
                }
            },
            ll::event::EventPriority::High
        ));
        mListeners.push_back(bus.emplaceListener<ll::event::MouseInputEvent>(
            [](ll::event::MouseInputEvent& ev) {
                if (ev.actionButtonId() == 1) state().leftDown = ev.buttonData() != 0;
            },
            ll::event::EventPriority::High
        ));
        mListeners.push_back(bus.emplaceListener<ll::event::BeforeUIRenderEvent>(
            [](ll::event::BeforeUIRenderEvent& ev) {
                auto& s = state();
                while (!s.deferred.empty()) {
                    auto fn = std::move(s.deferred.front());
                    s.deferred.pop_front();
                    fn();
                }
                holdFrame(ev.uiRenderContext(), false);
            },
            ll::event::EventPriority::High
        ));
        mListeners.push_back(bus.emplaceListener<ll::event::AfterUIRenderEvent>([](ll::event::AfterUIRenderEvent& ev) {
            state().afterSeen = true;

            holdFrame(ev.uiRenderContext(), true);
        }));        mListeners.push_back(bus.emplaceListener<ll::event::ClientExitLevelEvent>([](auto&) {
            setHovered({});
            state().history.clear();
            state().deferred.clear();
            resetRenderCache();
        }));

        namespace net = br::feature::net;
        // `/bearing guide [id]` on the server (feature/guide/GuideCommand.cpp)
        net::client::on("guide.open", [](nlohmann::json const& msg) {
            auto id = msg.value("id", std::string{});
            clearHistory();
            defer([id] {
                if (id.empty()) {
                    log().info("guide: opening the index");
                    openIndex();
                } else if (library().tag(id)) {
                    openTag(id);
                } else if (!openComponent(cp::normaliseId(id))) {
                    log().warn("guide: no guide for {}", id);
                }
            });
        });
    }

public:
    void uninstall() {
        GuideSlotHoverHook::unhook();
        GuideCraftingHoverHook::unhook();
        GuideSlotUnhoverHook::unhook();
        GuideContainerLeaveHook::unhook();
        GuideHovertextHook::unhook();
        auto& bus = ll::event::EventBus::getInstance();
        for (auto& l : mListeners) bus.removeListener(l);
        mListeners.clear();
    }

private:
    std::vector<ll::event::ListenerPtr> mListeners;
};

} // namespace br::client::guide

BR_REGISTER_MODULE(br::client::guide::GuideModule);

#endif // BR_CLIENT
