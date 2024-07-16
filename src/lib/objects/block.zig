const shapes = @import("../shapes/shapes.zig");

pub const Type = enum {
    empty,
    wall,
};

pub const Block = struct {
    const Self = @This();
    // TODO do not use Rectangle here
    // to fully optimize this for memory only the type is needed
    // if we assume width to be a constant then positions can be
    // determined from the indexes at which they are in the maps
    // slice of Blocks
    shape: shapes.Rectangle,
    type: Type,

    pub fn draw(self: Self) void {
        self.shape.draw();
    }
};
