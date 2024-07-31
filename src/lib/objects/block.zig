const shapes = @import("../shapes/shapes.zig");
const rl = @import("raylib");
const std = @import("std");

pub const Type = enum {
    empty,
    wall,
    // TODO maybe make drawing of towers do nothing here?
    // then a generic type for towers could be added here instead.
    basicTower,
};

pub const Block = struct {
    const Self = @This();
    shape: shapes.Square,
    type: Type,

    pub fn draw(self: Self) void {
        var color: rl.Color = undefined;
        switch (self.type) {
            .wall => |_| {
                color = rl.Color.black;
            },
            .empty => |_| {
                color = rl.Color.white;
            },
            .basicTower => |_| {
                color = rl.Color.yellow;
            },
        }
        rl.drawRectangle(self.shape.x, self.shape.y, self.shape.width, self.shape.width, color);
    }
};
