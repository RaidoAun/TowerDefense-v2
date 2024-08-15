const utils = @import("utils.zig");
const rl = @import("raylib");
const input = @import("../input.zig");

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

    pub fn containsMouseInput(self: Rectangle, pos: input.Position) bool {
        return self.x <= pos.x and self.x + self.width >= pos.x and self.y <= pos.y and self.y + self.height >= pos.y;
    }
};
pub const Square = struct {
    x: i32,
    y: i32,
    width: u16,
};
