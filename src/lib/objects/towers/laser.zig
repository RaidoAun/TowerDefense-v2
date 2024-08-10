const BaseTower = @import("base.zig");
const rl = @import("raylib");
const map = @import("../../map/map.zig");
const monster_radius = @import("../../objects/monster.zig").monster_radius;
const block_size = @import("../../objects/block.zig").block_size;
const Position = @import("../../objects/types.zig").Position;
const MonsterList = map.MonsterList();

const object_types = @import("../../objects/types.zig");
const Self = @This();
const color = rl.Color.red;

base: BaseTower,
damage: u16,
target_pos: ?Position,

pub fn init(pos: object_types.Position) Self {
    return .{
        .base = .{
            .pos = pos,
            .level = 0,
            .range = 5.0 * block_size,
            .target_selection = .close,
        },
        .damage = 2,
        .target_pos = null,
    };
}

fn drawAttackIndicatorLine(self_pos: Position, target_pos: Position) void {
    const line_length = 15;
    const line_end_pos: Position = target_pos.applyVector(target_pos.vectorTo(self_pos).withLength(line_length));
    rl.drawLineEx(.{ .x = target_pos.x, .y = target_pos.y }, .{ .x = line_end_pos.x, .y = line_end_pos.y }, 3, color);
}

pub fn update(self: *Self, monsters: *MonsterList) void {
    if (self.base.getTarget(monsters, self.base.target_selection)) |target| {
        var monster_base = target.monster.getBase();
        self.target_pos = monster_base.pos;

        const sub = @subWithOverflow(monster_base.hp, self.damage);
        const isOverflow = sub[1] == 1;
        if (isOverflow or sub[0] == 0) {
            _ = monsters.swapRemove(target.index);
        } else {
            monster_base.hp = sub[0];
        }
    } else {
        self.target_pos = null;
    }
}

pub fn draw(self: Self) void {
    self.base.draw(color);
    if (self.target_pos) |t| {
        drawAttackIndicatorLine(self.base.pos, t);
    }
}
