const std = @import("std");
const rl = @import("raylib");
const objects = @import("lib/objects/objects.zig");
const utils = @import("lib/shapes/utils.zig");
const shapes = @import("lib/shapes/shapes.zig");
const map = @import("lib/map/map.zig");
const Player = objects.Player;

const GameState = struct {
    const Self = @This();
    deltaTime: f64,
    player: Player,
    map: map.GameMap(),
    allocator: std.mem.Allocator,

    // TODO update rate should be seperate from draw rate
    // if setting fps too small then items could clip over the walls due to them just moving too many pixels at once
    // the rate should be such that the maximum pixels passed by an object per update shouldnt exceed a blocks smallest width
    fn update(self: *Self) !void {
        const dt: f64 = self.deltaTime;
        self.player.update(dt);
        try self.map.update();
    }

    fn draw(self: Self) void {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.white);

        self.map.draw();
        rl.drawFPS(100, 100);
        self.player.shape.draw();
    }

    fn init(allocator: std.mem.Allocator, dt: f64) !GameState {
        return .{
            .deltaTime = dt,
            .player = .{
                .speed = 500,
                .shape = .{
                    .x = 400,
                    .y = 225,
                    .width = 100,
                    .height = 20,
                    .color = rl.Color.red,
                },
            },
            .map = try map.GameMap().initMap(allocator, 20, 20),
            .allocator = allocator,
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

        state.draw();
    }
}

test "test GameState.init()" {
    const fps = 60.0;
    const dt: f64 = 1.0 / fps;
    const allocator = std.testing.allocator;

    var state = try GameState.init(allocator, dt);
    defer state.deInit();
}
