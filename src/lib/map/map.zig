const std = @import("std");
const shapes = @import("../shapes/shapes.zig");
const block = @import("../objects/block.zig");
const towers = @import("../objects/tower.zig");
const Tower = towers.Tower;
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
        blocks: [][]Block, // only for drawing
        towers: std.AutoArrayHashMap(BlockIndexes, Tower),
        const block_size = 20;

        pub fn draw(self: Self) void {
            for (self.blocks) |row| {
                for (row) |b| {
                    b.draw();
                }
            }
        }

        pub fn initMap(allocator: std.mem.Allocator, sizeX: MapSize, sizeY: MapSize) !GameMap() {
            const blocks = try allocator.alloc([]Block, sizeY);

            // std.debug.print("sizeof tower {}\n", .{@sizeOf(Block)});
            // std.debug.print("sizeof rec {}\n", .{@sizeOf(shapes.Rectangle)});
            // std.debug.print("sizeof sq {}\n", .{@sizeOf(shapes.Square)});

            // TODO probably can use FixedBufferAllocator here
            const pattern = try Pattern.init(allocator, sizeX, sizeY, 3);
            defer pattern.deInit();

            for (blocks, 0..) |*row, i| {
                row.* = try allocator.alloc(Block, sizeX);
                for (row.*, 0..) |*b, j| {
                    const is_wall = pattern.data[i][j];
                    b.* = .{
                        .shape = shapes.Square{
                            .x = @intCast(block_size * j),
                            .y = @intCast(block_size * i),
                            .width = block_size,
                        },
                        .type = if (is_wall) block.Type.wall else block.Type.empty,
                    };
                }
            }

            return .{
                .blocks = blocks,
                .allocator = allocator,
                .towers = std.AutoArrayHashMap(BlockIndexes, Tower).init(allocator),
            };
        }

        pub fn deInit(self: *Self) void {
            for (self.blocks) |row| {
                self.allocator.free(row);
            }
            self.allocator.free(self.blocks);
            self.towers.deinit();
        }

        const BlockIndexes = struct {
            x: u16,
            y: u16,
        };

        pub fn getBlockIndexesWithCoords(x: i32, y: i32) BlockIndexes {
            return .{
                .x = @intCast(@divFloor(x, block_size)),
                .y = @intCast(@divFloor(y, block_size)),
            };
        }

        pub fn createTower(self: *Self, x: i32, y: i32) !void {
            const indexes = getBlockIndexesWithCoords(x, y);
            try self.towers.putNoClobber(indexes, .{
                .basic = towers.BasicTurret.init(self.allocator, indexes.x * block_size, indexes.y * block_size),
            });
            self.blocks[indexes.y][indexes.x].type = block.Type.basicTower;
        }
    };
}

test "test map memory allocation and deallocation" {
    const allocator = std.testing.allocator;

    const m = try GameMap().initMap(allocator, 200, 400);
    defer m.deInit();
}
