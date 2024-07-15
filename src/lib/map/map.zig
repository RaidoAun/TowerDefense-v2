const std = @import("std");
const shapes = @import("../shapes/shapes.zig");
const block = @import("../objects/block.zig");
const Block = block.Block;
const rl = @import("raylib");

pub fn GameMap() type {
    const MapSize = u32;
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
            const block_size = 20;
            const blocks = try allocator.alloc([]Block, sizeY);

            // TODO probably can use FixedBufferAllocator here
            const pattern = try generateMapPattern(allocator, sizeX, sizeY, 1);

            for (blocks, 0..) |*row, i| {
                row.* = try allocator.alloc(Block, sizeX);
                for (row.*, 0..) |*b, j| {
                    const is_wall = pattern[i][j];
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

        fn generateMapPattern(allocator: std.mem.Allocator, sizeX: MapSize, sizeY: MapSize, steps: u8) ![][]bool {
            _ = steps;
            var random = std.Random.DefaultPrng.init(0);

            const pattern = try allocator.alloc([]bool, sizeY);
            for (pattern) |*row| {
                row.* = try allocator.alloc(bool, sizeX);
                for (row.*) |*b| {
                    b.* = random.random().boolean();
                }
            }
            return pattern;
        }

        pub fn deInit(self: Self) void {
            self.allocator.free(self.blocks);
        }
    };
}
