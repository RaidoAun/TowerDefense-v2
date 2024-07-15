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
        _ = steps;
        var random = std.Random.DefaultPrng.init(0);

        const data = try allocator.alloc([]bool, sizeY);
        for (data) |*row| {
            row.* = try allocator.alloc(bool, sizeX);
            for (row.*) |*b| {
                b.* = random.random().boolean();
            }
        }
        return .{
            .data = data,
            .allocator = allocator,
        };
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
            const block_size = 20;
            const blocks = try allocator.alloc([]Block, sizeY);

            // TODO probably can use FixedBufferAllocator here
            const pattern = try Pattern.init(allocator, sizeX, sizeY, 1);
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
