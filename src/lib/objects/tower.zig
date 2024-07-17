const shapes = @import("../shapes/shapes.zig");
const std = @import("std");

pub const Tower = union(enum) {
    const Self = @This();
    basic: BasicTurret,
    laser: Laser,

    fn attack(self: Self) void {
        switch (self) {
            .basic => |_| {},
            .laser => |_| {},
        }
    }
    pub fn draw(self: Self) void {
        switch (self) {
            .basic => |_| {},
            .laser => |_| {},
        }
    }
};

const BulletBase = struct {
    const Vector = struct {
        x: i8,
        y: i8,
    };
    x: i32,
    y: i32,
    vector: Vector,
};

const BaseTower = struct {
    // assume these to be the center of the tower
    x: i32,
    y: i32,
    level: u16,
};

pub const BasicTurret = struct {
    const Self = @This();
    base: BaseTower,
    bullets: std.ArrayList(Bullet),

    const Bullet = struct {
        base: BulletBase,
        damage: u16,
    };

    pub fn init(allocator: std.mem.Allocator, x: i32, y: i32) BasicTurret {
        return .{
            .base = .{
                .x = x,
                .y = y,
                .level = 0,
            },
            .bullets = std.ArrayList(Bullet).init(allocator),
        };
    }

    pub fn deinit(self: Self) void {
        self.bullets.deinit();
    }
};

pub const Laser = struct {
    base: BaseTower,
};
