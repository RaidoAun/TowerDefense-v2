const std = @import("std");
const lib = @import("lib/lib.zig");
const input = lib.input;
const rl = lib.rl;
const objects = lib.object;
const shapes = lib.shape;
const map = lib.map;
const BaseTower = lib.object.tower.BaseTower;
const Tower = lib.object.tower.Tower;

const GUI = struct {
    const TowerInfo = struct {
        upgrade: shapes.Rectangle,
        sell: shapes.Rectangle,
        shape: shapes.Rectangle,
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

    pub fn draw(self: Self) !void {
        if (self.towerInfo) |v| {
            try v.draw(self.allocator);
        }
    }

    pub fn towerClicked(self: *Self, tower: *Tower) void {
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

    pub fn handleInput(self: *Self, pos: input.Position, game_map: *map.GameMap()) !bool {
        if (self.towerInfo) |towerInfo| {
            if (!towerInfo.shape.containsMouseInput(pos)) return false;

            if (towerInfo.upgrade.containsMouseInput(pos)) {
                towerInfo.tower.levelUp();
            }
            if (towerInfo.sell.containsMouseInput(pos)) {
                try game_map.removeTower(map.GameMap().getBlockIndexesWithCoords(@intFromFloat(towerInfo.tower.getBase().pos.x), @intFromFloat(towerInfo.tower.getBase().pos.y)));
                self.towerInfo = null;
            }
            return true;
        }
        return false;
    }
};

const GameState = struct {
    const Self = @This();
    deltaTime: f64,
    map: map.GameMap(),
    allocator: std.mem.Allocator,
    gui: GUI,

    // TODO update rate should be seperate from draw rate
    // if setting fps too small then items could clip over the walls due to them just moving too many pixels at once
    // the rate should be such that the maximum pixels passed by an object per update shouldnt exceed a blocks smallest width
    fn update(self: *Self) !void {
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

    fn draw(self: Self) !void {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.white);

        self.map.draw();
        rl.drawFPS(100, 100);
        try self.gui.draw();
    }

    fn init(allocator: std.mem.Allocator, dt: f64) !GameState {
        return .{
            .deltaTime = dt,
            .map = try map.GameMap().initMap(allocator, 20, 20),
            .allocator = allocator,
            .gui = .{
                .towerInfo = null,
                .allocator = allocator,
            },
        };
    }

    fn deInit(self: *Self) void {
        self.map.deInit();
    }
};
pub fn main() !void {
    const screenWidth = 800;
    const screenHeight = 800;

    rl.initWindow(screenWidth, screenHeight, "raylib-zig [core] example - basic window");
    defer rl.closeWindow();

    const fps = 60.0;
    const dt: f64 = 1.0 / fps;

    // TODO figure out if this is even needed since we have a timer
    // here already and we could sleep in our loop ourselves
    rl.setTargetFPS(fps);
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var state = try GameState.init(allocator, dt);
    defer state.deInit();

    var timer = try std.time.Timer.start();

    var passedTime: f64 = 0.0;
    while (!rl.windowShouldClose()) {
        passedTime += @as(f64, @floatFromInt(timer.lap())) / @as(f64, std.time.ns_per_s);
        while (passedTime > 0) {
            passedTime -= dt;
            try state.update();
        }

        try state.draw();
    }
}

test "test GameState.init()" {
    const fps = 60.0;
    const dt: f64 = 1.0 / fps;
    const allocator = std.testing.allocator;

    var state = try GameState.init(allocator, dt);
    defer state.deInit();
}
