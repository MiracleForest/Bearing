#pragma once

// Elevator columns for other units (added by U58 for the RedstoneContactItem /
// RedstoneContactBlock.onWrenched, which turn a redstone contact placed into an elevator column
// into an elevator contact). Server thread only.

namespace br::feature::pistons {

/// The `ElevatorColumn.get(level, new ColumnCoords(x, z, side)) != null`: a column exists
/// while it has elevator contacts or its elevator is assembled. `side` is the contacts' facing
/// (Bedrock FacingID 2..5).
[[nodiscard]] bool elevatorColumnExists(int dim, int x, int z, int side);

} // namespace br::feature::pistons
