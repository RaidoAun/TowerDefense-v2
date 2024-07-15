const std = @import("std");
const shapes = @import("../shapes/shapes.zig");
const block = @import("../objects/block.zig");
const Block = block.Block;
const rl = @import("raylib");

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
        pub fn initMap(allocator: std.mem.Allocator, sizeX: u32, sizeY: u32) !GameMap() {
            const blocks = try allocator.alloc([]Block, sizeY);
            for (blocks, 0..) |*row, i| {
                row.* = try allocator.alloc(Block, sizeX);
                for (row.*, 0..) |*b, j| {
                    b.* = .{
                        .shape = shapes.Rectangle{
                            .x = @intCast(20 * j),
                            .y = @intCast(20 * i),
                            .width = 10,
                            .height = 10,
                            .color = rl.Color.yellow,
                        },
                        .type = block.Type.wall,
                    };
                }
            }

            return .{
                .blocks = blocks,
                .allocator = allocator,
            };
        }

        pub fn deInit(self: Self) void {
            self.allocator.free(self.blocks);
        }
    };
}
