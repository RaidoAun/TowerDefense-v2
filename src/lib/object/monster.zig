const lib = @import("../lib.zig");
const rl = lib.rl;
const object_types = lib.object.types;

pub const monster_radius = 10;

// TODO consider using Struct of Arrays for this.
pub const Monster = union(enum) {
    const Self = @This();
    basic: Basic,

    pub fn update(self: *Self) void {
        switch (self.*) {
            .basic => |*v| {
                v.base.pos.x += 0;
            },
        }
    }
    pub fn draw(self: Self) void {
        switch (self) {
            .basic => |v| {
                rl.drawCircle(@intFromFloat(v.base.pos.x), @intFromFloat(v.base.pos.y), monster_radius, rl.Color.green);
            },
        }
    }

    pub fn getBase(self: *Self) *Base {
        return switch (self.*) {
            .basic => |*v| &v.base,
        };
    }
};
const Base = struct {
    pos: object_types.Position,
    hp: u32,
    speed: u32,
};

const Basic = struct {
    base: Base,
};
