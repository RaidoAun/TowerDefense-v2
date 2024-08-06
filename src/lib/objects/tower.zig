const map = @import("../map/map.zig");
const Minigun = @import("../objects/towers/minigun.zig");
const Laser = @import("../objects/towers/laser.zig");
const MapBounds = map.Bounds;
const MonsterList = map.MonsterList();

// TODO consider using Struct of Arrays for this.
pub const Tower = union(enum) {
    const Self = @This();
    basic: Minigun,
    laser: Laser,

    // TODO maybe make the switch statement at the call site to avoid passing
    // excess parameters that might not be used.
    pub fn update(self: *Self, map_bounds: MapBounds, monsters: *MonsterList) !void {
        switch (self.*) {
            .basic => |*v| {
                try v.update(map_bounds, monsters);
            },
            .laser => |_| {},
        }
    }
    pub fn draw(self: Self) void {
        switch (self) {
            .basic => |v| {
                v.draw();
            },
            .laser => |_| {},
        }
    }
    pub fn deinit(self: Self) void {
        switch (self) {
            .basic => |v| {
                v.deinit();
            },
            .laser => |_| {},
        }
    }
};
