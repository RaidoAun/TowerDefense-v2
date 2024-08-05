const shapes = @import("../shapes/shapes.zig");
const map = @import("../map/map.zig");
const monster_radius = @import("../objects/monster.zig").monster_radius;
const MapBounds = map.Bounds;
const MonsterList = map.MonsterList();
const object_types = @import("../objects/types.zig");
const std = @import("std");
const rl = @import("raylib");

const bullet_radius = 5;

// TODO consider using Struct of Arrays for this.
pub const Tower = union(enum) {
    const Self = @This();
    basic: BasicTurret,
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
                for (v.bullets.items) |b| {
                    rl.drawCircle(@intFromFloat(b.base.pos.x), @intFromFloat(b.base.pos.y), bullet_radius, rl.Color.blue);
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
    pos: object_types.Position,
    vector: Vector,

    fn update(self: *Self) void {
        self.pos.x += self.vector.x;
        self.pos.y += self.vector.y;
    }
};

const BaseTower = struct {
    // assume this to be the center of the tower
    pos: object_types.Position,
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

    pub fn init(allocator: std.mem.Allocator, pos: object_types.Position) BasicTurret {
        return .{
            .base = .{
                .pos = pos,
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

    fn update(self: *Self, map_bounds: MapBounds, monsters: *MonsterList) !void {
        if (self.attack_tick == attack_cooldown_ticks) {
            try self.bullets.append(.{
                .base = .{
                    .pos = self.base.pos,
                    .vector = .{
                        .x = 1.0,
                        .y = 2.0,
                    },
                },
                .damage = 50,
            });
            self.attack_tick = 0;
        } else {
            self.attack_tick += 1;
        }

        self.updateBullets(map_bounds, monsters);
    }

    fn updateBullets(self: *Self, map_bounds: MapBounds, monsters: *MonsterList) void {
        var i: i32 = @as(i32, @intCast(self.bullets.items.len)) - 1;
        while (i >= 0) : (i -= 1) {
            var bullet = &self.bullets.items[@intCast(i)];
            bullet.base.update();

            if (map_bounds.isObjectOutsideBounds(bullet.base.pos)) {
                _ = self.bullets.swapRemove(@intCast(i));
                continue;
            }

            if (isBulletCollisionWithMonster(bullet.*, monsters)) {
                _ = self.bullets.swapRemove(@intCast(i));
                continue;
            }
        }
    }

    fn isBulletCollisionWithMonster(bullet: Bullet, monsters: *MonsterList) bool {
        var i: i32 = @as(i32, @intCast(monsters.items.len)) - 1;
        while (i >= 0) : (i -= 1) {
            var monster_base = monsters.items[@intCast(i)].getBase();
            if (object_types.Position.distanceBetween(monster_base.pos, bullet.base.pos) < monster_radius + bullet_radius) {
                const sub = @subWithOverflow(monster_base.hp, bullet.damage);
                const isOverflow = sub[1] == 1;
                if (isOverflow or sub[0] == 0) {
                    _ = monsters.swapRemove(@intCast(i));
                } else {
                    monster_base.hp = sub[0];
                }

                return true;
            }
        }
        return false;
    }
};

pub const Laser = struct {
    base: BaseTower,
};
