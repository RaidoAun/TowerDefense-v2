const BaseTower = @import("base.zig");
const map = @import("../../map/map.zig");
const monster_radius = @import("../../objects/monster.zig").monster_radius;
const MapBounds = map.Bounds;
const MonsterList = map.MonsterList();
const object_types = @import("../../objects/types.zig");
const block_size = @import("../../objects/block.zig").block_size;
const std = @import("std");
const rl = @import("raylib");
const BulletBase = @import("../bullet.zig").BulletBase;

const Self = @This();
const attack_cooldown_ticks = 60;
const bullet_speed = 3;
const bullet_radius = 5;
base: BaseTower,
bullets: std.ArrayList(Bullet),
attack_tick: u8,

const Bullet = struct {
    base: BulletBase,
    damage: u16,
};

pub fn init(allocator: std.mem.Allocator, pos: object_types.Position) Self {
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

pub fn update(self: *Self, map_bounds: MapBounds, monsters: *MonsterList) !void {
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

        if (bullet.base.isOutsideMap(map_bounds)) {
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

pub fn draw(self: Self) void {
    self.base.draw(rl.Color.dark_blue);
    for (self.bullets.items) |b| {
        rl.drawCircle(@intFromFloat(b.base.pos.x), @intFromFloat(b.base.pos.y), bullet_radius, rl.Color.blue);
    }
}

test "allocation and free of minigun" {
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
