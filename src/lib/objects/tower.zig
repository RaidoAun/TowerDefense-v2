const shapes = @import("../shapes/shapes.zig");
const MapBounds = @import("../map/map.zig").Bounds;
const MapPoint = @import("../map/map.zig").Point;
const std = @import("std");
const rl = @import("raylib");

pub const Tower = union(enum) {
    const Self = @This();
    basic: BasicTurret,
    laser: Laser,

    // TODO maybe make the switch statement at the call site to avoid passing
    // excess parameters that might not be used.
    pub fn update(self: *Self, map_bounds: MapBounds) !void {
        switch (self.*) {
            .basic => |*v| {
                try v.update(map_bounds);
            },
            .laser => |_| {},
        }
    }
    pub fn draw(self: Self) void {
        switch (self) {
            .basic => |v| {
                for (v.bullets.items) |b| {
                    rl.drawCircle(@intFromFloat(b.base.x), @intFromFloat(b.base.y), 5, rl.Color.blue);
                }
            },
            .laser => |_| {},
        }
    }
};

const BulletBase = struct {
    const Self = @This();
    const Vector = struct {
        x: f32,
        y: f32,
    };
    x: f32,
    y: f32,
    vector: Vector,

    fn update(self: *Self) void {
        self.x += self.vector.x;
        self.y += self.vector.y;
    }
};

const BaseTower = struct {
    // assume these to be the center of the tower
    x: i32,
    y: i32,
    level: u16,
};

pub const BasicTurret = struct {
    const Self = @This();
    const attack_cooldown_ticks = 60;
    base: BaseTower,
    bullets: std.ArrayList(Bullet),
    range: u32,
    attack_tick: u8,

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
            .attack_tick = 0,
        };
    }

    pub fn deinit(self: Self) void {
        self.bullets.deinit();
    }

    fn update(self: *Self, map_bounds: MapBounds) !void {
        if (self.attack_tick == attack_cooldown_ticks) {
            try self.bullets.append(.{
                .base = .{
                    .x = @floatFromInt(self.base.x),
                    .y = @floatFromInt(self.base.y),
                    .vector = .{
                        .x = 1.0,
                        .y = 2.0,
                    },
                },
                .damage = 5,
            });
            self.attack_tick = 0;
        } else {
            self.attack_tick += 1;
        }

        const bullet_count = self.bullets.items.len;
        if (bullet_count == 0) {
            return;
        }

        var i: usize = bullet_count - 1;
        while (i >= 0) : (i -= 1) {
            var bullet = &self.bullets.items[i];
            bullet.base.update();

            if (map_bounds.isOutsideBounds(.{ .x = @intFromFloat(bullet.base.x), .y = @intFromFloat(bullet.base.y) })) {
                _ = self.bullets.swapRemove(i);
            }

            if (i == 0) break;
        }
    }
};

pub const Laser = struct {
    base: BaseTower,
};
