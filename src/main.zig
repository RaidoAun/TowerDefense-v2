const std = @import("std");
const lib = @import("lib/lib.zig");
const rl = lib.rl;
const objects = lib.object;
const map = lib.map;
const GameState = lib.state.GameState;

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
