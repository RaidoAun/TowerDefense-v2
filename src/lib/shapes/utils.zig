const shapes = @import("shapes.zig");
const Rectangle = shapes.Rectangle;
const Circle = shapes.Circle;

pub fn clamp(comptime T: type, value: T, min: T, max: T) T {
    return if (value < min) min else if (value > max) max else value;
}

pub fn isCollisionRectCircle(rect: Rectangle, circle: Circle) bool {
    const closestX = clamp(i32, circle.x, rect.x, rect.x + rect.width);
    const closestY = clamp(i32, circle.y, rect.y, rect.y + rect.height);

    // Calculate the distance between the circle's center and this closest point
    const distanceX = circle.x - closestX;
    const distanceY = circle.y - closestY;

    // Calculate the distance squared and compare with the radius squared
    const distanceSquared = distanceX * distanceX + distanceY * distanceY;
    const radiusSquared: i32 = @intFromFloat(circle.radius * circle.radius);
    return distanceSquared <= radiusSquared;
}
