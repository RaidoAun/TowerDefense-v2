const std = @import("std");
const rl = @import("raylib");
const objects = @import("lib/objects/objects.zig");
const utils = @import("lib/shapes/utils.zig");
const shapes = @import("lib/shapes/shapes.zig");
const map = @import("lib/map/map.zig");
const Player = objects.Player;

const GameState = struct {
    deltaTime: f64,
    player: Player,
    map: map.GameMap(200, 100),
};

fn initGame(allocator: *const std.mem.Allocator) !GameState {
    const state = GameState{
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
    };
    return state;
}

fn update(state: *GameState) void {
    const dt: f64 = state.deltaTime;
    state.player.update(dt);
}

fn draw(state: *const GameState) void {
    rl.beginDrawing();
    defer rl.endDrawing();
    rl.clearBackground(rl.Color.white);

    state.map.draw();
    state.player.shape.draw();
}

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

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var state = try initGame(&allocator);
    state.deltaTime = dt;

    var previousTime: i64 = std.time.microTimestamp();
    var passedTime: f64 = 0.0;
    while (!rl.windowShouldClose()) {
        const currentTime = std.time.microTimestamp();
        passedTime += @as(f64, @floatFromInt(currentTime - previousTime)) / @as(f64, 1000000.0);
        while (passedTime > 0) {
            previousTime = std.time.microTimestamp();
            // std.debug.print("update\n", .{});
            passedTime -= dt;
            update(&state);
        }

        // std.debug.print("draw\n", .{});
        draw(&state);
    }
}
