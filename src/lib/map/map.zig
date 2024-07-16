const std = @import("std");
const shapes = @import("../shapes/shapes.zig");
const block = @import("../objects/block.zig");
const Block = block.Block;
const rl = @import("raylib");

const MapSize = u32;

const Pattern = struct {
    const Self = @This();
    data: [][]bool,
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator, sizeX: MapSize, sizeY: MapSize, steps: u8) !Pattern {
        var random = std.Random.DefaultPrng.init(0);

        const data = try allocator.alloc([]bool, sizeY);
        for (data) |*row| {
            row.* = try allocator.alloc(bool, sizeX);
            for (row.*) |*b| {
                b.* = random.random().boolean();
            }
        }

        // mutating the values that the data slices points to
        try smoothen(allocator, data, sizeX, sizeY, steps);

        return .{
            .data = data,
            .allocator = allocator,
        };
    }

    // TODO this could surely be optimized
    fn smoothen(allocator: std.mem.Allocator, pattern: [][]bool, sizeX: MapSize, sizeY: MapSize, steps: u8) !void {
        if (steps == 0) return;

        var arena = std.heap.ArenaAllocator.init(allocator);
        defer arena.deinit();

        const arena_allocator = arena.allocator();

        const result = try arena_allocator.alloc([]bool, sizeY);

        for (result) |*row| {
            row.* = try arena_allocator.alloc(bool, sizeX);
        }

        var i: u8 = 0;
        while (i < steps) : (i += 1) {
            for (0..sizeY) |y| {
                for (0..sizeX) |x| {
                    const val = pattern[y][x];
                    var same_count: usize = if (!val) 2 else 0;
                    var different_count: usize = 0;

                    const y0 = if (y > 0) y else 1;
                    const x0 = if (x > 0) x else 1;

                    for ((y0 - 1)..(y + 2)) |ny| {
                        for ((x0 - 1)..(x + 2)) |nx| {
                            if (ny == y and nx == x) continue; // Skip the current cell
                            if (ny < sizeY and nx < sizeX) {
                                if (pattern[ny][nx] == val) same_count += 1 else different_count += 1;
                            }
                        }
                    }

                    result[y][x] = if (same_count >= different_count) val else !val;
                }
            }

            for (0..sizeY) |y| {
                @memcpy(pattern[y], result[y]);
            }
        }
    }

    fn deInit(self: Self) void {
        for (self.data) |row| {
            self.allocator.free(row);
        }
        self.allocator.free(self.data);
    }
};

pub fn GameMap() type {
    return struct {
        const Self = @This();
        allocator: std.mem.Allocator,
        blocks: [][]Block,

        pub fn draw(self: Self) void {
            for (self.blocks) |row| {
                for (row) |b| {
                    b.draw();
                }
            }
        }

        pub fn initMap(allocator: std.mem.Allocator, sizeX: MapSize, sizeY: MapSize) !GameMap() {
            const block_size = 5;
            const blocks = try allocator.alloc([]Block, sizeY);

            // TODO probably can use FixedBufferAllocator here
            const pattern = try Pattern.init(allocator, sizeX, sizeY, 3);
            defer pattern.deInit();

            for (blocks, 0..) |*row, i| {
                row.* = try allocator.alloc(Block, sizeX);
                for (row.*, 0..) |*b, j| {
                    const is_wall = pattern.data[i][j];
                    b.* = .{
                        .shape = shapes.Rectangle{
                            .x = @intCast(block_size * j),
                            .y = @intCast(block_size * i),
                            .width = block_size,
                            .height = block_size,
                            .color = if (is_wall) rl.Color.black else rl.Color.white,
                        },
                        .type = if (is_wall) block.Type.wall else block.Type.empty,
                    };
                }
            }

            return .{
                .blocks = blocks,
                .allocator = allocator,
            };
        }

        pub fn deInit(self: Self) void {
            for (self.blocks) |row| {
                self.allocator.free(row);
            }
            self.allocator.free(self.blocks);
        }
    };
}

test "test map memory allocation and deallocation" {
    const allocator = std.testing.allocator;

    const m = try GameMap().initMap(allocator, 200, 400);
    defer m.deInit();
}
