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

pub fn getTarget(self: Self, monsters: *MonsterList, selection: Selection) ?*Monster {
    return switch (selection) {
        .close => self.getMonsterInRangeClosest(monsters),
        .far => self.getMonsterInRangeFarthest(monsters),
    };
}

pub fn draw(self: Self, color: rl.Color) void {
    rl.drawRectangle(@as(i32, @intFromFloat(self.pos.x)) - block_size / 2, @as(i32, @intFromFloat(self.pos.y)) - block_size / 2, block_size, block_size, color);
}
