const std = @import("std");
const shapes = @import("../shapes/shapes.zig");
const block = @import("../objects/block.zig");
const Block = block.Block;
const rl = @import("raylib");

// TODO currently map size must be comptime known
// make it so it can be modified during runtime
pub fn GameMap(sizeX: i32, sizeY: i32) type {
    return struct {
        const Self = @This();
        allocator: std.mem.Allocator,
        // TODO using Rectangle here is very inefficient
        blocks: *[sizeX][sizeY]Block,

        pub fn draw(self: Self) void {
            for (self.blocks) |row| {
                for (row) |b| {
                    b.draw();
                }
            }
        }
        pub fn initMap(allocator: *const std.mem.Allocator) !GameMap(sizeX, sizeY) {
            var result = GameMap(sizeX, sizeY){
                .blocks = try allocator.create([sizeX][sizeY]Block),
                .allocator = allocator,
            };

            for (0..result.data.len) |i| {
                var row = &result.data[i];
                for (0..row.len) |j| {
                    row[j] = .{
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
            return result;
        }

        pub fn deInit(self: Self) void {
            self.allocator.destroy(self.blocks);
        }
    };
}
