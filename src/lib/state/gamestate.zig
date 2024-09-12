const std = @import("std");
const lib = @import("../lib.zig");
const input = lib.input;
const rl = lib.rl;
const BaseTower = lib.object.tower.BaseTower;
const Tower = lib.object.tower.Tower;
const shapes = lib.shape;

const GUI = struct {
    const TowerInfo = struct {
        upgrade: shapes.Rectangle,
        sell: shapes.Rectangle,
        shape: shapes.Rectangle,
        // TODO reconsider if using a pointer here is a good idea.
        // If the towers list gets resized this will beciome a dangling pointer.
        // This should never happen right now though.
        tower: *Tower,

        pub fn draw(self: @This(), allocator: std.mem.Allocator) !void {
            self.shape.draw();
            self.upgrade.draw();
            self.sell.draw();

            // TODO write test for allocation and free
            const text = try std.fmt.allocPrintZ(allocator, "level: {}\nrange: {d}", .{ self.tower.getBase().level, self.tower.getBase().range });
            defer allocator.free(text);
            rl.drawText(text, self.shape.x + 10, self.shape.y + 50, 20, rl.Color.black);
        }
    };
    const Self = @This();
    towerInfo: ?TowerInfo,
    allocator: std.mem.Allocator,

    pub fn draw(self: @This()) !void {
        if (self.towerInfo) |v| {
            try v.draw(self.allocator);
        }
    }

    pub fn towerClicked(self: *@This(), tower: *Tower) void {
        const towerBase = tower.getBase();
        const w = 200;
        const h = 100;
        const x = @as(i32, @intFromFloat(towerBase.pos.x - w / 2));
        const y = @as(i32, @intFromFloat(towerBase.pos.y - h * 2));
        self.towerInfo = .{
            .sell = .{
                .x = x + w - 40,
                .y = y + h - 40,
                .width = 20,
                .height = 20,
                .color = rl.Color.red,
            },
            .upgrade = .{
                .x = x + 20,
                .y = y + h - 40,
                .width = 20,
                .height = 20,
                .color = rl.Color.green,
            },
            .shape = .{
                .x = x,
                .y = y,
                .width = w,
                .height = h,
                .color = rl.Color.light_gray,
            },
            .tower = tower,
        };
    }

    pub fn handleInput(self: *@This(), pos: input.Position, game_map: *lib.map.GameMap()) !bool {
        if (self.towerInfo) |towerInfo| {
            if (!towerInfo.shape.containsMouseInput(pos)) return false;

            if (towerInfo.upgrade.containsMouseInput(pos)) {
                towerInfo.tower.levelUp();
            }
            if (towerInfo.sell.containsMouseInput(pos)) {
                try game_map.removeTower(lib.map.GameMap().getBlockIndexesWithCoords(@intFromFloat(towerInfo.tower.getBase().pos.x), @intFromFloat(towerInfo.tower.getBase().pos.y)));
                self.towerInfo = null;
            }
            return true;
        }
        return false;
    }
};

const Self = @This();
deltaTime: f64,
map: lib.map.GameMap(),
allocator: std.mem.Allocator,
gui: GUI,

// TODO update rate should be seperate from draw rate
// if setting fps too small then items could clip over the walls due to them just moving too many pixels at once
// the rate should be such that the maximum pixels passed by an object per update shouldnt exceed a blocks smallest width
pub fn update(self: *Self) !void {
    try self.map.update();

    if (rl.isMouseButtonPressed(rl.MouseButton.mouse_button_left)) {
        const mouse_pos = input.getMousePosition();
        if (!(try self.gui.handleInput(mouse_pos, &self.map))) {
            self.gui.towerInfo = null;

            if (try self.map.getOrCreateTower(mouse_pos)) |tower| {
                self.gui.towerClicked(tower);

                std.debug.print("tower: {}\n", .{tower.*});
            }
        }
    }
    if (rl.isMouseButtonPressed(rl.MouseButton.mouse_button_right)) {
        try self.map.createMonster(input.getMousePosition());
    }
}

pub fn draw(self: Self) !void {
    rl.beginDrawing();
    defer rl.endDrawing();

    rl.clearBackground(rl.Color.white);

    self.map.draw();
    rl.drawFPS(100, 100);
    try self.gui.draw();
}

pub fn init(allocator: std.mem.Allocator, dt: f64) !Self {
    return .{
        .deltaTime = dt,
        .map = try lib.map.GameMap().initMap(allocator, 20, 20),
        .allocator = allocator,
        .gui = .{
            .towerInfo = null,
            .allocator = allocator,
        },
    };
}

pub fn deInit(self: *Self) void {
    self.map.deInit();
}
