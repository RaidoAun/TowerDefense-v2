const std = @import("std");
const lib = @import("../lib.zig");
const shapes = lib.shape;
const block = lib.object.block;
const towers = lib.object.tower;
const Minigun = towers.Minigun;
const Tower = towers.Tower;
const Block = block.Block;
const monsters = lib.object.monster;
const object_types = lib.object.types;
const Monster = monsters.Monster;
const input = lib.input;
const rl = lib.rl;
const block_size = block.block_size;

pub const MapIndexSize = u32;
pub const MapPixelSize = u32;

const Error = error{
    OutsideMapBounds,
    InvalidKey,
};

pub const Bounds = struct {
    const Self = @This();
    size_x: object_types.Position.T,
    size_y: object_types.Position.T,

    pub fn isObjectOutsideBounds(self: Self, pos: object_types.Position) bool {
        return pos.x < 0 or pos.x > self.size_x or pos.y < 0 or pos.y > self.size_y;
    }
};

const Pattern = struct {
    const Self = @This();
    data: [][]bool,
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator, sizeX: MapIndexSize, sizeY: MapIndexSize, steps: u8) !Pattern {
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
    fn smoothen(allocator: std.mem.Allocator, pattern: [][]bool, sizeX: MapIndexSize, sizeY: MapIndexSize, steps: u8) !void {
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

pub fn MonsterList() type {
    return std.ArrayList(Monster);
}

pub fn GameMap() type {
    return struct {
        const Self = @This();
        allocator: std.mem.Allocator,
        blocks: [][]Block, // only for drawing
        towers: std.AutoArrayHashMap(BlockIndexes, Tower),
        monsters: MonsterList(),
        bounds: Bounds,

        pub fn draw(self: Self) void {
            for (self.blocks) |row| {
                for (row) |b| {
                    b.draw();
                }
            }

            for (self.monsters.items) |m| {
                m.draw();
            }
            for (self.towers.values()) |t| {
                t.draw();
            }
        }

        pub fn update(self: *Self) !void {
            for (self.monsters.items) |*m| {
                m.update();
            }
            for (self.towers.values()) |*t| {
                try t.update(self.bounds, &self.monsters);
            }
        }

        pub fn initMap(allocator: std.mem.Allocator, sizeX: MapIndexSize, sizeY: MapIndexSize) !GameMap() {
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
                .monsters = std.ArrayList(Monster).init(allocator),
                .bounds = .{
                    .size_x = @floatFromInt(blocks.len * block_size),
                    .size_y = @floatFromInt(blocks.len * block_size),
                },
            };
        }

        pub fn deInit(self: *Self) void {
            for (self.blocks) |row| {
                self.allocator.free(row);
            }
            self.allocator.free(self.blocks);
            for (self.towers.values()) |tower| {
                tower.deinit();
            }
            self.towers.deinit();
            self.monsters.deinit();
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

        pub fn getOrCreateTower(self: *Self, pos: input.Position) !?*Tower {
            const indexes = getBlockIndexesWithCoords(pos.x, pos.y);
            if (indexes.y >= self.blocks.len or indexes.x >= self.blocks.len) {
                return Error.OutsideMapBounds;
            }
            const tower_pos = object_types.Position{
                .x = @as(object_types.Position.T, @floatFromInt(indexes.x * block_size)) + @as(object_types.Position.T, block_size) / 2,
                .y = @as(object_types.Position.T, @floatFromInt(indexes.y * block_size)) + @as(object_types.Position.T, block_size) / 2,
            };

            const result = try self.towers.getOrPutValue(indexes, .{
                .basic = Minigun.init(self.allocator, tower_pos),
            });
            if (result.found_existing) {
                return result.value_ptr;
            }

            self.blocks[indexes.y][indexes.x].type = block.Type.tower;
            return null;
        }

        pub fn removeTower(self: *Self, indexes: BlockIndexes) !void {
            if (!self.towers.swapRemove(indexes)) return Error.InvalidKey;
            self.blocks[indexes.y][indexes.x].type = block.Type.empty;
        }

        pub fn createMonster(self: *Self, pos: input.Position) !void {
            const x = @as(object_types.Position.T, @floatFromInt(pos.x));
            const y = @as(object_types.Position.T, @floatFromInt(pos.y));
            try self.monsters.append(.{
                .basic = .{
                    .base = .{
                        .pos = .{
                            .x = x,
                            .y = y,
                        },

                        .hp = 100,
                        .speed = 5,
                    },
                },
            });
        }
    };
}

test "test map memory allocation and deallocation" {
    const allocator = std.testing.allocator;

    var m = try GameMap().initMap(allocator, 200, 400);
    defer m.deInit();
}

test "creating towers on map" {
    const allocator = std.testing.allocator;

    var m = try GameMap().initMap(allocator, 10, 10);
    defer m.deInit();

    try std.testing.expect(m.towers.values().len == 0);

    const t = try m.getOrCreateTower(.{
        .x = 20,
        .y = 20,
    });

    try std.testing.expect(t == null);

    try std.testing.expect(m.towers.values().len == 1);

    const coords = GameMap().getBlockIndexesWithCoords(20, 20);
    try std.testing.expect(m.blocks[coords.y][coords.x].type == block.Type.tower);
    const t2 = try m.getOrCreateTower(.{
        .x = 20,
        .y = 20,
    });
    try std.testing.expect(t2 != null);
    try std.testing.expect(m.towers.values().len == 1);

    try m.removeTower(coords);
    try std.testing.expect(m.towers.values().len == 0);
    try std.testing.expect(m.blocks[coords.y][coords.x].type == block.Type.empty);

    try std.testing.expectError(Error.InvalidKey, m.removeTower(coords));
}

test "creating towers outside map bounds does not panic" {
    const allocator = std.testing.allocator;

    var m = try GameMap().initMap(allocator, 1, 1);
    defer m.deInit();

    try std.testing.expectError(Error.OutsideMapBounds, m.getOrCreateTower(.{ .x = 50, .y = 50 }));
}
