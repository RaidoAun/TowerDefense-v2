const std = @import("std");
const rl = @import("raylib");
const objects = @import("lib/objects.zig");
const Player = objects.Player;
const Bubble = objects.Bubble;

const GameState = struct {
    deltaTime: i64,
    player: Player,
    bubbles: std.ArrayList(Bubble),
};

fn initGame(allocator: *const std.mem.Allocator) !GameState {
    var state = GameState{
        .deltaTime = 0,
        .player = .{
            .speed = 0.0003,
            .shape = .{
                .x = 400,
                .y = 225,
                .width = 200,
                .height = 20,
                .color = rl.Color.red,
            },
        },
        .bubbles = std.ArrayList(Bubble).init(allocator.*),
    };
    for (0..10) |i| {
        try state.bubbles.append(Bubble{
            .speed = 0.0002,
            .shape = .{
                .x = @intCast(i * 50),
                .y = 200,
                .radius = 25,
                .color = rl.Color.green,
            },
        });
    }
    return state;
}

fn update(state: *GameState) void {
    const dt: f64 = @floatFromInt(state.deltaTime);
    state.player.update(dt);

    for (state.bubbles.items) |*v| {
        v.update(dt);
        if (state.player.shape.isCollision(v.shape)) {
            v.onCollision();
        }
    }
}

fn draw(state: *const GameState) void {
    rl.beginDrawing();
    defer rl.endDrawing();
    rl.clearBackground(rl.Color.white);

    state.player.shape.draw();

    for (state.bubbles.items) |*v| {
        v.shape.draw();
    }
}

pub fn main() !void {
    const screenWidth = 800;
    const screenHeight = 800;

    rl.initWindow(screenWidth, screenHeight, "raylib-zig [core] example - basic window");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var state = try initGame(&allocator);

    var previousTime = std.time.microTimestamp();
    while (!rl.windowShouldClose()) {
        const currentTime = std.time.microTimestamp();
        state.deltaTime = currentTime - previousTime;
        previousTime = std.time.microTimestamp();
        // std.debug.print("{}\n", .{state.deltaTime});

        update(&state);
        draw(&state);
    }
}
