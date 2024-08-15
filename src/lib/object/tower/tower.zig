pub const BaseTower = @import("base.zig");
pub const Minigun = @import("minigun.zig");
pub const Laser = @import("laser.zig");
const lib = @import("../../lib.zig");
const MapBounds = lib.map.Bounds;
const MonsterList = lib.map.MonsterList();

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
            .laser => |*v| {
                v.update(monsters);
            },
        }
    }
    pub fn draw(self: Self) void {
        switch (self) {
            .basic => |v| {
                v.draw();
            },
            .laser => |v| {
                v.draw();
            },
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
    pub fn getBase(self: Self) BaseTower {
        return switch (self) {
            .basic => |v| v.base,
            .laser => |v| v.base,
        };
    }

    pub fn levelUp(self: *Self) void {
        switch (self.*) {
            .basic => |*v| {
                v.base.level += 1;
            },
            .laser => |*v| {
                v.base.level += 1;
            },
        }
    }
};
