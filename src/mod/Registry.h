#pragma once

#include <vector>

/// Token pasting helpers for unique static registration objects.
#define BR_CONCAT_IMPL(a, b) a##b
#define BR_CONCAT(a, b)      BR_CONCAT_IMPL(a, b)
#define BR_UNIQUE(prefix)    BR_CONCAT(prefix, __COUNTER__)

namespace br {

/// A process-wide list of `Entry`, filled by static registrar objects before `main`/mod load.
/// The function-local static avoids static-initialization-order problems.
///
/// Registrations live in translation units linked directly into the mod DLL (never into a
/// static library), so the linker can't drop them.
template <class Entry>
class StaticRegistry {
public:
    static std::vector<Entry>& entries() {
        static std::vector<Entry> v;
        return v;
    }
    static void add(Entry e) { entries().push_back(std::move(e)); }
};

} // namespace br
