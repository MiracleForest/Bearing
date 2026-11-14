#pragma once

// Value boxes ("value settings"), independent of the game (U3, SPEC §3.2).
//
// A block face may expose a value box. The reference design edits it on a *board*: a grid of `rows` (e.g.
// the creative motor's clockwise / counter-clockwise) by `0..maxValue` columns with milestone
// ticks every `milestoneInterval`. A box's stored value maps to (row, value) and back; option
// boxes are a single row whose columns are the options.

#include <array>
#include <optional>
#include <string>
#include <vector>

namespace br::core::common {

/// A point on a board.
struct ValueChoice {
    int row   = 0;
    int value = 0;
    friend bool operator==(ValueChoice const&, ValueChoice const&) = default;
};

/// The board layout.
struct BoardSpec {
    int                      maxValue          = 0;
    int                      milestoneInterval = 1;
    std::vector<std::string> rows; ///< row labels (at least one)
};

/// Clamps a board point into the board.
[[nodiscard]] ValueChoice clampSettings(BoardSpec const& board, ValueChoice s);
/// The column under a pointer at `fraction` (0 = left edge, 1 = right edge) of the board width.
[[nodiscard]] int valueAtFraction(BoardSpec const& board, double fraction);
/// The column after a scroll of `steps` notches (`coarse`: whole milestones), clamped.
[[nodiscard]] int scrollValue(BoardSpec const& board, int value, int steps, bool coarse);

/// Plain number box `min..max` (ScrollValueBehaviour with min >= 0): one row.
[[nodiscard]] BoardSpec     plainBoard(int max, int milestoneInterval, std::string rowLabel);
[[nodiscard]] ValueChoice plainToSettings(int value);
[[nodiscard]] int           plainFromSettings(ValueChoice s, int min, int max);

/// Signed box `-max..max` with a row per direction (kinetic scroll value: row 0 is
/// clockwise = negative, row 1 counter-clockwise = positive; 0 is not selectable, min 1).
[[nodiscard]] BoardSpec     signedBoard(int max, int milestoneInterval, std::string negativeLabel, std::string positiveLabel);
[[nodiscard]] ValueChoice signedToSettings(int value);
[[nodiscard]] int           signedFromSettings(ValueChoice s, int max);

/// Option box with `count` options (ScrollOptionBehaviour): one row, columns 0..count-1.
[[nodiscard]] BoardSpec optionBoard(int count, std::string rowLabel);

// ---- hit testing ------------------------------------------------------------------------------

/// A point in block-local coordinates (0..1 on each axis inside the block).
using Vec = std::array<double, 3>;

/// Face ids as Bedrock's FacingID: 0 down, 1 up, 2 north (-z), 3 south (+z), 4 west (-x), 5 east (+x).
/// The point at face-local pixel (u, v) (0..16, u to the right and v up when looking at the face
/// from outside, the same orientation the reference design uses for value box placement), pushed `inset`
/// pixels out of the face.
[[nodiscard]] Vec faceLocalPoint(int face, double u, double v, double inset = 0.0);
/// The ValueBoxTransform.testHit: the hit is within `scale / 2` blocks of the box centre.
[[nodiscard]] bool testBoxHit(Vec const& localHit, Vec const& boxCentre, double scale = 0.5);

} // namespace br::core::common
