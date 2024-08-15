const lib = @import("../lib.zig");
const rl = lib.rl;

pub const Position = struct {
    x: i32,
    y: i32,
};

pub fn getMousePosition() Position {
    return .{
        .x = rl.getMouseX(),
        .y = rl.getMouseY(),
    };
}
