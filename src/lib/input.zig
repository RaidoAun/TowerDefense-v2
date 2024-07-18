const rl = @import("raylib");

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
