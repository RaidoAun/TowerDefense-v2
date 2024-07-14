const utils = @import("utils.zig");
const rl = @import("raylib");

pub const Circle = struct {
    x: i32,
    y: i32,
    radius: f32,
    color: rl.Color,
    pub fn draw(self: Circle) void {
        rl.drawCircle(self.x, self.y, self.radius, self.color);
    }
};

pub const Rectangle = struct {
    x: i32,
    y: i32,
    width: u16,
    height: u16,
    color: rl.Color,
    pub fn draw(self: Rectangle) void {
        rl.drawRectangle(self.x, self.y, self.width, self.height, self.color);
    }
};
