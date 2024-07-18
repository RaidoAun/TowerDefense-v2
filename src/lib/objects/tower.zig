const shapes = @import("../shapes/shapes.zig");
const std = @import("std");
const rl = @import("raylib");

pub const Tower = union(enum) {
    const Self = @This();
    basic: BasicTurret,
    laser: Laser,

    pub fn update(self: *Self) !void {
        switch (self.*) {
            .basic => |*v| {
                try v.update();
            },
            .laser => |_| {},
        }
    }
    pub fn draw(self: Self) void {
        switch (self) {
            .basic => |v| {
                for (v.bullets.items) |b| {
                    rl.drawCircle(b.base.x, b.base.y, 5, rl.Color.blue);
                }
            },
            .laser => |_| {},
        }
    }
};

const BulletBase = struct {
    const Vector = struct {
        x: f32,
        y: f32,
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
    const attack_speed = 5;
    base: BaseTower,
    bullets: std.ArrayList(Bullet),
    range: u32,

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
            .range = 100.0,
        };
    }

    pub fn deinit(self: Self) void {
        self.bullets.deinit();
    }

    fn update(self: *Self) !void {
        try self.bullets.append(.{
            .base = .{
                .x = self.base.x,
                .y = self.base.y,
                .vector = .{
                    .x = 1.0,
                    .y = 2.0,
                },
            },
            .damage = 5,
        });

        for (self.bullets.items) |*v| {
            v.base.y += 1;
        }
    }
};

pub const Laser = struct {
    base: BaseTower,
};
