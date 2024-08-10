const object_types = @import("../../objects/types.zig");
const block_size = @import("../../objects/block.zig").block_size;
const rl = @import("raylib");
const map = @import("../../map/map.zig");
const MonsterList = map.MonsterList();
const Monster = @import("../../objects/monster.zig").Monster;

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

const Target = struct {
    monster: *Monster,
    index: usize,
};

fn getMonsterInRangeClosest(self: Self, monsters: *MonsterList) ?Target {
    var monster: ?*Monster = null;
    var index: usize = undefined;
    var closestDist = self.range;
    for (monsters.items, 0..) |*m, i| {
        const dist = m.getBase().pos.distanceTo(self.pos);
        if (dist < closestDist) {
            closestDist = dist;
            monster = m;
            index = i;
        }
    }
    if (monster) |m| {
        return .{
            .monster = m,
            .index = index,
        };
    }
    return null;
}

fn getMonsterInRangeFarthest(self: Self, monsters: *MonsterList) ?Target {
    var monster: ?*Monster = null;
    var index: usize = undefined;
    var x: object_types.Position.T = 0;
    for (monsters.items, 0..) |*m, i| {
        const dist = m.getBase().pos.distanceTo(self.pos);
        if (dist < self.range and dist > x) {
            x = dist;
            monster = m;
            index = i;
        }
    }
    if (monster) |m| {
        return .{
            .monster = m,
            .index = index,
        };
    }
    return null;
}

pub fn getTarget(self: Self, monsters: *MonsterList, selection: Selection) ?Target {
    return switch (selection) {
        .close => self.getMonsterInRangeClosest(monsters),
        .far => self.getMonsterInRangeFarthest(monsters),
    };
}

pub fn draw(self: Self, color: rl.Color) void {
    rl.drawRectangle(@as(i32, @intFromFloat(self.pos.x)) - block_size / 2, @as(i32, @intFromFloat(self.pos.y)) - block_size / 2, block_size, block_size, color);
}
