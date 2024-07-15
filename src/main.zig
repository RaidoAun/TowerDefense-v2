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
    map: map.GameMap(100, 100),
    allocator: std.mem.Allocator,

    fn update(self: *Self) void {
        const dt: f64 = self.deltaTime;
        self.player.update(dt);
    }

    fn draw(self: Self) void {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.white);

        self.map.draw();
        self.player.shape.draw();
    }

    fn init(allocator: std.mem.Allocator) !GameState {
        return .{
            .deltaTime = 0.0,
            .player = .{
                .speed = 500,
                .shape = .{
                    .x = 400,
                    .y = 225,
                    .width = 200,
                    .height = 20,
                    .color = rl.Color.red,
                },
            },
            .map = try map.GameMap(100, 100).initMap(allocator),
            .allocator = allocator,
        };
    }
};

// TODO make deinit func, also use maps deinit there
pub fn main() !void {
    const screenWidth = 800;
    const screenHeight = 800;

    rl.initWindow(screenWidth, screenHeight, "raylib-zig [core] example - basic window");
    defer rl.closeWindow();

    const fps = 165.0;
    const dt: f64 = 1.0 / fps;
    std.debug.print("{}\n", .{dt});
    std.debug.print("sizeof rect {}\n", .{@sizeOf(map.GameMap(100, 100))});

    rl.setTargetFPS(fps);
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var state = try GameState.init(allocator);
    state.deltaTime = dt;

    var previousTime: i64 = std.time.microTimestamp();
    var passedTime: f64 = 0.0;
    while (!rl.windowShouldClose()) {
        const currentTime = std.time.microTimestamp();
        passedTime += @as(f64, @floatFromInt(currentTime - previousTime)) / @as(f64, 1000000.0);
        while (passedTime > 0) {
            previousTime = std.time.microTimestamp();
            passedTime -= dt;
            state.update();
        }

        state.draw();
    }
}
