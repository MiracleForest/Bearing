#pragma once

// Create's wrench rotation (IWrenchable.getRotatedBlockState) on Bearing's block state
// conventions (pure C++, unit-tested). See docs/SPEC.md §3.6.8 (U8).
//
// State conventions (integer block states):
//   bearing:facing / minecraft:facing_direction  0..5 in Create's Direction order
//                                                  (down, up, north, south, west, east)
//   bearing:axis                                  0 x, 1 y, 2 z   (RotatedPillarKineticBlock.AXIS)
//   bearing:horizontal_facing                     0 south, 1 west, 2 north, 3 east (Java 2D value)
//   bearing:horizontal_axis                       0 x, 2 z        (HorizontalAxisKineticBlock)
//   bearing:axis_along_first                      0 / 1           (DirectionalAxisKineticBlock)
//   bearing:along_first                           0 / 1           the same flag on the gauges and the
//                                                                  fluid valve (a block with an axis
//                                                                  state, the chain drives, never reads it)

#include <array>
#include <map>
#include <string>

namespace br::core::goggles {

/// The rotation-relevant states of a block: name -> integer value.
using States = std::map<std::string, int>;

inline constexpr char const* kFacing           = "bearing:facing";
inline constexpr char const* kVanillaFacing    = "minecraft:facing_direction";
inline constexpr char const* kAxis             = "bearing:axis";
inline constexpr char const* kHorizontalFacing = "bearing:horizontal_facing";
inline constexpr char const* kHorizontalAxis   = "bearing:horizontal_axis";
inline constexpr char const* kAxisAlongFirst   = "bearing:axis_along_first";
inline constexpr char const* kAlongFirst       = "bearing:along_first";

/// The state names `rotatedStates` reads.
inline constexpr std::array<char const*, 7> kRotationStates{
    kFacing, kVanillaFacing, kAxis, kHorizontalFacing, kHorizontalAxis, kAxisAlongFirst, kAlongFirst
};

/// Axis of a direction (0..5, Create order): 0 x, 1 y, 2 z.
[[nodiscard]] int axisOfDirection(int dir);
/// The positive direction of an axis (Create's VoxelShaper.axisAsFace): x -> east, y -> up, z -> south.
[[nodiscard]] int positiveDirection(int axis);
/// Minecraft's Direction.getClockWise(Axis): a quarter turn about `axis`; directions on the
/// axis stay unchanged.
[[nodiscard]] int clockwise(int dir, int axis);
/// Java 2D data value (0 S, 1 W, 2 N, 3 E) <-> direction (2..5).
[[nodiscard]] int directionFromHorizontal(int value);
[[nodiscard]] int horizontalFromDirection(int dir);

/// Create's IWrenchable.getRotatedBlockState: the states after a wrench click on `face`
/// (0..5). Only the states listed above change; a block without any of them is returned as is.
[[nodiscard]] States rotatedStates(States const& states, int face);

} // namespace br::core::goggles
