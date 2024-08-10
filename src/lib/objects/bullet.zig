const object_types = @import("../objects/types.zig");
const map = @import("../map/map.zig");
const MapBounds = map.Bounds;

pub const BulletBase = struct {
    const Self = @This();
    pos: object_types.Position,
    vector: object_types.Vector,

    pub fn update(self: *Self) void {
        self.pos.x += self.vector.x;
        self.pos.y += self.vector.y;
    }

    pub fn isOutsideMap(self: Self, map_bounds: MapBounds) bool {
        return map_bounds.isObjectOutsideBounds(self.pos);
    }
};
