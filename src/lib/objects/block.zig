const shapes = @import("../shapes/shapes.zig");

pub const Type = enum {
    empty,
    wall,
};

pub const Block = struct {
    const Self = @This();
    // TODO do not use Rectangle here
    shape: shapes.Rectangle,
    type: Type,

    pub fn draw(self: Self) void {
        self.shape.draw();
    }
};
