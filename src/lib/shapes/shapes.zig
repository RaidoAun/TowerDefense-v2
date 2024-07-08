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
    width: i32,
    height: i32,
    color: rl.Color,
    pub fn draw(self: Rectangle) void {
        rl.drawRectangle(self.x, self.y, self.width, self.height, self.color);
    }

    pub fn isCollision(self: Rectangle, circle: Circle) bool {
        const closestX = utils.clamp(i32, circle.x, self.x, self.x + self.width);
        const closestY = utils.clamp(i32, circle.y, self.y, self.y + self.height);

        // Calculate the distance between the circle's center and this closest point
        const distanceX = circle.x - closestX;
        const distanceY = circle.y - closestY;

        // Calculate the distance squared and compare with the radius squared
        const distanceSquared = distanceX * distanceX + distanceY * distanceY;
        const radiusSquared: i32 = @intFromFloat(circle.radius * circle.radius);
        return distanceSquared <= radiusSquared;
    }
};
