const std = @import("std");
const lib = @import("../lib.zig");
const shapes = lib.shape;
const rl = lib.rl;

pub const block_size = 20;

pub const Type = enum {
    empty,
    wall,
    tower,
};

pub const Block = struct {
    const Self = @This();
    shape: shapes.Square,
    type: Type,

    pub fn draw(self: Self) void {
        const color: rl.Color = switch (self.type) {
            .wall => rl.Color.black,
            .empty => rl.Color.white,
            .tower => rl.Color.yellow,
        };
        rl.drawRectangle(self.shape.x, self.shape.y, self.shape.width, self.shape.width, color);
    }
};
