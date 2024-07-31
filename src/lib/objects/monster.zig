const rl = @import("raylib");
const object_types = @import("../objects/types.zig");

pub const monster_radius = 10;

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
