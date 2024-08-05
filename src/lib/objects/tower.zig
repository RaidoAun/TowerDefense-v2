const shapes = @import("../shapes/shapes.zig");
const map = @import("../map/map.zig");
const monster_radius = @import("../objects/monster.zig").monster_radius;
const Monster = @import("../objects/monster.zig").Monster;
const MapBounds = map.Bounds;
const MonsterList = map.MonsterList();
const object_types = @import("../objects/types.zig");
const block_size = @import("../objects/block.zig").block_size;
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

const BulletBase = struct {
    const Self = @This();
    pos: object_types.Position,
    vector: object_types.Vector,

    fn update(self: *Self) void {
        self.pos.x += self.vector.x;
        self.pos.y += self.vector.y;
    }
};

const BaseTower = struct {
    const Self = @This();
    pub const Selection = enum {
        close,
        far,
    };
    // assume this to be the center of the tower
    pos: object_types.Position,
    level: u16,
    range: f32,
    target_selection: Selection,

    fn getMonsterInRangeClosest(self: Self, monsters: *MonsterList) ?*Monster {
        var result: ?*Monster = null;
        var closestDist = self.range;
        for (monsters.items) |*m| {
            const dist = m.getBase().pos.distanceTo(self.pos);
            if (dist < closestDist) {
                closestDist = dist;
                result = m;
            }
        }
        return result;
    }

    fn getMonsterInRangeFarthest(self: Self, monsters: *MonsterList) ?*Monster {
        var result: ?*Monster = null;
        var x: object_types.Position.T = 0;
        for (monsters.items) |*m| {
            const dist = m.getBase().pos.distanceTo(self.pos);
            if (dist < self.range and dist > x) {
                x = dist;
                result = m;
            }
        }
        return result;
    }

    fn getTarget(self: Self, monsters: *MonsterList, selection: Selection) ?*Monster {
        return switch (selection) {
            .close => self.getMonsterInRangeClosest(monsters),
            .far => self.getMonsterInRangeFarthest(monsters),
        };
    }
};

pub const BasicTurret = struct {
    const Self = @This();
    const attack_cooldown_ticks = 60;
    const bullet_speed = 3;
    base: BaseTower,
    bullets: std.ArrayList(Bullet),
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
                .range = 3.0 * block_size,
                .target_selection = .close,
            },
            .bullets = std.ArrayList(Bullet).init(allocator),
            .attack_tick = 0,
        };
    }

    pub fn deinit(self: Self) void {
        self.bullets.deinit();
    }

    fn update(self: *Self, map_bounds: MapBounds, monsters: *MonsterList) !void {
        if (self.attack_tick == attack_cooldown_ticks) {
            if (self.base.getTarget(monsters, self.base.target_selection)) |m| {
                const vector = self.base.pos.vectorTo(m.getBase().pos).withLength(bullet_speed);

                try self.bullets.append(.{
                    .base = .{
                        .pos = self.base.pos,
                        .vector = vector,
                    },
                    .damage = 50,
                });
                self.attack_tick = 0;
            }
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

    fn draw(self: Self) void {
        rl.drawRectangle(@as(i32, @intFromFloat(self.base.pos.x)) - block_size / 2, @as(i32, @intFromFloat(self.base.pos.y)) - block_size / 2, block_size, block_size, rl.Color.dark_blue);
        for (self.bullets.items) |b| {
            rl.drawCircle(@intFromFloat(b.base.pos.x), @intFromFloat(b.base.pos.y), bullet_radius, rl.Color.blue);
        }
    }
};

pub const Laser = struct {
    base: BaseTower,
};

test "allocation and free of basicturret" {
    const allocator = std.testing.allocator;

    var m = try map.GameMap().initMap(allocator, 10, 10);
    defer m.deInit();
    try m.createMonster(.{ .x = 11, .y = 11 });
    _ = try m.getOrCreateTower(.{ .x = 15, .y = 15 });
    var i: i32 = 0;

    while (i < 1000) : (i += 1) {
        try m.update();
    }
}
