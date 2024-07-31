const rl = @import("raylib");

pub const monster_radius = 10;

pub const Monster = union(enum) {
    const Self = @This();
    basic: Basic,

    pub fn update(self: *Self) void {
        switch (self.*) {
            .basic => |*v| {
                v.base.x += 0;
            },
        }
    }
    pub fn draw(self: Self) void {
        switch (self) {
            .basic => |v| {
                rl.drawCircle(v.base.x, v.base.y, monster_radius, rl.Color.green);
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
    x: i32,
    y: i32,
    hp: u32,
    speed: u32,
};

const Basic = struct {
    base: Base,
};
