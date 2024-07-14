// TODO split this up into subfiles
const rl = @import("raylib");
const shapes = @import("../shapes/shapes.zig");
const Rectangle = shapes.Rectangle;
const Circle = shapes.Circle;

pub const Player = struct {
    shape: Rectangle,
    speed: f32,
    pub fn update(self: *Player, dt: f64) void {
        const dSpeed: i32 = @intFromFloat(self.speed * dt);

        if (rl.isKeyDown(rl.KeyboardKey.key_right)) {
            self.shape.x += dSpeed;
        }
        if (rl.isKeyDown(rl.KeyboardKey.key_left)) {
            self.shape.x -= dSpeed;
        }
        if (rl.isKeyDown(rl.KeyboardKey.key_up)) {
            self.shape.y -= dSpeed;
        }
        if (rl.isKeyDown(rl.KeyboardKey.key_down)) {
            self.shape.y += dSpeed;
        }
    }
};
// TODO complete this
pub const Bullet = struct {
    const Self = @This();
    shape: Circle,
    speed: f32,
    pub fn update(self: *Self, dt: f64) void {
        const dSpeed: i32 = @intFromFloat(self.speed * dt);
        self.shape.y += dSpeed;
    }

    pub fn onCollision(self: *Self) void {
        self.shape.y -= 1000;
    }
};
